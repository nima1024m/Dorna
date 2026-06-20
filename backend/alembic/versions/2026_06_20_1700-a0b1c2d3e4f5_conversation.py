"""conversation practice (F4)

Revision ID: a0b1c2d3e4f5
Revises: f8a0b1c2d3e4
Create Date: 2026-06-20 17:00:00.000000

Scene-based practice conversations (session + turns). Hand-written; review.
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = "a0b1c2d3e4f5"
down_revision = "f8a0b1c2d3e4"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "conversation_sessions",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            server_default=sa.text("gen_random_uuid()"),
            nullable=False,
        ),
        sa.Column("user_id", sa.Integer(), nullable=True),
        sa.Column("scene", sa.String(length=64), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=True,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=True,
        ),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
            ondelete="CASCADE",
            name="fk_conversation_sessions_user_id_users",
        ),
        sa.PrimaryKeyConstraint("id", name="pk_conversation_sessions"),
    )
    op.create_index(
        "ix_conversation_sessions_user_id", "conversation_sessions", ["user_id"]
    )

    op.create_table(
        "conversation_turns",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            server_default=sa.text("gen_random_uuid()"),
            nullable=False,
        ),
        sa.Column("session_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=True),
        sa.Column("role", sa.String(length=16), nullable=False),
        sa.Column("text", sa.Text(), nullable=False),
        sa.Column("feedback", postgresql.JSONB(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=True,
        ),
        sa.ForeignKeyConstraint(
            ["session_id"],
            ["conversation_sessions.id"],
            ondelete="CASCADE",
            name="fk_conversation_turns_session_id_conversation_sessions",
        ),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
            ondelete="CASCADE",
            name="fk_conversation_turns_user_id_users",
        ),
        sa.PrimaryKeyConstraint("id", name="pk_conversation_turns"),
    )
    op.create_index(
        "ix_conversation_turns_session_id", "conversation_turns", ["session_id"]
    )
    op.create_index(
        "ix_conversation_turns_user_id", "conversation_turns", ["user_id"]
    )


def downgrade() -> None:
    op.drop_index("ix_conversation_turns_user_id", table_name="conversation_turns")
    op.drop_index(
        "ix_conversation_turns_session_id", table_name="conversation_turns"
    )
    op.drop_table("conversation_turns")
    op.drop_index(
        "ix_conversation_sessions_user_id", table_name="conversation_sessions"
    )
    op.drop_table("conversation_sessions")
