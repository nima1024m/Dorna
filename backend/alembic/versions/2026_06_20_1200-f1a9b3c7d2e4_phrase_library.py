"""phrase library + saved phrases (F1)

Revision ID: f1a9b3c7d2e4
Revises: b2a7f3c19d40
Create Date: 2026-06-20 12:00:00.000000

Creates the `phrases` library and the per-user `user_saved_phrases` join table,
and seeds an initial set of everyday phrases for Iranian newcomers in Canada.
Hand-written (no DB available where it was authored); review before `make upgrade`.
"""
from alembic import op
import sqlalchemy as sa

revision = "f1a9b3c7d2e4"
down_revision = "b2a7f3c19d40"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "phrases",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("text", sa.String(length=255), nullable=False),
        sa.Column("ipa", sa.String(length=255), nullable=True),
        sa.Column("translation", sa.Text(), nullable=True),
        sa.Column("when_to_use", sa.Text(), nullable=True),
        sa.Column("example", sa.Text(), nullable=True),
        sa.Column("category", sa.String(length=64), nullable=True),
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
        sa.PrimaryKeyConstraint("id", name="pk_phrases"),
    )
    op.create_index("ix_phrases_category", "phrases", ["category"])

    op.create_table(
        "user_saved_phrases",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=True),
        sa.Column("phrase_id", sa.Integer(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=True,
        ),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
            ondelete="CASCADE",
            name="fk_user_saved_phrases_user_id_users",
        ),
        sa.ForeignKeyConstraint(
            ["phrase_id"],
            ["phrases.id"],
            ondelete="CASCADE",
            name="fk_user_saved_phrases_phrase_id_phrases",
        ),
        sa.PrimaryKeyConstraint("id", name="pk_user_saved_phrases"),
        sa.UniqueConstraint(
            "user_id", "phrase_id", name="uq_user_saved_phrases_user_id"
        ),
    )
    op.create_index(
        "ix_user_saved_phrases_user_id", "user_saved_phrases", ["user_id"]
    )
    op.create_index(
        "ix_user_saved_phrases_phrase_id", "user_saved_phrases", ["phrase_id"]
    )

    phrases = sa.table(
        "phrases",
        sa.column("text", sa.String),
        sa.column("ipa", sa.String),
        sa.column("translation", sa.Text),
        sa.column("when_to_use", sa.Text),
        sa.column("example", sa.Text),
        sa.column("category", sa.String),
    )
    op.bulk_insert(phrases, _SEED_PHRASES)


def downgrade() -> None:
    op.drop_index(
        "ix_user_saved_phrases_phrase_id", table_name="user_saved_phrases"
    )
    op.drop_index(
        "ix_user_saved_phrases_user_id", table_name="user_saved_phrases"
    )
    op.drop_table("user_saved_phrases")
    op.drop_index("ix_phrases_category", table_name="phrases")
    op.drop_table("phrases")


_SEED_PHRASES = [
    {
        "text": "How's it going?",
        "ipa": "/haʊz ɪt ˈɡoʊɪŋ/",
        "translation": "اوضاع چطوره؟",
        "when_to_use": "A casual, friendly greeting for people you already know.",
        "example": "Hey Sara, how's it going?",
        "category": "greetings",
    },
    {
        "text": "Nice to meet you.",
        "ipa": "/naɪs tə ˈmiːt juː/",
        "translation": "از آشنایی‌تون خوشوقتم.",
        "when_to_use": "When you meet someone for the first time.",
        "example": "I'm Nima — nice to meet you.",
        "category": "greetings",
    },
    {
        "text": "What do you do?",
        "ipa": "/wʌt də juː ˈduː/",
        "translation": "شغلت چیه؟",
        "when_to_use": "Asking about someone's job at events or small talk.",
        "example": "So, what do you do?",
        "category": "networking",
    },
    {
        "text": "What brings you here?",
        "ipa": "/wʌt brɪŋz juː hɪər/",
        "translation": "چی شد که اومدی اینجا؟",
        "when_to_use": "Starting a conversation at an event or meetup.",
        "example": "What brings you here today?",
        "category": "networking",
    },
    {
        "text": "Can I get a medium latte, please?",
        "ipa": "/kən aɪ ɡɛt ə ˈmiːdiəm ˈlɑːteɪ pliːz/",
        "translation": "می‌تونم یه لاته متوسط بگیرم، لطفاً؟",
        "when_to_use": "Ordering at a coffee shop.",
        "example": "Hi, can I get a medium latte, please?",
        "category": "cafe",
    },
    {
        "text": "For here or to go?",
        "ipa": "/fɔːr hɪər ɔːr tə ɡoʊ/",
        "translation": "همین‌جا می‌خورید یا می‌برید؟",
        "when_to_use": "A barista asks this; good to recognise and answer.",
        "example": "— For here or to go? — To go, thanks.",
        "category": "cafe",
    },
    {
        "text": "No worries.",
        "ipa": "/noʊ ˈwʌriz/",
        "translation": "مشکلی نیست / خواهش می‌کنم.",
        "when_to_use": "A relaxed way to say 'it's okay' or 'you're welcome'.",
        "example": "— Sorry I'm late! — No worries.",
        "category": "small_talk",
    },
    {
        "text": "Gorgeous day, isn't it?",
        "ipa": "/ˈɡɔːrdʒəs deɪ ˈɪzənt ɪt/",
        "translation": "چه روز قشنگیه، نه؟",
        "when_to_use": "Breaking the ice with small talk about the weather.",
        "example": "Gorgeous day, isn't it?",
        "category": "small_talk",
    },
    {
        "text": "Do you have a moment to sync?",
        "ipa": "/də juː hæv ə ˈmoʊmənt tə sɪŋk/",
        "translation": "یه لحظه وقت داری هماهنگ کنیم؟",
        "when_to_use": "Asking a coworker for a quick chat.",
        "example": "Do you have a moment to sync on the report?",
        "category": "work",
    },
    {
        "text": "Could you walk me through it?",
        "ipa": "/kʊd juː wɔːk miː θruː ɪt/",
        "translation": "می‌تونی قدم‌به‌قدم توضیح بدی؟",
        "when_to_use": "Politely asking someone to explain something step by step.",
        "example": "I'm not sure I follow — could you walk me through it?",
        "category": "work",
    },
    {
        "text": "Beautiful weather we're having!",
        "ipa": "/ˈbjuːtɪfəl ˈwɛðər wɪər ˈhævɪŋ/",
        "translation": "چه هوای خوبی داریم!",
        "when_to_use": "A friendly opener with neighbours.",
        "example": "Morning! Beautiful weather we're having.",
        "category": "neighbours",
    },
    {
        "text": "Do you have this in a smaller size?",
        "ipa": "/də juː hæv ðɪs ɪn ə ˈsmɔːlər saɪz/",
        "translation": "این رو سایز کوچک‌تر دارید؟",
        "when_to_use": "Shopping for clothes.",
        "example": "Excuse me, do you have this in a smaller size?",
        "category": "shopping",
    },
]
