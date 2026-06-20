from __future__ import annotations

import uuid

from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

import app.core.ai as AI
from app.models import ConversationSession, ConversationTurn

_OPENERS = {
    "networking": "Hi! Great to meet you. So, what brings you here today?",
    "cafe": "Hi there! What can I get started for you?",
    "small_talk": "Hey! Lovely weather today, isn't it? How's your day going?",
    "work": "Morning! Do you have a moment to chat about the project?",
    "neighbours": "Hi neighbour! Settling in okay?",
}


def _opener(scene: str) -> str:
    return _OPENERS.get(scene, "Hi! What would you like to talk about?")


async def start_session(
    db: AsyncSession, user_id: int, scene: str
) -> tuple[ConversationSession, str]:
    session = ConversationSession(user_id=user_id, scene=scene)
    db.add(session)
    await db.commit()
    await db.refresh(session)

    opener = _opener(scene)
    db.add(
        ConversationTurn(
            session_id=session.id, user_id=user_id, role="assistant", text=opener
        )
    )
    await db.commit()
    return session, opener


async def _load_session(
    db: AsyncSession, session_id: str, user_id: int
) -> ConversationSession:
    try:
        sid = uuid.UUID(str(session_id))
    except (ValueError, TypeError):
        raise HTTPException(status_code=404, detail="Conversation not found")
    res = await db.execute(
        select(ConversationSession).where(
            ConversationSession.id == sid,
            ConversationSession.user_id == user_id,
        )
    )
    session = res.scalar_one_or_none()
    if session is None:
        raise HTTPException(status_code=404, detail="Conversation not found")
    return session


async def _turns(db: AsyncSession, session_id: str) -> list[ConversationTurn]:
    res = await db.execute(
        select(ConversationTurn)
        .where(ConversationTurn.session_id == session_id)
        .order_by(ConversationTurn.created_at.asc())
    )
    return list(res.scalars().all())


def _history_text(turns: list[ConversationTurn]) -> str:
    lines = []
    for t in turns:
        who = "Partner" if t.role == "assistant" else "Learner"
        lines.append(f"{who}: {t.text}")
    return "\n".join(lines)


async def add_turn(
    db: AsyncSession, session_id: str, user_id: int, user_text: str
) -> dict:
    session = await _load_session(db, session_id, user_id)

    # Build history from the prior turns, call the model, then persist both the
    # user turn and the reply in ONE commit. If the AI call fails nothing is
    # committed — so a failed request leaves no dangling user turn and a retry
    # won't duplicate it.
    history = _history_text(await _turns(db, session_id))
    result = await AI.conversation_turn(
        scene=session.scene, history=history, user_message=user_text
    )
    reply = result.get("reply") or "Sorry, could you say that again?"
    correction = (result.get("correction") or "").strip() or None
    tip = (result.get("tip") or "").strip() or None
    feedback = {"correction": correction, "tip": tip} if (correction or tip) else None

    db.add(
        ConversationTurn(
            session_id=session.id, user_id=user_id, role="user", text=user_text
        )
    )
    db.add(
        ConversationTurn(
            session_id=session.id,
            user_id=user_id,
            role="assistant",
            text=reply,
            feedback=feedback,
        )
    )
    await db.commit()

    return {"reply": reply, "correction": correction, "tip": tip}


async def get_history(db: AsyncSession, session_id: str, user_id: int) -> dict:
    session = await _load_session(db, session_id, user_id)
    turns = await _turns(db, session_id)
    return {
        "session_id": str(session.id),
        "scene": session.scene,
        "turns": [
            {"role": t.role, "text": t.text, "feedback": t.feedback} for t in turns
        ],
    }
