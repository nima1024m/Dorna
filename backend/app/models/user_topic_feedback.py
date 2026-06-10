from __future__ import annotations

from datetime import datetime

import sqlalchemy as sa
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class UserTopicFeedback(Base):
    __tablename__ = "user_topic_feedback"
    __table_args__ = (
        sa.UniqueConstraint("user_id", "topic_id", name="uq_user_topic_feedback"),
    )

    id: Mapped[int] = mapped_column(sa.Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int | None] = mapped_column(
        sa.ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    topic_id: Mapped[str | None] = mapped_column(
        sa.ForeignKey("news_topics.topic_id", ondelete="CASCADE"), index=True
    )
    feedback: Mapped[str] = mapped_column(sa.String(16), nullable=False)  # like | dislike
    created_at: Mapped[datetime | None] = mapped_column(
        sa.DateTime(timezone=True), server_default=sa.func.now()
    )
    updated_at: Mapped[datetime | None] = mapped_column(
        sa.DateTime(timezone=True), server_default=sa.func.now(), onupdate=sa.func.now()
    )
