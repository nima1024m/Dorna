from __future__ import annotations

from datetime import datetime

import sqlalchemy as sa
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class DeviceToken(Base):
    """An FCM registration token for one user's device/install."""

    __tablename__ = "device_tokens"
    __table_args__ = (sa.UniqueConstraint("token", name="uq_device_tokens_token"),)

    id: Mapped[int] = mapped_column(sa.Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int | None] = mapped_column(
        sa.ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    token: Mapped[str] = mapped_column(sa.Text, nullable=False)
    platform: Mapped[str | None] = mapped_column(sa.String(16), nullable=True)
    is_active: Mapped[bool] = mapped_column(
        sa.Boolean, server_default=sa.true(), nullable=False
    )
    created_at: Mapped[datetime | None] = mapped_column(
        sa.DateTime(timezone=True), server_default=sa.func.now()
    )
    updated_at: Mapped[datetime | None] = mapped_column(
        sa.DateTime(timezone=True), server_default=sa.func.now(), onupdate=sa.func.now()
    )
