"""
Tests for admin schemas validation.
"""
import pytest
from datetime import datetime
from pydantic import ValidationError

from apps.admin.schemas.users import (
    UserListRequest, UserUpdateRequest, UserNoteRequest, UserFlagRequest
)
from apps.admin.schemas.topics import TopicCreateRequest, TopicUpdateRequest
from apps.admin.schemas.auth import AdminLoginRequest


class TestUserSchemas:
    """Tests for user management schemas."""
    
    def test_user_list_request_defaults(self):
        """Test UserListRequest default values."""
        req = UserListRequest()
        assert req.page == 1
        assert req.page_size == 20
        assert req.search is None
        assert req.sort_by == "created_timestamp"
        assert req.sort_order == "desc"
    
    def test_user_list_request_custom_values(self):
        """Test UserListRequest with custom values."""
        req = UserListRequest(
            page=2,
            page_size=50,
            search="test",
            status="active"
        )
        assert req.page == 2
        assert req.page_size == 50
        assert req.search == "test"
        assert req.status == "active"
    
    def test_user_list_request_validation(self):
        """Test UserListRequest validation."""
        with pytest.raises(ValidationError):
            UserListRequest(page=0)  # page must be >= 1
        
        with pytest.raises(ValidationError):
            UserListRequest(page_size=200)  # max 100
    
    def test_user_update_request(self):
        """Test UserUpdateRequest validation."""
        req = UserUpdateRequest(full_name="New Name", is_active=False)
        assert req.full_name == "New Name"
        assert req.is_active is False
    
    def test_user_update_request_name_too_short(self):
        """Test UserUpdateRequest with short name."""
        with pytest.raises(ValidationError):
            UserUpdateRequest(full_name="A")
    
    def test_user_note_request_valid(self):
        """Test UserNoteRequest with valid data."""
        req = UserNoteRequest(
            content="This is a test note",
            category="info",
            is_pinned=True
        )
        assert req.content == "This is a test note"
        assert req.category == "info"
        assert req.is_pinned is True
    
    def test_user_note_request_invalid_category(self):
        """Test UserNoteRequest with invalid category."""
        with pytest.raises(ValidationError):
            UserNoteRequest(content="Test", category="invalid")
    
    def test_user_flag_request(self):
        """Test UserFlagRequest validation."""
        req = UserFlagRequest(reason="Suspicious activity")
        assert req.reason == "Suspicious activity"
        
        with pytest.raises(ValidationError):
            UserFlagRequest(reason="")  # empty reason


class TestTopicSchemas:
    """Tests for topic management schemas."""
    
    def test_topic_create_request_valid(self):
        """Test TopicCreateRequest with valid data."""
        req = TopicCreateRequest(
            topic_id="tech_news",
            title="Tech News",
            ai_search_prompt="Search for tech news articles",
            tags=["tech", "ai"],
            geo_codes=["US", "CA"],
        )
        assert req.topic_id == "tech_news"
        assert req.update_minutes == 60  # default
    
    def test_topic_create_request_invalid_topic_id(self):
        """Test TopicCreateRequest with invalid topic_id."""
        with pytest.raises(ValidationError):
            TopicCreateRequest(
                topic_id="Tech News!",  # invalid chars
                title="Tech News",
                ai_search_prompt="Search for tech news",
            )
    
    def test_topic_update_request_partial(self):
        """Test TopicUpdateRequest with partial data."""
        req = TopicUpdateRequest(title="Updated Title")
        assert req.title == "Updated Title"
        assert req.priority is None  # not set


class TestAuthSchemas:
    """Tests for authentication schemas."""
    
    def test_admin_login_request_valid(self):
        """Test AdminLoginRequest with valid data."""
        req = AdminLoginRequest(
            email="admin@example.com",
            password="securepassword123"
        )
        assert req.email == "admin@example.com"
    
    def test_admin_login_request_invalid_email(self):
        """Test AdminLoginRequest with invalid email."""
        with pytest.raises(ValidationError):
            AdminLoginRequest(
                email="not-an-email",
                password="securepassword123"
            )
    
    def test_admin_login_request_short_password(self):
        """Test AdminLoginRequest with short password."""
        with pytest.raises(ValidationError):
            AdminLoginRequest(
                email="admin@example.com",
                password="short"
            )
