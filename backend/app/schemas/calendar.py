from __future__ import annotations

from datetime import datetime
from typing import Literal, Optional

from pydantic import BaseModel, ConfigDict, Field


class EventOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    provider: str
    title: Optional[str] = None
    description: Optional[str] = None
    location: Optional[str] = None
    starts_at: Optional[datetime] = None
    ends_at: Optional[datetime] = None
    is_all_day: bool = False


class EventListResponse(BaseModel):
    events: list[EventOut]
    total: int


class DeviceEventIn(BaseModel):
    external_event_id: str = Field(min_length=1)
    title: Optional[str] = None
    description: Optional[str] = None
    location: Optional[str] = None
    starts_at: Optional[datetime] = None
    ends_at: Optional[datetime] = None
    is_all_day: bool = False


class DeviceEventsSyncRequest(BaseModel):
    provider: Literal["apple_device", "android_device"]
    events: list[DeviceEventIn]


class GoogleConnectRequest(BaseModel):
    server_auth_code: str = Field(min_length=1)


class ConnectResponse(BaseModel):
    status: str = "OK"
    provider: str
    connected: bool


class SyncResponse(BaseModel):
    status: str = "OK"
    synced: int


class EventPrepResponse(BaseModel):
    event_id: str
    summary: str
    openers: list[str]
    tips: list[str]
