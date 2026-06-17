from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Any

from fastapi import HTTPException
from sqlalchemy import delete, func, select, update
from sqlalchemy.ext.asyncio import AsyncSession

import app.core.ai as AI
from app.core.agents.usage import pop_usages
from app.core.config import settings
from app.core.database import FeedItemStatus, PodcastJobStatus
from app.models import (
    FeedItem,
    LearningGoal,
    PodcastJob,
    TopicCategory,
    UserGoal,
    UserPreferences,
    UserTopicCategory,
)
from app.worker.podcast_tasks import enqueue_podcast_job
from app.services.token_usage import TokenUsageService


# Image gallery keyed by category ID (matching frontend onboarding categories)
IMAGE_GALLERY: dict[str, list[str]] = {
    # Innovation & Growth
    "ai": [
        "https://images.unsplash.com/photo-1677442136019-21780ecad995",
        "https://images.unsplash.com/photo-1620712943543-bcc4688e7485",
    ],
    "money": [
        "https://images.unsplash.com/photo-1611974765270-ca12586343bb",
        "https://images.unsplash.com/photo-1486406146926-c627a92ad1ab",
    ],
    "startups": [
        "https://images.unsplash.com/photo-1559136555-9303baea8ebd",
        "https://images.unsplash.com/photo-1522071820081-009f0129c71c",
    ],
    "psychology": [
        "https://images.unsplash.com/photo-1507413245164-6160d8298b31",
        "https://images.unsplash.com/photo-1544027993-37dbfe43562a",
    ],
    "habits": [
        "https://images.unsplash.com/photo-1484480974693-6ca0a78fb36b",
        "https://images.unsplash.com/photo-1506784983877-45594efa4cbe",
    ],
    "digital": [
        "https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c",
        "https://images.unsplash.com/photo-1518770660439-4636190af475",
    ],
    # World & Lifestyle
    "world": [
        "https://images.unsplash.com/photo-1451187580459-43490279c0fa",
        "https://images.unsplash.com/photo-1526470608268-f674ce90ebd4",
    ],
    "history": [
        "https://images.unsplash.com/photo-1461360370896-922624d12aa1",
        "https://images.unsplash.com/photo-1555677284-6a6f971638e0",
    ],
    "health": [
        "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b",
        "https://images.unsplash.com/photo-1505576399279-565b52d4ac71",
    ],
    "travel": [
        "https://images.unsplash.com/photo-1544717305-2782549b5136",
        "https://images.unsplash.com/photo-1436491865332-7a61a109cc05",
    ],
    "relationships": [
        "https://images.unsplash.com/photo-1529333166437-7750a6dd5a70",
        "https://images.unsplash.com/photo-1516589178581-6cd7833ae3b2",
    ],
    "food": [
        "https://images.unsplash.com/photo-1504674900247-0877df9cc836",
        "https://images.unsplash.com/photo-1493770348161-369560ae357d",
    ],
    # Culture & Curiosity
    "movies": [
        "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba",
        "https://images.unsplash.com/photo-1536440136628-849c177e76a1",
    ],
    "science": [
        "https://images.unsplash.com/photo-1507413245164-6160d8298b31",
        "https://images.unsplash.com/photo-1532094349884-543bc11b234d",
    ],
    "pop": [
        "https://images.unsplash.com/photo-1514525253161-7a46d19cd819",
        "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f",
    ],
    "facts": [
        "https://images.unsplash.com/photo-1457369804613-52c61a468e7d",
        "https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8",
    ],
    "philosophy": [
        "https://images.unsplash.com/photo-1481627834876-b7833e8f5570",
        "https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c",
    ],
    "internet": [
        "https://images.unsplash.com/photo-1558494949-ef010cbdcc31",
        "https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5",
    ],
    # Fallback
    "general": [
        "https://images.unsplash.com/photo-1451187580459-43490279c0fa",
        "https://images.unsplash.com/photo-1506784983877-45594efa4cbe",
    ],
}


def get_curated_image(category_id: str) -> str:
    """
    Get a curated image URL based on the category ID.
    
    Args:
        category_id: The category ID from user's selected preferences 
                     (e.g., "ai", "travel", "money", "history")
    """
    import random
    
    images = IMAGE_GALLERY.get(category_id, IMAGE_GALLERY["general"])
    return random.choice(images) + "?q=80&w=800&auto=format&fit=crop"





