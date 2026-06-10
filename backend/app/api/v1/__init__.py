from fastapi import APIRouter
from app.api.v1 import auth
from app.api.v1 import users
from app.api.v1 import assistant
from app.api.v1 import track
from app.api.v1 import tts
from app.api.v1 import podcast
from app.api.v1 import news
from app.api.v1 import onboarding

api_router = APIRouter()
api_router.include_router(auth.router, prefix='/auth', tags=["auth"])
api_router.include_router(users.router, prefix='/user', tags=["user"])
api_router.include_router(onboarding.router, prefix='/user/onboarding', tags=["onboarding"])
api_router.include_router(assistant.router, prefix='/assistant', tags=["assistant"])
api_router.include_router(track.router, prefix='/track', tags=["track"])
api_router.include_router(tts.router, prefix='/tts', tags=["tts"])
api_router.include_router(podcast.router, prefix='/podcast', tags=["podcast"])
api_router.include_router(news.router, prefix='/news', tags=["news"])
