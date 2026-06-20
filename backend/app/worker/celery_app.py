from celery import Celery
from celery.schedules import crontab

from app.core.config import settings

celery_app = Celery(
    "dorna",
    broker=settings.CELERY_BROKER_URL,
    backend=settings.CELERY_RESULT_BACKEND,
    include=[
        "app.worker.tts_tasks",
        "app.worker.user_tasks",
        "app.worker.podcast_tasks",
        "app.worker.news_tasks",
        "app.worker.daily_brief_tasks",
    ],
)

celery_app.conf.task_routes = {
    "app.worker.tts_tasks.*": {"queue": "tts"},
    "app.worker.user_tasks.*": {"queue": "user"},
    "app.worker.podcast_tasks.*": {"queue": "podcast"},
    "app.worker.news_tasks.*": {"queue": "news"},
    "app.worker.daily_brief_tasks.*": {"queue": "daily_brief"},
}

# Periodic schedule (requires a separate `celery beat` process at deploy).
celery_app.conf.timezone = "UTC"
celery_app.conf.beat_schedule = {
    "dispatch-daily-briefs-every-morning": {
        "task": "app.worker.daily_brief_tasks.dispatch_daily_briefs",
        "schedule": crontab(hour=6, minute=0),  # 06:00 UTC daily
    },
}
