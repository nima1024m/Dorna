from __future__ import annotations
import uuid
from datetime import datetime
from typing import Optional, List, Dict

import sqlalchemy as sa
from sqlalchemy import String
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class NewsTopic(Base):
    __tablename__ = "news_topics"

    topic_id: Mapped[str] = mapped_column(String(64), primary_key=True)
    title: Mapped[str] = mapped_column(String(160), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(sa.Text, nullable=True)
    ai_search_prompt: Mapped[str] = mapped_column(sa.Text, nullable=False)
    tags: Mapped[Optional[List]] = mapped_column(JSONB, server_default=sa.text("'[]'::jsonb"))
    geo_codes: Mapped[Optional[List]] = mapped_column(JSONB, server_default=sa.text("'[]'::jsonb"))
    update_minutes: Mapped[int] = mapped_column(sa.Integer, nullable=False, server_default="60")
    is_active: Mapped[bool] = mapped_column(sa.Boolean, nullable=False, server_default=sa.text("TRUE"))
    priority: Mapped[int] = mapped_column(sa.Integer, nullable=False, server_default="0")
    language: Mapped[Optional[str]] = mapped_column(String(16), nullable=True)
    last_refreshed_at: Mapped[Optional[datetime]] = mapped_column(sa.DateTime(timezone=True), nullable=True)
    created_timestamp: Mapped[Optional[datetime]] = mapped_column(sa.DateTime(timezone=True), server_default=sa.func.now())
    updated_timestamp: Mapped[Optional[datetime]] = mapped_column(sa.DateTime(timezone=True), server_default=sa.func.now(), onupdate=sa.func.now())


class UserTopicPreference(Base):
    __tablename__ = "user_topic_preferences"

    id: Mapped[uuid.UUID] = mapped_column(
        primary_key=True,
        default=uuid.uuid4,
        server_default=sa.text("gen_random_uuid()"),
    )
    user_id: Mapped[Optional[int]] = mapped_column(sa.ForeignKey("users.id", ondelete="CASCADE"), index=True)
    topic_id: Mapped[Optional[str]] = mapped_column(sa.ForeignKey("news_topics.topic_id", ondelete="CASCADE"), index=True)
    is_following: Mapped[bool] = mapped_column(sa.Boolean, nullable=False, server_default=sa.text("TRUE"))
    is_hidden: Mapped[bool] = mapped_column(sa.Boolean, nullable=False, server_default=sa.text("FALSE"))
    weight: Mapped[int] = mapped_column(sa.Integer, nullable=False, server_default="0")
    assigned_by: Mapped[Optional[str]] = mapped_column(String(24), nullable=True)  # system/admin/user
    tags: Mapped[Optional[List]] = mapped_column(JSONB, server_default=sa.text("'[]'::jsonb"))
    geo_code: Mapped[Optional[str]] = mapped_column(String(8), nullable=True)
    created_timestamp: Mapped[Optional[datetime]] = mapped_column(sa.DateTime(timezone=True), server_default=sa.func.now())
    updated_timestamp: Mapped[Optional[datetime]] = mapped_column(sa.DateTime(timezone=True), server_default=sa.func.now(), onupdate=sa.func.now())


class NewsItem(Base):
    __tablename__ = "news_items"

    id: Mapped[uuid.UUID] = mapped_column(
        primary_key=True,
        default=uuid.uuid4,
        server_default=sa.text("gen_random_uuid()"),
    )
    topic_id: Mapped[Optional[str]] = mapped_column(sa.ForeignKey("news_topics.topic_id", ondelete="CASCADE"), index=True)
    title: Mapped[str] = mapped_column(String(300), nullable=False)
    summary: Mapped[Optional[str]] = mapped_column(sa.Text, nullable=True)
    source_url: Mapped[str] = mapped_column(sa.Text, nullable=False)
    source_name: Mapped[Optional[str]] = mapped_column(String(160), nullable=True)
    image_url: Mapped[Optional[str]] = mapped_column(sa.Text, nullable=True)
    published_at: Mapped[Optional[datetime]] = mapped_column(sa.DateTime(timezone=True), nullable=True)
    fetched_at: Mapped[Optional[datetime]] = mapped_column(sa.DateTime(timezone=True), server_default=sa.func.now())
    rank_score: Mapped[Optional[float]] = mapped_column(sa.Float, nullable=True)
    content_hash: Mapped[Optional[str]] = mapped_column(String(64), unique=True)
    raw_json: Mapped[Optional[Dict]] = mapped_column(JSONB, server_default=sa.text("'{}'::jsonb"))
    language: Mapped[Optional[str]] = mapped_column(String(16), nullable=True)


class TopicRefreshJob(Base):
    __tablename__ = "topic_refresh_jobs"

    id: Mapped[uuid.UUID] = mapped_column(
        primary_key=True,
        default=uuid.uuid4,
        server_default=sa.text("gen_random_uuid()"),
    )
    topic_id: Mapped[Optional[str]] = mapped_column(sa.ForeignKey("news_topics.topic_id", ondelete="CASCADE"), index=True)
    status: Mapped[str] = mapped_column(String(24), nullable=False, server_default="queued")
    window_minutes: Mapped[Optional[int]] = mapped_column(sa.Integer, nullable=True)
    scheduled_at: Mapped[Optional[datetime]] = mapped_column(sa.DateTime(timezone=True), nullable=True)
    started_at: Mapped[Optional[datetime]] = mapped_column(sa.DateTime(timezone=True), nullable=True)
    completed_at: Mapped[Optional[datetime]] = mapped_column(sa.DateTime(timezone=True), nullable=True)
    error_message: Mapped[Optional[str]] = mapped_column(sa.Text, nullable=True)
    triggered_by: Mapped[Optional[str]] = mapped_column(String(24), nullable=True)  # system/admin/user
    created_timestamp: Mapped[Optional[datetime]] = mapped_column(sa.DateTime(timezone=True), server_default=sa.func.now())
    updated_timestamp: Mapped[Optional[datetime]] = mapped_column(sa.DateTime(timezone=True), server_default=sa.func.now(), onupdate=sa.func.now())


class TopicArticleRefreshJob(Base):
    __tablename__ = "topic_article_refresh_jobs"

    id: Mapped[uuid.UUID] = mapped_column(
        primary_key=True,
        default=uuid.uuid4,
        server_default=sa.text("gen_random_uuid()"),
    )
    status: Mapped[str] = mapped_column(String(24), nullable=False, server_default="queued")
    topic_ids: Mapped[Optional[List]] = mapped_column(JSONB, server_default=sa.text("'[]'::jsonb"))
    total_topics: Mapped[int] = mapped_column(sa.Integer, nullable=False, server_default="0")
    succeeded_topics: Mapped[Optional[List]] = mapped_column(JSONB, server_default=sa.text("'[]'::jsonb"))
    failed_topics: Mapped[Optional[List]] = mapped_column(JSONB, server_default=sa.text("'[]'::jsonb"))
    error_details: Mapped[Optional[Dict]] = mapped_column(JSONB, server_default=sa.text("'{}'::jsonb"))
    duration_seconds: Mapped[Optional[int]] = mapped_column(sa.Integer, nullable=True)
    started_at: Mapped[Optional[datetime]] = mapped_column(sa.DateTime(timezone=True), nullable=True)
    completed_at: Mapped[Optional[datetime]] = mapped_column(sa.DateTime(timezone=True), nullable=True)
    triggered_by: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    created_timestamp: Mapped[Optional[datetime]] = mapped_column(sa.DateTime(timezone=True), server_default=sa.func.now())
    updated_timestamp: Mapped[Optional[datetime]] = mapped_column(sa.DateTime(timezone=True), server_default=sa.func.now(), onupdate=sa.func.now())
