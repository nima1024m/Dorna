from fastapi import APIRouter, Depends
from fastapi.responses import FileResponse
from app.api.deps import get_db
from app.core.auth_deps import auth_required
from app.models import User, PodcastJob, FeedItem
from app.core.config import settings
from app.core.rate_limit import rate_limit_hit
from app.core.database import PodcastJobStatus, FeedItemStatus
from app.schemas.podcast import *
from app.worker.podcast_tasks import enqueue_podcast_job
from app.services.podcast import (
    generate_topics,
    get_user_podcast_preferences,
    list_learning_goals,
    list_podcast_topic_categories,
    play_feed_item,
    refresh_feed,
    upsert_user_podcast_preferences,
)

import json
import base64
import asyncio
import os
from fastapi import WebSocket, WebSocketDisconnect, HTTPException
from typing import List, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select


router = APIRouter()



# --- Routes ---

@router.get("/preferences", response_model=UserPodcastPreferencesResponse)
async def get_preferences(
    user: User = Depends(auth_required),
    db: AsyncSession = Depends(get_db),
):
    """
    Get current user's podcast onboarding preferences.
    """
    data = await get_user_podcast_preferences(user.id, db)
    return UserPodcastPreferencesResponse(**data)


@router.put("/preferences", response_model=UserPodcastPreferencesResponse)
async def put_preferences(
    req: UserPodcastPreferenceUpsertRequest,
    user: User = Depends(auth_required),
    db: AsyncSession = Depends(get_db),
):
    """
    Upsert current user's podcast onboarding preferences.
    Rejects empty category_ids/goal_ids.
    """
    data = await upsert_user_podcast_preferences(user.id, req, db)
    return UserPodcastPreferencesResponse(**data)


@router.get("/categories", response_model=PodcastTopicCategoryListResponse)
async def list_categories(
    user: User = Depends(auth_required),
    db: AsyncSession = Depends(get_db),
):
    """
    List all podcast topic categories (static lookup table).
    """
    rows = await list_podcast_topic_categories(db)
    return PodcastTopicCategoryListResponse(
        categories=[PodcastTopicCategoryOut(id=r.id, label=r.label) for r in rows]
    )


@router.get("/goals", response_model=LearningGoalListResponse)
async def list_goals(
    user: User = Depends(auth_required),
    db: AsyncSession = Depends(get_db),
):
    """
    List all learning goals (static lookup table).
    """
    rows = await list_learning_goals(db)
    return LearningGoalListResponse(
        goals=[
            LearningGoalOut(
                id=r.id,
                key=r.key,
                title=r.title,
                description=r.description,
            )
            for r in rows
        ]
    )

# @router.post("/feed/init", response_model=TopicSuggestionResponse)
# async def suggest_topics(req: TopicSuggestionRequest):
#     """
#     Suggests new topics based on user interests using Gemini Flash.
#     """
#     prompt = f"""
#       You are a curator for a personalized podcast feed.
#       User Interests: {', '.join(req.interests)}.
#       Already covered: {', '.join(req.current_topics[:10])}.
      
#       Suggest 3 NEW, distinct, and highly engaging topics for the "Discover" section.
#       Output strictly a JSON Array: 
#       [ {{ "query": "Brief topic query", "category": "Category Name" }} ]
#     """
    
#     try:
#         # Create content with text
#         content = types.Content(
#             parts=[types.Part(text=prompt)]
#         )
        
#         response = client.models.generate_content(
#             model=settings.PODCAST_GENERATE_MODEL,
#             contents=content,
#             config=types.GenerateContentConfig(
#                 response_mime_type="application/json",
#                 response_schema={
#                     "type": "ARRAY",
#                     "items": {
#                         "type": "OBJECT",
#                         "properties": {
#                             "query": {"type": "STRING"},
#                             "category": {"type": "STRING"}
#                         }
#                     }
#                 }
#             )
#         )
#         topics = json.loads(response.text)
#         return TopicSuggestionResponse(topics=topics)
#     except Exception as e:
#         print(f"Error suggesting topics: {type(e).__name__}: {str(e)}")
#         import traceback
#         traceback.print_exc()
#         raise HTTPException(status_code=500, detail=str(e))


