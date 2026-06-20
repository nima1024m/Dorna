from __future__ import annotations

from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import DeviceToken


async def register_token(
    db: AsyncSession, user_id: int, token: str, platform: str | None
) -> None:
    """Idempotently bind an FCM token to a user (re-binds if seen before)."""
    res = await db.execute(select(DeviceToken).where(DeviceToken.token == token))
    row = res.scalar_one_or_none()
    if row is None:
        db.add(
            DeviceToken(
                user_id=user_id, token=token, platform=platform, is_active=True
            )
        )
    else:
        row.user_id = user_id
        row.platform = platform or row.platform
        row.is_active = True
    await db.commit()


async def unregister_token(db: AsyncSession, user_id: int, token: str) -> None:
    await db.execute(
        delete(DeviceToken).where(
            DeviceToken.user_id == user_id, DeviceToken.token == token
        )
    )
    await db.commit()


async def active_tokens_for_user(db: AsyncSession, user_id: int) -> list[str]:
    res = await db.execute(
        select(DeviceToken.token).where(
            DeviceToken.user_id == user_id, DeviceToken.is_active.is_(True)
        )
    )
    return [t for t in res.scalars().all() if t]
