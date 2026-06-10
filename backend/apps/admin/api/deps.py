"""Admin authentication dependencies and utilities."""
from __future__ import annotations
from typing import Optional
import uuid

from fastapi import Depends, HTTPException, status, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.database import get_db
from app.core.security import parse_jwt
from apps.admin.models import AdminUser


admin_security = HTTPBearer(auto_error=False)


def _admin_unauth(code: str, message: str):
    """Raise admin authentication error."""
    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail={"status": "ERROR", "code": code, "message": message},
    )


def _admin_forbidden(code: str, message: str):
    """Raise admin authorization error."""
    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail={"status": "ERROR", "code": code, "message": message},
    )


async def get_current_admin(
    credentials: HTTPAuthorizationCredentials = Depends(admin_security),
    db: AsyncSession = Depends(get_db),
) -> AdminUser:
    """
    Dependency to get the current authenticated admin user.
    Uses the same JWT structure but validates against admin_users table.
    """
    if not credentials or credentials.scheme.lower() != "bearer" or not credentials.credentials:
        _admin_unauth("no_token", "Missing or invalid Authorization header")

    token = credentials.credentials

    try:
        payload = parse_jwt(token)
    except Exception:
        _admin_unauth("invalid_access", "Invalid or expired access token")

    admin_id = payload.get("sub")
    token_type = payload.get("type")
    
    # Validate it's an admin token
    if token_type != "admin":
        _admin_unauth("invalid_token_type", "Not an admin token")
    
    if not admin_id:
        _admin_unauth("invalid_access", "Invalid token payload")

    try:
        admin_uuid = uuid.UUID(admin_id)
    except ValueError:
        _admin_unauth("invalid_access", "Invalid admin ID format")

    result = await db.execute(select(AdminUser).where(AdminUser.id == admin_uuid))
    admin = result.scalar_one_or_none()
    
    if not admin:
        _admin_unauth("admin_not_found", "Admin user not found")
    
    if not admin.is_active:
        _admin_unauth("admin_inactive", "Admin account is not active")
    
    if admin.is_locked:
        _admin_unauth("admin_locked", "Admin account is locked")

    return admin


def require_permission(permission: str):
    """
    Dependency factory to require a specific permission.
    Usage: Depends(require_permission("manage_users"))
    """
    async def checker(admin: AdminUser = Depends(get_current_admin)) -> AdminUser:
        if not admin.has_permission(permission):
            _admin_forbidden("permission_denied", f"Missing permission: {permission}")
        return admin
    return checker


def require_role(*roles: str):
    """
    Dependency factory to require one of the specified roles.
    Usage: Depends(require_role("super_admin", "admin"))
    """
    async def checker(admin: AdminUser = Depends(get_current_admin)) -> AdminUser:
        if admin.role not in roles:
            _admin_forbidden("role_denied", f"Required role: {', '.join(roles)}")
        return admin
    return checker


def get_client_ip(request: Request) -> str:
    """Extract client IP from request."""
    forwarded = request.headers.get("X-Forwarded-For")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return request.client.host if request.client else "unknown"
