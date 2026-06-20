from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db
from app.core.auth_deps import auth_required
from app.models import User
from app.schemas.conversation import (
    ConversationHistoryResponse,
    ConversationStartResponse,
    StartConversationRequest,
    TurnRequest,
    TurnResponse,
)
from app.services.conversation import add_turn, get_history, start_session

router = APIRouter()


@router.post("/start", response_model=ConversationStartResponse)
async def start(
    req: StartConversationRequest,
    user: User = Depends(auth_required),
    db: AsyncSession = Depends(get_db),
):
    """Start a scene-based practice conversation."""
    session, opener = await start_session(db, user.id, req.scene)
    return ConversationStartResponse(
        session_id=str(session.id), scene=session.scene, opener=opener
    )


@router.post("/{session_id}/turn", response_model=TurnResponse)
async def turn(
    session_id: str,
    req: TurnRequest,
    user: User = Depends(auth_required),
    db: AsyncSession = Depends(get_db),
):
    """Send the learner's message; get Dorna's reply + gentle feedback."""
    data = await add_turn(db, session_id, user.id, req.text)
    return TurnResponse(**data)


@router.get("/{session_id}", response_model=ConversationHistoryResponse)
async def history(
    session_id: str,
    user: User = Depends(auth_required),
    db: AsyncSession = Depends(get_db),
):
    data = await get_history(db, session_id, user.id)
    return ConversationHistoryResponse(**data)
