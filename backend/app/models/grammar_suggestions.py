import uuid
from datetime import datetime
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID, ENUM as PgEnum
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base, AIStatus


class GrammarSuggestion(Base):
    __tablename__ = "grammar_suggestions"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()"),
    )
    user_id: Mapped[int] = mapped_column(
        sa.ForeignKey("users.id", onupdate="CASCADE", ondelete="CASCADE"),
    )
    __table_args__ = (
        sa.Index("idx_suggestions_user_id", "user_id"),
    )
    status: Mapped[AIStatus] = mapped_column(PgEnum(AIStatus, name="ai_status"))
    created_timestamp: Mapped[datetime] = mapped_column(sa.DateTime(timezone=True), server_default=sa.func.now())
    updated_timestamp: Mapped[datetime] = mapped_column(sa.DateTime(timezone=True), server_default=sa.func.now())
