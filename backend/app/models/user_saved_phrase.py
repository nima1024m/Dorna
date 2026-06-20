from __future__ import annotations

from datetime import datetime

import sqlalchemy as sa
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class UserSavedPhrase(Base):
    """A phrase a user has saved to their collection."""

    __tablename__ = "user_saved_phrases"
    __table_args__ = (
        sa.UniqueConstraint(
            "user_id", "phrase_id", name="uq_user_saved_phrases_user_id"
        ),
    )

    id: Mapped[int] = mapped_column(sa.Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int | None] = mapped_column(
        sa.ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    phrase_id: Mapped[int | None] = mapped_column(
        sa.ForeignKey("phrases.id", ondelete="CASCADE"), index=True
    )
    created_at: Mapped[datetime | None] = mapped_column(
        sa.DateTime(timezone=True), server_default=sa.func.now()
    )
