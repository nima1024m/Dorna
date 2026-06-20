"""user stats / streaks (F6)

Revision ID: c2d4e6f8a0b1
Revises: f1a9b3c7d2e4
Create Date: 2026-06-20 13:00:00.000000

Per-user progress counters + daily streak. Rows are created lazily and seeded
with sample values by services/stats.py. Hand-written; review before upgrade.
"""
from alembic import op
import sqlalchemy as sa

revision = "c2d4e6f8a0b1"
down_revision = "f1a9b3c7d2e4"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "user_stats",
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column(
            "streak_days", sa.Integer(), server_default=sa.text("0"), nullable=False
        ),
        sa.Column(
            "longest_streak", sa.Integer(), server_default=sa.text("0"), nullable=False
        ),
        sa.Column("last_active_on", sa.Date(), nullable=True),
        sa.Column(
            "phrases_learned",
            sa.Integer(),
            server_default=sa.text("0"),
            nullable=False,
        ),
        sa.Column(
            "conversations", sa.Integer(), server_default=sa.text("0"), nullable=False
        ),
        sa.Column(
            "briefs_heard", sa.Integer(), server_default=sa.text("0"), nullable=False
        ),
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
            name="fk_user_stats_user_id_users",
        ),
        sa.PrimaryKeyConstraint("user_id", name="pk_user_stats"),
    )


def downgrade() -> None:
    op.drop_table("user_stats")
