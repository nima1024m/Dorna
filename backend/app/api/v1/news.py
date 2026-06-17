import json

from fastapi import APIRouter, Depends, UploadFile, File, HTTPException
from google.genai import types
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db
from app.core.auth_deps import auth_required
from app.core.config import settings
from app.core.agents.genai_client import make_genai_client
from app.models import User, UserTopicFeedback
from app.schemas.news import (
    NewsTopicCreate,
    NewsTopicUpdate,
    NewsTopicOut,
    CSVSyncResult,
    UserTopicPreferenceIn,
    UserTopicPreferenceOut,
    UserTopicFeedbackIn,
    UserTopicFeedbackOut,
    NewsFeedOut,
    NewsItemOut,
)
from app.schemas.podcast import NewsPodcastRequest, NewsPodcastResponse, NewsSource, ScriptItem
from app.services import news as news_service
from app.services.podcast import get_curated_image
from app.services.token_usage import TokenUsageService
from app.worker.news_tasks import enqueue_topic_refresh

router = APIRouter()
client = make_genai_client(force_direct=True)  # Google Search grounding — gateway can't proxy it


def _topic_to_out(obj) -> NewsTopicOut:
    return NewsTopicOut(
        topic_id=obj.topic_id,
        title=obj.title,
        description=obj.description,
        ai_search_prompt=obj.ai_search_prompt,
        tags=obj.tags or [],
        geo_codes=obj.geo_codes or [],
        update_minutes=obj.update_minutes,
        is_active=obj.is_active,
        priority=obj.priority,
        language=obj.language,
        last_refreshed_at=obj.last_refreshed_at,
        created_timestamp=obj.created_timestamp,
        updated_timestamp=obj.updated_timestamp,
    )


def _pref_to_out(obj) -> UserTopicPreferenceOut:
    return UserTopicPreferenceOut(
        topic_id=obj.topic_id,
        is_following=obj.is_following,
        is_hidden=obj.is_hidden,
        weight=obj.weight,
        tags=obj.tags or [],
        geo_code=obj.geo_code,
    )


def _feedback_to_out(obj) -> UserTopicFeedbackOut:
    return UserTopicFeedbackOut(
        topic_id=obj.topic_id,
        feedback=obj.feedback,
    )


def _item_to_out(obj) -> NewsItemOut:
    return NewsItemOut(
        id=str(obj.id),
        topic_id=obj.topic_id,
        title=obj.title,
        summary=obj.summary,
        source_url=obj.source_url,
        source_name=obj.source_name,
        image_url=obj.image_url,
        published_at=obj.published_at,
        fetched_at=obj.fetched_at,
        rank_score=obj.rank_score,
        language=obj.language,
    )


@router.get("/topics", response_model=list[NewsTopicOut])
async def list_topics(active_only: bool = True, db: AsyncSession = Depends(get_db)):
    topics = await news_service.list_topics(db, active_only=active_only)
    return [_topic_to_out(t) for t in topics]


@router.post("/topics", response_model=NewsTopicOut)
async def create_topic(
    body: NewsTopicCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(auth_required),
):
    topic = await news_service.create_topic(db, body.model_dump())
    return _topic_to_out(topic)


@router.put("/topics/{topic_id}", response_model=NewsTopicOut)
async def update_topic(
    topic_id: str,
    body: NewsTopicUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(auth_required),
):
    topic = await news_service.update_topic(db, topic_id, {k: v for k, v in body.model_dump().items() if v is not None})
    if not topic:
        raise HTTPException(status_code=404, detail="Topic not found")
    return _topic_to_out(topic)


@router.post("/topics/sync-csv", response_model=CSVSyncResult)
async def sync_topics_csv(
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(auth_required),
):
    if not file.filename.lower().endswith(".csv"):
        raise HTTPException(status_code=400, detail="CSV file required")
    tmp_path = f"/tmp/{file.filename}"
    data = await file.read()
    with open(tmp_path, "wb") as f:
        f.write(data)

    rows = news_service.parse_topics_csv(tmp_path)
    inserted, updated = await news_service.sync_topics_from_csv(db, rows)
    return CSVSyncResult(inserted=inserted, updated=updated, total=len(rows))


@router.post("/topics/{topic_id}/refresh")
async def refresh_topic(
    topic_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(auth_required),
):
    topic = await news_service.get_topic(db, topic_id)
    if not topic:
        raise HTTPException(status_code=404, detail="Topic not found")
    job = await news_service.create_refresh_job(db, topic_id, topic.update_minutes, "admin")
    enqueue_topic_refresh(str(job.id))
    return {"status": "OK", "job_id": str(job.id)}


@router.get("/feed", response_model=NewsFeedOut)
async def get_feed(db: AsyncSession = Depends(get_db), current_user: User = Depends(auth_required)):
    payload = await news_service.get_cached_feed(db, current_user.id)
    topics = [_topic_to_out(t) for t in payload["topics"]]
    items = [_item_to_out(i) for i in payload["items"]]
    return NewsFeedOut(topics=topics, items=items)


@router.get("/preferences", response_model=list[UserTopicPreferenceOut])
async def list_preferences(db: AsyncSession = Depends(get_db), current_user: User = Depends(auth_required)):
    prefs = await news_service.list_user_preferences(db, current_user.id)
    return [_pref_to_out(p) for p in prefs]


