from __future__ import annotations

from pydantic import BaseModel


class ProfileStatsResponse(BaseModel):
    streak_days: int
    longest_streak: int
    phrases_learned: int
    conversations: int
    briefs_heard: int
    saved_count: int
    weak_areas: list[str]
