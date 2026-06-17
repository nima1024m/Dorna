"""align constraint names to naming convention

Revision ID: b2a7f3c19d40
Revises: 5133a004f071
Create Date: 2026-06-17 18:50:00.000000

Renames existing indexes/constraints (created by the old create_all path with
PostgreSQL default names) to the project naming convention introduced in
app/core/database.py. All operations are **catalog-only RENAMEs** -- no table
or index is rewritten, no foreign key is revalidated.

Production safety:
  * `SET LOCAL lock_timeout` makes any rename that cannot immediately take its
    (very brief) ACCESS EXCLUSIVE lock abort the whole migration instead of
    blocking live queries. Re-run during a quiet window if that happens.
  * Every rename is guarded (only runs if the old name still exists and the new
    one does not), so the migration is idempotent and safe to re-run.
"""
from alembic import op

revision = 'b2a7f3c19d40'
down_revision = '5133a004f071'
branch_labels = None
depends_on = None

LOCK_TIMEOUT = "4s"

# (table, old_name, new_name)
CONSTRAINT_RENAMES = [
    ('admin_audit_logs', 'admin_audit_logs_admin_id_fkey', 'fk_admin_audit_logs_admin_id_admin_users'),
    ('admin_audit_logs', 'admin_audit_logs_pkey', 'pk_admin_audit_logs'),
    ('admin_notes', 'admin_notes_admin_id_fkey', 'fk_admin_notes_admin_id_admin_users'),
    ('admin_notes', 'admin_notes_pkey', 'pk_admin_notes'),
    ('admin_notes', 'admin_notes_resolved_by_fkey', 'fk_admin_notes_resolved_by_admin_users'),
    ('admin_notes', 'admin_notes_user_id_fkey', 'fk_admin_notes_user_id_users'),
    ('admin_users', 'admin_users_created_by_fkey', 'fk_admin_users_created_by_admin_users'),
    ('admin_users', 'admin_users_email_key', 'uq_admin_users_email'),
    ('admin_users', 'admin_users_pkey', 'pk_admin_users'),
    ('feed_items', 'feed_items_pkey', 'pk_feed_items'),
    ('feed_items', 'feed_items_podcast_job_id_fkey', 'fk_feed_items_podcast_job_id_podcast_jobs'),
    ('feed_items', 'feed_items_user_id_fkey', 'fk_feed_items_user_id_users'),
    ('grammar_corrections', 'grammar_corrections_grammar_id_fkey', 'fk_grammar_corrections_grammar_id_grammar_suggestions'),
    ('grammar_corrections', 'grammar_corrections_pkey', 'pk_grammar_corrections'),
    ('grammar_suggestions', 'grammar_suggestions_pkey', 'pk_grammar_suggestions'),
    ('grammar_suggestions', 'grammar_suggestions_user_id_fkey', 'fk_grammar_suggestions_user_id_users'),
    ('learning_goals', 'learning_goals_key_key', 'uq_learning_goals_key'),
    ('learning_goals', 'learning_goals_pkey', 'pk_learning_goals'),
    ('news_items', 'news_items_content_hash_key', 'uq_news_items_content_hash'),
    ('news_items', 'news_items_pkey', 'pk_news_items'),
    ('news_items', 'news_items_topic_id_fkey', 'fk_news_items_topic_id_news_topics'),
    ('news_topics', 'news_topics_pkey', 'pk_news_topics'),
    ('password_reset_codes', 'password_reset_codes_pkey', 'pk_password_reset_codes'),
    ('password_reset_codes', 'password_reset_codes_user_id_fkey', 'fk_password_reset_codes_user_id_users'),
    ('password_reset_tokens', 'password_reset_tokens_pkey', 'pk_password_reset_tokens'),
    ('password_reset_tokens', 'password_reset_tokens_user_id_fkey', 'fk_password_reset_tokens_user_id_users'),
    ('podcast_jobs', 'podcast_jobs_pkey', 'pk_podcast_jobs'),
    ('podcast_jobs', 'podcast_jobs_user_id_fkey', 'fk_podcast_jobs_user_id_users'),
    ('preauth_tokens', 'preauth_tokens_pkey', 'pk_preauth_tokens'),
    ('session_tokens', 'session_tokens_pkey', 'pk_session_tokens'),
    ('session_tokens', 'session_tokens_replaced_by_fkey', 'fk_session_tokens_replaced_by_session_tokens'),
    ('session_tokens', 'session_tokens_user_id_fkey', 'fk_session_tokens_user_id_users'),
    ('signup_tokens', 'signup_tokens_pkey', 'pk_signup_tokens'),
    ('signup_tokens', 'signup_tokens_user_id_fkey', 'fk_signup_tokens_user_id_users'),
    ('task_images', 'task_images_pkey', 'pk_task_images'),
    ('task_images', 'task_images_task_id_fkey', 'fk_task_images_task_id_tasks'),
    ('tasks', 'tasks_pkey', 'pk_tasks'),
    ('tasks', 'tasks_user_id_fkey', 'fk_tasks_user_id_users'),
    ('token_usage_daily', 'token_usage_daily_pkey', 'pk_token_usage_daily'),
    ('token_usage_daily', 'token_usage_daily_user_id_fkey', 'fk_token_usage_daily_user_id_users'),
    ('tone_adjustments', 'tone_adjustments_parent_tone_id_fkey', 'fk_tone_adjustments_parent_tone_id_tone_adjustments'),
    ('tone_adjustments', 'tone_adjustments_pkey', 'pk_tone_adjustments'),
    ('tone_adjustments', 'tone_adjustments_user_id_fkey', 'fk_tone_adjustments_user_id_users'),
    ('topic_article_refresh_jobs', 'topic_article_refresh_jobs_pkey', 'pk_topic_article_refresh_jobs'),
    ('topic_articles', 'topic_articles_pkey', 'pk_topic_articles'),
    ('topic_articles', 'topic_articles_topic_id_fkey', 'fk_topic_articles_topic_id_news_topics'),
    ('topic_categories', 'topic_categories_pkey', 'pk_topic_categories'),
    ('topic_podcast_scripts', 'topic_podcast_scripts_pkey', 'pk_topic_podcast_scripts'),
    ('topic_podcast_scripts', 'topic_podcast_scripts_topic_id_fkey', 'fk_topic_podcast_scripts_topic_id_news_topics'),
    ('topic_refresh_jobs', 'topic_refresh_jobs_pkey', 'pk_topic_refresh_jobs'),
    ('topic_refresh_jobs', 'topic_refresh_jobs_topic_id_fkey', 'fk_topic_refresh_jobs_topic_id_news_topics'),
    ('translate_texts', 'translate_texts_pkey', 'pk_translate_texts'),
    ('translate_texts', 'translate_texts_user_id_fkey', 'fk_translate_texts_user_id_users'),
    ('user_goals', 'user_goals_goal_id_fkey', 'fk_user_goals_goal_id_learning_goals'),
    ('user_goals', 'user_goals_pkey', 'pk_user_goals'),
    ('user_goals', 'user_goals_user_id_fkey', 'fk_user_goals_user_id_users'),
    ('user_learning_insights', 'user_learning_insights_pkey', 'pk_user_learning_insights'),
    ('user_learning_insights', 'user_learning_insights_user_id_fkey', 'fk_user_learning_insights_user_id_users'),
    ('user_preferences', 'user_preferences_pkey', 'pk_user_preferences'),
    ('user_preferences', 'user_preferences_user_id_fkey', 'fk_user_preferences_user_id_users'),
    ('user_preferences', 'user_preferences_user_id_key', 'uq_user_preferences_user_id'),
    ('user_topic_categories', 'user_topic_categories_category_id_fkey', 'fk_user_topic_categories_category_id_topic_categories'),
    ('user_topic_categories', 'user_topic_categories_pkey', 'pk_user_topic_categories'),
    ('user_topic_categories', 'user_topic_categories_user_id_fkey', 'fk_user_topic_categories_user_id_users'),
    ('user_topic_feedback', 'user_topic_feedback_pkey', 'pk_user_topic_feedback'),
    ('user_topic_feedback', 'user_topic_feedback_topic_id_fkey', 'fk_user_topic_feedback_topic_id_news_topics'),
    ('user_topic_feedback', 'user_topic_feedback_user_id_fkey', 'fk_user_topic_feedback_user_id_users'),
    ('user_topic_preferences', 'user_topic_preferences_pkey', 'pk_user_topic_preferences'),
    ('user_topic_preferences', 'user_topic_preferences_topic_id_fkey', 'fk_user_topic_preferences_topic_id_news_topics'),
    ('user_topic_preferences', 'user_topic_preferences_user_id_fkey', 'fk_user_topic_preferences_user_id_users'),
    ('users', 'users_pkey', 'pk_users'),
]

