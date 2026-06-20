"""Calendar integration (F5).

Google uses a server-side auth-code exchange (offline access → refresh token);
Apple/Android local calendars are read on-device and pushed to `sync_device_events`.
The Google token-exchange + Calendar API calls require real OAuth credentials and
run only at deploy; device-sync / list / event-prep are unit-testable.

Tokens are encrypted at rest when `CALENDAR_TOKEN_ENC_KEY` (a Fernet key) is set.
"""
from __future__ import annotations

import logging
import uuid
from datetime import datetime, timedelta, timezone

import httpx
from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

import app.core.ai as AI
from app.core.config import settings
from app.models import CalendarConnection, CalendarEvent

logger = logging.getLogger(__name__)
UTC = timezone.utc

_GOOGLE_SCOPES = "https://www.googleapis.com/auth/calendar.readonly"
_GOOGLE_EVENTS_URL = (
    "https://www.googleapis.com/calendar/v3/calendars/primary/events"
)


# ── token encryption (best-effort) ──
def _enc(value: str | None) -> str | None:
    if not value or not settings.CALENDAR_TOKEN_ENC_KEY:
        return value
    try:
        from cryptography.fernet import Fernet

        return Fernet(settings.CALENDAR_TOKEN_ENC_KEY.encode()).encrypt(
            value.encode()
        ).decode()
    except Exception:  # pragma: no cover
        logger.warning("calendar: token encryption unavailable; storing as-is")
        return value


def _dec(value: str | None) -> str | None:
    if not value or not settings.CALENDAR_TOKEN_ENC_KEY:
        return value
    try:
        from cryptography.fernet import Fernet

        return Fernet(settings.CALENDAR_TOKEN_ENC_KEY.encode()).decrypt(
            value.encode()
        ).decode()
    except Exception:  # pragma: no cover
        return value


async def _get_connection(
    db: AsyncSession, user_id: int, provider: str
) -> CalendarConnection | None:
    res = await db.execute(
        select(CalendarConnection).where(
            CalendarConnection.user_id == user_id,
            CalendarConnection.provider == provider,
        )
    )
    return res.scalar_one_or_none()


async def _upsert_connection(
    db: AsyncSession, user_id: int, provider: str, **fields
) -> CalendarConnection:
    conn = await _get_connection(db, user_id, provider)
    if conn is None:
        conn = CalendarConnection(user_id=user_id, provider=provider, **fields)
        db.add(conn)
    else:
        for k, v in fields.items():
            setattr(conn, k, v)
        conn.is_active = True
    await db.commit()
    await db.refresh(conn)
    return conn


# ── Google (deploy-verified) ──
async def connect_google(
    db: AsyncSession, user_id: int, server_auth_code: str
) -> CalendarConnection:
    if not settings.GOOGLE_OAUTH_CLIENT_ID or not settings.GOOGLE_OAUTH_CLIENT_SECRET:
        raise HTTPException(status_code=503, detail="Google OAuth not configured")
    async with httpx.AsyncClient(timeout=15) as client:
        resp = await client.post(
            settings.GOOGLE_TOKEN_URI or "https://oauth2.googleapis.com/token",
            data={
                "code": server_auth_code,
                "client_id": settings.GOOGLE_OAUTH_CLIENT_ID,
                "client_secret": settings.GOOGLE_OAUTH_CLIENT_SECRET,
                "grant_type": "authorization_code",
                "access_type": "offline",
            },
        )
    if resp.status_code != 200:
        raise HTTPException(status_code=400, detail="Google code exchange failed")
    tok = resp.json()
    expiry = datetime.now(UTC) + timedelta(seconds=int(tok.get("expires_in", 3600)))
    return await _upsert_connection(
        db,
        user_id,
        "google",
        access_token=_enc(tok.get("access_token")),
        refresh_token=_enc(tok.get("refresh_token")),
        token_expiry=expiry,
        scopes=tok.get("scope") or _GOOGLE_SCOPES,
    )


async def _google_access_token(db: AsyncSession, conn: CalendarConnection) -> str:
    if conn.token_expiry and conn.token_expiry > datetime.now(UTC) + timedelta(
        seconds=60
    ):
        return _dec(conn.access_token) or ""
    # refresh
    refresh = _dec(conn.refresh_token)
    if not refresh:
        raise HTTPException(status_code=400, detail="No refresh token; reconnect")
    async with httpx.AsyncClient(timeout=15) as client:
        resp = await client.post(
            settings.GOOGLE_TOKEN_URI or "https://oauth2.googleapis.com/token",
            data={
                "refresh_token": refresh,
                "client_id": settings.GOOGLE_OAUTH_CLIENT_ID,
                "client_secret": settings.GOOGLE_OAUTH_CLIENT_SECRET,
                "grant_type": "refresh_token",
            },
        )
    if resp.status_code != 200:
        raise HTTPException(status_code=400, detail="Token refresh failed")
    tok = resp.json()
    conn.access_token = _enc(tok.get("access_token"))
    conn.token_expiry = datetime.now(UTC) + timedelta(
        seconds=int(tok.get("expires_in", 3600))
    )
    # Commit the refreshed token immediately so it isn't lost if a later step
    # (e.g. the events fetch) fails.
    await db.commit()
    return _dec(conn.access_token) or ""


