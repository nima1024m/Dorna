import sqlalchemy as sa
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.dialects.postgresql import JSONB
from datetime import datetime
from app.core.database import Base

class UserLearningInsights(Base):
    __tablename__ = "user_learning_insights"

    user_id: Mapped[int] = mapped_column(sa.ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    last_processed_at: Mapped[datetime | None] = mapped_column(sa.DateTime(timezone=True), server_default=sa.func.now())
    
    # Store unique misspelled words and their corrections: {"word": "correction"}
    misspelled_words: Mapped[dict | None] = mapped_column(JSONB, server_default=sa.text("'{}'::jsonb"))
    
    # Store grammar patterns and their frequency: {"subject-verb agreement": 5, "verb tense": 3}
    grammar_issues: Mapped[dict | None] = mapped_column(JSONB, server_default=sa.text("'{}'::jsonb"))

    # Detailed linguistic patterns: [{"structure": "Conditionals", "issue": "Uses Present Simple instead of will", "examples": ["if I go, I do it"]}]
    linguistic_profile: Mapped[list | None] = mapped_column(JSONB, server_default=sa.text("'[]'::jsonb"))
    
    # New fields for structured analysis
    estimated_clb_level: Mapped[str | None] = mapped_column(sa.String(20), nullable=True)
    language_development_grammar: Mapped[list | None] = mapped_column(JSONB, server_default=sa.text("'[]'::jsonb"))
    vocabulary_improvement: Mapped[list | None] = mapped_column(JSONB, server_default=sa.text("'[]'::jsonb"))
    learning_path: Mapped[list | None] = mapped_column(JSONB, server_default=sa.text("'[]'::jsonb"))

    # AI generated summary of how the user is doing
    overall_summary: Mapped[str | None] = mapped_column(sa.Text, nullable=True)
    
    created_timestamp: Mapped[datetime | None] = mapped_column(sa.DateTime(timezone=True), server_default=sa.func.now())
    updated_timestamp: Mapped[datetime | None] = mapped_column(sa.DateTime(timezone=True), server_default=sa.func.now(), onupdate=sa.func.now())
