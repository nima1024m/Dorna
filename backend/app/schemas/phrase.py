from __future__ import annotations

from pydantic import BaseModel, ConfigDict


class PhraseOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    text: str
    ipa: str | None = None
    translation: str | None = None
    when_to_use: str | None = None
    example: str | None = None
    category: str | None = None
    saved: bool = False


class PhraseListResponse(BaseModel):
    items: list[PhraseOut]
    total: int


class SavedPhraseActionResponse(BaseModel):
    status: str = "OK"
    phrase_id: int
    saved: bool
