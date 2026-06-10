"""
Tests for admin user management service.
"""
import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from datetime import datetime, timezone

from apps.admin.services.user_service import AdminUserService


class TestAdminUserService:
    """Tests for AdminUserService."""
    
    @pytest.mark.asyncio
    async def test_get_user_by_id_found(self, mock_db, mock_user):
        """Test getting a user by ID when user exists."""
        # Arrange
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = mock_user
        mock_db.execute.return_value = mock_result
        
        service = AdminUserService(mock_db)
        
        # Act
        user = await service.get_user_by_id(1)
        
        # Assert
        assert user is not None
        assert user.id == 1
        assert user.email == "user@example.com"
    
    @pytest.mark.asyncio
    async def test_get_user_by_id_not_found(self, mock_db):
        """Test getting a user by ID when user doesn't exist."""
        # Arrange
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = None
        mock_db.execute.return_value = mock_result
        
        service = AdminUserService(mock_db)
        
        # Act
        user = await service.get_user_by_id(999)
        
        # Assert
        assert user is None
    
    @pytest.mark.asyncio
    async def test_lock_user(self, mock_db):
        """Test locking a user account."""
        # Arrange
        service = AdminUserService(mock_db)
        
        # Act
        result = await service.lock_user(1)
        
        # Assert
        assert result is True
        mock_db.execute.assert_called()
        mock_db.commit.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_unlock_user(self, mock_db):
        """Test unlocking a user account."""
        # Arrange
        service = AdminUserService(mock_db)
        
        # Act
        result = await service.unlock_user(1)
        
        # Assert
        assert result is True
        mock_db.execute.assert_called()
        mock_db.commit.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_soft_delete_user(self, mock_db):
        """Test soft deleting a user."""
        # Arrange
        service = AdminUserService(mock_db)
        
        # Act
        result = await service.soft_delete_user(1)
        
        # Assert
        assert result is True
        mock_db.commit.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_force_logout_user(self, mock_db):
        """Test force logout of a user."""
        # Arrange
        mock_result = MagicMock()
        mock_result.rowcount = 3
        mock_db.execute.return_value = mock_result
        
        service = AdminUserService(mock_db)
        
        # Act
        count = await service.force_logout_user(1)
        
        # Assert
        assert count == 3
        mock_db.commit.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_get_user_activity_stats(self, mock_db):
        """Test getting user activity statistics."""
        # Arrange
        mock_db.scalar.return_value = 10
        
        service = AdminUserService(mock_db)
        
        # Act
        stats = await service.get_user_activity_stats(1)
        
        # Assert
        assert stats["user_id"] == 1
        assert "total_grammar_corrections" in stats
        assert "total_translations" in stats


class TestAdminNotes:
    """Tests for admin notes functionality."""
    
    @pytest.mark.asyncio
    async def test_add_note(self, mock_db, mock_admin_user):
        """Test adding an admin note."""
        # Arrange
        service = AdminUserService(mock_db)
        
        # Act
        note = await service.add_note(
            user_id=1,
            admin_id=str(mock_admin_user.id),
            admin_email=mock_admin_user.email,
            content="Test note",
            category="info",
            is_pinned=False
        )
        
        # Assert
        mock_db.add.assert_called_once()
        mock_db.commit.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_resolve_note(self, mock_db, mock_admin_user):
        """Test resolving a note."""
        # Arrange
        import uuid
        note_id = str(uuid.uuid4())
        
        service = AdminUserService(mock_db)
        
        # Act
        result = await service.resolve_note(note_id, str(mock_admin_user.id))
        
        # Assert
        assert result is True
        mock_db.commit.assert_called_once()
