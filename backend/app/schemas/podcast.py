from __future__ import annotations

from datetime import datetime
import uuid
from typing import List, Optional, Literal
from pydantic import BaseModel, Field, model_validator


# =============================================================================
# FEED ENDPOINTS - Topic Discovery & Metadata
# =============================================================================

# class TopicSuggestionRequest(BaseModel):
#     interests: List[str] = Field(
#         ...,
#         description="User's interest categories (e.g., 'Tech', 'AI', 'Travel')",
#         examples=[["AI", "Technology", "Psychology"]],
#     )
#     current_topics: List[str] = Field(
#         ...,
#         description="Topics already shown to user (to avoid duplicates)",
#         examples=[["Tech news and trends", "AI in healthcare", "Travel hacks"]],
#     )

# class TopicItem(BaseModel):
#     query: str = Field(
#         ...,
#         description="Brief topic query/title for the podcast",
#         examples=["The Future of Remote Work"],
#     )
#     category: str = Field(
#         ...,
#         description="Category for UI grouping",
#         examples=["Technology"],
#     )

# class TopicSuggestionResponse(BaseModel):
#     topics: List[TopicItem]


# -----------------------------------------------------------------------------

# class MetadataRequest(BaseModel):
#     query: str = Field(
#         ...,
#         description="The topic query to generate metadata for",
#         examples=["The Future of Remote Work"],
#     )

# class MetadataResponse(BaseModel):
#     title: str = Field(
#         ...,
#         description="Catchy headline for the podcast (max 5 words)",
#         examples=["Remote Work Revolution"],
#     )
#     description: str = Field(
#         ...,
#         description="2-sentence intriguing summary",
#         examples=["The office is dead, or is it? Discover how companies are reimagining work in 2024."],
#     )
#     imageUrl: str = Field(
#         ...,
#         description="URL for podcast cover image",
#         examples=["https://images.unsplash.com/photo-1518770660439-4636190af475?q=80&w=800"],
#     )
#     category: str = Field(
#         ...,
#         description="Category label for the podcast",
#         examples=["Technology"],
#     )


# =============================================================================
# PODCAST SCRIPT ENDPOINTS - Content Generation
# =============================================================================


class ScriptItem(BaseModel):
    speaker: Literal["Alex", "Sarah"] = Field(
        ...,
        description="Speaker name (Alex or Sarah)",
        examples=["Alex"],
    )
    text: str = Field(
        ...,
        description="The dialogue text for this turn",
        examples=["Welcome to today's episode! We're diving into something that affects millions of workers worldwide."],
    )

class ScriptGenerateRequest(BaseModel):
    topic: str = Field(
        ...,
        description="The podcast topic to generate script for",
        examples=["The Future of Remote Work"],
    )

class ScriptGenerateResponse(BaseModel):
    script: List[ScriptItem]    

# -----------------------------------------------------------------------------

class ExtendScriptRequest(BaseModel):
    podcast_topic: str = Field(
        ...,
        description="Podcast topic/title used as identifier",
        examples=["The Future of Remote Work"],
    )
    current_history: List[ScriptItem] = Field(
        ...,
        description="Previous dialogue turns for context (last 6-10 turns recommended)",
        examples=[
            [
                {"speaker": "Alex", "text": "Welcome to today's episode!"},
                {"speaker": "Sarah", "text": "Let's dive into the data."},
            ]
        ],
    )

class ExtendScriptResponse(BaseModel):
    script: List[ScriptItem]

# =============================================================================
# AUDIO SYNTHESIS ENDPOINT - Text-to-Speech
# =============================================================================

class TTSRequest(BaseModel):
    text: str = Field(
        ...,
        description="The text to synthesize to speech",
        examples=["Welcome to today's episode! We're diving into something exciting."],
    )
    speaker: str = Field(
        ...,
        description="Speaker name for voice selection (Alex or Sarah)",
        examples=["Alex"],
    )
    voice_name: Optional[str] = Field(
        None,
        description="Optional: Override default voice (Charon for Alex, Fenrir for Sarah)",
        examples=["Charon"],
    )

class TTSResponse(BaseModel):
    audio_base64: str = Field(
        ...,
        description="Base64-encoded PCM audio data"
    )

# =============================================================================
# PODCAST JOB ENDPOINTS - Async Celery-based Generation
# =============================================================================

class PodcastCreateRequest(BaseModel):
    """Request to create a new podcast generation job."""
    topic: str = Field(
        ...,
        description="The podcast topic",
        examples=["AI in Healthcare"],
    )


class PodcastCreateResponse(BaseModel):
    """Response after creating a podcast job."""
    job_id: str = Field(..., description="Unique job identifier (UUID)")
    status: str = Field(..., description="Initial job status (queued)")


