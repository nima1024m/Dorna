import uuid
from datetime import datetime

import sqlalchemy as sa
from sqlalchemy import String, DateTime, func, Boolean, ForeignKey, text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base, CITEXT


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True)
    email: Mapped[str] = mapped_column(CITEXT)
    password: Mapped[str] = mapped_column(String(255))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, server_default=text("true"))
    is_deleted: Mapped[bool] = mapped_column(Boolean, default=False, server_default=text("false"))
    full_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    last_login_timestamp: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    avatar_url: Mapped[str | None] = mapped_column(String(255), nullable=True)
    created_timestamp: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_timestamp: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    preferences = relationship(
        "UserPreferences",
        uselist=False,
        back_populates="user",
        cascade="all, delete-orphan",
    )
    topics = relationship(
        "TopicCategory",
        secondary="user_topic_categories",
        back_populates="users",
    )
    learning_goals = relationship(
        "LearningGoal",
        secondary="user_goals",
        back_populates="users",
    )
    feed_items = relationship(
        "FeedItem",
        back_populates="user",
        cascade="all, delete-orphan",
        order_by="FeedItem.position",
    )

    __table_args__ = (
        sa.Index(
            "users_email_unique_active",
            "email",
            unique=True,
            postgresql_where=text("is_deleted = false"),
        ),
    )


class PreAuthToken(Base):
    __tablename__ = "preauth_tokens"
    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    device_nonce: Mapped[str | None] = mapped_column(String(128), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    used_at: Mapped[DateTime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class SessionToken(Base):
    __tablename__ = "session_tokens"
    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", onupdate="CASCADE", ondelete="CASCADE"))
    refresh_hash: Mapped[str] = mapped_column(String(128), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    revoked_at: Mapped[DateTime | None] = mapped_column(DateTime(timezone=True))
    replaced_by: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("session_tokens.id", onupdate="CASCADE", ondelete="CASCADE"), nullable=True)

    user = relationship("User")

    __table_args__ = (
        sa.Index("idx_session_tokens_user_id", "user_id"),
    )


class PasswordResetCode(Base):
    __tablename__ = "password_reset_codes"
    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4, server_default=text("gen_random_uuid()"))
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", onupdate="CASCADE", ondelete="CASCADE"), index=True)
    code_hash: Mapped[str] = mapped_column(String(128), nullable=False)  # SHA-256
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    used_at: Mapped[DateTime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    user = relationship("User")


class PasswordResetToken(Base):
    __tablename__ = "password_reset_tokens"
    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4, server_default=text("gen_random_uuid()"))
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", onupdate="CASCADE", ondelete="CASCADE"), index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    used_at: Mapped[DateTime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    user = relationship("User")


class SignupTokens(Base):
    __tablename__ = "signup_tokens"
    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4, server_default=text("gen_random_uuid()"))
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", onupdate="CASCADE", ondelete="CASCADE"))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    used_at: Mapped[DateTime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    user = relationship("User")

    __table_args__ = (
        sa.Index("fki_signup_tokens_user_id_fkey", "user_id"),
        sa.Index("ix_password_reset_tokens_user_id_copy1", "user_id"),
    )
