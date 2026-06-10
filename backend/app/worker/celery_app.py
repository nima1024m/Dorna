from celery import Celery
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
    ],
)

celery_app.conf.task_routes = {
    "app.worker.tts_tasks.*": {"queue": "tts"},
    "app.worker.user_tasks.*": {"queue": "user"},
    "app.worker.podcast_tasks.*": {"queue": "podcast"},
    "app.worker.news_tasks.*": {"queue": "news"},
}
