from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db
from app.core.auth_deps import auth_required
from app.models import User
from app.schemas.phrase import (
    PhraseListResponse,
    SavedPhraseActionResponse,
)
from app.services.phrase import (
    list_phrases,
    save_phrase,
    unsave_phrase,
)

router = APIRouter()


@router.get("", response_model=PhraseListResponse)
async def get_phrases(
    category: str | None = Query(default=None),
    q: str | None = Query(default=None, description="Search by phrase text"),
    user: User = Depends(auth_required),
    db: AsyncSession = Depends(get_db),
):
    """List active library phrases, optionally filtered by category/search.
    Each item carries a `saved` flag for the current user."""
    items = await list_phrases(db, user.id, category=category, query=q)
    return PhraseListResponse(items=items, total=len(items))


@router.get("/saved", response_model=PhraseListResponse)
async def get_saved_phrases(
    user: User = Depends(auth_required),
    db: AsyncSession = Depends(get_db),
):
    """List the current user's saved phrases."""
    items = await list_phrases(db, user.id, saved_only=True)
    return PhraseListResponse(items=items, total=len(items))


@router.post("/{phrase_id}/save", response_model=SavedPhraseActionResponse)
async def save(
    phrase_id: int,
    user: User = Depends(auth_required),
    db: AsyncSession = Depends(get_db),
):
    """Save a phrase to the current user's collection (idempotent)."""
    await save_phrase(db, user.id, phrase_id)
    return SavedPhraseActionResponse(phrase_id=phrase_id, saved=True)


@router.delete("/{phrase_id}/save", response_model=SavedPhraseActionResponse)
async def unsave(
    phrase_id: int,
    user: User = Depends(auth_required),
    db: AsyncSession = Depends(get_db),
):
    """Remove a phrase from the current user's collection."""
    await unsave_phrase(db, user.id, phrase_id)
    return SavedPhraseActionResponse(phrase_id=phrase_id, saved=False)