class PodcastSegmentStatus(BaseModel):
    """Status of a single audio segment."""
    index: int = Field(..., description="Segment index (0-based)")
    url: Optional[str] = Field(
        None,
        description="URL path to audio file (e.g., /files/voices/podcast/{job_id}/segment_0.wav)",
    )
    ready: bool = Field(..., description="Whether the audio file is ready")


class PodcastJobStatusResponse(BaseModel):
    """Full status response for a podcast job."""
    job_id: str = Field(..., description="Unique job identifier")
    status: str = Field(
        ...,
        description="Job status: queued | generating_script | generating_audio | completed | failed",
    )
    progress: int = Field(..., description="Progress percentage (0-100)")
    current_step: Optional[str] = Field(
        None, description="Human-readable current step description"
    )
    topic: str = Field(..., description="The podcast topic")
    script: Optional[List[ScriptItem]] = Field(
        None, description="Script turns (available after script generation)"
    )
    total_segments: Optional[int] = Field(
        None, description="Total number of audio segments"
    )
    completed_segments: int = Field(
        ..., description="Number of completed audio segments"
    )
    segments: List[PodcastSegmentStatus] = Field(
        ..., description="List of all segments with ready status"
    )
    error_message: Optional[str] = Field(
        None, description="Error details if job failed"
    )


# =============================================================================
# PODCAST PREFERENCES (DB) - Lookup tables & per-user preferences
# =============================================================================

class PodcastTopicCategoryOut(BaseModel):
    id: str = Field(
        ...,
        description="Stable category ID (lookup table PK)",
        examples=["internet"],
    )
    label: str = Field(
        ...,
        description="Human readable category label",
        examples=["Internet Mysteries"],
    )


class PodcastTopicCategoryListResponse(BaseModel):
    categories: List[PodcastTopicCategoryOut]


class LearningGoalOut(BaseModel):
    id: int = Field(..., description="Learning goal ID", examples=[1])
    key: str = Field(..., description="Stable goal key", examples=["fluency"])
    title: str = Field(..., description="Goal title", examples=["Improve fluency"])
    description: str = Field(..., description="Goal description")


class LearningGoalListResponse(BaseModel):
    goals: List[LearningGoalOut]


class UserPodcastPreferenceUpsertRequest(BaseModel):
    language_level: int = Field(
        ...,
        ge=4,
        le=9,
        description="User language level (CLB scale 4-9)",
        examples=[6],
    )
    # Frontend-friendly shape (preferred): [{id, label}, ...]
    categories: List[PodcastTopicCategoryOut] = Field(
        default_factory=list,
        description="Selected podcast topic categories (id/label objects). Only id is persisted; label is display-only.",
        examples=[[{"id": "internet", "label": "Internet Mysteries"}]],
    )
    # Back-compat shape: ["internet", ...]
    category_ids: List[str] = Field(
        default_factory=list,
        description="Selected podcast topic category IDs",
        examples=[["tech", "business", "science"]],
    )

    category_labels: List[str] = Field(
        default_factory=list,
        description="Selected podcast topic category labels",
        examples=["Technology", "Business", "Science"],
    )
    goal_ids: List[int] = Field(
        default_factory=list,
        description="Selected learning goal IDs",
        examples=[[1, 5]],
    )

    @model_validator(mode="before")
    @classmethod
    def _normalize_categories(cls, data):
        """
        Accept both:
        - categories: [{id, label}, ...]
        - category_ids: ["id", ...] (+ optional category_labels)
        Normalize into category_ids for persistence/validation.
        """
        if not isinstance(data, dict):
            return data

        categories = data.get("categories")
        category_ids = data.get("category_ids")

        if categories and (not category_ids):
            try:
                data["category_ids"] = [
                    (c.get("id") if isinstance(c, dict) else getattr(c, "id", None))
                    for c in categories
                ]
            except Exception:
                # Let pydantic surface the correct validation error
                return data

        return data


class UserPodcastPreferencesResponse(BaseModel):
    language_level: Optional[int] = Field(
        None,
        description="User language level (CLB scale 4-9). Null if preferences not set.",
        examples=[6],
    )
    categories: List[PodcastTopicCategoryOut] = Field(
        default_factory=list,
        description="Selected categories (id/label objects).",
    )
    goal_ids: List[int] = Field(
        default_factory=list,
        description="Selected learning goal IDs.",
        examples=[[1, 5]],
    )


# =============================================================================
# FEED ITEM (DB-backed) - Persisted user feed
# =============================================================================

