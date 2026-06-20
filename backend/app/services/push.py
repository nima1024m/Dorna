"""FCM HTTP v1 push sender.

Reuses the existing Google service account (rendered from settings via
`render_service_account_json`) — the same SA used for Google Cloud TTS, in the
same Firebase project. No new credential file is required as long as that SA has
the Firebase Cloud Messaging API enabled. `google-auth` + `httpx` are already
dependencies, so this needs no extra packages.
"""
from __future__ import annotations

import asyncio
import logging

import httpx
from google.auth.transport.requests import Request as GoogleAuthRequest
from google.oauth2 import service_account
from sqlalchemy import update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.agents.gc_renderer import render_service_account_json
from app.core.config import settings
from app.models import DeviceToken

logger = logging.getLogger(__name__)

_FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging"
_creds: service_account.Credentials | None = None


def _get_credentials() -> service_account.Credentials:
    global _creds
    if _creds is None:
        info = render_service_account_json()
        _creds = service_account.Credentials.from_service_account_info(
            info, scopes=[_FCM_SCOPE]
        )
    return _creds


def _bearer_token() -> str:
    creds = _get_credentials()
    if not creds.valid:
        creds.refresh(GoogleAuthRequest())
    return creds.token


def _project_id() -> str | None:
    return settings.FCM_PROJECT_ID or settings.GOOGLE_APPLICATION_CREDENTIALS_PROJECT_ID


async def send_to_token(
    db: AsyncSession,
    token: str,
    *,
    title: str,
    body: str,
    data: dict[str, str] | None = None,
) -> bool:
    """Send one FCM HTTP v1 message. Returns True on 200; deactivates dead tokens."""
    project_id = _project_id()
    if not project_id:
        logger.warning("FCM: no project id configured; skipping send")
        return False

    bearer = await asyncio.to_thread(_bearer_token)
    url = f"https://fcm.googleapis.com/v1/projects/{project_id}/messages:send"
    message = {
        "message": {
            "token": token,
            "notification": {"title": title, "body": body},
            "data": {k: str(v) for k, v in (data or {}).items()},
        }
    }
    async with httpx.AsyncClient(timeout=10) as client:
        resp = await client.post(
            url, json=message, headers={"Authorization": f"Bearer {bearer}"}
        )
    if resp.status_code == 200:
        return True
    if resp.status_code in (400, 404):
        await db.execute(
            update(DeviceToken)
            .where(DeviceToken.token == token)
            .values(is_active=False)
        )
        await db.commit()
    else:  # pragma: no cover
        logger.warning("FCM send failed (%s): %s", resp.status_code, resp.text)
    return False


async def send_to_user(
    db: AsyncSession,
    user_id: int,
    *,
    title: str,
    body: str,
    data: dict[str, str] | None = None,
) -> int:
    from app.services.notifications import active_tokens_for_user

    tokens = await active_tokens_for_user(db, user_id)
    sent = 0
    for t in tokens:
        if await send_to_token(db, t, title=title, body=body, data=data):
            sent += 1
    return sent
