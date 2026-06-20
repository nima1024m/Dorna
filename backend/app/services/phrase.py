from __future__ import annotations

from sqlalchemy import delete, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Phrase, UserSavedPhrase
from app.schemas.phrase import PhraseOut


async def _saved_phrase_ids(db: AsyncSession, user_id: int) -> set[int]:
    res = await db.execute(
        select(UserSavedPhrase.phrase_id).where(UserSavedPhrase.user_id == user_id)
    )
    return {pid for pid in res.scalars().all() if pid is not None}


async def list_phrases(
    db: AsyncSession,
    user_id: int,
    *,
    category: str | None = None,
    query: str | None = None,
    saved_only: bool = False,
) -> list[PhraseOut]:
    saved_ids = await _saved_phrase_ids(db, user_id)
    if saved_only and not saved_ids:
        return []

    stmt = select(Phrase).where(Phrase.is_active.is_(True))
    if saved_only:
        stmt = stmt.where(Phrase.id.in_(saved_ids))
    if category:
        stmt = stmt.where(Phrase.category == category)
    if query and query.strip():
        stmt = stmt.where(Phrase.text.ilike(f"%{query.strip()}%"))
    stmt = stmt.order_by(Phrase.id)

    rows = (await db.execute(stmt)).scalars().all()
    items: list[PhraseOut] = []
    for r in rows:
        item = PhraseOut.model_validate(r)
        item.saved = r.id in saved_ids
        items.append(item)
    return items


async def save_phrase(db: AsyncSession, user_id: int, phrase_id: int) -> None:
    """Idempotently add a phrase to the user's saved collection."""
    existing = await db.execute(
        select(UserSavedPhrase.id).where(
            UserSavedPhrase.user_id == user_id,
            UserSavedPhrase.phrase_id == phrase_id,
        )
    )
    if existing.scalar_one_or_none() is None:
        db.add(UserSavedPhrase(user_id=user_id, phrase_id=phrase_id))
        try:
            await db.commit()
        except IntegrityError:
            # Concurrent save of the same phrase — already there; idempotent.
            await db.rollback()


async def unsave_phrase(db: AsyncSession, user_id: int, phrase_id: int) -> None:
    await db.execute(
        delete(UserSavedPhrase).where(
            UserSavedPhrase.user_id == user_id,
            UserSavedPhrase.phrase_id == phrase_id,
        )
    )
    await db.commit()
