"""
Tests for admin audit service.
"""
import pytest
from unittest.mock import AsyncMock, MagicMock
import uuid
from datetime import datetime, timezone

from apps.admin.services.audit_service import AuditService
from apps.admin.models.audit_log import AuditAction


class TestAuditService:
    """Tests for AuditService."""
    
    @pytest.mark.asyncio
    async def test_log_action(self, mock_db, mock_admin_user):
        """Test logging an admin action."""
        # Arrange
        service = AuditService(mock_db)
        
        # Act
        log = await service.log_action(
            admin_id=str(mock_admin_user.id),
            admin_email=mock_admin_user.email,
            action=AuditAction.USER_VIEW.value,
            resource_type="user",
            resource_id="1",
            description="Viewed user profile",
            ip_address="127.0.0.1",
            success=True
        )
        
        # Assert
        mock_db.add.assert_called_once()
        mock_db.commit.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_log_action_with_old_new_values(self, mock_db, mock_admin_user):
        """Test logging an action with state changes."""
        # Arrange
        service = AuditService(mock_db)
        
        old_value = {"is_active": True}
        new_value = {"is_active": False}
        
        # Act
        log = await service.log_action(
            admin_id=str(mock_admin_user.id),
            admin_email=mock_admin_user.email,
            action=AuditAction.USER_LOCK.value,
            resource_type="user",
            resource_id="1",
            old_value=old_value,
            new_value=new_value,
            success=True
        )
        
        # Assert
        mock_db.add.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_get_log_by_id_found(self, mock_db):
        """Test getting an audit log by ID when it exists."""
        # Arrange
        log_id = uuid.uuid4()
        mock_log = MagicMock()
        mock_log.id = log_id
        mock_log.admin_email = "admin@test.com"
        mock_log.action = AuditAction.USER_VIEW.value
        
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = mock_log
        mock_db.execute.return_value = mock_result
        
        service = AuditService(mock_db)
        
        # Act
        log = await service.get_log_by_id(str(log_id))
        
        # Assert
        assert log is not None
        assert log.id == log_id
    
    @pytest.mark.asyncio
    async def test_get_log_by_id_not_found(self, mock_db):
        """Test getting an audit log by ID when it doesn't exist."""
        # Arrange
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = None
        mock_db.execute.return_value = mock_result
        
        service = AuditService(mock_db)
        
        # Act
        log = await service.get_log_by_id(str(uuid.uuid4()))
        
        # Assert
        assert log is None
    
    @pytest.mark.asyncio
    async def test_get_user_action_history(self, mock_db):
        """Test getting action history for a user."""
        # Arrange
        mock_logs = [MagicMock() for _ in range(3)]
        mock_result = MagicMock()
        mock_result.scalars.return_value.all.return_value = mock_logs
        mock_db.execute.return_value = mock_result
        
        service = AuditService(mock_db)
        
        # Act
        logs = await service.get_user_action_history(user_id=1)
        
        # Assert
        assert len(logs) == 3
