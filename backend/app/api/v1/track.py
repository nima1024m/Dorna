from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.schemas.track import *
from app.api.deps import get_db
from app.core.auth_deps import auth_required
from app.models import User
from app.services.track import TrackService

router = APIRouter()


@router.post("/grammar", response_model=TrackGrammarOut)
async def grammar(data: TrackGrammarIn, db: AsyncSession = Depends(get_db), current_user: User = Depends(auth_required)):
    data.user_id = current_user.id
    res = await TrackService.action_grammar(db, data)
    return TrackGrammarOut.model_validate(res)


@router.post("/translate", response_model=TrackTranslateOut)
async def translate(data: TrackTranslateIn, db: AsyncSession = Depends(get_db), current_user: User = Depends(auth_required)):
    data.user_id = current_user.id
    res = await TrackService.action_translate(db, data)
    return TrackTranslateOut.model_validate(res)


@router.post("/tone", response_model=TrackToneOut)
async def tone(data: TrackToneIn, db: AsyncSession = Depends(get_db), current_user: User = Depends(auth_required)):
    data.user_id = current_user.id
    res = await TrackService.action_tone(db, data)
    return TrackToneOut.model_validate(res)
