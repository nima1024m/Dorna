from typing import List, Optional, Literal
from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.core.config import settings
from app.schemas.base import BaseResponse


class TrackGrammarIn(BaseModel):
    correction_id: str = Field(
        ...,
        min_length=1,
        description="Correction ID",
        examples=["UUID"],
    )
    action: Literal["approved", "rejected"] = Field(
        ...,
        description="User action",
        examples=["approved", "rejected"],
    )

    model_config = ConfigDict(extra='allow')


class TrackGrammarOut(BaseModel):
    status: Literal["OK", "ERROR"] = Field(
        ...,
        description="Operation status. 'OK' for success, 'ERROR' for failures.",
        examples=["OK"],
    )
    message: str = Field(
        ...,
        min_length=1,
        description="Action message",
        examples=["Action successfully applied."],
    )


class TrackTranslateIn(BaseModel):
    translate_id: str = Field(
        ...,
        min_length=1,
        description="Correction ID",
        examples=["UUID"],
    )
    action: Literal["approved", "rejected"] = Field(
        ...,
        description="User action",
        examples=["approved", "rejected"],
    )

    model_config = ConfigDict(extra='allow')


class TrackTranslateOut(BaseModel):
    status: Literal["OK", "ERROR"] = Field(
        ...,
        description="Operation status. 'OK' for success, 'ERROR' for failures.",
        examples=["OK"],
    )
    message: str = Field(
        ...,
        min_length=1,
        description="Action message",
        examples=["Action successfully applied."],
    )


class TrackToneIn(BaseModel):
    tone_id: str = Field(
        ...,
        min_length=1,
        description="Correction ID",
        examples=["UUID"],
    )
    action: Literal["approved", "rejected"] = Field(
        ...,
        description="User action",
        examples=["approved", "rejected"],
    )

    model_config = ConfigDict(extra='allow')


class TrackToneOut(BaseModel):
    status: Literal["OK", "ERROR"] = Field(
        ...,
        description="Operation status. 'OK' for success, 'ERROR' for failures.",
        examples=["OK"],
    )
    message: str = Field(
        ...,
        min_length=1,
        description="Action message",
        examples=["Action successfully applied."],
    )


__all__ = [
    # grammar
    "TrackGrammarIn",
    "TrackGrammarOut",
    # translate
    "TrackTranslateIn",
    "TrackTranslateOut",
    # tone
    "TrackToneIn",
    "TrackToneOut",
]