async def generate_topics(count: int, user_id: int, db: AsyncSession) -> list[FeedItem]:
    """
    Generate and persist new feed items for a user.

    - Uses user's selected podcast topic categories as interests
    - Avoids repeating any existing feed item queries for that user
    - Calls Gemini to suggest topics, then enriches each with metadata
    """
    if not settings.GEMINI_API_KEY or not settings.PODCAST_GENERATE_MODEL:
        raise HTTPException(status_code=500, detail="Gemini is not configured")

    # 1) User interests (id + label)
    result = await db.execute(
        select(TopicCategory.id, TopicCategory.label)
        .join(
            UserTopicCategory,
            TopicCategory.id == UserTopicCategory.category_id,
        )
        .where(UserTopicCategory.user_id == user_id)
    )
    user_categories: list[tuple[str, str]] = result.all()  # [(id, label), ...]
    user_category_ids: list[str] = [cat_id for cat_id, _ in user_categories]
    user_topic_labels: list[str] = [label for _, label in user_categories]

    # 2) Already covered (all existing queries for this user)
    result = await db.execute(select(FeedItem.query).where(FeedItem.user_id == user_id))
    already_covered: list[str] = result.scalars().all()
    covered_set = {q.strip().lower() for q in already_covered if q}

    # 3) Ask Gemini for NEW topic suggestions via AI facade
    interests_text = ", ".join(user_topic_labels) if user_topic_labels else "General news, technology, business, science, culture"
    covered_preview = ", ".join(already_covered[:20])

    try:
        llm_res = await AI.suggest_podcast_topics(
            interests=interests_text,
            already_covered=covered_preview,
            count=count,
        )
        suggestions_raw: Any = llm_res.get("topics", [])

        # Record token usage
        await TokenUsageService.record_all(db, pop_usages(llm_res), user_id=user_id, source="gemini")

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error suggesting topics: {type(e).__name__}: {str(e)}")

    if not isinstance(suggestions_raw, list):
        suggestions_raw = []

    # Normalize + de-dupe + exclude already covered
    suggestions: list[dict[str, str | None]] = []
    seen: set[str] = set()

    for item in suggestions_raw:
        if not isinstance(item, dict):
            continue
        query = str(item.get("query", "")).strip()
        title = str(item.get("title", "")).strip() or None
        description = str(item.get("description", "")).strip() or None
        category = str(item.get("category", "")).strip() or None
        if not query:
            continue
        qkey = query.lower()
        if qkey in covered_set or qkey in seen:
            continue
        seen.add(qkey)
        suggestions.append(
            {
                "query": query,
                "title": title,
                "description": description,
                "category": category,
            }
        )
        if len(suggestions) >= count:
            break

    if not suggestions:
        return []

    # 4) Compute positions (append to end of user's feed)
    max_pos_result = await db.execute(select(func.max(FeedItem.position)).where(FeedItem.user_id == user_id))
    max_pos = max_pos_result.scalar_one() or 0
    next_pos = int(max_pos) + 1

    # 5) Persist
    created: list[FeedItem] = []

    for s in suggestions:
        query = (s.get("query") or "").strip()
        category_hint = s.get("category")

        title = str(s.get("title") or query).strip()
        description = str(s.get("description") or "Daily update").strip()

        # Determine category label (for display)
        category_label = ""
        if isinstance(category_hint, str) and category_hint.strip():
            category_label = category_hint.strip()
        else:
            category_label = "General"

        # Pick a random category ID from user's selected categories for image
        import random as rand
        image_category_id = rand.choice(user_category_ids) if user_category_ids else "general"
        image_url = get_curated_image(image_category_id)

        feed_item = FeedItem(
            user_id=user_id,
            query=query,
            category=category_label,
            title=title,
            description=description,
            image_url=image_url,
            status=FeedItemStatus.SUGGESTED,
            position=next_pos,
        )
        next_pos += 1
        db.add(feed_item)
        created.append(feed_item)

    await db.commit()
    for item in created:
        await db.refresh(item)

    return created


