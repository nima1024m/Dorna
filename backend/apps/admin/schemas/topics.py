"""Topic & Content management schemas."""
from __future__ import annotations
from typing import Optional, List
from datetime import datetime
from pydantic import BaseModel, Field


# ============================================
# TOPIC LIST & SEARCH
# ============================================

class TopicListRequest(BaseModel):
    page: int = Field(default=1, ge=1)
    page_size: int = Field(default=20, ge=1, le=100)
    
    # Search
    search: Optional[str] = None
    
    # Filters
    is_active: Optional[bool] = None
    category: Optional[str] = None
    geo_code: Optional[str] = None  # US, CA, BC, ON, etc.
    language: Optional[str] = None
    
    # Sorting
    sort_by: str = Field(default="priority", pattern="^(priority|created_timestamp|title|last_refreshed_at)$")
    sort_order: str = Field(default="desc", pattern="^(asc|desc)$")


class TopicSummary(BaseModel):
    topic_id: str
    title: str
    description: Optional[str] = None
    ai_search_prompt: Optional[str] = None
    is_active: bool
    priority: int
    language: Optional[str] = None
    tags: List[str] = []
    geo_codes: List[str] = []
    update_minutes: int
    last_refreshed_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime
    
    # Stats
    news_item_count: Optional[int] = None
    podcast_ready: Optional[bool] = None
    podcast_generated_at: Optional[datetime] = None
    article_ready: Optional[bool] = None
    article_generated_at: Optional[datetime] = None


class TopicListResponse(BaseModel):
    status: str = "OK"
    topics: List[TopicSummary]
    total: int
    page: int
    page_size: int


# ============================================
# TOPIC CRUD
# ============================================

class TopicCreateRequest(BaseModel):
    topic_id: str = Field(min_length=2, max_length=64, pattern="^[a-z0-9_-]+$")
    title: str = Field(min_length=2, max_length=160)
    description: Optional[str] = Field(None, max_length=1000)
    ai_search_prompt: str = Field(min_length=10, max_length=2000)
    tags: List[str] = []
    geo_codes: List[str] = []  # e.g., ["US", "CA", "BC"]
    update_minutes: int = Field(default=60, ge=15, le=1440)
    is_active: bool = True
    priority: int = Field(default=0, ge=0, le=100)
    language: Optional[str] = Field(None, max_length=16)


class TopicUpdateRequest(BaseModel):
    title: Optional[str] = Field(None, min_length=2, max_length=160)
    description: Optional[str] = Field(None, max_length=1000)
    ai_search_prompt: Optional[str] = Field(None, min_length=10, max_length=2000)
    tags: Optional[List[str]] = None
    geo_codes: Optional[List[str]] = None
    update_minutes: Optional[int] = Field(None, ge=15, le=1440)
    is_active: Optional[bool] = None
    priority: Optional[int] = Field(None, ge=0, le=100)
    language: Optional[str] = Field(None, max_length=16)


class TopicDetailResponse(BaseModel):
    status: str = "OK"
    topic: TopicSummary


class TopicActionResponse(BaseModel):
    status: str = "OK"
    message: str
    topic_id: str


# ============================================
# PODCAST SCRIPT
# ============================================

class TopicPodcastTurn(BaseModel):
    speaker: str
    text: str


class TopicPodcastSource(BaseModel):
    title: str
    url: str


class TopicPodcastResponse(BaseModel):
    status: str = "OK"
    topic_id: str
    script: List[TopicPodcastTurn] = []
    sources: List[TopicPodcastSource] = []
    generated_at: Optional[datetime] = None
    error_message: Optional[str] = None


# ============================================
# ARTICLE
# ============================================

class TopicArticleSource(BaseModel):
    title: str
    url: str


class TopicArticleResponse(BaseModel):
    status: str = "OK"
    topic_id: str
    id: str
    title: str
    published_at: datetime
    content: str
    image_url: str
    sources: List[TopicArticleSource] = []
    generated_at: Optional[datetime] = None


class TopicArticleListResponse(BaseModel):
    status: str = "OK"
    topic_id: str
    articles: List[TopicArticleResponse]


# ============================================
# GEO CODES & TAGS (Reference data)
# ============================================

class GeoCodeInfo(BaseModel):
    code: str
    name: str
    country: str


class TagInfo(BaseModel):
    tag: str
    count: int  # How many topics use this tag


class ReferenceDataResponse(BaseModel):
    status: str = "OK"
    geo_codes: List[GeoCodeInfo]
    tags: List[TagInfo]
    languages: List[str]