class FeedGenerateRequest(BaseModel):
    """Request to generate new feed items (for infinite scroll)."""
    count: int = Field(
        default=3,
        ge=1,
        le=10,
        description="Number of topics to generate (1-10)",
        examples=[5],
    )


class FeedGenerateResponse(BaseModel):
    """Response after generating new feed items."""
    items: List[FeedItemOut]
    generated_count: int = Field(..., description="Number of items generated")


class FeedItemCreateIn(BaseModel):
    """Request to create a feed item (usually called internally after topic suggestion)."""
    query: str = Field(
        ...,
        description="The topic query",
        examples=["The Future of Remote Work"],
    )
    category: Optional[str] = Field(
        None,
        description="Category for UI grouping",
        examples=["Technology"],
    )
    title: Optional[str] = Field(
        None,
        description="AI-generated title",
        examples=["Remote Work Revolution"],
    )
    description: Optional[str] = Field(
        None,
        description="AI-generated description",
        examples=["The office is dead, or is it?"],
    )
    image_url: Optional[str] = Field(
        None,
        description="Cover image URL",
        examples=["https://images.unsplash.com/photo-1518770660439"],
    )
    position: int = Field(
        default=0,
        description="Position in the feed (for ordering)",
    )


class FeedItemOut(BaseModel):
    """Response schema for a persisted feed item."""
    id: uuid.UUID = Field(..., description="Feed item UUID")
    query: str = Field(..., description="Topic query")
    category: Optional[str] = Field(None, description="Category")
    title: Optional[str] = Field(None, description="Title")
    description: Optional[str] = Field(None, description="Description")
    image_url: Optional[str] = Field(None, description="Image URL")
    status: str = Field(..., description="Status: suggested | generating | ready | listened | archived")
    podcast_job_id: Optional[uuid.UUID] = Field(None, description="Linked podcast job ID (if any)")
    position: int = Field(..., description="Position in feed")
    created_at: datetime = Field(..., description="Creation timestamp")
    updated_at: datetime = Field(..., description="Last update timestamp")

    class Config:
        from_attributes = True


class FeedListResponse(BaseModel):
    """Response for listing user's feed items."""
    items: List[FeedItemOut]
    total: int = Field(..., description="Total number of feed items")


class FeedRefreshResponse(BaseModel):
    """Response after refreshing the feed with new topics."""
    items: List[FeedItemOut]
    archived_count: int = Field(..., description="Number of items archived")


class FeedItemPlayResponse(BaseModel):
    """Response when user taps to play a feed item."""
    feed_item_id: str = Field(..., description="Feed item UUID")
    podcast_job_id: str = Field(..., description="Created podcast job UUID")
    status: str = Field(..., description="New status (generating)")


class NewsSource(BaseModel):
    """A news source from Google Search Grounding."""

    title: str = Field(..., description="Title of the news article")
    url: str = Field(..., description="URL to the news article")


class NewsPodcastRequest(BaseModel):
    """Request to generate a podcast script based on live news about a topic."""

    topic: str = Field(
        ...,
        description="The topic to search for live news about",
        examples=["AI developments", "Climate change"],
    )


class NewsPodcastResponse(BaseModel):
    """Response containing podcast script generated from live news."""

    topic: str = Field(..., description="The original topic")
    script: List[ScriptItem] = Field(
        ...,
        description="Podcast dialogue between Alex and Sarah based on real news",
    )
    sources: List[NewsSource] = Field(
        ...,
        description="Real news sources from Google Search Grounding",
    )
    imageUrl: str = Field(..., description="Curated image URL for the topic")


__all__ = [
    # Script Generation
    "ScriptGenerateRequest",
    "ExtendScriptRequest",
    "ExtendScriptResponse",
    "ScriptGenerateResponse",
    "ScriptItem",
    "NewsSource",
    "NewsPodcastRequest",
    "NewsPodcastResponse",
    # Audio Synthesis
    "TTSRequest",
    "TTSResponse",
    # Podcast Job (Celery)
    "PodcastCreateRequest",
    "PodcastCreateResponse",
    "PodcastSegmentStatus",
    "PodcastJobStatusResponse",
    # User Preferences (DB-backed)
    "UserPodcastPreferenceUpsertRequest",
    "UserPodcastPreferencesResponse",
    "PodcastTopicCategoryOut",
    "PodcastTopicCategoryListResponse",
    "LearningGoalOut",
    "LearningGoalListResponse",
    # Feed Items (DB-backed)
    "FeedGenerateRequest",
    "FeedGenerateResponse",
    "FeedItemCreateIn",
    "FeedItemOut",
    "FeedListResponse",
    "FeedRefreshResponse",
    "FeedItemPlayResponse",
]