# @router.post("/feed/metadata", response_model=MetadataResponse)
# async def get_metadata(req: MetadataRequest):
#     """
#     Generates Title/Desc using AI, but picks Image deterministically.
#     """
    # prompt = f"""
    #   You are an editor for a premium audio news app.
    #   For the topic: "{req.query}", generate:
    #   1. A catchy, short headline (max 5 words).
    #   2. A 2-sentence intriguing summary.
      
    #   Output JSON.
    # """
    
    # try:
    #     # Create content with text
    #     content = types.Content(
    #         parts=[types.Part(text=prompt)]
    #     )
        
    #     response = client.models.generate_content(
    #         model=settings.PODCAST_GENERATE_MODEL,
    #         contents=content,
    #         config=types.GenerateContentConfig(
    #             response_mime_type="application/json",
    #             response_schema={
    #                 "type": "OBJECT",
    #                 "properties": {
    #                     "title": {"type": "STRING"},
    #                     "description": {"type": "STRING"},
    #                     "category": {"type": "STRING"}
    #                 }
    #             }
    #         )
    #     )
    #     data = json.loads(response.text)
    #     image_url = get_curated_image(req.query)
        
    #     return MetadataResponse(
    #         title=data.get("title", req.query),
    #         description=data.get("description", "Daily update"),
    #         imageUrl=image_url,
    #         category=data.get("category", "General")
    #     )
    # except Exception as e:
    #     print(f"Error getting metadata: {type(e).__name__}: {str(e)}")
    #     import traceback
    #     traceback.print_exc()
    #     raise HTTPException(status_code=500, detail=str(e))

@router.post("/feed/generate", response_model=FeedGenerateResponse)
async def generate_feed(
    req: FeedGenerateRequest,
    user: User = Depends(auth_required),
    db: AsyncSession = Depends(get_db),
):
    """
    Generate a new feed of topics.
    """
    user_id = user.id
    items = await generate_topics(req.count, user_id, db)
    return FeedGenerateResponse(items=items, generated_count=len(items))


@router.get("/feed", response_model=FeedListResponse)
async def list_feed(
    user: User = Depends(auth_required),
    db: AsyncSession = Depends(get_db),
):
    """
    List current feed items for the user (excludes archived).
    """
    result = await db.execute(
        select(FeedItem)
        .where(
            FeedItem.user_id == user.id,
            FeedItem.status != FeedItemStatus.ARCHIVED,
        )
        .order_by(FeedItem.position.asc(), FeedItem.created_at.desc())
    )
    items = result.scalars().all()
    return FeedListResponse(items=items, total=len(items))


@router.post("/feed/refresh", response_model=FeedRefreshResponse)
async def refresh_user_feed(
    req: FeedGenerateRequest,
    user: User = Depends(auth_required),
    db: AsyncSession = Depends(get_db),
):
    """
    Archive all currently suggested feed items for the user and generate a fresh set.
    """
    user_id = user.id
    archived_count, items = await refresh_feed(req.count, user_id, db)
    return FeedRefreshResponse(items=items, archived_count=archived_count)


@router.post("/feed/{feed_item_id}/play", response_model=FeedItemPlayResponse)
async def play_feed_item_route(
    feed_item_id: str,
    user: User = Depends(auth_required),
    db: AsyncSession = Depends(get_db),
):
    """
    Idempotent endpoint to play a feed item.
    Creates a PodcastJob if one doesn't exist, or returns the existing job.
    Uses row-level locking to handle concurrent requests safely.
    """
    feed_item, job = await play_feed_item(feed_item_id, user.id, db)

    return FeedItemPlayResponse(
        feed_item_id=str(feed_item.id),
        podcast_job_id=str(job.id),
        status=job.status.value.lower(),
    )


# =============================================================================
# ASYNC JOB-BASED PODCAST GENERATION (Celery Queue)
# =============================================================================

# @router.post("/create", response_model=PodcastCreateResponse)
# async def create_podcast_job(
#     req: PodcastCreateRequest,
#     user: User = Depends(auth_required),
#     db: AsyncSession = Depends(get_db),
# ):
#     """
#     Create a new podcast generation job.
#     Returns immediately with job_id. Poll /status endpoint for progress.
#     """
#     # Create the job in database
#     job = PodcastJob(
#         user_id=user.id,
#         topic=req.topic,
#         status=PodcastJobStatus.QUEUED,
#         progress=0,
#         current_step="Job queued",
#         completed_segments=0,
#     )
#     db.add(job)
#     await db.commit()
#     await db.refresh(job)

#     # Enqueue the Celery task chain
#     enqueue_podcast_job(job.id)

