"""
Tests for admin analytics service.
"""
import pytest
from unittest.mock import AsyncMock, MagicMock
from datetime import date, timedelta

from apps.admin.services.analytics_service import AnalyticsService


class TestAnalyticsService:
    """Tests for AnalyticsService."""
    
    @pytest.mark.asyncio
    async def test_get_dashboard_overview(self, mock_db):
        """Test getting dashboard overview."""
        # Arrange
        mock_db.scalar.return_value = 100
        
        service = AnalyticsService(mock_db)
        
        # Act
        overview = await service.get_dashboard_overview()
        
        # Assert
        assert "total_users" in overview
        assert "active_users_today" in overview
        assert "new_users_today" in overview
        assert "total_topics" in overview
    
    @pytest.mark.asyncio
    async def test_get_user_growth(self, mock_db):
        """Test getting user growth data."""
        # Arrange
        mock_db.scalar.return_value = 10
        
        service = AnalyticsService(mock_db)
        
        start_date = date.today() - timedelta(days=7)
        end_date = date.today()
        
        # Act
        data = await service.get_user_growth(start_date, end_date)
        
        # Assert
        assert "new_users" in data
        assert "cumulative_users" in data
        assert len(data["new_users"]) == 8  # 7 days + today
    
    @pytest.mark.asyncio
    async def test_get_feature_usage(self, mock_db):
        """Test getting feature usage data."""
        # Arrange
        mock_db.scalar.return_value = 50
        
        service = AnalyticsService(mock_db)
        
        start_date = date.today() - timedelta(days=7)
        end_date = date.today()
        
        # Act
        features = await service.get_feature_usage(start_date, end_date)
        
        # Assert
        assert len(features) == 3  # grammar, translate, tone (includes polish)
        feature_names = [f["feature"] for f in features]
        assert "grammar" in feature_names
        assert "translate" in feature_names
    
    @pytest.mark.asyncio
    async def test_get_aggregated_language_insights(self, mock_db):
        """Test getting aggregated language insights."""
        # Arrange
        mock_result = MagicMock()
        mock_result.all.return_value = [("CLB 5", 100), ("CLB 6", 50)]
        mock_db.execute.return_value = mock_result
        
        mock_insights_result = MagicMock()
        mock_insights_result.scalars.return_value.all.return_value = [{"test": 1}]
        mock_db.execute.return_value = mock_insights_result
        
        service = AnalyticsService(mock_db)
        
        # Act
        insights = await service.get_aggregated_language_insights()
        
        # Assert
        assert "clb_distribution" in insights
        assert "top_grammar_issues" in insights
        assert "generated_at" in insights
