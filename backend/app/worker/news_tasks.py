import asyncio
from contextlib import asynccontextmanager
from datetime import datetime, timezone

from celery import shared_task
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy import select, update

from app.core.config import settings
from app.models import NewsTopic, TopicRefreshJob
from app.services.news import refresh_topic_with_ai

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


@shared_task(name="app.worker.news_tasks.refresh_topic_job")
def refresh_topic_job(job_id: str):
    asyncio.run(_refresh_topic_job(job_id))


async def _refresh_topic_job(job_id: str):
    async with _session_scope() as db:
        res = await db.execute(select(TopicRefreshJob).where(TopicRefreshJob.id == job_id))
        job = res.scalar_one_or_none()
        if not job:
            return

        await db.execute(
            update(TopicRefreshJob)
            .where(TopicRefreshJob.id == job_id)
            .values(status="running", started_at=datetime.now(UTC))
        )
        await db.commit()

        try:
            res = await db.execute(select(NewsTopic).where(NewsTopic.topic_id == job.topic_id))
            topic = res.scalar_one_or_none()
            if not topic:
                raise ValueError("topic_not_found")

            window = job.window_minutes or topic.update_minutes
            await refresh_topic_with_ai(db, topic, window)

            await db.execute(
                update(TopicRefreshJob)
                .where(TopicRefreshJob.id == job_id)
                .values(status="completed", completed_at=datetime.now(UTC), error_message=None)
            )
            await db.commit()
        except Exception as e:
            await db.execute(
                update(TopicRefreshJob)
                .where(TopicRefreshJob.id == job_id)
                .values(status="failed", error_message=str(e))
            )
            await db.commit()


def enqueue_topic_refresh(job_id: str) -> None:
    refresh_topic_job.apply_async(args=[job_id], queue="news")
