"""device tokens for FCM push (F7)

Revision ID: e6f8a0b1c2d3
Revises: d4e6f8a0b1c2
Create Date: 2026-06-20 15:00:00.000000

Per-device FCM registration tokens. Hand-written; review before upgrade.
"""
from alembic import op
import sqlalchemy as sa

revision = "e6f8a0b1c2d3"
down_revision = "d4e6f8a0b1c2"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "device_tokens",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=True),
        sa.Column("token", sa.Text(), nullable=False),
        sa.Column("platform", sa.String(length=16), nullable=True),
        sa.Column(
            "is_active", sa.Boolean(), server_default=sa.true(), nullable=False
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
            name="fk_device_tokens_user_id_users",
        ),
        sa.PrimaryKeyConstraint("id", name="pk_device_tokens"),
        sa.UniqueConstraint("token", name="uq_device_tokens_token"),
    )
    op.create_index("ix_device_tokens_user_id", "device_tokens", ["user_id"])


def downgrade() -> None:
    op.drop_index("ix_device_tokens_user_id", table_name="device_tokens")
    op.drop_table("device_tokens")
