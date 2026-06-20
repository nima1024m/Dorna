from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db
from app.core.auth_deps import auth_required
from app.models import User
from app.schemas.stats import ProfileStatsResponse
from app.services.stats import (
    build_summary,
    get_or_create_stats,
    record_activity,
)

router = APIRouter()


@router.get("/me", response_model=ProfileStatsResponse)
async def get_my_stats(
    user: User = Depends(auth_required),
    db: AsyncSession = Depends(get_db),
):
    """Current user's progress summary (streak, counters, saved count, weak areas)."""
    stats = await get_or_create_stats(db, user.id)
    return ProfileStatsResponse(**await build_summary(db, user.id, stats))


@router.post("/activity", response_model=ProfileStatsResponse)
async def post_activity(
    user: User = Depends(auth_required),
    db: AsyncSession = Depends(get_db),
):
    """Record an app-open ping (updates the daily streak) and return the summary."""
    stats = await record_activity(db, user.id)
    return ProfileStatsResponse(**await build_summary(db, user.id, stats))
