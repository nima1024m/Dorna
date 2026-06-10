"""Topic management API endpoints for admin panel."""
from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Request, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.database import get_db
from app.models import NewsTopic, TopicArticleRefreshJob
from app.worker.article_tasks import refresh_active_articles_job
from apps.admin.models import AdminUser
from apps.admin.api.deps import get_current_admin, require_role, get_client_ip
from apps.admin.services import TopicManagementService, AuditService
from apps.admin.models.audit_log import AuditAction
from apps.admin.schemas.topics import (
    TopicListRequest, TopicListResponse, TopicSummary,
    TopicCreateRequest, TopicUpdateRequest,
    TopicDetailResponse, TopicActionResponse,
    ReferenceDataResponse, GeoCodeInfo, TagInfo,
    TopicPodcastResponse, TopicPodcastTurn, TopicPodcastSource,
    TopicArticleResponse, TopicArticleSource, TopicArticleListResponse,
)

router = APIRouter(prefix="/topics", tags=["Admin - Topics"])


@router.get("", response_model=TopicListResponse)
async def list_topics(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    search: str = Query(None),
    is_active: bool = Query(None),
    category: str = Query(None),
    geo_code: str = Query(None),
    language: str = Query(None),
    sort_by: str = Query("priority"),
    sort_order: str = Query("desc"),
    admin: AdminUser = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """List and search topics."""
    service = TopicManagementService(db)
    
    topics, total = await service.list_topics(
        page=page,
        page_size=page_size,
        search=search,
        is_active=is_active,
        category=category,
        geo_code=geo_code,
        language=language,
        sort_by=sort_by,
        sort_order=sort_order,
    )
    
    topic_ids = [t.topic_id for t in topics]
    podcast_map = await service.get_podcast_status_map(topic_ids)
    article_map = await service.get_article_status_map(topic_ids)
    topic_summaries = []
    for t in topics:
        podcast_record = podcast_map.get(t.topic_id)
        podcast_ready = bool(podcast_record and podcast_record.status == "READY" and podcast_record.script_json)
        article_record = article_map.get(t.topic_id)
        article_ready = bool(article_record and article_record.content)
        news_count = await service.get_news_item_count(t.topic_id)
        topic_summaries.append(TopicSummary(
            topic_id=t.topic_id,
            title=t.title,
            description=t.description,
            ai_search_prompt=t.ai_search_prompt,
            is_active=t.is_active,
            priority=t.priority,
            language=t.language,
            tags=t.tags or [],
            geo_codes=t.geo_codes or [],
            update_minutes=t.update_minutes,
            last_refreshed_at=t.last_refreshed_at,
            created_at=t.created_timestamp,
            updated_at=t.updated_timestamp,
            news_item_count=news_count,
            podcast_ready=podcast_ready,
            podcast_generated_at=podcast_record.generated_at if podcast_record else None,
            article_ready=article_ready,
            article_generated_at=article_record.generated_at if article_record else None,
        ))
    
    return TopicListResponse(
        topics=topic_summaries,
        total=total,
        page=page,
        page_size=page_size,
    )


@router.get("/reference-data", response_model=ReferenceDataResponse)
async def get_reference_data(
    admin: AdminUser = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """Get reference data for topic forms (geo codes, tags, languages)."""
    service = TopicManagementService(db)
    
    geo_codes = await service.get_all_geo_codes()
    tags = await service.get_all_tags()
    languages = await service.get_all_languages()
    
    return ReferenceDataResponse(
        geo_codes=[GeoCodeInfo(**g) for g in geo_codes],
        tags=[TagInfo(**t) for t in tags],
        languages=languages,
    )


@router.get("/{topic_id}", response_model=TopicDetailResponse)
async def get_topic(
    topic_id: str,
    admin: AdminUser = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """Get a single topic."""
    service = TopicManagementService(db)
    
    topic = await service.get_topic_by_id(topic_id)
    if not topic:
        raise HTTPException(status_code=404, detail="Topic not found")
    
    podcast_map = await service.get_podcast_status_map([topic_id])
    record = podcast_map.get(topic_id)
    podcast_ready = bool(record and record.status == "READY" and record.script_json)
    article_map = await service.get_article_status_map([topic_id])
    article_record = article_map.get(topic_id)
    article_ready = bool(article_record and article_record.content)
    news_count = await service.get_news_item_count(topic_id)
    
    return TopicDetailResponse(
        topic=TopicSummary(
            topic_id=topic.topic_id,
            title=topic.title,
            description=topic.description,
            ai_search_prompt=topic.ai_search_prompt,
            is_active=topic.is_active,
            priority=topic.priority,
            language=topic.language,
            tags=topic.tags or [],
            geo_codes=topic.geo_codes or [],
            update_minutes=topic.update_minutes,
            last_refreshed_at=topic.last_refreshed_at,
            created_at=topic.created_timestamp,
            updated_at=topic.updated_timestamp,
            news_item_count=news_count,
            podcast_ready=podcast_ready,
            podcast_generated_at=record.generated_at if record else None,
            article_ready=article_ready,
            article_generated_at=article_record.generated_at if article_record else None,
        )
    )


@router.post("", response_model=TopicDetailResponse)
async def create_topic(
    req: TopicCreateRequest,
    request: Request,
    admin: AdminUser = Depends(require_role("super_admin", "admin")),
    db: AsyncSession = Depends(get_db),
):
    """Create a new topic."""
    service = TopicManagementService(db)
    
    # Check if topic_id already exists
    existing = await service.get_topic_by_id(req.topic_id)
    if existing:
        raise HTTPException(status_code=400, detail="Topic ID already exists")
    
    topic = await service.create_topic(req.model_dump())
    
    # Log action
    audit = AuditService(db)
    await audit.log_action(
        admin_id=str(admin.id),
        admin_email=admin.email,
        action=AuditAction.TOPIC_CREATE.value,
        resource_type="topic",
        resource_id=topic.topic_id,
        description=f"Created topic: {topic.title}",
        new_value=req.model_dump(),
        ip_address=get_client_ip(request),
        success=True
    )
    
    return TopicDetailResponse(
        topic=TopicSummary(
            topic_id=topic.topic_id,
            title=topic.title,
            description=topic.description,
            ai_search_prompt=topic.ai_search_prompt,
            is_active=topic.is_active,
            priority=topic.priority,
            language=topic.language,
            tags=topic.tags or [],
            geo_codes=topic.geo_codes or [],
            update_minutes=topic.update_minutes,
            last_refreshed_at=topic.last_refreshed_at,
            created_at=topic.created_timestamp,
            updated_at=topic.updated_timestamp,
            news_item_count=0,
        )
    )


@router.patch("/{topic_id}", response_model=TopicDetailResponse)
async def update_topic(
    topic_id: str,
    req: TopicUpdateRequest,
    request: Request,
    admin: AdminUser = Depends(require_role("super_admin", "admin")),
    db: AsyncSession = Depends(get_db),
):
    """Update a topic."""
    service = TopicManagementService(db)
    
    old_topic = await service.get_topic_by_id(topic_id)
    if not old_topic:
        raise HTTPException(status_code=404, detail="Topic not found")
    
    old_state = {
        "title": old_topic.title,
        "is_active": old_topic.is_active,
        "priority": old_topic.priority,
    }
    
    updates = req.model_dump(exclude_unset=True)
    topic = await service.update_topic(topic_id, updates)
    
    new_state = {
        "title": topic.title,
        "is_active": topic.is_active,
        "priority": topic.priority,
    }
    
    # Log action
    audit = AuditService(db)
    await audit.log_action(
        admin_id=str(admin.id),
        admin_email=admin.email,
        action=AuditAction.TOPIC_UPDATE.value,
        resource_type="topic",
        resource_id=topic_id,
        old_value=old_state,
        new_value=new_state,
        ip_address=get_client_ip(request),
        success=True
    )
    
    news_count = await service.get_news_item_count(topic_id)
    
    return TopicDetailResponse(
        topic=TopicSummary(
            topic_id=topic.topic_id,
            title=topic.title,
            description=topic.description,
            ai_search_prompt=topic.ai_search_prompt,
            is_active=topic.is_active,
            priority=topic.priority,
            language=topic.language,
            tags=topic.tags or [],
            geo_codes=topic.geo_codes or [],
            update_minutes=topic.update_minutes,
            last_refreshed_at=topic.last_refreshed_at,
            created_at=topic.created_timestamp,
            updated_at=topic.updated_timestamp,
            news_item_count=news_count,
        )
    )


@router.delete("/{topic_id}", response_model=TopicActionResponse)
async def delete_topic(
    topic_id: str,
    request: Request,
    admin: AdminUser = Depends(require_role("super_admin")),
    db: AsyncSession = Depends(get_db),
):
    """Delete a topic and all its news items."""
    service = TopicManagementService(db)
    
    topic = await service.get_topic_by_id(topic_id)
    if not topic:
        raise HTTPException(status_code=404, detail="Topic not found")
    
    await service.delete_topic(topic_id)
    
    # Log action
    audit = AuditService(db)
    await audit.log_action(
        admin_id=str(admin.id),
        admin_email=admin.email,
        action=AuditAction.TOPIC_DELETE.value,
        resource_type="topic",
        resource_id=topic_id,
        description=f"Deleted topic: {topic.title}",
        ip_address=get_client_ip(request),
        success=True
    )
    
    return TopicActionResponse(message="Topic deleted successfully", topic_id=topic_id)


@router.post("/{topic_id}/activate", response_model=TopicActionResponse)
async def activate_topic(
    topic_id: str,
    request: Request,
    admin: AdminUser = Depends(require_role("super_admin", "admin")),
    db: AsyncSession = Depends(get_db),
):
    """Activate a topic."""
    service = TopicManagementService(db)
    
    topic = await service.get_topic_by_id(topic_id)
    if not topic:
        raise HTTPException(status_code=404, detail="Topic not found")
    
    await service.activate_topic(topic_id)
    
    # Log action
    audit = AuditService(db)
    await audit.log_action(
        admin_id=str(admin.id),
        admin_email=admin.email,
        action=AuditAction.TOPIC_ACTIVATE.value,
        resource_type="topic",
        resource_id=topic_id,
        ip_address=get_client_ip(request),
        success=True
    )
    
    return TopicActionResponse(message="Topic activated", topic_id=topic_id)


@router.post("/{topic_id}/deactivate", response_model=TopicActionResponse)
async def deactivate_topic(
    topic_id: str,
    request: Request,
    admin: AdminUser = Depends(require_role("super_admin", "admin")),
    db: AsyncSession = Depends(get_db),
):
    """Deactivate a topic."""
    service = TopicManagementService(db)
    
    topic = await service.get_topic_by_id(topic_id)
    if not topic:
        raise HTTPException(status_code=404, detail="Topic not found")
    
    await service.deactivate_topic(topic_id)
    
    # Log action
    audit = AuditService(db)
    await audit.log_action(
        admin_id=str(admin.id),
        admin_email=admin.email,
        action=AuditAction.TOPIC_DEACTIVATE.value,
        resource_type="topic",
        resource_id=topic_id,
        ip_address=get_client_ip(request),
        success=True
    )
    
    return TopicActionResponse(message="Topic deactivated", topic_id=topic_id)


@router.post("/{topic_id}/podcast/generate", response_model=TopicPodcastResponse)
async def generate_topic_podcast(
    topic_id: str,
    request: Request,
    admin: AdminUser = Depends(require_role("super_admin", "admin", "moderator")),
    db: AsyncSession = Depends(get_db),
):
    """Generate and store a podcast script for a topic."""
    service = TopicManagementService(db)
    record = await service.generate_topic_podcast(topic_id)

    audit = AuditService(db)
    await audit.log_action(
        admin_id=str(admin.id),
        admin_email=admin.email,
        action=AuditAction.TOPIC_UPDATE.value,
        resource_type="topic",
        resource_id=topic_id,
        description="Generated topic podcast script",
        ip_address=get_client_ip(request),
        success=record.status == "READY"
    )

    return TopicPodcastResponse(
        topic_id=topic_id,
        script=[TopicPodcastTurn(**t) for t in (record.script_json or [])],
        sources=[TopicPodcastSource(**s) for s in (record.sources_json or [])],
        generated_at=record.generated_at,
        error_message=record.error_message,
    )


@router.get("/{topic_id}/podcast", response_model=TopicPodcastResponse)
async def get_topic_podcast(
    topic_id: str,
    admin: AdminUser = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """Get the latest stored podcast script for a topic."""
    service = TopicManagementService(db)
    record = await service.get_topic_podcast(topic_id)
    if not record:
        raise HTTPException(status_code=404, detail="No podcast script found for topic")

    return TopicPodcastResponse(
        topic_id=topic_id,
        script=[TopicPodcastTurn(**t) for t in (record.script_json or [])],
        sources=[TopicPodcastSource(**s) for s in (record.sources_json or [])],
        generated_at=record.generated_at,
        error_message=record.error_message,
    )


@router.post("/{topic_id}/articles/generate", response_model=TopicArticleListResponse)
async def generate_topic_article(
    topic_id: str,
    request: Request,
    count: int = Query(3, ge=1, le=5),
    admin: AdminUser = Depends(require_role("super_admin", "admin", "moderator")),
    db: AsyncSession = Depends(get_db),
):
    """Generate and store multiple long-form articles for a topic."""
    service = TopicManagementService(db)
    records = await service.generate_topic_articles(topic_id, count=count)

    audit = AuditService(db)
    await audit.log_action(
        admin_id=str(admin.id),
        admin_email=admin.email,
        action=AuditAction.TOPIC_UPDATE.value,
        resource_type="topic",
        resource_id=topic_id,
        description="Generated topic article",
        ip_address=get_client_ip(request),
        success=True
    )

    return TopicArticleListResponse(
        topic_id=topic_id,
        articles=[
            TopicArticleResponse(
                topic_id=topic_id,
                id=str(r.id),
                title=r.title,
                published_at=r.published_at,
                content=r.content,
                image_url=r.image_url,
                sources=[TopicArticleSource(**s) for s in (r.sources_json or [])],
                generated_at=r.generated_at,
            )
            for r in records
        ],
    )


@router.post("/articles/refresh-active")
async def refresh_active_topic_articles(
    request: Request,
    count: int = Query(3, ge=1, le=5),
    admin: AdminUser = Depends(require_role("super_admin", "admin", "moderator")),
    db: AsyncSession = Depends(get_db),
):
    """Queue article generation for all active topics."""
    result = await db.execute(select(NewsTopic).where(NewsTopic.is_active == True))
    topics = list(result.scalars().all())

    topic_ids = [t.topic_id for t in topics]
    job = TopicArticleRefreshJob(
        topic_ids=topic_ids,
        total_topics=len(topic_ids),
        status="queued",
        triggered_by=str(admin.id),
    )
    db.add(job)
    await db.commit()
    await db.refresh(job)

    refresh_active_articles_job.apply_async(args=[str(job.id), topic_ids, count], queue="news")

    audit = AuditService(db)
    await audit.log_action(
        admin_id=str(admin.id),
        admin_email=admin.email,
        action=AuditAction.TOPIC_UPDATE.value,
        resource_type="topic",
        resource_id="bulk",
        description=f"Queued article refresh for {len(topics)} active topics",
        ip_address=get_client_ip(request),
        success=True,
    )

    return {
        "status": "OK",
        "job_id": str(job.id),
        "queued_topics": len(topics),
        "count_per_topic": count,
    }


@router.get("/articles/refresh-active/{job_id}")
async def get_refresh_active_job(
    job_id: str,
    admin: AdminUser = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """Get status and logs for a bulk article refresh job."""
    result = await db.execute(
        select(TopicArticleRefreshJob).where(TopicArticleRefreshJob.id == job_id)
    )
    job = result.scalar_one_or_none()
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")

    return {
        "status": "OK",
        "job": {
            "id": str(job.id),
            "state": job.status,
            "total_topics": job.total_topics,
            "succeeded_topics": job.succeeded_topics or [],
            "failed_topics": job.failed_topics or [],
            "error_details": job.error_details or {},
            "started_at": job.started_at,
            "completed_at": job.completed_at,
            "duration_seconds": job.duration_seconds,
            "created_at": job.created_timestamp,
        },
    }


@router.get("/{topic_id}/articles", response_model=TopicArticleListResponse)
async def get_topic_article(
    topic_id: str,
    admin: AdminUser = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """Get stored articles for a topic."""
    service = TopicManagementService(db)
    records = await service.get_topic_articles(topic_id)
    if not records:
        raise HTTPException(status_code=404, detail="No article found for topic")

    return TopicArticleListResponse(
        topic_id=topic_id,
        articles=[
            TopicArticleResponse(
                topic_id=topic_id,
                id=str(r.id),
                title=r.title,
                published_at=r.published_at,
                content=r.content,
                image_url=r.image_url,
                sources=[TopicArticleSource(**s) for s in (r.sources_json or [])],
                generated_at=r.generated_at,
            )
            for r in records
        ],
    )


@router.post("/articles/{article_id}/image/refresh", response_model=TopicArticleResponse)
async def refresh_article_image(
    article_id: str,
    request: Request,
    admin: AdminUser = Depends(require_role("super_admin", "admin", "moderator")),
    db: AsyncSession = Depends(get_db),
):
    """Regenerate image URL for a single article."""
    service = TopicManagementService(db)
    record = await service.refresh_article_image(article_id)
    if not record:
        raise HTTPException(status_code=404, detail="Article not found")

    audit = AuditService(db)
    await audit.log_action(
        admin_id=str(admin.id),
        admin_email=admin.email,
        action=AuditAction.TOPIC_UPDATE.value,
        resource_type="topic_article",
        resource_id=str(record.id),
        description="Refreshed article image",
        ip_address=get_client_ip(request),
        success=True
    )

    return TopicArticleResponse(
        topic_id=record.topic_id,
        id=str(record.id),
        title=record.title,
        published_at=record.published_at,
        content=record.content,
        image_url=record.image_url,
        sources=[TopicArticleSource(**s) for s in (record.sources_json or [])],
        generated_at=record.generated_at,
    )
