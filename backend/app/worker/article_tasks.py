import asyncio
from contextlib import asynccontextmanager

from celery import shared_task
from sqlalchemy import select
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession

from datetime import datetime, timezone

from app.core.config import settings
from app.models import TopicArticleRefreshJob
from apps.admin.services.topic_service import TopicManagementService

UTC = timezone.utc


@asynccontextmanager
async def _session_scope():
    engine = create_async_engine(settings.DB_URL, echo=False, future=True)
    session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    async with session() as db:
        try:
            yield db
        finally:
            await db.close()
            await engine.dispose()


@shared_task(
    bind=True,
    name="app.worker.article_tasks.generate_topic_articles",
    max_retries=3,
    default_retry_delay=30,
)
def generate_topic_articles(self, topic_id: str, count: int = 3):
    try:
        asyncio.run(_generate_topic_articles(topic_id, count))
    except Exception as exc:
        delay = settings.ARTICLE_REFRESH_RETRY_DELAY_SEC or self.default_retry_delay or 30
        max_retries = settings.ARTICLE_REFRESH_MAX_RETRIES or self.max_retries or 3
        raise self.retry(exc=exc, countdown=delay, max_retries=max_retries)


async def _generate_topic_articles(topic_id: str, count: int):
    async with _session_scope() as db:
        service = TopicManagementService(db)
        await service.generate_topic_articles(topic_id, count=count)


@shared_task(
    bind=True,
    name="app.worker.article_tasks.refresh_active_articles_job",
    max_retries=1,
    default_retry_delay=10,
)
def refresh_active_articles_job(self, job_id: str, topic_ids: list[str], count: int = 3):
    try:
        asyncio.run(_refresh_active_articles_job(job_id, topic_ids, count))
    except Exception as exc:
        raise self.retry(exc=exc)


async def _refresh_active_articles_job(job_id: str, topic_ids: list[str], count: int):
    async with _session_scope() as db:
        res = await db.execute(
            select(TopicArticleRefreshJob).where(TopicArticleRefreshJob.id == job_id)
        )
        job = res.scalar_one_or_none()
        if not job:
            return

        job.status = "running"
        job.started_at = datetime.now(UTC)
        await db.commit()

        service = TopicManagementService(db)
        succeeded = []
        failed = []
        errors = {}
        delay = settings.ARTICLE_REFRESH_RETRY_DELAY_SEC or 30
        max_retries = settings.ARTICLE_REFRESH_MAX_RETRIES or 3

        for topic_id in topic_ids:
            attempt = 0
            while attempt < max_retries:
                try:
                    await service.generate_topic_articles(topic_id, count=count)
                    succeeded.append(topic_id)
                    break
                except Exception as exc:
                    attempt += 1
                    if attempt >= max_retries:
                        failed.append(topic_id)
                        errors[topic_id] = str(exc)
                    else:
                        await asyncio.sleep(delay)

        job.completed_at = datetime.now(UTC)
        if job.started_at and job.completed_at:
            job.duration_seconds = int((job.completed_at - job.started_at).total_seconds())
        job.status = "completed" if not failed else "failed"
        job.succeeded_topics = succeeded
        job.failed_topics = failed
        job.error_details = errors
        await db.commit()
