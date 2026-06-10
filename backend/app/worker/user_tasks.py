import asyncio
from contextlib import asynccontextmanager

from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy import delete

from app.worker.celery_app import celery_app
from app.core.config import settings
from app.models import User, GrammarSuggestion, Task, ToneAdjustments, TranslateTexts


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


@celery_app.task(name="app.worker.user_tasks.delete_user_task")
def delete_user_task(user_id: int):
    asyncio.run(_delete_user(user_id))


async def _delete_user(user_id):
    async with _session_scope() as db:
        await db.execute(
            delete(User).where(User.id == user_id)
        )
        await db.commit()


@celery_app.task(name="app.worker.user_tasks.delete_personal_data_task")
def delete_personal_data_task(user_id: int):
    asyncio.run(_delete_personal_data(user_id))


async def _delete_personal_data(user_id):
    async with _session_scope() as db:
        await db.execute(
            delete(GrammarSuggestion).where(GrammarSuggestion.user_id == user_id)
        )
        await db.execute(
            delete(ToneAdjustments).where(ToneAdjustments.user_id == user_id)
        )
        await db.execute(
            delete(TranslateTexts).where(TranslateTexts.user_id == user_id)
        )
        await db.execute(
            delete(Task).where(Task.user_id == user_id)
        )
        await db.commit()