#     return PodcastCreateResponse(
#         job_id=str(job.id),
#         status="queued",
#     )


@router.get("/{job_id}/status", response_model=PodcastJobStatusResponse)
async def get_podcast_job_status(
    job_id: str,
    user: User = Depends(auth_required),
    db: AsyncSession = Depends(get_db),
):
    """
    Get the status of a podcast generation job.
    Poll this endpoint every 2-3 seconds to track progress.
    """
    # Fetch the job
    result = await db.execute(
        select(PodcastJob).where(PodcastJob.id == job_id)
    )
    job = result.scalar_one_or_none()

    if not job:
        raise HTTPException(status_code=404, detail="Job not found")

    # Verify ownership
    if job.user_id != user.id:
        raise HTTPException(status_code=403, detail="Access denied")

    # Parse script if available
    script = None
    if job.script_json:
        try:
            script_data = json.loads(job.script_json)
            script = [ScriptItem(**item) for item in script_data]
        except Exception:
            script = None

    # Build segments list
    segments: List[PodcastSegmentStatus] = []
    total_segments = job.total_segments or 0

    for i in range(total_segments):
        segment_path = f"{job.audio_folder}/segment_{i}.wav" if job.audio_folder else None
        file_exists = segment_path and os.path.exists(segment_path)

        segments.append(PodcastSegmentStatus(
            index=i,
            url=f"/v1/podcast/{job_id}/audio/{i}" if file_exists else None,
            ready=file_exists,
        ))

    return PodcastJobStatusResponse(
        job_id=str(job.id),
        status=job.status.value.lower(),
        progress=job.progress or 0,
        current_step=job.current_step,
        topic=job.topic,
        script=script,
        total_segments=job.total_segments,
        completed_segments=job.completed_segments or 0,
        segments=segments,
        error_message=job.error_message,
    )


@router.get("/{job_id}/audio/{segment_index}")
async def get_podcast_audio_segment(
    job_id: str,
    segment_index: int,
    user: User = Depends(auth_required),
    db: AsyncSession = Depends(get_db),
):
    """
    Serve an audio segment file for a podcast job.
    """
    # Fetch the job
    result = await db.execute(
        select(PodcastJob).where(PodcastJob.id == job_id)
    )
    job = result.scalar_one_or_none()

    if not job:
        raise HTTPException(status_code=404, detail="Job not found")

    # Verify ownership
    if job.user_id != user.id:
        raise HTTPException(status_code=403, detail="Access denied")

    # Check if audio folder exists
    if not job.audio_folder:
        raise HTTPException(status_code=404, detail="Audio not yet generated")

    # Build file path
    audio_path = f"{job.audio_folder}/segment_{segment_index}.wav"

    if not os.path.exists(audio_path):
        raise HTTPException(status_code=404, detail="Segment not found")

    return FileResponse(
        path=audio_path,
        media_type="audio/wav",
        filename=f"segment_{segment_index}.wav",
    )


# --- Live Conversation (WebSocket) ---
# Note: This is a simplified proxy. A production B2B proxy for Live API is complex.
# This implementation assumes the Python backend acts as a pass-through.

# @router.websocket("/ws/live/{topic}")
# async def websocket_live_endpoint(websocket: WebSocket, topic: str):
#     await websocket.accept()
    
#     # 1. Connect to Gemini Live Session
#     # Note: The live API implementation may vary based on SDK version
#     # This is a simplified implementation
    
#     try:
#         # For now, we'll use a simplified approach
#         # In production, you'd use the actual live API from google-genai
#         async def receive_from_client():
#             """Reads audio from client and processes it"""
#             try:
#                 while True:
#                     data = await websocket.receive_json()
#                     if "audio_data" in data:
#                         # Process audio data here
#                         # For now, just acknowledge receipt
#                         pass
#             except WebSocketDisconnect:
#                 pass

#         async def send_to_client():
#             """Sends audio to client"""
#             try:
#                 # Placeholder for actual live API integration
#                 # This would connect to Gemini Live API and stream audio
#                 while True:
#                     await asyncio.sleep(0.1)
#                     # In production, this would receive audio from Gemini Live API
#             except Exception:
#                 pass
        
#         # Run loops concurrently
#         await asyncio.gather(receive_from_client(), send_to_client())

#     except Exception as e:
#         print(f"Live Session Error: {e}")
#         await websocket.close()