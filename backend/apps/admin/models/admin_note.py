from __future__ import annotations
import uuid
from datetime import datetime
from typing import Optional

import sqlalchemy as sa
from sqlalchemy import String, DateTime, func, Text, Boolean
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class AdminNote(Base):
    """
    Internal admin notes about users.
    These are private and never visible to the user.
    """
    __tablename__ = "admin_notes"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4, server_default=sa.text("gen_random_uuid()"))
    
    # Which user this note is about
    user_id: Mapped[int] = mapped_column(sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    
    # Who created the note
    admin_id: Mapped[Optional[uuid.UUID]] = mapped_column(sa.ForeignKey("admin_users.id", ondelete="SET NULL"), nullable=True, index=True)
    admin_email: Mapped[str] = mapped_column(String(255), nullable=False)  # Denormalized
    
    # Note content
    content: Mapped[str] = mapped_column(Text, nullable=False)
    category: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)  # warning, info, review, etc.
    
    # Priority/importance
    is_pinned: Mapped[Optional[bool]] = mapped_column(Boolean, default=False, server_default=sa.text("false"))
    is_resolved: Mapped[Optional[bool]] = mapped_column(Boolean, default=False, server_default=sa.text("false"))
    resolved_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    resolved_by: Mapped[Optional[uuid.UUID]] = mapped_column(sa.ForeignKey("admin_users.id"), nullable=True)
    
    # Timestamps
    created_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
