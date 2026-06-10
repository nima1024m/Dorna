from pydantic import BaseModel, ConfigDict, Field


class TTSAddIn(BaseModel):
    cover_title: str = Field(..., min_length=1)
    user_id: int

    model_config = ConfigDict(extra='forbid')


__all__ = ['TTSAddIn']
