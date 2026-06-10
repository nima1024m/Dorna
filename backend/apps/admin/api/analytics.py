"""Analytics API endpoints for admin dashboard."""
from __future__ import annotations
from datetime import date, datetime, timezone

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from apps.admin.models import AdminUser
from apps.admin.api.deps import get_current_admin, require_role
from apps.admin.services import AnalyticsService
from apps.admin.schemas.analytics import (
    DashboardResponse, DashboardOverview,
    UserGrowthRequest, UserGrowthResponse, TimeSeriesPoint,
    FeatureUsageResponse, FeatureUsageStat,
    AggregatedLanguageInsights
)

router = APIRouter(prefix="/analytics", tags=["Admin - Analytics"])


@router.get("/dashboard", response_model=DashboardResponse)
async def get_dashboard(
    admin: AdminUser = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """Get high-level dashboard overview."""
    service = AnalyticsService(db)
    
    overview_data = await service.get_dashboard_overview()
    
    return DashboardResponse(
        overview=DashboardOverview(**overview_data),
        updated_at=datetime.now(timezone.utc),
    )


@router.get("/user-growth", response_model=UserGrowthResponse)
async def get_user_growth(
    start_date: date = Query(...),
    end_date: date = Query(...),
    granularity: str = Query("day", pattern="^(day|week|month)$"),
    admin: AdminUser = Depends(require_role("super_admin", "admin", "analyst")),
    db: AsyncSession = Depends(get_db),
):
    """Get user growth metrics over time."""
    service = AnalyticsService(db)
    
    data = await service.get_user_growth(start_date, end_date, granularity)
    
    return UserGrowthResponse(
        new_users=[TimeSeriesPoint(**p) for p in data["new_users"]],
        cumulative_users=[TimeSeriesPoint(**p) for p in data["cumulative_users"]],
        churned_users=[TimeSeriesPoint(**p) for p in data["churned_users"]],
    )


@router.get("/feature-usage", response_model=FeatureUsageResponse)
async def get_feature_usage(
    start_date: date = Query(...),
    end_date: date = Query(...),
    admin: AdminUser = Depends(require_role("super_admin", "admin", "analyst")),
    db: AsyncSession = Depends(get_db),
):
    """Get feature usage breakdown."""
    service = AnalyticsService(db)
    
    features = await service.get_feature_usage(start_date, end_date)
    
    return FeatureUsageResponse(
        period_start=start_date,
        period_end=end_date,
        features=[FeatureUsageStat(**f) for f in features],
    )


@router.get("/language-insights", response_model=AggregatedLanguageInsights)
async def get_aggregated_language_insights(
    admin: AdminUser = Depends(require_role("super_admin", "admin", "analyst")),
    db: AsyncSession = Depends(get_db),
):
    """
    Get aggregated language learning insights across ALL users.
    Useful for understanding common patterns and improving the product.
    """
    service = AnalyticsService(db)
    
    insights = await service.get_aggregated_language_insights()
    
    return AggregatedLanguageInsights(**insights)
