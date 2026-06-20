from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db
from app.core.auth_deps import auth_required
from app.models import User
from app.schemas.notifications import DeviceTokenActionResponse, RegisterTokenRequest
from app.services.notifications import register_token, unregister_token

router = APIRouter()


@router.post("/register-token", response_model=DeviceTokenActionResponse)
async def register(
    req: RegisterTokenRequest,
    user: User = Depends(auth_required),
    db: AsyncSession = Depends(get_db),
):
    """Register (or re-bind) an FCM device token for the current user."""
    await register_token(db, user.id, req.token, req.platform)
    return DeviceTokenActionResponse(registered=True)


@router.delete("/register-token", response_model=DeviceTokenActionResponse)
async def unregister(
    req: RegisterTokenRequest,
    user: User = Depends(auth_required),
    db: AsyncSession = Depends(get_db),
):
    """Remove an FCM device token (e.g. on sign-out)."""
    await unregister_token(db, user.id, req.token)
    return DeviceTokenActionResponse(registered=False)
