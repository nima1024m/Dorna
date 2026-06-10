from __future__ import annotations

from datetime import datetime
from typing import Optional, List, Dict, Any

import sqlalchemy as sa
from sqlalchemy import String
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class TopicPodcastScript(Base):
    __tablename__ = "topic_podcast_scripts"

    topic_id: Mapped[str] = mapped_column(
        String(64),
        sa.ForeignKey("news_topics.topic_id", ondelete="CASCADE"),
        primary_key=True,
    )
    status: Mapped[str] = mapped_column(String(24), nullable=False, server_default="READY")
    script_json: Mapped[Optional[List[Dict[str, Any]]]] = mapped_column(JSONB, nullable=True)
    sources_json: Mapped[Optional[List[Dict[str, Any]]]] = mapped_column(JSONB, nullable=True)
    error_message: Mapped[Optional[str]] = mapped_column(sa.Text, nullable=True)
    generated_at: Mapped[Optional[datetime]] = mapped_column(
        sa.DateTime(timezone=True), server_default=sa.func.now()
    )
    updated_at: Mapped[Optional[datetime]] = mapped_column(
        sa.DateTime(timezone=True), server_default=sa.func.now(), onupdate=sa.func.now()
    )
