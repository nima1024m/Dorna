"""daily briefs (F2)

Revision ID: d4e6f8a0b1c2
Revises: c2d4e6f8a0b1
Create Date: 2026-06-20 14:00:00.000000

One generated daily brief per user per day (weather/news/phrases/challenge
segments in content_json). Hand-written; review before upgrade.
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = "d4e6f8a0b1c2"
down_revision = "c2d4e6f8a0b1"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "daily_briefs",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            server_default=sa.text("gen_random_uuid()"),
            nullable=False,
        ),
        sa.Column("user_id", sa.Integer(), nullable=True),
        sa.Column("brief_date", sa.Date(), nullable=False),
        sa.Column(
            "status",
            postgresql.ENUM(
                "QUEUED",
                "GENERATING",
                "COMPLETED",
                "FAILED",
                name="daily_brief_status",
            ),
            server_default="QUEUED",
            nullable=False,
        ),
        sa.Column(
            "progress", sa.Integer(), server_default=sa.text("0"), nullable=True
        ),
        sa.Column("current_step", sa.Text(), nullable=True),
        sa.Column("content_json", postgresql.JSONB(), nullable=True),
        sa.Column("error_message", sa.Text(), nullable=True),
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
            onupdate="CASCADE",
            ondelete="RESTRICT",
            name="fk_daily_briefs_user_id_users",
        ),
        sa.PrimaryKeyConstraint("id", name="pk_daily_briefs"),
        sa.UniqueConstraint(
            "user_id", "brief_date", name="uq_daily_briefs_user_id_brief_date"
        ),
    )
    op.create_index("ix_daily_briefs_user_id", "daily_briefs", ["user_id"])
    op.create_index("ix_daily_briefs_brief_date", "daily_briefs", ["brief_date"])


def downgrade() -> None:
    op.drop_index("ix_daily_briefs_brief_date", table_name="daily_briefs")
    op.drop_index("ix_daily_briefs_user_id", table_name="daily_briefs")
    op.drop_table("daily_briefs")
    op.execute("DROP TYPE IF EXISTS daily_brief_status")
