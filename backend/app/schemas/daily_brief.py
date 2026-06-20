from __future__ import annotations

from typing import Any

from pydantic import BaseModel


class DailyBriefResponse(BaseModel):
    id: str
    brief_date: str
    status: str
    # { "date": str, "segments": [ {id,label,transcript,highlight,fa}, ... ] }
    content: dict[str, Any]


class DailyBriefStatusResponse(BaseModel):
    status: str
    progress: int
    current_step: str | None = None
    error_message: str | None = None
