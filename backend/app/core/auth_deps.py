from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.database import get_db
from app.core.security import parse_jwt
from app.models import User

security = HTTPBearer(auto_error=False)


def _unauth(code: str, message: str):
    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail={"status": "ERROR", "code": code, "message": message},
    )


async def auth_required(
        credentials: HTTPAuthorizationCredentials = Depends(security),
        db: AsyncSession = Depends(get_db),
) -> User:
    if not credentials or credentials.scheme.lower() != "bearer" or not credentials.credentials:
        _unauth("no_token", "Missing or invalid Authorization header")

    token = credentials.credentials

    try:
        payload = parse_jwt(token)
    except Exception:
        _unauth("invalid_access", "Invalid or expired access token")

    user_id = payload.get("sub")
    if not user_id:
        _unauth("invalid_access", "Invalid token payload")

    res = await db.execute(select(User).where(User.id == int(user_id)))
    user = res.scalar_one_or_none()
    if not user or user.is_deleted or not user.is_active:
        _unauth("inactive_user", "User is not active")

    return user
