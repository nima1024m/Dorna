from __future__ import annotations

import uuid
from datetime import datetime
from typing import Dict, Optional

import sqlalchemy as sa
from sqlalchemy import DateTime, ForeignKey, String, func, text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class CalendarConnection(Base):
    """A user's calendar connection. For Google: holds the (encrypted) OAuth
    tokens. For apple_device / android_device: no server tokens — events are
    pushed from the device."""

    __tablename__ = "calendar_connections"
    __table_args__ = (
        sa.UniqueConstraint(
            "user_id", "provider", name="uq_calendar_connections_user_provider"
        ),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", onupdate="CASCADE", ondelete="CASCADE"), index=True
    )
    provider: Mapped[str] = mapped_column(String(24), nullable=False)
    provider_account_id: Mapped[Optional[str]] = mapped_column(
        String(255), nullable=True
    )
    # Stored ENCRYPTED when CALENDAR_TOKEN_ENC_KEY is set (see services/calendar.py).
    access_token: Mapped[Optional[str]] = mapped_column(sa.Text, nullable=True)
    refresh_token: Mapped[Optional[str]] = mapped_column(sa.Text, nullable=True)
    token_expiry: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    scopes: Mapped[Optional[str]] = mapped_column(sa.Text, nullable=True)
    is_active: Mapped[bool] = mapped_column(
        sa.Boolean, nullable=False, server_default=text("TRUE")
    )
    last_synced_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    created_timestamp: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_timestamp: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    user = relationship("User")


class CalendarEvent(Base):
    """A cached upcoming calendar event for a user (from any provider)."""

    __tablename__ = "calendar_events"
    __table_args__ = (
        sa.UniqueConstraint(
            "connection_id",
            "external_event_id",
            name="uq_calendar_events_connection_external",
        ),
        sa.Index("ix_calendar_events_user_starts", "user_id", "starts_at"),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )
    connection_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("calendar_connections.id", ondelete="CASCADE"), index=True
    )
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    provider: Mapped[str] = mapped_column(String(24), nullable=False)
    external_event_id: Mapped[str] = mapped_column(String(512), nullable=False)
    title: Mapped[Optional[str]] = mapped_column(String(512), nullable=True)
    description: Mapped[Optional[str]] = mapped_column(sa.Text, nullable=True)
    location: Mapped[Optional[str]] = mapped_column(sa.Text, nullable=True)
    starts_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True, index=True
    )
    ends_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    is_all_day: Mapped[bool] = mapped_column(
        sa.Boolean, nullable=False, server_default=text("FALSE")
    )
    attendees: Mapped[Optional[Dict]] = mapped_column(
        JSONB, server_default=text("'[]'::jsonb")
    )
    raw_json: Mapped[Optional[Dict]] = mapped_column(
        JSONB, server_default=text("'{}'::jsonb")
    )
    fetched_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
