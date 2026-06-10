import uuid
from datetime import datetime
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID, ENUM as PgEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base, PodcastJobStatus


class PodcastJob(Base):
    __tablename__ = "podcast_jobs"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True,
        server_default=sa.text("gen_random_uuid()")
    )
    user_id: Mapped[int | None] = mapped_column(
        sa.ForeignKey("users.id", onupdate="CASCADE", ondelete="RESTRICT"),
        index=True,
    )
    topic: Mapped[str] = mapped_column(sa.Text, nullable=False)
    status: Mapped[PodcastJobStatus] = mapped_column(
        PgEnum(PodcastJobStatus, name="podcast_job_status"),
        server_default=PodcastJobStatus.QUEUED.value, nullable=False
    )
    progress: Mapped[int | None] = mapped_column(sa.Integer, default=0, server_default=sa.text("0"))
    current_step: Mapped[str | None] = mapped_column(sa.Text, nullable=True)
    script_json: Mapped[str | None] = mapped_column(sa.Text, nullable=True)
    total_segments: Mapped[int | None] = mapped_column(sa.Integer, nullable=True)
    completed_segments: Mapped[int | None] = mapped_column(sa.Integer, default=0, server_default=sa.text("0"))
    audio_folder: Mapped[str | None] = mapped_column(sa.Text, nullable=True)
    error_message: Mapped[str | None] = mapped_column(sa.Text, nullable=True)
    created_at: Mapped[datetime | None] = mapped_column(
        sa.DateTime(timezone=True), server_default=sa.func.now()
    )
    updated_at: Mapped[datetime | None] = mapped_column(
        sa.DateTime(timezone=True), server_default=sa.func.now(),
        onupdate=sa.func.now()
    )

    # Relationship to FeedItem (one-to-one, optional)
    feed_item = relationship("FeedItem", back_populates="podcast_job", uselist=False)
