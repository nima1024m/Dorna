from __future__ import annotations

import uuid
from datetime import datetime
from typing import Optional, List, Dict, Any

import sqlalchemy as sa
from sqlalchemy import String
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class TopicArticle(Base):
    __tablename__ = "topic_articles"

    id: Mapped[uuid.UUID] = mapped_column(
        sa.dialects.postgresql.UUID(as_uuid=True),
        primary_key=True,
        server_default=sa.text("gen_random_uuid()"),
    )
    topic_id: Mapped[str] = mapped_column(
        String(64),
        sa.ForeignKey("news_topics.topic_id", ondelete="CASCADE"),
        index=True,
    )
    title: Mapped[str] = mapped_column(sa.Text, nullable=False)
    published_at: Mapped[datetime] = mapped_column(sa.DateTime(timezone=True), nullable=False)
    content: Mapped[str] = mapped_column(sa.Text, nullable=False)
    image_url: Mapped[str] = mapped_column(sa.Text, nullable=False)
    sources_json: Mapped[Optional[List[Dict[str, Any]]]] = mapped_column(JSONB, nullable=True)
    generated_at: Mapped[Optional[datetime]] = mapped_column(
        sa.DateTime(timezone=True), server_default=sa.func.now()
    )
    updated_at: Mapped[Optional[datetime]] = mapped_column(
        sa.DateTime(timezone=True), server_default=sa.func.now(), onupdate=sa.func.now()
    )
