from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db
from app.core.auth_deps import auth_required
from app.models import User
from app.schemas.onboarding import (
    LearningGoalListResponse,
    LearningGoalOut,
    TopicCategoryListResponse,
    TopicCategoryOut,
    OnboardingUpsertRequest,
    OnboardingPreferencesResponse,
)
from app.services.podcast import (
    get_user_podcast_preferences,
    list_learning_goals,
    list_podcast_topic_categories,
    upsert_user_podcast_preferences,
)

router = APIRouter()


@router.get("/", response_model=OnboardingPreferencesResponse)
async def get_onboarding(
    user: User = Depends(auth_required),
    db: AsyncSession = Depends(get_db),
):
    """
    Get current user's onboarding preferences.
    """
    data = await get_user_podcast_preferences(user.id, db)
    return OnboardingPreferencesResponse(**data)


@router.put("/", response_model=OnboardingPreferencesResponse)
async def put_onboarding(
    req: OnboardingUpsertRequest,
    user: User = Depends(auth_required),
    db: AsyncSession = Depends(get_db),
):
    """
    Upsert current user's onboarding preferences.
    Rejects empty category_ids/goal_ids.
    """
    data = await upsert_user_podcast_preferences(user.id, req, db)
    return OnboardingPreferencesResponse(**data)


@router.get("/categories", response_model=TopicCategoryListResponse)
async def list_categories(
    user: User = Depends(auth_required),
    db: AsyncSession = Depends(get_db),
):
    """
    List all topic categories (static lookup table).
    """
    rows = await list_podcast_topic_categories(db)
    return TopicCategoryListResponse(
        categories=[TopicCategoryOut(id=r.id, label=r.label) for r in rows]
    )


@router.get("/goals", response_model=LearningGoalListResponse)
async def list_goals(
    user: User = Depends(auth_required),
    db: AsyncSession = Depends(get_db),
):
    """
    List all learning goals (static lookup table).
    """
    rows = await list_learning_goals(db)
    return LearningGoalListResponse(
        goals=[
            LearningGoalOut(
                id=r.id,
                key=r.key,
                title=r.title,
                description=r.description,
            )
            for r in rows
        ]
    )
