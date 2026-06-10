"""Analytics service for admin dashboard."""
from __future__ import annotations
from typing import List, Optional
from datetime import datetime, date, timedelta, timezone

from sqlalchemy import select, func, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import (
    User,
    GrammarSuggestion,
    TranslateTexts,
    ToneAdjustments,
    NewsTopic,
    UserLearningInsights,
)
from app.services.system import SystemService
from app.models import TokenUsageDaily


class AnalyticsService:
    """Service for generating analytics and dashboards."""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    # ==========================================
    # DASHBOARD OVERVIEW
    # ==========================================
    
    async def get_dashboard_overview(self) -> dict:
        """Get high-level dashboard metrics."""
        now = datetime.now(timezone.utc)
        today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
        week_ago = now - timedelta(days=7)
        month_ago = now - timedelta(days=30)
        quarter_ago = now - timedelta(days=90)
        
        # User counts
        total_users = await self.db.scalar(
            select(func.count()).select_from(User).where(User.is_deleted == False)
        ) or 0
        
        new_users_today = await self.db.scalar(
            select(func.count()).select_from(User).where(
                and_(User.created_timestamp >= today_start, User.is_deleted == False)
            )
        ) or 0
        
        new_users_week = await self.db.scalar(
            select(func.count()).select_from(User).where(
                and_(User.created_timestamp >= week_ago, User.is_deleted == False)
            )
        ) or 0
        
        # Active users (based on updated_timestamp as proxy for activity)
        active_today = await self.db.scalar(
            select(func.count()).select_from(User).where(
                and_(User.updated_timestamp >= today_start, User.is_active == True)
            )
        ) or 0
        
        active_week = await self.db.scalar(
            select(func.count()).select_from(User).where(
                and_(User.updated_timestamp >= week_ago, User.is_active == True)
            )
        ) or 0
        
        active_month = await self.db.scalar(
            select(func.count()).select_from(User).where(
                and_(User.updated_timestamp >= month_ago, User.is_active == True)
            )
        ) or 0
        
        # Topics
        total_topics = await self.db.scalar(
            select(func.count()).select_from(NewsTopic)
        ) or 0
        
        active_topics = await self.db.scalar(
            select(func.count()).select_from(NewsTopic).where(NewsTopic.is_active == True)
        ) or 0
        
        # Requests today (simple approximation)
        grammar_today = await self.db.scalar(
            select(func.count()).select_from(GrammarSuggestion).where(
                GrammarSuggestion.created_timestamp >= today_start
            )
        ) or 0
        
        translate_today = await self.db.scalar(
            select(func.count()).select_from(TranslateTexts).where(
                TranslateTexts.created_timestamp >= today_start
            )
        ) or 0
        
        total_requests_today = grammar_today + translate_today

        # System status checks
        ai_status = "unknown"
        try:
            ai_ok = await SystemService.ai_health()
            ai_status = "online" if ai_ok else "offline"
        except Exception:
            ai_status = "offline"

        tts_status = "unknown"
        try:
            tts_ok = await SystemService.tts_health()
            tts_status = "online" if tts_ok else "offline"
        except Exception:
            tts_status = "offline"

        db_status = "unknown"
        try:
            await self.db.execute(select(1))
            db_status = "healthy"
        except Exception:
            db_status = "down"

        token_usage_7d = await self._get_token_usage_summary(week_ago.date())
        token_usage_30d = await self._get_token_usage_summary(month_ago.date())
        token_usage_90d = await self._get_token_usage_summary(quarter_ago.date())
        
        return {
            "total_users": total_users,
            "active_users_today": active_today,
            "active_users_week": active_week,
            "active_users_month": active_month,
            "new_users_today": new_users_today,
            "new_users_week": new_users_week,
            "total_requests_today": total_requests_today,
            "total_requests_week": 0,  # Would need more tracking
            "avg_requests_per_user": round(total_requests_today / max(active_today, 1), 2),
            "total_topics": total_topics,
            "active_topics": active_topics,
            "error_rate_percent": 0.0,  # Would need error tracking
            "avg_response_time_ms": 0.0,  # Would need perf tracking
            "system_status": {
                "ai": ai_status,
                "tts": tts_status,
                "database": db_status,
            },
            "token_usage_7d": token_usage_7d,
            "token_usage_30d": token_usage_30d,
            "token_usage_90d": token_usage_90d,
        }

    async def _get_token_usage_summary(self, start_date: date) -> dict:
        user_tokens = await self.db.scalar(
            select(func.coalesce(func.sum(TokenUsageDaily.total_tokens), 0))
            .where(
                and_(
                    TokenUsageDaily.usage_date >= start_date,
                    TokenUsageDaily.user_id.is_not(None),
                    TokenUsageDaily.source != "tts",
                )
            )
        ) or 0

        user_cost_cents = await self.db.scalar(
            select(func.coalesce(func.sum(TokenUsageDaily.cost_cents), 0))
            .where(
                and_(
                    TokenUsageDaily.usage_date >= start_date,
                    TokenUsageDaily.user_id.is_not(None),
                    TokenUsageDaily.source != "tts",
                )
            )
        ) or 0

        system_tokens = await self.db.scalar(
            select(func.coalesce(func.sum(TokenUsageDaily.total_tokens), 0))
            .where(
                and_(
                    TokenUsageDaily.usage_date >= start_date,
                    TokenUsageDaily.user_id.is_(None),
                    TokenUsageDaily.source != "tts",
                )
            )
        ) or 0

        system_cost_cents = await self.db.scalar(
            select(func.coalesce(func.sum(TokenUsageDaily.cost_cents), 0))
            .where(
                and_(
                    TokenUsageDaily.usage_date >= start_date,
                    TokenUsageDaily.user_id.is_(None),
                    TokenUsageDaily.source != "tts",
                )
            )
        ) or 0

        tts_tokens = await self.db.scalar(
            select(func.coalesce(func.sum(TokenUsageDaily.total_tokens), 0))
            .where(
                and_(
                    TokenUsageDaily.usage_date >= start_date,
                    TokenUsageDaily.source == "tts",
                )
            )
        ) or 0

        tts_cost_cents = await self.db.scalar(
            select(func.coalesce(func.sum(TokenUsageDaily.cost_cents), 0))
            .where(
                and_(
                    TokenUsageDaily.usage_date >= start_date,
                    TokenUsageDaily.source == "tts",
                )
            )
        ) or 0

        return {
            "user_tokens": int(user_tokens),
            "system_tokens": int(system_tokens),
            "tts_tokens": int(tts_tokens),
            "user_cost_cents": int(user_cost_cents),
            "system_cost_cents": int(system_cost_cents),
            "tts_cost_cents": int(tts_cost_cents),
        }
    
    # ==========================================
    # USER GROWTH
    # ==========================================
    
    async def get_user_growth(
        self,
        start_date: date,
        end_date: date,
        granularity: str = "day"
    ) -> dict:
        """Get user growth over time."""
        
        # For simplicity, we'll return daily counts
        # In production, you'd use proper date_trunc queries
        
        new_users = []
        cumulative = []
        
        current = start_date
        running_total = await self.db.scalar(
            select(func.count()).select_from(User).where(
                and_(
                    User.created_timestamp < datetime.combine(start_date, datetime.min.time()),
                    User.is_deleted == False
                )
            )
        ) or 0
        
        while current <= end_date:
            day_start = datetime.combine(current, datetime.min.time())
            day_end = datetime.combine(current + timedelta(days=1), datetime.min.time())
            
            day_count = await self.db.scalar(
                select(func.count()).select_from(User).where(
                    and_(
                        User.created_timestamp >= day_start,
                        User.created_timestamp < day_end,
                        User.is_deleted == False
                    )
                )
            ) or 0
            
            running_total += day_count
            
            new_users.append({"date": current, "value": day_count})
            cumulative.append({"date": current, "value": running_total})
            
            current += timedelta(days=1)
        
        return {
            "new_users": new_users,
            "cumulative_users": cumulative,
            "churned_users": [],  # Would need churn tracking
        }
    
    # ==========================================
    # FEATURE USAGE
    # ==========================================
    
    async def get_feature_usage(self, start_date: date, end_date: date) -> List[dict]:
        """Get feature usage breakdown."""
        
        start_dt = datetime.combine(start_date, datetime.min.time())
        end_dt = datetime.combine(end_date + timedelta(days=1), datetime.min.time())
        
        features = []
        
        # Grammar
        grammar_count = await self.db.scalar(
            select(func.count()).select_from(GrammarSuggestion).where(
                and_(
                    GrammarSuggestion.created_timestamp >= start_dt,
                    GrammarSuggestion.created_timestamp < end_dt
                )
            )
        ) or 0
        
        grammar_users = await self.db.scalar(
            select(func.count(func.distinct(GrammarSuggestion.user_id))).where(
                and_(
                    GrammarSuggestion.created_timestamp >= start_dt,
                    GrammarSuggestion.created_timestamp < end_dt
                )
            )
        ) or 0
        
        features.append({
            "feature": "grammar",
            "total_uses": grammar_count,
            "unique_users": grammar_users,
            "avg_uses_per_user": round(grammar_count / max(grammar_users, 1), 2)
        })
        
        # Translate
        translate_count = await self.db.scalar(
            select(func.count()).select_from(TranslateTexts).where(
                and_(
                    TranslateTexts.created_timestamp >= start_dt,
                    TranslateTexts.created_timestamp < end_dt
                )
            )
        ) or 0
        
        translate_users = await self.db.scalar(
            select(func.count(func.distinct(TranslateTexts.user_id))).where(
                and_(
                    TranslateTexts.created_timestamp >= start_dt,
                    TranslateTexts.created_timestamp < end_dt
                )
            )
        ) or 0
        
        features.append({
            "feature": "translate",
            "total_uses": translate_count,
            "unique_users": translate_users,
            "avg_uses_per_user": round(translate_count / max(translate_users, 1), 2)
        })
        
        # Tone (includes polish — polish is stored as target_tone='polish' in tone_adjustments)
        tone_count = await self.db.scalar(
            select(func.count()).select_from(ToneAdjustments).where(
                and_(
                    ToneAdjustments.created_timestamp >= start_dt,
                    ToneAdjustments.created_timestamp < end_dt
                )
            )
        ) or 0
        
        tone_users = await self.db.scalar(
            select(func.count(func.distinct(ToneAdjustments.user_id))).where(
                and_(
                    ToneAdjustments.created_timestamp >= start_dt,
                    ToneAdjustments.created_timestamp < end_dt
                )
            )
        ) or 0
        
        features.append({
            "feature": "tone",
            "total_uses": tone_count,
            "unique_users": tone_users,
            "avg_uses_per_user": round(tone_count / max(tone_users, 1), 2)
        })
        
        return features
    
    # ==========================================
    # AGGREGATED LANGUAGE INSIGHTS
    # ==========================================
    
    async def get_aggregated_language_insights(self) -> dict:
        """Get aggregated language learning insights across all users."""
        
        # CLB distribution
        clb_result = await self.db.execute(
            select(
                UserLearningInsights.estimated_clb_level,
                func.count(UserLearningInsights.user_id)
            )
            .where(UserLearningInsights.estimated_clb_level.isnot(None))
            .group_by(UserLearningInsights.estimated_clb_level)
        )
        clb_distribution = {row[0]: row[1] for row in clb_result.all()}
        
        # Aggregate grammar issues
        all_insights = await self.db.execute(
            select(UserLearningInsights.grammar_issues)
        )
        
        grammar_counts = {}
        for row in all_insights.scalars().all():
            for issue, count in (row or {}).items():
                grammar_counts[issue] = grammar_counts.get(issue, 0) + count
        
        top_grammar_issues = sorted(
            [{"pattern": k, "frequency": v, "example_correction": None} for k, v in grammar_counts.items()],
            key=lambda x: -x["frequency"]
        )[:10]
        
        return {
            "clb_distribution": clb_distribution,
            "top_grammar_issues": top_grammar_issues,
            "top_vocabulary_gaps": [],  # Would need more aggregation
            "avg_improvement_rate": 0.0,  # Would need time-series analysis
            "generated_at": datetime.now(timezone.utc),
        }
