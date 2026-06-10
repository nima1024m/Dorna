from datetime import datetime

import sqlalchemy as sa
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class UserPreferences(Base):
    """
    User preferences model - used across multiple features (podcast, etc.)
    Stores user-specific settings like language level.
    """
    __tablename__ = "user_preferences"
    user_id: Mapped[int] = mapped_column(
        sa.ForeignKey("users.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
    )
    __table_args__ = (
        sa.CheckConstraint(
            "language_level BETWEEN 4 AND 9",
            name="ck_user_preferences_language_level",
        ),
        sa.Index("ix_user_preferences_user_id", "user_id"),
    )
    id: Mapped[int] = mapped_column(sa.Integer, primary_key=True)
    language_level: Mapped[int] = mapped_column(sa.SmallInteger, nullable=False)
    age: Mapped[int | None] = mapped_column(sa.Integer, nullable=True)
    nationality: Mapped[str | None] = mapped_column(sa.String(100), nullable=True)
    profession: Mapped[str | None] = mapped_column(sa.String(255), nullable=True)
    onboarding_completed: Mapped[bool] = mapped_column(sa.Boolean, default=False, server_default=sa.text("false"), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        sa.DateTime(timezone=True),
        server_default=sa.func.now(),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        sa.DateTime(timezone=True),
        server_default=sa.func.now(),
        onupdate=sa.func.now(),
        nullable=False,
    )

    user = relationship("User", back_populates="preferences")


class TopicCategory(Base):
    __tablename__ = "topic_categories"

    # Fixed lookup ID (string) so the client can use stable keys like "tech", "business", etc.
    # Note: if you change this type in an existing DB, you must drop/recreate or migrate
    # both this table and the join table `user_topic_categories`.
    id: Mapped[str] = mapped_column(sa.String(64), primary_key=True)
    label: Mapped[str] = mapped_column(sa.String(255), nullable=False)

    users = relationship(
        "User",
        secondary="user_topic_categories",
        back_populates="topics",
    )


class LearningGoal(Base):
    __tablename__ = "learning_goals"

    id: Mapped[int] = mapped_column(sa.Integer, primary_key=True, autoincrement=False)
    key: Mapped[str] = mapped_column(sa.String(64), unique=True, nullable=False)
    title: Mapped[str] = mapped_column(sa.String(255), nullable=False)
    description: Mapped[str] = mapped_column(sa.Text, nullable=False)

    users = relationship(
        "User",
        secondary="user_goals",
        back_populates="learning_goals",
    )


class UserTopicCategory(Base):
    __tablename__ = "user_topic_categories"

    user_id: Mapped[int] = mapped_column(
        sa.ForeignKey("users.id", ondelete="CASCADE"),
        primary_key=True,
        nullable=False,
    )
    category_id: Mapped[str] = mapped_column(
        sa.ForeignKey("topic_categories.id", ondelete="CASCADE"),
        primary_key=True,
        nullable=False,
    )

    user = relationship("User", overlaps="topics,users")
    category = relationship("TopicCategory", overlaps="topics,users")


class UserGoal(Base):
    __tablename__ = "user_goals"

    user_id: Mapped[int] = mapped_column(
        sa.ForeignKey("users.id", ondelete="CASCADE"),
        primary_key=True,
        nullable=False,
    )
    goal_id: Mapped[int] = mapped_column(
        sa.ForeignKey("learning_goals.id", ondelete="CASCADE"),
        primary_key=True,
        nullable=False,
    )

    user = relationship("User", overlaps="learning_goals,users")
    goal = relationship("LearningGoal", overlaps="learning_goals,users")