INDEX_RENAMES = [
]


def _rename_constraint(table, old, new):
    op.execute(
        "DO $$ BEGIN\n"
        "  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = '%s' AND conrelid = '%s'::regclass)\n"
        "     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = '%s' AND conrelid = '%s'::regclass)\n"
        "  THEN EXECUTE 'ALTER TABLE \"%s\" RENAME CONSTRAINT \"%s\" TO \"%s\"';\n"
        "  END IF;\n"
        "END $$;" % (old, table, new, table, table, old, new)
    )


def upgrade() -> None:
    op.execute("SET LOCAL lock_timeout = '%s'" % LOCK_TIMEOUT)
    for table, old, new in CONSTRAINT_RENAMES:
        _rename_constraint(table, old, new)
    for _table, old, new in INDEX_RENAMES:
        op.execute('ALTER INDEX IF EXISTS "%s" RENAME TO "%s"' % (old, new))


def downgrade() -> None:
    op.execute("SET LOCAL lock_timeout = '%s'" % LOCK_TIMEOUT)
    for _table, old, new in INDEX_RENAMES:
        op.execute('ALTER INDEX IF EXISTS "%s" RENAME TO "%s"' % (new, old))
    for table, old, new in CONSTRAINT_RENAMES:
        _rename_constraint(table, new, old)
