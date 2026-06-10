from __future__ import annotations

from datetime import date, datetime
import sqlalchemy as sa
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class TokenUsageDaily(Base):
    __tablename__ = "token_usage_daily"

    id: Mapped[int] = mapped_column(sa.BigInteger, primary_key=True, autoincrement=True)
    user_id: Mapped[int | None] = mapped_column(
        sa.ForeignKey("users.id", onupdate="CASCADE", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    usage_date: Mapped[date | None] = mapped_column(sa.Date, server_default=sa.text("CURRENT_DATE"), index=True)
    source: Mapped[str] = mapped_column(sa.String(32), nullable=False, index=True)
    model_name: Mapped[str | None] = mapped_column(sa.String(128), nullable=True)
    prompt_tokens: Mapped[int] = mapped_column(sa.Integer, server_default="0", nullable=False)
    completion_tokens: Mapped[int] = mapped_column(sa.Integer, server_default="0", nullable=False)
    total_tokens: Mapped[int] = mapped_column(sa.Integer, server_default="0", nullable=False)
    cost_cents: Mapped[int] = mapped_column(sa.Integer, server_default="0", nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False
    )

    __table_args__ = (
        sa.UniqueConstraint("usage_date", "user_id", "source", "model_name", name="uq_token_usage_daily"),
    )