async def refresh_feed(count: int, user_id: int, db: AsyncSession) -> tuple[int, list[FeedItem]]:
    """
    Archive all currently suggested feed items for the user, then generate `count` new ones.

    Returns: (archived_count, new_items)
    """
    result = await db.execute(
        update(FeedItem)
        .where(FeedItem.user_id == user_id, FeedItem.status == FeedItemStatus.SUGGESTED)
        .values(status=FeedItemStatus.ARCHIVED)
    )
    archived_count = int(result.rowcount or 0)
    await db.commit()

    new_items = await generate_topics(count, user_id, db)
    return archived_count, new_items


async def play_feed_item(
    feed_item_id: str,
    user_id: int,
    db: AsyncSession,
) -> tuple[FeedItem, PodcastJob]:
    """
    Idempotent function to play a feed item.
    Creates a PodcastJob if one doesn't exist, or returns the existing job.
    Uses row-level locking to handle concurrent requests safely.

    Args:
        feed_item_id: UUID of the feed item
        user_id: ID of the authenticated user
        db: Database session

    Returns:
        Tuple of (feed_item, podcast_job)

    Raises:
        HTTPException: 404 if feed item not found, 403 if access denied
    """
    # Load feed item with FOR UPDATE lock to prevent race conditions
    result = await db.execute(
        select(FeedItem)
        .where(FeedItem.id == feed_item_id)
        .with_for_update()
    )
    feed_item = result.scalar_one_or_none()

    if not feed_item:
        raise HTTPException(status_code=404, detail="Feed item not found")

    # Verify ownership
    if feed_item.user_id != user_id:
        raise HTTPException(status_code=403, detail="Access denied")

    # Idempotency: check if a job already exists
    if feed_item.podcast_job_id:
        # Load existing job to verify it exists
        job_result = await db.execute(
            select(PodcastJob).where(PodcastJob.id == feed_item.podcast_job_id)
        )
        existing_job = job_result.scalar_one_or_none()

        if existing_job:
            # Job exists - check if it's in a terminal state
            if existing_job.status == PodcastJobStatus.COMPLETED:
                # Completed - just return the existing job
                return feed_item, existing_job
            elif existing_job.status == PodcastJobStatus.FAILED:
                # Failed - reset and re-enqueue for retry
                existing_job.status = PodcastJobStatus.QUEUED
                existing_job.progress = 0 if not existing_job.script_json else 20
                existing_job.current_step = "Retrying job..."
                existing_job.error_message = None
                existing_job.completed_segments = 0
                feed_item.status = FeedItemStatus.GENERATING
                await db.commit()
                await db.refresh(existing_job)
                enqueue_podcast_job(existing_job.id)
                return feed_item, existing_job
            else:
                # Job is in a non-terminal state (QUEUED, GENERATING_SCRIPT, GENERATING_AUDIO).
                # Only re-enqueue if the job appears stale (no updates for >30s).
                # This prevents duplicate Celery chains when the task is actively running,
                # while still allowing resume after server restart.
                stale_threshold = timedelta(seconds=30)
                job_updated_at = existing_job.updated_at
                if job_updated_at.tzinfo is None:
                    job_updated_at = job_updated_at.replace(tzinfo=timezone.utc)
                is_stale = (datetime.now(timezone.utc) - job_updated_at) > stale_threshold

                if is_stale:
                    # Task likely died (server restart) - re-enqueue to resume.
                    # Both Celery stages are idempotent:
                    # - script_stage skips if script_json already exists
                    # - audio_stage skips segments that already exist on disk
                    enqueue_podcast_job(existing_job.id)

                return feed_item, existing_job
        else:
            # DB inconsistency: FK points to missing job - clear it and create new
            feed_item.podcast_job_id = None

    # Create new PodcastJob
    job = PodcastJob(
        user_id=user_id,
        topic=feed_item.query,
        status=PodcastJobStatus.QUEUED,
        progress=0,
        current_step="Job queued",
        completed_segments=0,
    )
    db.add(job)
    await db.flush()  # Get the job.id before committing

    # Link feed item to job and update status
    feed_item.podcast_job_id = job.id
    feed_item.status = FeedItemStatus.GENERATING

    await db.commit()
    await db.refresh(job)
    await db.refresh(feed_item)

    # Enqueue the Celery task chain
    enqueue_podcast_job(job.id)

    return feed_item, job


