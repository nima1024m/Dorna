import uuid
from datetime import datetime
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID, ENUM as PgEnum
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base, AIStatus, ActionStatus


class ToneAdjustments(Base):
    __tablename__ = "tone_adjustments"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()"),
    )
    user_id: Mapped[int] = mapped_column(
        sa.ForeignKey("users.id", onupdate="CASCADE", ondelete="CASCADE"),
    )
    parent_tone_id: Mapped[uuid.UUID | None] = mapped_column(
        sa.ForeignKey("tone_adjustments.id", onupdate="CASCADE", ondelete="CASCADE"), nullable=True
    )
    __table_args__ = (
        sa.Index("idx_tone_adjustments_id", "user_id"),
        sa.Index("idx_tone_adjustments_parent_tone_id", "parent_tone_id"),
    )
    status: Mapped[AIStatus] = mapped_column(PgEnum(AIStatus, name="ai_status"))
    input_text: Mapped[str | None] = mapped_column(sa.Text, nullable=True)
    adjusted: Mapped[str] = mapped_column(sa.Text, nullable=False)
    target_tone: Mapped[str] = mapped_column(sa.Text, nullable=False)
    user_action: Mapped[ActionStatus | None] = mapped_column(PgEnum(ActionStatus, name="grammar_user_action"), nullable=True)
    user_action_timestamp: Mapped[datetime | None] = mapped_column(sa.DateTime(timezone=True), nullable=True)
    created_timestamp: Mapped[datetime] = mapped_column(sa.DateTime(timezone=True), server_default=sa.func.now())
    updated_timestamp: Mapped[datetime] = mapped_column(sa.DateTime(timezone=True), server_default=sa.func.now())
