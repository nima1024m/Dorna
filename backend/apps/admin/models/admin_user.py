from __future__ import annotations
import uuid
from datetime import datetime
from enum import Enum
from typing import Optional

import sqlalchemy as sa
from sqlalchemy import String, DateTime, func, Boolean
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.dialects.postgresql import JSONB

from app.core.database import Base


class AdminRole(str, Enum):
    SUPER_ADMIN = "super_admin"       # Full access to everything
    ADMIN = "admin"                   # Full access except admin management
    MODERATOR = "moderator"           # User management & content moderation
    ANALYST = "analyst"               # Read-only access to analytics
    SUPPORT = "support"               # Limited user management (view, notes)


class AdminUser(Base):
    """
    Separate admin user table for enhanced security.
    Admins are not regular users - they have different auth and permissions.
    """
    __tablename__ = "admin_users"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4, server_default=sa.text("gen_random_uuid()"))
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    full_name: Mapped[str] = mapped_column(String(255), nullable=False)
    
    # Role-based access control
    role: Mapped[str] = mapped_column(String(50), nullable=False, default=AdminRole.SUPPORT.value, server_default=sa.text("'support'"))
    permissions: Mapped[Optional[dict]] = mapped_column(JSONB, server_default=sa.text("'{}'::jsonb"))
    
    # Status
    is_active: Mapped[Optional[bool]] = mapped_column(Boolean, default=True, server_default=sa.text("true"))
    is_locked: Mapped[Optional[bool]] = mapped_column(Boolean, default=False, server_default=sa.text("false"))
    
    # Security
    last_login_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    last_login_ip: Mapped[Optional[str]] = mapped_column(String(45), nullable=True)  # IPv6 max length
    failed_login_attempts: Mapped[Optional[int]] = mapped_column(sa.Integer, default=0, server_default=sa.text("0"))
    password_changed_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    
    # MFA
    mfa_enabled: Mapped[Optional[bool]] = mapped_column(Boolean, default=False, server_default=sa.text("false"))
    mfa_secret: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    
    # Timestamps
    created_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    created_by: Mapped[Optional[uuid.UUID]] = mapped_column(sa.ForeignKey("admin_users.id"), nullable=True)

    def has_permission(self, permission: str) -> bool:
        """Check if admin has a specific permission."""
        if self.role == AdminRole.SUPER_ADMIN.value:
            return True
        return (self.permissions or {}).get(permission, False)

    def can_manage_users(self) -> bool:
        """Check if admin can manage users."""
        return self.role in [AdminRole.SUPER_ADMIN.value, AdminRole.ADMIN.value, AdminRole.MODERATOR.value]

    def can_view_analytics(self) -> bool:
        """Check if admin can view analytics."""
        return self.role in [AdminRole.SUPER_ADMIN.value, AdminRole.ADMIN.value, AdminRole.ANALYST.value]
