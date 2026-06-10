from typing import List, Optional, Literal
from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.core.config import settings

ALLOWED_LANGS: tuple[str, ...] = tuple(settings.ASSISTANT_LANGS)
ALLOWED_TONES: tuple[str, ...] = tuple(settings.ASSISTANT_TONES)

LangCode = str
ToneName = str


class BaseResponse(BaseModel):
    status: Literal["OK", "ERROR"] = Field(
        ...,
        description="Operation status. 'OK' for success, 'ERROR' for failures.",
        examples=["OK"],
    )
    task: Literal["grammar", "translate", "tone"] = Field(
        ...,
        description="Operation task type.",
        examples=["grammar", "translate", "tone"],
    )
    query_id: str = Field(
        ...,
        description="Operation ID",
        examples=["UUID"],
    )
    message: str = Field(
        None,
        description="Optional message",
        examples=["message text"],
    )
