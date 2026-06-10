from __future__ import annotations
from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, Field


class NewsTopicBase(BaseModel):
    topic_id: str = Field(..., min_length=2, max_length=64)
    title: str = Field(..., min_length=2, max_length=160)
    description: Optional[str] = None
    ai_search_prompt: str = Field(..., min_length=5)
    tags: List[str] = []
    geo_codes: List[str] = []
    update_minutes: int = Field(default=60, ge=5, le=1440)
    is_active: bool = True
    priority: int = Field(default=0, ge=0, le=100)
    language: Optional[str] = None


class NewsTopicCreate(NewsTopicBase):
    pass


class NewsTopicUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    ai_search_prompt: Optional[str] = None
    tags: Optional[List[str]] = None
    geo_codes: Optional[List[str]] = None
    update_minutes: Optional[int] = None
    is_active: Optional[bool] = None
    priority: Optional[int] = None
    language: Optional[str] = None


class NewsTopicOut(NewsTopicBase):
    last_refreshed_at: Optional[datetime] = None
    created_timestamp: Optional[datetime] = None
    updated_timestamp: Optional[datetime] = None


class CSVSyncResult(BaseModel):
    inserted: int
    updated: int
    total: int


class UserTopicPreferenceIn(BaseModel):
    topic_id: str
    is_following: Optional[bool] = True
    is_hidden: Optional[bool] = False
    weight: Optional[int] = 0
    tags: Optional[List[str]] = None
    geo_code: Optional[str] = None


class UserTopicPreferenceOut(BaseModel):
    topic_id: str
    is_following: bool
    is_hidden: bool
    weight: int
    tags: List[str]
    geo_code: Optional[str] = None


class UserTopicFeedbackIn(BaseModel):
    topic_id: str
    feedback: str = Field(..., pattern="^(like|dislike)$")


class UserTopicFeedbackOut(BaseModel):
    topic_id: str
    feedback: str


class NewsItemOut(BaseModel):
    id: str
    topic_id: str
    title: str
    summary: Optional[str]
    source_url: str
    source_name: Optional[str]
    image_url: Optional[str]
    published_at: Optional[datetime]
    fetched_at: Optional[datetime]
    rank_score: Optional[float]
    language: Optional[str]


class NewsFeedOut(BaseModel):
    topics: List[NewsTopicOut]
    items: List[NewsItemOut]
