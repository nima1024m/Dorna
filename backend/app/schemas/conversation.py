from __future__ import annotations

from typing import Any, Optional

from pydantic import BaseModel, Field


class StartConversationRequest(BaseModel):
    scene: str = Field(default="small_talk")


class ConversationStartResponse(BaseModel):
    session_id: str
    scene: str
    opener: str


class TurnRequest(BaseModel):
    text: str = Field(min_length=1)


class TurnResponse(BaseModel):
    reply: str
    correction: Optional[str] = None
    tip: Optional[str] = None


class ConversationTurnOut(BaseModel):
    role: str
    text: str
    feedback: Optional[dict[str, Any]] = None


class ConversationHistoryResponse(BaseModel):
    session_id: str
    scene: str
    turns: list[ConversationTurnOut]
