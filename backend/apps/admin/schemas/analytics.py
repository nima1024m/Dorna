"""Analytics & Dashboard schemas."""
from __future__ import annotations
from typing import Optional, List
from datetime import datetime, date
from pydantic import BaseModel, Field


class SystemStatus(BaseModel):
    ai: str
    tts: str
    database: str


class TokenUsagePeriod(BaseModel):
    user_tokens: int
    system_tokens: int
    tts_tokens: int
    user_cost_cents: int
    system_cost_cents: int
    tts_cost_cents: int


# ============================================
# DASHBOARD OVERVIEW
# ============================================

class DashboardOverview(BaseModel):
    """High-level dashboard metrics."""
    
    # User metrics
    total_users: int
    active_users_today: int
    active_users_week: int
    active_users_month: int
    new_users_today: int
    new_users_week: int
    
    # Engagement
    total_requests_today: int
    total_requests_week: int
    avg_requests_per_user: float
    
    # Content
    total_topics: int
    active_topics: int
    
    # System health
    error_rate_percent: float
    avg_response_time_ms: float
    system_status: SystemStatus
    
    # Token usage
    token_usage_7d: TokenUsagePeriod
    token_usage_30d: TokenUsagePeriod
    token_usage_90d: TokenUsagePeriod


class DashboardResponse(BaseModel):
    status: str = "OK"
    overview: DashboardOverview
    updated_at: datetime


# ============================================
# USER GROWTH & RETENTION
# ============================================

class TimeSeriesPoint(BaseModel):
    date: date
    value: int


class UserGrowthRequest(BaseModel):
    start_date: date
    end_date: date
    granularity: str = Field(default="day", pattern="^(day|week|month)$")


class UserGrowthResponse(BaseModel):
    status: str = "OK"
    new_users: List[TimeSeriesPoint]
    cumulative_users: List[TimeSeriesPoint]
    churned_users: List[TimeSeriesPoint]


class RetentionCohort(BaseModel):
    cohort_date: date
    cohort_size: int
    retention_rates: List[float]  # [100%, 80%, 65%, 50%...] for day 0, 1, 2, 3...


class RetentionResponse(BaseModel):
    status: str = "OK"
    cohorts: List[RetentionCohort]


# ============================================
# FEATURE USAGE
# ============================================

class FeatureUsageStat(BaseModel):
    feature: str  # grammar, translate, tone, polish, news, podcast
    total_uses: int
    unique_users: int
    avg_uses_per_user: float


class FeatureUsageResponse(BaseModel):
    status: str = "OK"
    period_start: date
    period_end: date
    features: List[FeatureUsageStat]


# ============================================
# AI & SYSTEM METRICS
# ============================================

class AIModelUsage(BaseModel):
    model_name: str
    total_calls: int
    avg_latency_ms: float
    error_rate_percent: float
    estimated_cost_usd: float


class AIUsageResponse(BaseModel):
    status: str = "OK"
    period_start: date
    period_end: date
    models: List[AIModelUsage]
    total_estimated_cost_usd: float


class ErrorSummary(BaseModel):
    error_type: str
    count: int
    last_occurred: datetime
    sample_message: Optional[str] = None


class ErrorTrackingResponse(BaseModel):
    status: str = "OK"
    period_start: date
    period_end: date
    total_errors: int
    errors: List[ErrorSummary]


# ============================================
# AGGREGATED LANGUAGE INSIGHTS (ALL USERS)
# ============================================

class CommonMistake(BaseModel):
    pattern: str
    frequency: int
    example_correction: Optional[str] = None


class VocabularyGap(BaseModel):
    word: str
    frequency: int
    suggested_replacement: Optional[str] = None


class AggregatedLanguageInsights(BaseModel):
    """Aggregated language learning insights across ALL users."""
    status: str = "OK"
    
    # CLB Distribution
    clb_distribution: dict  # {"CLB 4": 100, "CLB 5": 200, ...}
    
    # Common grammar issues
    top_grammar_issues: List[CommonMistake]
    
    # Vocabulary gaps
    top_vocabulary_gaps: List[VocabularyGap]
    
    # Learning patterns
    avg_improvement_rate: float
    
    # Updated at
    generated_at: datetime
