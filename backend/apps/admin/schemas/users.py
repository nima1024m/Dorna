"""User management schemas for admin panel."""
from __future__ import annotations
from typing import Optional, List, Any
from datetime import datetime
from pydantic import BaseModel, EmailStr, Field


# ============================================
# USER LIST & SEARCH
# ============================================

class UserListRequest(BaseModel):
    """Request for listing/searching users."""
    page: int = Field(default=1, ge=1)
    page_size: int = Field(default=20, ge=1, le=100)
    
    # Search
    search: Optional[str] = None  # Search by name, email, or ID
    
    # Filters
    status: Optional[str] = None  # active, inactive, locked, deleted
    onboarding_completed: Optional[bool] = None
    clb_level: Optional[str] = None
    
    # Date range
    created_after: Optional[datetime] = None
    created_before: Optional[datetime] = None
    last_active_after: Optional[datetime] = None
    
    # Sorting
    sort_by: str = Field(default="created_timestamp", pattern="^(created_timestamp|updated_timestamp|email|full_name)$")
    sort_order: str = Field(default="desc", pattern="^(asc|desc)$")


class UserSummary(BaseModel):
    """Summarized user info for list view."""
    id: int
    email: str
    full_name: Optional[str] = None
    is_active: bool
    is_deleted: bool
    onboarding_completed: bool
    initial_clb_level: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    
    # Quick stats (nullable for performance)
    total_grammar_corrections: Optional[int] = None
    total_translations: Optional[int] = None

    # Token usage summary
    token_usage: dict = Field(default_factory=dict)
    token_cost_cents: int = 0


class UserListResponse(BaseModel):
    status: str = "OK"
    users: List[UserSummary]
    total: int
    page: int
    page_size: int
    total_pages: int


# ============================================
# USER PROFILE (DETAILED VIEW)
# ============================================

class UserProfile(BaseModel):
    """Full user profile for admin detail view."""
    id: int
    email: str
    full_name: Optional[str] = None
    avatar_url: Optional[str] = None
    
    # Personal
    age: Optional[int] = None
    nationality: Optional[str] = None
    profession: Optional[str] = None
    interests: List[str] = []
    learning_goal: Optional[str] = None
    
    # Status
    is_active: bool
    is_deleted: bool
    onboarding_completed: bool
    initial_clb_level: Optional[str] = None
    
    # Timestamps
    created_at: datetime
    updated_at: datetime
    
    # Note: Raw user content is NOT exposed here (privacy)


class UserProfileResponse(BaseModel):
    status: str = "OK"
    user: UserProfile


# ============================================
# USER ACTIONS
# ============================================

class UserUpdateRequest(BaseModel):
    """Admin update of user profile."""
    full_name: Optional[str] = Field(None, min_length=2, max_length=100)
    is_active: Optional[bool] = None


class UserActionResponse(BaseModel):
    status: str = "OK"
    message: str
    user_id: int


class UserNoteRequest(BaseModel):
    """Add internal admin note about user."""
    content: str = Field(min_length=1, max_length=5000)
    category: Optional[str] = Field(None, pattern="^(warning|info|review|support|other)$")
    is_pinned: bool = False


class UserNoteResponse(BaseModel):
    id: str
    user_id: int
    admin_email: str
    content: str
    category: Optional[str] = None
    is_pinned: bool
    is_resolved: bool
    created_at: datetime


class UserNotesListResponse(BaseModel):
    status: str = "OK"
    notes: List[UserNoteResponse]


class UserFlagRequest(BaseModel):
    """Flag user for review."""
    reason: str = Field(min_length=1, max_length=1000)


# ============================================
# USER LEARNING INSIGHTS (AGGREGATED - NO RAW CONTENT)
# ============================================

class UserLearningInsightsResponse(BaseModel):
    """Language learning insights - only aggregated data, no raw user content."""
    status: str = "OK"
    user_id: int
    
    # CLB Level
    estimated_clb_level: Optional[str] = None
    
    # Grammar patterns (aggregated, not raw sentences)
    grammar_issues: dict = {}  # {"subject-verb agreement": 5, "verb tense": 3}
    
    # Vocabulary insights (aggregated)
    misspelled_word_count: int = 0
    top_misspelled_categories: List[str] = []
    
    # Linguistic profile
    linguistic_patterns: List[dict] = []
    
    # Learning path recommendations
    learning_path: List[dict] = []
    
    # AI Summary (not raw content)
    overall_summary: Optional[str] = None
    
    # Last analysis
    last_processed_at: Optional[datetime] = None


# ============================================
# USER ACTIVITY STATS
# ============================================

class UserActivityStats(BaseModel):
    """Usage statistics for a user."""
    user_id: int
    
    # Counts
    total_grammar_corrections: int = 0
    total_translations: int = 0
    total_tone_adjustments: int = 0
    
    # Time-based
    first_activity: Optional[datetime] = None
    last_activity: Optional[datetime] = None
    days_active: int = 0
    
    # Engagement
    avg_requests_per_day: float = 0.0


class UserActivityResponse(BaseModel):
    status: str = "OK"
    stats: UserActivityStats
