import csv
import hashlib
import json
from datetime import datetime, timezone
from typing import Iterable, List, Dict, Any, Tuple

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.agents.grounded import GroundedGeminiAgent
from app.models import NewsTopic, UserTopicPreference, NewsItem, TopicRefreshJob
from app.services.token_usage import TokenUsageService


# Schema for the grounded news-items search. Domain-specific; the grounding
# machinery itself lives in GroundedGeminiAgent.
_NEWS_ITEMS_SCHEMA = {
    "type": "OBJECT",
    "properties": {
        "items": {
            "type": "ARRAY",
            "items": {
                "type": "OBJECT",
                "properties": {
                    "title": {"type": "STRING"},
                    "summary": {"type": "STRING"},
                    "url": {"type": "STRING"},
                    "source_name": {"type": "STRING"},
                    "published_at": {"type": "STRING"},
                    "image_url": {"type": "STRING"},
                    "importance": {"type": "NUMBER"},
                },
            },
        }
    },
}


UTC = timezone.utc


def _parse_list(value: str) -> list:
    if value is None:
        return []
    raw = str(value).strip()
    if not raw:
        return []
    if raw.startswith("[") and raw.endswith("]"):
        try:
            parsed = json.loads(raw)
            if isinstance(parsed, list):
                return [str(x).strip() for x in parsed if str(x).strip()]
        except Exception:
            return []
    return [x.strip() for x in raw.split(",") if x.strip()]


def _parse_bool(value: str) -> bool:
    if value is None:
        return False
    return str(value).strip().lower() in {"1", "true", "yes", "y", "on"}


def _parse_int(value: str, default: int) -> int:
    if value is None or str(value).strip() == "":
        return default
    try:
        return int(str(value).strip())
    except Exception:
        return default


def _hash_item(topic_id: str, source_url: str, title: str) -> str:
    base = f"{topic_id}|{source_url.strip()}|{title.strip()}".lower()
    return hashlib.sha256(base.encode("utf-8")).hexdigest()


def parse_topics_csv(csv_path: str) -> List[Dict[str, Any]]:
    with open(csv_path, "r", encoding="utf-8", errors="replace", newline="") as f:
        reader = csv.DictReader(f)
        rows = []
        for row in reader:
            topic_id = (row.get("topic_id") or "").strip()
            title = (row.get("title") or row.get("title_short") or "").strip()
            prompt = (row.get("ai_search_prompt") or "").strip()
            if not topic_id or not title or not prompt:
                continue
            description = (row.get("description") or row.get("description_short") or "").strip()
            geo_raw = row.get("geo_codes")
            if geo_raw is None:
                geo_raw = row.get("geo_scope")
            is_active_raw = row.get("is_active")
            if is_active_raw is None:
                is_active_raw = row.get("default_enabled")
            rows.append({
                "topic_id": topic_id,
                "title": title,
                "description": description or None,
                "ai_search_prompt": prompt,
                "tags": _parse_list(row.get("tags")),
                "geo_codes": _parse_list(geo_raw),
                "update_minutes": _parse_int(row.get("update_minutes"), 60),
                "is_active": _parse_bool(is_active_raw or "true"),
                "priority": _parse_int(row.get("priority"), 0),
                "language": (row.get("language") or "").strip() or None,
            })
        return rows


async def sync_topics_from_csv(db: AsyncSession, rows: Iterable[Dict[str, Any]]) -> Tuple[int, int]:
    inserted = 0
    updated = 0
    for row in rows:
        topic_id = row["topic_id"]
        res = await db.execute(select(NewsTopic).where(NewsTopic.topic_id == topic_id))
        existing = res.scalar_one_or_none()
        if existing:
            await db.execute(
                update(NewsTopic)
                .where(NewsTopic.topic_id == topic_id)
                .values(**row)
            )
            updated += 1
        else:
            db.add(NewsTopic(**row))
            inserted += 1
    await db.commit()
    return inserted, updated


async def list_topics(db: AsyncSession, active_only: bool) -> List[NewsTopic]:
    q = select(NewsTopic)
    if active_only:
        q = q.where(NewsTopic.is_active == True)
    q = q.order_by(NewsTopic.priority.desc(), NewsTopic.title.asc())
    res = await db.execute(q)
    return res.scalars().all()


async def get_topic(db: AsyncSession, topic_id: str) -> NewsTopic | None:
    res = await db.execute(select(NewsTopic).where(NewsTopic.topic_id == topic_id))
    return res.scalar_one_or_none()


async def create_topic(db: AsyncSession, payload: Dict[str, Any]) -> NewsTopic:
    obj = NewsTopic(**payload)
    db.add(obj)
    await db.commit()
    await db.refresh(obj)
    return obj