async def sync_google_events(db: AsyncSession, user_id: int) -> int:
    conn = await _get_connection(db, user_id, "google")
    if conn is None or not conn.is_active:
        raise HTTPException(status_code=404, detail="Google calendar not connected")
    access = await _google_access_token(db, conn)
    now = datetime.now(UTC).isoformat()
    async with httpx.AsyncClient(timeout=15) as client:
        resp = await client.get(
            _GOOGLE_EVENTS_URL,
            headers={"Authorization": f"Bearer {access}"},
            params={
                "timeMin": now,
                "maxResults": 20,
                "singleEvents": "true",
                "orderBy": "startTime",
            },
        )
    if resp.status_code != 200:
        raise HTTPException(status_code=400, detail="Google events fetch failed")
    items = resp.json().get("items", [])
    count = 0
    for it in items:
        start = (it.get("start") or {})
        end = (it.get("end") or {})
        is_all_day = "date" in start
        await _upsert_event(
            db,
            connection_id=conn.id,
            user_id=user_id,
            provider="google",
            external_event_id=it.get("id", ""),
            title=it.get("summary"),
            description=it.get("description"),
            location=it.get("location"),
            starts_at=_parse_dt(start.get("dateTime") or start.get("date")),
            ends_at=_parse_dt(end.get("dateTime") or end.get("date")),
            is_all_day=is_all_day,
            raw=it,
        )
        count += 1
    conn.last_synced_at = datetime.now(UTC)
    await db.commit()
    return count


# ── device (Apple / Android local) ──
async def sync_device_events(
    db: AsyncSession, user_id: int, provider: str, events: list
) -> int:
    conn = await _upsert_connection(db, user_id, provider)
    count = 0
    for e in events:
        await _upsert_event(
            db,
            connection_id=conn.id,
            user_id=user_id,
            provider=provider,
            external_event_id=e.external_event_id,
            title=e.title,
            description=e.description,
            location=e.location,
            starts_at=e.starts_at,
            ends_at=e.ends_at,
            is_all_day=e.is_all_day,
            raw={},
        )
        count += 1
    conn.last_synced_at = datetime.now(UTC)
    await db.commit()
    return count


async def _upsert_event(db: AsyncSession, **f) -> None:
    res = await db.execute(
        select(CalendarEvent).where(
            CalendarEvent.connection_id == f["connection_id"],
            CalendarEvent.external_event_id == f["external_event_id"],
        )
    )
    row = res.scalar_one_or_none()
    raw = f.pop("raw", {})
    if row is None:
        db.add(CalendarEvent(raw_json=raw, **f))
    else:
        for k, v in f.items():
            setattr(row, k, v)
        row.raw_json = raw


async def list_upcoming_events(
    db: AsyncSession, user_id: int, limit: int = 20
) -> list[CalendarEvent]:
    now = datetime.now(UTC)
    res = await db.execute(
        select(CalendarEvent)
        .where(
            CalendarEvent.user_id == user_id,
            (CalendarEvent.starts_at.is_(None)) | (CalendarEvent.starts_at >= now),
        )
        .order_by(CalendarEvent.starts_at.asc().nullslast())
        .limit(limit)
    )
    return list(res.scalars().all())


async def get_event_prep(db: AsyncSession, user_id: int, event_id: str) -> dict:
    try:
        eid = uuid.UUID(str(event_id))
    except (ValueError, TypeError):
        raise HTTPException(status_code=404, detail="Event not found")
    res = await db.execute(
        select(CalendarEvent).where(
            CalendarEvent.id == eid, CalendarEvent.user_id == user_id
        )
    )
    event = res.scalar_one_or_none()
    if event is None:
        raise HTTPException(status_code=404, detail="Event not found")
    when = event.starts_at.isoformat() if event.starts_at else ""
    result = await AI.generate_event_prep(
        title=event.title or "your event",
        description=event.description or "",
        location=event.location or "",
        when=when,
    )
    return {
        "event_id": str(event.id),
        "summary": result.get("summary", ""),
        "openers": result.get("openers", []),
        "tips": result.get("tips", []),
    }


def _parse_dt(value: str | None) -> datetime | None:
    if not value:
        return None
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except Exception:
        return None
