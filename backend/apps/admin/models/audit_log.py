from __future__ import annotations
import uuid
from datetime import datetime
from enum import Enum
from typing import Optional

import sqlalchemy as sa
from sqlalchemy import String, DateTime, func, Text
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.dialects.postgresql import JSONB

from app.core.database import Base


class AuditAction(str, Enum):
    # User Management
    USER_VIEW = "user_view"
    USER_UPDATE = "user_update"
    USER_LOCK = "user_lock"
    USER_UNLOCK = "user_unlock"
    USER_SUSPEND = "user_suspend"
    USER_REACTIVATE = "user_reactivate"
    USER_DELETE_SOFT = "user_delete_soft"
    USER_DELETE_HARD = "user_delete_hard"
    USER_PASSWORD_RESET = "user_password_reset"
    USER_FORCE_LOGOUT = "user_force_logout"
    USER_FLAG = "user_flag"
    USER_NOTE_ADD = "user_note_add"
    
    # Content Management
    TOPIC_CREATE = "topic_create"
    TOPIC_UPDATE = "topic_update"
    TOPIC_DELETE = "topic_delete"
    TOPIC_ACTIVATE = "topic_activate"
    TOPIC_DEACTIVATE = "topic_deactivate"
    
    # Admin Management
    ADMIN_CREATE = "admin_create"
    ADMIN_UPDATE = "admin_update"
    ADMIN_DELETE = "admin_delete"
    ADMIN_LOGIN = "admin_login"
    ADMIN_LOGOUT = "admin_logout"
    ADMIN_FAILED_LOGIN = "admin_failed_login"
    
    # System
    SETTINGS_UPDATE = "settings_update"
    EXPORT_DATA = "export_data"


class AuditLog(Base):
    """
    Immutable audit trail for all admin actions.
    Critical for security, compliance, and debugging.
    """
    __tablename__ = "admin_audit_logs"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4, server_default=sa.text("gen_random_uuid()"))
    
    # Who performed the action
    admin_id: Mapped[Optional[uuid.UUID]] = mapped_column(sa.ForeignKey("admin_users.id", ondelete="SET NULL"), nullable=True, index=True)
    admin_email: Mapped[str] = mapped_column(String(255), nullable=False)  # Denormalized for historical record
    
    # What action was performed
    action: Mapped[str] = mapped_column(String(50), nullable=False, index=True)
    resource_type: Mapped[str] = mapped_column(String(50), nullable=False, index=True)  # user, topic, admin, etc.
    resource_id: Mapped[Optional[str]] = mapped_column(String(255), nullable=True, index=True)
    
    # Details
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    old_value: Mapped[Optional[dict]] = mapped_column(JSONB, nullable=True)  # State before action
    new_value: Mapped[Optional[dict]] = mapped_column(JSONB, nullable=True)  # State after action
    action_metadata: Mapped[Optional[dict]] = mapped_column(JSONB, server_default=sa.text("'{}'::jsonb"))
    
    # Request context
    ip_address: Mapped[Optional[str]] = mapped_column(String(45), nullable=True)
    user_agent: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    request_id: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    
    # Status
    success: Mapped[Optional[bool]] = mapped_column(sa.Boolean, default=True, server_default=sa.text("true"))
    error_message: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    
    # Timestamp
    created_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), server_default=func.now(), index=True)
