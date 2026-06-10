from fastapi import APIRouter, Depends
from fastapi.responses import JSONResponse
from sqlalchemy.ext.asyncio import AsyncSession
from app.schemas.assistant import *
from app.api.deps import get_db
from app.core.auth_deps import auth_required
from app.models import User
from app.services.assistant import AssistantService
from app.services.learning import MistakeTrackerService, LearningExperienceService

router = APIRouter()


@router.get("/learning-insights", response_model=PersonalizedLearningProfile)
async def get_learning_insights(db: AsyncSession = Depends(get_db), current_user: User = Depends(auth_required)):
    insights = await LearningExperienceService.get_personalized_profile(db, current_user.id)
    return insights


@router.post("/analysis/process/{user_id}", response_model=PersonalizedLearningProfile)
async def process_user_analysis(user_id: int, db: AsyncSession = Depends(get_db)):
    """Triggers analysis for a specific user ID (admin/internal use)."""
    insights = await LearningExperienceService.get_personalized_profile(db, user_id)
    return insights


@router.get("/analysis/view/{email}", response_model=PersonalizedLearningProfile)
async def view_user_analysis(email: str, db: AsyncSession = Depends(get_db)):
    """Retrieves analysis results by user email."""
    insights_model = await MistakeTrackerService.get_insights_by_email(db, email)
    if not insights_model:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="User insights not found")
    
    insights = await LearningExperienceService.get_personalized_profile(db, insights_model.user_id)
    return insights


@router.post("/grammar", response_model=SuggestGrammarOut)
async def grammar(data: SuggestGrammarIn, db: AsyncSession = Depends(get_db), current_user: User = Depends(auth_required)):
    data.user_id = current_user.id
    res = await AssistantService.grammar_correction(db, data)

    if res["status"] == "ERROR":
        return JSONResponse(
            status_code=422,
            content=res
        )

    return SuggestGrammarOut.model_validate(res)


@router.post("/translate", response_model=SuggestTranslateOut)
async def translate(data: SuggestTranslateIn, db: AsyncSession = Depends(get_db), current_user: User = Depends(auth_required)):
    data.user_id = current_user.id
    res = await AssistantService.translate_text(db, data)

    if res["status"] == "ERROR":
        return JSONResponse(
            status_code=422,
            content=res
        )

    return SuggestTranslateOut.model_validate(res)


@router.post("/tone", response_model=SuggestToneOut)
async def tone(data: SuggestToneIn, db: AsyncSession = Depends(get_db), current_user: User = Depends(auth_required)):
    data.user_id = current_user.id
    res = await AssistantService.tone_adjustment(db, data)

    if res["status"] == "ERROR":
        return JSONResponse(
            status_code=422,
            content=res
        )

    return SuggestToneOut.model_validate(res)