async def update_topic(db: AsyncSession, topic_id: str, payload: Dict[str, Any]) -> NewsTopic | None:
    await db.execute(
        update(NewsTopic).where(NewsTopic.topic_id == topic_id).values(**payload)
    )
    await db.commit()
    return await get_topic(db, topic_id)


async def upsert_user_preference(db: AsyncSession, user_id: int, payload: Dict[str, Any]) -> UserTopicPreference:
    topic_id = payload["topic_id"]
    res = await db.execute(
        select(UserTopicPreference).where(
            UserTopicPreference.user_id == user_id,
            UserTopicPreference.topic_id == topic_id,
        )
    )
    pref = res.scalar_one_or_none()
    if pref:
        await db.execute(
            update(UserTopicPreference)
            .where(UserTopicPreference.id == pref.id)
            .values(**payload)
        )
        await db.commit()
        res = await db.execute(select(UserTopicPreference).where(UserTopicPreference.id == pref.id))
        return res.scalar_one()

    obj = UserTopicPreference(user_id=user_id, **payload)
    db.add(obj)
    await db.commit()
    await db.refresh(obj)
    return obj


async def list_user_preferences(db: AsyncSession, user_id: int) -> List[UserTopicPreference]:
    res = await db.execute(
        select(UserTopicPreference).where(UserTopicPreference.user_id == user_id)
    )
    return res.scalars().all()


async def get_cached_feed(db: AsyncSession, user_id: int, limit_per_topic: int = 5) -> Dict[str, Any]:
    topics = await list_topics(db, active_only=True)
    prefs = {p.topic_id: p for p in await list_user_preferences(db, user_id)}
    visible_topics = [
        t for t in topics
        if not prefs.get(t.topic_id) or not prefs[t.topic_id].is_hidden
    ]

    items: List[NewsItem] = []
    for topic in visible_topics:
        res = await db.execute(
            select(NewsItem)
            .where(NewsItem.topic_id == topic.topic_id)
            .order_by(NewsItem.rank_score.desc().nullslast(), NewsItem.published_at.desc().nullslast())
            .limit(limit_per_topic)
        )
        items.extend(res.scalars().all())

    return {"topics": visible_topics, "items": items}


async def create_refresh_job(db: AsyncSession, topic_id: str, window_minutes: int, triggered_by: str) -> TopicRefreshJob:
    job = TopicRefreshJob(
        topic_id=topic_id,
        status="queued",
        window_minutes=window_minutes,
        scheduled_at=datetime.now(UTC),
        triggered_by=triggered_by,
    )
    db.add(job)
    await db.commit()
    await db.refresh(job)
    return job


async def refresh_topic_with_ai(db: AsyncSession, topic: NewsTopic, window_minutes: int) -> int:
    now = datetime.now(UTC)
    window_hours = max(1, int(window_minutes / 60))
    prompt = f"""
You are a news analyst.
Use the instruction below to search for recent news and return the most important items.
Instruction: {topic.ai_search_prompt}
Time window: last {window_hours} hours.

Return JSON in this exact format:
{{
  "items": [
    {{
      "title": "...",
      "summary": "...",
      "url": "...",
      "source_name": "...",
      "published_at": "ISO-8601 timestamp if known",
      "image_url": "...",
      "importance": 0-100
    }}
  ]
}}
"""

    result = GroundedGeminiAgent().generate(
        prompt, schema=_NEWS_ITEMS_SCHEMA, model=settings.PODCAST_GENERATE_MODEL
    )
    await TokenUsageService.record(db, result.usage, user_id=None, source="system")

    payload = result.data or {}
    items = payload.get("items", [])
    dedup = {}
    for item in items:
        url = (item.get("url") or "").strip()
        title = (item.get("title") or "").strip()
        if not url or not title:
            continue
        dedup[url] = item

    inserted = 0
    for item in dedup.values():
        url = item.get("url", "")
        title = item.get("title", "")
        h = _hash_item(topic.topic_id, url, title)
        res = await db.execute(select(NewsItem).where(NewsItem.content_hash == h))
        exists = res.scalar_one_or_none()
        if exists:
            continue

        published_at = None
        if item.get("published_at"):
            try:
                published_at = datetime.fromisoformat(item["published_at"]).astimezone(UTC)
            except Exception:
                published_at = None

        db.add(NewsItem(
            topic_id=topic.topic_id,
            title=title,
            summary=item.get("summary"),
            source_url=url,
            source_name=item.get("source_name"),
            image_url=item.get("image_url"),
            published_at=published_at,
            fetched_at=now,
            rank_score=float(item.get("importance") or 0),
            content_hash=h,
            raw_json=item,
            language=topic.language,
        ))
        inserted += 1

    await db.execute(
        update(NewsTopic)
        .where(NewsTopic.topic_id == topic.topic_id)
        .values(last_refreshed_at=now)
    )
    await db.commit()
    return inserted