@router.post("/preferences", response_model=UserTopicPreferenceOut)
async def upsert_preference(
    body: UserTopicPreferenceIn,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(auth_required),
):
    payload = body.model_dump()
    pref = await news_service.upsert_user_preference(db, current_user.id, payload)
    return _pref_to_out(pref)


@router.get("/feedback", response_model=list[UserTopicFeedbackOut])
async def list_feedback(db: AsyncSession = Depends(get_db), current_user: User = Depends(auth_required)):
    res = await db.execute(
        select(UserTopicFeedback).where(UserTopicFeedback.user_id == current_user.id)
    )
    rows = res.scalars().all()
    return [_feedback_to_out(r) for r in rows]


@router.post("/feedback", response_model=UserTopicFeedbackOut)
async def upsert_feedback(
    body: UserTopicFeedbackIn,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(auth_required),
):
    res = await db.execute(
        select(UserTopicFeedback).where(
            UserTopicFeedback.user_id == current_user.id,
            UserTopicFeedback.topic_id == body.topic_id,
        )
    )
    existing = res.scalar_one_or_none()
    if existing:
        existing.feedback = body.feedback
        db.add(existing)
        await db.commit()
        await db.refresh(existing)
        return _feedback_to_out(existing)

    record = UserTopicFeedback(
        user_id=current_user.id,
        topic_id=body.topic_id,
        feedback=body.feedback,
    )
    db.add(record)
    await db.commit()
    await db.refresh(record)
    return _feedback_to_out(record)


@router.post("/podcast", response_model=NewsPodcastResponse)
async def generate_podcast_from_live_news(
    body: NewsPodcastRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(auth_required),
):
    try:
        topic = (body.topic or "").strip()

        prompt = f"""
You are a podcast producer for a breaking news show.

Hosts:
- Alex: energetic, curious
- Sarah: calm, analytical

Task:
1) Use Google Search to find the TOP 3 real breaking news stories about: "{topic}".
2) Focus on stories from the last 24-48 hours when possible.
3) Create a natural 6-8 turn dialogue (alternating speakers is preferred).
4) The dialogue must be grounded in real reporting; avoid inventing facts.

Output strictly a JSON Array:
[{{"speaker": "Alex"|"Sarah", "text": "..."}}]
"""

        content = types.Content(parts=[types.Part(text=prompt)])
        response = client.models.generate_content(
            model="gemini-2.5-flash-preview-05-20",
            contents=content,
            config=types.GenerateContentConfig(
                tools=[types.Tool(google_search=types.GoogleSearch())],
                response_mime_type="application/json",
                response_schema={
                    "type": "ARRAY",
                    "items": {
                        "type": "OBJECT",
                        "properties": {
                            "speaker": {"type": "STRING"},
                            "text": {"type": "STRING"},
                        },
                    },
                },
            ),
        )

        # Record token usage (exact extraction pattern)
        usage = getattr(response, "usage_metadata", None) or getattr(response, "usageMetadata", None)
        if usage:
            prompt_tokens = getattr(usage, "prompt_token_count", None) or getattr(usage, "promptTokenCount", None)
            completion_tokens = getattr(usage, "candidates_token_count", None) or getattr(usage, "candidatesTokenCount", None)
            total_tokens = getattr(usage, "total_token_count", None) or getattr(usage, "totalTokenCount", None)
            if total_tokens is None and (prompt_tokens is not None or completion_tokens is not None):
                total_tokens = (prompt_tokens or 0) + (completion_tokens or 0)
            if total_tokens is not None:
                await TokenUsageService.record_usage(
                    db,
                    user_id=current_user.id,
                    source="system",
                    model_name="gemini-2.5-flash-preview-05-20",
                    prompt_tokens=int(prompt_tokens or 0),
                    completion_tokens=int(completion_tokens or 0),
                    total_tokens=int(total_tokens or 0),
                )

        script_raw = json.loads(response.text or "[]")
        if not isinstance(script_raw, list):
            script_raw = []

        script: list[ScriptItem] = []
        for item in script_raw:
            if not isinstance(item, dict):
                continue
            try:
                script.append(ScriptItem(**item))
            except Exception:
                continue

        # Extract news sources from search grounding metadata
        sources: list[NewsSource] = []
        seen_urls: set[str] = set()

        candidates = getattr(response, "candidates", None) or []
        if candidates:
            candidate0 = candidates[0]
            gm = getattr(candidate0, "grounding_metadata", None) or getattr(candidate0, "groundingMetadata", None)
            chunks = getattr(gm, "grounding_chunks", None) or getattr(gm, "groundingChunks", None) or []
            for chunk in chunks:
                web = getattr(chunk, "web", None)
                uri = (getattr(web, "uri", None) or "").strip() if web else ""
                title = (getattr(web, "title", None) or "").strip() if web else ""
                if not uri or uri in seen_urls:
                    continue
                seen_urls.add(uri)
                sources.append(NewsSource(title=title or uri, url=uri))
                if len(sources) >= 5:
                    break

        image_url = get_curated_image("general")

        return NewsPodcastResponse(
            topic=topic,
            script=script,
            sources=sources,
            imageUrl=image_url,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
