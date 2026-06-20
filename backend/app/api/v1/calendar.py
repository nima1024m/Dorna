from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db
from app.core.auth_deps import auth_required
from app.models import User
from app.schemas.calendar import (
    ConnectResponse,
    DeviceEventsSyncRequest,
    EventListResponse,
    EventOut,
    EventPrepResponse,
    GoogleConnectRequest,
    SyncResponse,
)
from app.services.calendar import (
    connect_google,
    get_event_prep,
    list_upcoming_events,
    sync_device_events,
    sync_google_events,
)

router = APIRouter()


@router.post("/connect/google", response_model=ConnectResponse)
async def connect_google_calendar(
    req: GoogleConnectRequest,
    user: User = Depends(auth_required),
    db: AsyncSession = Depends(get_db),
):
    """Exchange a Google server-auth-code for offline calendar access."""
    await connect_google(db, user.id, req.server_auth_code)
    return ConnectResponse(provider="google", connected=True)


@router.post("/sync/google", response_model=SyncResponse)
async def sync_google(
    user: User = Depends(auth_required),
    db: AsyncSession = Depends(get_db),
):
    """Pull upcoming events from the connected Google calendar."""
    n = await sync_google_events(db, user.id)
    return SyncResponse(synced=n)


@router.post("/events/sync", response_model=SyncResponse)
async def sync_device(
    req: DeviceEventsSyncRequest,
    user: User = Depends(auth_required),
    db: AsyncSession = Depends(get_db),
):
    """Receive on-device (Apple/Android) calendar events and cache them."""
    n = await sync_device_events(db, user.id, req.provider, req.events)
    return SyncResponse(synced=n)


@router.get("/events", response_model=EventListResponse)
async def list_events(
    user: User = Depends(auth_required),
    db: AsyncSession = Depends(get_db),
):
    """List the user's upcoming cached calendar events."""
    rows = await list_upcoming_events(db, user.id)
    events = [
        EventOut(
            id=str(r.id),
            provider=r.provider,
            title=r.title,
            description=r.description,
            location=r.location,
            starts_at=r.starts_at,
            ends_at=r.ends_at,
            is_all_day=r.is_all_day,
        )
        for r in rows
    ]
    return EventListResponse(events=events, total=len(events))


@router.post("/events/{event_id}/prep", response_model=EventPrepResponse)
async def event_prep(
    event_id: str,
    user: User = Depends(auth_required),
    db: AsyncSession = Depends(get_db),
):
    """Generate AI event-prep (summary, openers, tips) for one event."""
    data = await get_event_prep(db, user.id, event_id)
    return EventPrepResponse(**data)
