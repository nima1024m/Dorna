import uuid
from enum import Enum
from datetime import datetime
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID, ENUM as PgEnum
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base, ActionStatus


class GrammarCorrection(Base):
    __tablename__ = "grammar_corrections"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()"),
    )
    grammar_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), sa.ForeignKey("grammar_suggestions.id", onupdate="CASCADE", ondelete="CASCADE"),
    )
    __table_args__ = (
        sa.Index("idx_corrections_grammar_id", "grammar_id"),
        sa.Index("idx_corrections_grammar_id_uuid", "grammar_id"),
    )
    changed: Mapped[bool] = mapped_column(sa.Boolean, nullable=False)
    suggestion: Mapped[str] = mapped_column(sa.Text, nullable=False)
    explanation: Mapped[str] = mapped_column(sa.Text, nullable=False)
    original: Mapped[str] = mapped_column(sa.Text, nullable=False)
    user_action: Mapped[ActionStatus | None] = mapped_column(PgEnum(ActionStatus, name="grammar_user_action"), nullable=True)
    user_action_timestamp: Mapped[datetime | None] = mapped_column(sa.DateTime(timezone=True), nullable=True)
