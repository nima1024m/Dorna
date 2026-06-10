from datetime import datetime
from typing import List, Optional, Literal, Dict
from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.core.config import settings
from app.schemas.base import BaseResponse

ALLOWED_LANGS: tuple[str, ...] = tuple(settings.ASSISTANT_LANGS)
ALLOWED_TONES: tuple[str, ...] = tuple(settings.ASSISTANT_TONES)

LangCode = str
ToneName = str

class CorrectionItem(BaseModel):
    correction_id: str = Field(
        ...,
        description="Correction ID",
        examples=["UUID"],
    )
    changed: bool = Field(
        ...,
        description="Whether this sentence was changed.",
        examples=[True],
    )
    suggestion: str = Field(
        ...,
        description="Corrected sentence with <wrong>/<correct> tags.",
        examples=[
            "He <wrong>want</wrong><correct>wants</correct> to go <wrong>to paris</wrong><correct>to Paris</correct> next <wrong>summers</wrong><correct>summer</correct>."
        ],
    )
    explanation: str = Field(
        ...,
        description="Brief explanation for the change.",
        examples=["Subject-verb agreement; proper noun capitalization; singular/plural fix."],
    )
    original: str = Field(
        ...,
        description="original sentence.",
        examples=["He are fantastic"],
    )


class SuggestGrammarIn(BaseModel):
    content: str = Field(
        ...,
        min_length=1,
        description="Raw English text; agent detects sentence boundaries and fixes grammar.",
        examples=["He want to go paris next summers because he loving art. He are fantastik He is lovely. This are a great ideea."],
    )

    model_config = ConfigDict(extra='allow')


class SuggestGrammarOut(BaseResponse):
    corrections: Optional[List[CorrectionItem]] = Field(
        None,
        description="List of per-sentence corrections when status='OK'. Empty or null when error.",
    )


class SuggestTranslateIn(BaseModel):
    content: str = Field(
        ...,
        min_length=1,
        description="Raw text in English or Persian.",
        examples=["I will arrive tomorrow morning."],
    )
    target_lang: LangCode = Field(
        ...,
        description=f"Target language code. Allowed: {', '.join(ALLOWED_LANGS) or '—'}",
        json_schema_extra={"enum": list(ALLOWED_LANGS)},
        examples=[ALLOWED_LANGS[0]],
    )

    model_config = ConfigDict(extra='allow')

    @field_validator("target_lang")
    @classmethod
    def _validate_lang(cls, v: str) -> str:
        if ALLOWED_LANGS and v not in ALLOWED_LANGS:
            raise ValueError(f"target_lang must be one of {list(ALLOWED_LANGS)}")
        return v


class SuggestTranslateOut(BaseResponse):
    translated: Optional[str] = Field(
        None,
        description="Translated string when status='OK'.",
        examples=["من فردا صبح می‌رسم."],
    )
    correct_input: Optional[str] = Field(
        None,
        description="Correct input",
        examples=["I will arrive [dwwfwf] tomorrow morning"],
    )


class SuggestToneIn(BaseModel):
    content: str = Field(
        ...,
        min_length=1,
        description="Raw English text to be rewritten in the requested tone.",
        examples=["Can you review my report and share your feedback?"],
    )
    target_tone: ToneName = Field(
        ...,
        description=f"Desired tone for rewriting. Allowed: {', '.join(ALLOWED_TONES) or '—'}",
        json_schema_extra={"enum": list(ALLOWED_TONES)},
        examples=[ALLOWED_TONES[0]],
    )
    parent_tone_id: Optional[str] = Field(
        default=None,
        description="Optional parent tone identifier (UUID).",
        examples=["UUID"],
    )

    model_config = ConfigDict(extra='allow')

    @field_validator("target_tone")
    @classmethod
    def _validate_tone(cls, v: str) -> str:
        if ALLOWED_TONES and v not in ALLOWED_TONES:
            raise ValueError(f"target_tone must be one of {list(ALLOWED_TONES)}")
        return v


class SuggestToneOut(BaseResponse):
    adjusted: Optional[str] = Field(
        None,
        description="Rewritten text with the requested tone when status='OK'.",
        examples=["Could you please review my report and share your feedback at your convenience?"],
    )



class GrammarDevelopment(BaseModel):
    topic: str = Field(..., description="The grammar structure (e.g. Present Perfect)")
    rationale: str = Field(..., description="Why the user needs this based on their data")


class VocabImprovement(BaseModel):
    current: str = Field(..., description="The simple/common word used")
    target: str = Field(..., description="The high-impact replacement")


class PersonalizedLearningProfile(BaseModel):
    estimated_clb_level: str = Field(..., description="Estimated CLB level (e.g. CLB 6)")
    misspelled_words: Dict[str, str] = Field(..., description="Tricky spelling mapping (wrong -> correct)")
    linguistic_profile: List[Dict] = Field(..., description="Deep structural patterns identified from history")
    language_development_grammar: List[GrammarDevelopment] = Field(..., description="Advanced structures for growth")
    vocabulary_improvement: List[VocabImprovement] = Field(..., description="Mapping of simple words to Power Words")
    overall_summary: str = Field(..., description="A professional, encouraging growth summary")
    last_reviewed_at: datetime = Field(..., description="Timestamp of the latest analysis")

    model_config = ConfigDict(from_attributes=True)


__all__ = [
    # grammar
    "SuggestGrammarIn",
    "SuggestGrammarOut",
    "CorrectionItem",
    # translate
    "SuggestTranslateIn",
    "SuggestTranslateOut",
    # tone (includes polish)
    "SuggestToneIn",
    "SuggestToneOut",
    # learning
    "PersonalizedLearningProfile",
    # aliases + allowed lists
    "LangCode",
    "ToneName",
    "ALLOWED_LANGS",
    "ALLOWED_TONES",
]
