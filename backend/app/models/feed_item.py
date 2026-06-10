import uuid
from datetime import datetime

import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID, ENUM as PgEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base, FeedItemStatus


class FeedItem(Base):
    __tablename__ = "feed_items"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        server_default=sa.text("gen_random_uuid()")
    )
    user_id: Mapped[int] = mapped_column(
        sa.ForeignKey("users.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )

    # Topic info (from /feed/init)
    query: Mapped[str] = mapped_column(sa.Text, nullable=False)
    category: Mapped[str | None] = mapped_column(sa.String(100), nullable=True)

    # Metadata (from /feed/metadata)
    title: Mapped[str | None] = mapped_column(sa.String(255), nullable=True)
    description: Mapped[str | None] = mapped_column(sa.Text, nullable=True)
    image_url: Mapped[str | None] = mapped_column(sa.Text, nullable=True)

    # Status & linking
    status: Mapped[FeedItemStatus] = mapped_column(
        PgEnum(FeedItemStatus, name="feed_item_status"),
        server_default=FeedItemStatus.SUGGESTED.value,
        nullable=False,
    )
    podcast_job_id: Mapped[uuid.UUID | None] = mapped_column(
        sa.ForeignKey("podcast_jobs.id", ondelete="SET NULL"),
        nullable=True,
    )

    # Playback resume (prefetch-safe):
    # The client reports the segment that is ACTUALLY playing (not merely fetched),
    # and on reopen we resume from the START of this segment for a simpler UX.
    # Example: if the user stopped mid segment_7, we store 7 and resume from segment_7.wav.
    last_segment_index: Mapped[int | None] = mapped_column(sa.Integer, default=0, server_default=sa.text("0"))

    # Ordering & timestamps
    position: Mapped[int | None] = mapped_column(sa.Integer, default=0, server_default=sa.text("0"))
    created_at: Mapped[datetime | None] = mapped_column(
        sa.DateTime(timezone=True),
        server_default=sa.func.now(),
    )
    updated_at: Mapped[datetime | None] = mapped_column(
        sa.DateTime(timezone=True),
        server_default=sa.func.now(),
        onupdate=sa.func.now(),
    )

    # Relationships (use strings to avoid circular imports)
    user = relationship("User", back_populates="feed_items")
    podcast_job = relationship("PodcastJob", back_populates="feed_item")
