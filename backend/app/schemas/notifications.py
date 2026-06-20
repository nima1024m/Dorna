from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field


class RegisterTokenRequest(BaseModel):
    token: str = Field(min_length=1)
    platform: Literal["android", "ios"] | None = None


class DeviceTokenActionResponse(BaseModel):
    status: str = "OK"
    registered: bool
