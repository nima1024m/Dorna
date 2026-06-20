from fastapi import APIRouter
from app.api.v1 import auth
from app.api.v1 import users
from app.api.v1 import assistant
from app.api.v1 import track
from app.api.v1 import tts
from app.api.v1 import podcast
from app.api.v1 import news
from app.api.v1 import onboarding
from app.api.v1 import phrase
from app.api.v1 import stats
from app.api.v1 import daily_brief

api_router = APIRouter()
api_router.include_router(auth.router, prefix='/auth', tags=["auth"])
api_router.include_router(users.router, prefix='/user', tags=["user"])
api_router.include_router(onboarding.router, prefix='/user/onboarding', tags=["onboarding"])
api_router.include_router(assistant.router, prefix='/assistant', tags=["assistant"])
api_router.include_router(track.router, prefix='/track', tags=["track"])
api_router.include_router(tts.router, prefix='/tts', tags=["tts"])
api_router.include_router(podcast.router, prefix='/podcast', tags=["podcast"])
api_router.include_router(news.router, prefix='/news', tags=["news"])
api_router.include_router(phrase.router, prefix='/phrases', tags=["phrases"])
api_router.include_router(stats.router, prefix='/stats', tags=["stats"])
api_router.include_router(daily_brief.router, prefix='/daily-brief', tags=["daily-brief"])
