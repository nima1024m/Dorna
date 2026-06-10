"""
Tests for admin topic management service.
"""
import pytest
from unittest.mock import AsyncMock, MagicMock

from apps.admin.services.topic_service import TopicManagementService


class TestTopicManagementService:
    """Tests for TopicManagementService."""
    
    @pytest.mark.asyncio
    async def test_get_topic_by_id_found(self, mock_db, mock_topic):
        """Test getting a topic by ID when it exists."""
        # Arrange
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = mock_topic
        mock_db.execute.return_value = mock_result
        
        service = TopicManagementService(mock_db)
        
        # Act
        topic = await service.get_topic_by_id("tech_news")
        
        # Assert
        assert topic is not None
        assert topic.topic_id == "tech_news"
        assert topic.title == "Tech News"
    
    @pytest.mark.asyncio
    async def test_get_topic_by_id_not_found(self, mock_db):
        """Test getting a topic by ID when it doesn't exist."""
        # Arrange
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = None
        mock_db.execute.return_value = mock_result
        
        service = TopicManagementService(mock_db)
        
        # Act
        topic = await service.get_topic_by_id("nonexistent")
        
        # Assert
        assert topic is None
    
    @pytest.mark.asyncio
    async def test_create_topic(self, mock_db):
        """Test creating a new topic."""
        # Arrange
        service = TopicManagementService(mock_db)
        
        topic_data = {
            "topic_id": "new_topic",
            "title": "New Topic",
            "ai_search_prompt": "Search for new topic news",
            "tags": ["news"],
            "geo_codes": ["US"],
            "update_minutes": 60,
            "is_active": True,
            "priority": 5,
        }
        
        # Act
        topic = await service.create_topic(topic_data)
        
        # Assert
        mock_db.add.assert_called_once()
        mock_db.commit.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_delete_topic(self, mock_db):
        """Test deleting a topic."""
        # Arrange
        mock_result = MagicMock()
        mock_result.rowcount = 1
        mock_db.execute.return_value = mock_result
        
        service = TopicManagementService(mock_db)
        
        # Act
        result = await service.delete_topic("tech_news")
        
        # Assert
        assert result is True
        mock_db.commit.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_activate_topic(self, mock_db):
        """Test activating a topic."""
        # Arrange
        service = TopicManagementService(mock_db)
        
        # Act
        result = await service.activate_topic("tech_news")
        
        # Assert
        assert result is True
        mock_db.commit.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_deactivate_topic(self, mock_db):
        """Test deactivating a topic."""
        # Arrange
        service = TopicManagementService(mock_db)
        
        # Act
        result = await service.deactivate_topic("tech_news")
        
        # Assert
        assert result is True
        mock_db.commit.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_get_all_geo_codes(self, mock_db):
        """Test getting all geo codes."""
        # Arrange
        service = TopicManagementService(mock_db)
        
        # Act
        geo_codes = await service.get_all_geo_codes()
        
        # Assert
        assert len(geo_codes) > 0
        assert any(g["code"] == "US" for g in geo_codes)
        assert any(g["code"] == "CA" for g in geo_codes)
    
    @pytest.mark.asyncio
    async def test_get_news_item_count(self, mock_db):
        """Test getting news item count for a topic."""
        # Arrange
        mock_db.scalar.return_value = 42
        
        service = TopicManagementService(mock_db)
        
        # Act
        count = await service.get_news_item_count("tech_news")
        
        # Assert
        assert count == 42
