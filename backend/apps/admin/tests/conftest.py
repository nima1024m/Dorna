"""
Test fixtures for admin panel tests.
"""
import pytest
import asyncio
from datetime import datetime, timezone
from unittest.mock import AsyncMock, MagicMock
import uuid

from sqlalchemy.ext.asyncio import AsyncSession


@pytest.fixture
def mock_db():
    """Create a mock database session."""
    session = AsyncMock(spec=AsyncSession)
    session.execute = AsyncMock()
    session.scalar = AsyncMock()
    session.commit = AsyncMock()
    session.refresh = AsyncMock()
    session.add = MagicMock()
    return session


@pytest.fixture
def mock_admin_user():
    """Create a mock admin user."""
    admin = MagicMock()
    admin.id = uuid.uuid4()
    admin.email = "admin@example.com"
    admin.full_name = "Test Admin"
    admin.role = "admin"
    admin.permissions = {}
    admin.is_active = True
    admin.is_locked = False
    admin.mfa_enabled = False
    admin.has_permission = MagicMock(return_value=True)
    admin.can_manage_users = MagicMock(return_value=True)
    return admin


@pytest.fixture
def mock_user():
    """Create a mock regular user."""
    user = MagicMock()
    user.id = 1
    user.email = "user@example.com"
    user.full_name = "Test User"
    user.is_active = True
    user.is_deleted = False
    user.onboarding_completed = True
    user.initial_clb_level = "CLB 5"
    user.age = 30
    user.nationality = "CA"
    user.profession = "Developer"
    user.interests = ["Tech", "AI"]
    user.learning_goal = "Improve English"
    user.avatar_url = None
    user.created_timestamp = datetime.now(timezone.utc)
    user.updated_timestamp = datetime.now(timezone.utc)
    return user


@pytest.fixture
def mock_topic():
    """Create a mock news topic."""
    topic = MagicMock()
    topic.topic_id = "tech_news"
    topic.title = "Tech News"
    topic.description = "Latest technology news"
    topic.ai_search_prompt = "Search for latest tech news"
    topic.is_active = True
    topic.priority = 10
    topic.language = "en"
    topic.tags = ["tech", "ai"]
    topic.geo_codes = ["US", "CA"]
    topic.update_minutes = 60
    topic.last_refreshed_at = datetime.now(timezone.utc)
    topic.created_timestamp = datetime.now(timezone.utc)
    topic.updated_timestamp = datetime.now(timezone.utc)
    return topic
