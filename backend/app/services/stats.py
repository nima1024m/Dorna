from __future__ import annotations

from datetime import date, timedelta

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import UserLearningInsights, UserSavedPhrase, UserStats

# Sample seed values for a new user's stats (placeholder until real tracking
# fills them in via the other features). Matches the design mockup.
_SEED = dict(
    streak_days=6,
    longest_streak=6,
    phrases_learned=24,
    conversations=8,
    briefs_heard=12,
)
_SAMPLE_WEAK_AREAS = ["articles (a/an)", "past tense"]

# Increment-able counter fields (used by other features as they ship).
COUNTERS = ("phrases_learned", "conversations", "briefs_heard")


async def get_or_create_stats(db: AsyncSession, user_id: int) -> UserStats:
    res = await db.execute(select(UserStats).where(UserStats.user_id == user_id))
    stats = res.scalar_one_or_none()
    if stats is None:
        stats = UserStats(user_id=user_id, last_active_on=date.today(), **_SEED)
        db.add(stats)
        await db.commit()
    return stats


async def record_activity(db: AsyncSession, user_id: int) -> UserStats:
    """Update the daily streak for an app-open ping."""
    stats = await get_or_create_stats(db, user_id)
    today = date.today()
    last = stats.last_active_on
    if last == today:
        return stats
    if last == today - timedelta(days=1):
        stats.streak_days += 1
    else:
        stats.streak_days = 1
    if stats.streak_days > (stats.longest_streak or 0):
        stats.longest_streak = stats.streak_days
    stats.last_active_on = today
    await db.commit()
    return stats


async def increment_counter(
    db: AsyncSession, user_id: int, field: str, amount: int = 1
) -> UserStats:
    if field not in COUNTERS:
        raise ValueError(f"unknown counter: {field}")
    stats = await get_or_create_stats(db, user_id)
    setattr(stats, field, (getattr(stats, field) or 0) + amount)
    await db.commit()
    return stats


def _weak_areas(insights: UserLearningInsights | None) -> list[str]:
    if insights is not None:
        issues = insights.grammar_issues or {}
        if issues:
            ranked = sorted(issues.items(), key=lambda kv: kv[1], reverse=True)
            return [k for k, _ in ranked[:3]]
        dev = insights.language_development_grammar or []
        topics = [d.get("topic") for d in dev if isinstance(d, dict) and d.get("topic")]
        if topics:
            return topics[:3]
    return list(_SAMPLE_WEAK_AREAS)


async def build_summary(
    db: AsyncSession, user_id: int, stats: UserStats
) -> dict:
    saved = await db.execute(
        select(func.count())
        .select_from(UserSavedPhrase)
        .where(UserSavedPhrase.user_id == user_id)
    )
    saved_count = saved.scalar_one() or 0

    ins = await db.execute(
        select(UserLearningInsights).where(UserLearningInsights.user_id == user_id)
    )
    insights = ins.scalar_one_or_none()

    return {
        "streak_days": stats.streak_days,
        "longest_streak": stats.longest_streak,
        "phrases_learned": stats.phrases_learned,
        "conversations": stats.conversations,
        "briefs_heard": stats.briefs_heard,
        "saved_count": saved_count,
        "weak_areas": _weak_areas(insights),
    }