# =============================================================================
# PODCAST PREFERENCES (DB-backed) - Lookup tables & per-user preferences
# =============================================================================


async def list_podcast_topic_categories(db: AsyncSession) -> list[TopicCategory]:
    result = await db.execute(select(TopicCategory).order_by(TopicCategory.label.asc()))
    return result.scalars().all()


async def list_learning_goals(db: AsyncSession) -> list[LearningGoal]:
    result = await db.execute(select(LearningGoal).order_by(LearningGoal.id.asc()))
    return result.scalars().all()


async def get_user_podcast_preferences(user_id: int, db: AsyncSession) -> dict[str, Any]:
    pref_result = await db.execute(
        select(UserPreferences).where(UserPreferences.user_id == user_id)
    )
    pref = pref_result.scalar_one_or_none()

    cat_result = await db.execute(
        select(TopicCategory.id, TopicCategory.label)
        .join(
            UserTopicCategory,
            TopicCategory.id == UserTopicCategory.category_id,
        )
        .where(UserTopicCategory.user_id == user_id)
        .order_by(TopicCategory.label.asc())
    )
    categories: list[dict[str, str]] = [{"id": cid, "label": label} for cid, label in cat_result.all()]

    goal_result = await db.execute(
        select(UserGoal.goal_id).where(UserGoal.user_id == user_id)
    )
    goal_ids: list[int] = goal_result.scalars().all()

    return {
        "language_level": pref.language_level if pref else None,
        "categories": categories,
        "goal_ids": goal_ids,
    }


async def upsert_user_podcast_preferences(user_id: int, req: Any, db: AsyncSession) -> dict[str, Any]:
    """
    Upsert user podcast preferences and replace join-table rows in one transaction.

    Validation:
    - language_level must be 4..9
    - category_ids and goal_ids must be non-empty
    - all category_ids must exist in podcast_topic_categories
    - all goal_ids must exist in learning_goals
    """
    try:
        category_ids: list[str] = [
            str(x).strip()
            for x in (getattr(req, "category_ids", []) or [])
            if str(x).strip()
        ]
        goal_ids: list[int] = [int(x) for x in (getattr(req, "goal_ids", []) or [])]
        language_level = int(getattr(req, "language_level"))

        if language_level < 4 or language_level > 9:
            raise HTTPException(status_code=400, detail="language_level must be between 4 and 9")

        if not category_ids:
            raise HTTPException(status_code=400, detail="category_ids must not be empty")
        if not goal_ids:
            raise HTTPException(status_code=400, detail="goal_ids must not be empty")

        category_ids_set = sorted(set(category_ids))
        goal_ids_set = sorted(set(goal_ids))

        # Validate category IDs
        result = await db.execute(
            select(TopicCategory.id).where(TopicCategory.id.in_(category_ids_set))
        )
        found = set(result.scalars().all())
        invalid = sorted(set(category_ids_set) - found)
        if invalid:
            raise HTTPException(status_code=400, detail=f"Invalid category_ids: {invalid}")

        # Validate goal IDs
        result = await db.execute(select(LearningGoal.id).where(LearningGoal.id.in_(goal_ids_set)))
        found_goals = set(result.scalars().all())
        invalid_goals = sorted(set(goal_ids_set) - found_goals)
        if invalid_goals:
            raise HTTPException(status_code=400, detail=f"Invalid goal_ids: {invalid_goals}")

        # Upsert user_preferences
        pref_result = await db.execute(
            select(UserPreferences).where(UserPreferences.user_id == user_id)
        )
        pref = pref_result.scalar_one_or_none()
        if pref:
            pref.language_level = language_level
            db.add(pref)
        else:
            pref = UserPreferences(user_id=user_id, language_level=language_level)
            db.add(pref)

        # Replace categories
        await db.execute(
            delete(UserTopicCategory).where(UserTopicCategory.user_id == user_id)
        )
        for cid in category_ids_set:
            db.add(UserTopicCategory(user_id=user_id, category_id=cid))

        # Replace goals
        await db.execute(delete(UserGoal).where(UserGoal.user_id == user_id))
        for gid in goal_ids_set:
            db.add(UserGoal(user_id=user_id, goal_id=gid))

        await db.commit()
        return await get_user_podcast_preferences(user_id=user_id, db=db)
    except Exception:
        await db.rollback()
        raise