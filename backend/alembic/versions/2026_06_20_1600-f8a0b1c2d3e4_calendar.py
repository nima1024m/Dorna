"""calendar integration (F5)

Revision ID: f8a0b1c2d3e4
Revises: e6f8a0b1c2d3
Create Date: 2026-06-20 16:00:00.000000

Google (OAuth tokens) + device (Apple/Android) calendar connections and a cached
upcoming-events table. Hand-written; review before upgrade.
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = "f8a0b1c2d3e4"
down_revision = "e6f8a0b1c2d3"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "calendar_connections",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            server_default=sa.text("gen_random_uuid()"),
            nullable=False,
        ),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("provider", sa.String(length=24), nullable=False),
        sa.Column("provider_account_id", sa.String(length=255), nullable=True),
        sa.Column("access_token", sa.Text(), nullable=True),
        sa.Column("refresh_token", sa.Text(), nullable=True),
        sa.Column("token_expiry", sa.DateTime(timezone=True), nullable=True),
        sa.Column("scopes", sa.Text(), nullable=True),
        sa.Column(
            "is_active", sa.Boolean(), server_default=sa.text("TRUE"), nullable=False
        ),
        sa.Column("last_synced_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column(
            "created_timestamp",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_timestamp",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
            onupdate="CASCADE",
            ondelete="CASCADE",
            name="fk_calendar_connections_user_id_users",
        ),
        sa.PrimaryKeyConstraint("id", name="pk_calendar_connections"),
        sa.UniqueConstraint(
            "user_id", "provider", name="uq_calendar_connections_user_provider"
        ),
    )
    op.create_index(
        "ix_calendar_connections_user_id", "calendar_connections", ["user_id"]
    )

    op.create_table(
        "calendar_events",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            server_default=sa.text("gen_random_uuid()"),
            nullable=False,
        ),
        sa.Column("connection_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("provider", sa.String(length=24), nullable=False),
        sa.Column("external_event_id", sa.String(length=512), nullable=False),
        sa.Column("title", sa.String(length=512), nullable=True),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("location", sa.Text(), nullable=True),
        sa.Column("starts_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("ends_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column(
            "is_all_day", sa.Boolean(), server_default=sa.text("FALSE"), nullable=False
        ),
        sa.Column(
            "attendees",
            postgresql.JSONB(),
            server_default=sa.text("'[]'::jsonb"),
            nullable=True,
        ),
        sa.Column(
            "raw_json",
            postgresql.JSONB(),
            server_default=sa.text("'{}'::jsonb"),
            nullable=True,
        ),
        sa.Column(
            "fetched_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(
            ["connection_id"],
            ["calendar_connections.id"],
            ondelete="CASCADE",
            name="fk_calendar_events_connection_id_calendar_connections",
        ),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
            ondelete="CASCADE",
            name="fk_calendar_events_user_id_users",
        ),
        sa.PrimaryKeyConstraint("id", name="pk_calendar_events"),
        sa.UniqueConstraint(
            "connection_id",
            "external_event_id",
            name="uq_calendar_events_connection_external",
        ),
    )
    op.create_index(
        "ix_calendar_events_connection_id", "calendar_events", ["connection_id"]
    )
    op.create_index("ix_calendar_events_user_id", "calendar_events", ["user_id"])
    op.create_index("ix_calendar_events_starts_at", "calendar_events", ["starts_at"])
    op.create_index(
        "ix_calendar_events_user_starts", "calendar_events", ["user_id", "starts_at"]
    )


def downgrade() -> None:
    op.drop_index("ix_calendar_events_user_starts", table_name="calendar_events")
    op.drop_index("ix_calendar_events_starts_at", table_name="calendar_events")
    op.drop_index("ix_calendar_events_user_id", table_name="calendar_events")
    op.drop_index("ix_calendar_events_connection_id", table_name="calendar_events")
    op.drop_table("calendar_events")
    op.drop_index(
        "ix_calendar_connections_user_id", table_name="calendar_connections"
    )
    op.drop_table("calendar_connections")
