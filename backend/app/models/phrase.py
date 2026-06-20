from __future__ import annotations

from datetime import datetime

import sqlalchemy as sa
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class Phrase(Base):
    """A reusable English phrase in the library (with pronunciation, a Persian
    gloss, when-to-use guidance and an example)."""

    __tablename__ = "phrases"

    id: Mapped[int] = mapped_column(sa.Integer, primary_key=True, autoincrement=True)
    text: Mapped[str] = mapped_column(sa.String(255), nullable=False)
    ipa: Mapped[str | None] = mapped_column(sa.String(255))
    translation: Mapped[str | None] = mapped_column(sa.Text)  # Persian gloss
    when_to_use: Mapped[str | None] = mapped_column(sa.Text)
    example: Mapped[str | None] = mapped_column(sa.Text)
    category: Mapped[str | None] = mapped_column(sa.String(64), index=True)
    is_active: Mapped[bool] = mapped_column(
        sa.Boolean, server_default=sa.true(), nullable=False
    )
    created_at: Mapped[datetime | None] = mapped_column(
        sa.DateTime(timezone=True), server_default=sa.func.now()
    )
    updated_at: Mapped[datetime | None] = mapped_column(
        sa.DateTime(timezone=True), server_default=sa.func.now(), onupdate=sa.func.now()
    )
