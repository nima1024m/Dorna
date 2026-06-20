from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db
from app.core.auth_deps import auth_required
from app.models import DailyBrief, User
from app.schemas.daily_brief import DailyBriefResponse, DailyBriefStatusResponse
from app.worker.daily_brief_tasks import enqueue_daily_brief

router = APIRouter()


async def _load_today(db: AsyncSession, user_id: int) -> DailyBrief | None:
    today = datetime.now(timezone.utc).date()
    res = await db.execute(
        select(DailyBrief).where(
            DailyBrief.user_id == user_id, DailyBrief.brief_date == today
        )
    )
    return res.scalar_one_or_none()


@router.get("/today", response_model=DailyBriefResponse)
async def get_today_brief(
    user: User = Depends(auth_required),
    db: AsyncSession = Depends(get_db),
):
    """Today's daily brief. If none exists yet, kick off generation and return 202."""
    brief = await _load_today(db, user.id)
    if brief is None:
        enqueue_daily_brief(user.id)
        raise HTTPException(status_code=202, detail="Daily brief is being generated")
    return DailyBriefResponse(
        id=str(brief.id),
        brief_date=brief.brief_date.isoformat(),
        status=brief.status.value.lower(),
        content=brief.content_json or {},
    )


@router.get("/today/status", response_model=DailyBriefStatusResponse)
async def get_today_brief_status(
    user: User = Depends(auth_required),
    db: AsyncSession = Depends(get_db),
):
    brief = await _load_today(db, user.id)
    if brief is None:
        raise HTTPException(status_code=404, detail="No brief for today")
    return DailyBriefStatusResponse(
        status=brief.status.value.lower(),
        progress=brief.progress or 0,
        current_step=brief.current_step,
        error_message=brief.error_message,
    )
