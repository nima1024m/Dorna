"""Admin authentication API endpoints."""
from __future__ import annotations
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update

from app.core.database import get_db
from app.core.security import hash_password, verify_password, create_jwt
from apps.admin.models import AdminUser
from apps.admin.models.admin_user import AdminRole
from apps.admin.schemas.auth import (
    AdminLoginRequest, AdminLoginResponse, AdminProfile,
    AdminRefreshRequest, AdminRefreshResponse,
    AdminPasswordChangeRequest, AdminPasswordChangeResponse
)
from apps.admin.api.deps import get_current_admin, get_client_ip
from apps.admin.services import AuditService
from apps.admin.models.audit_log import AuditAction

router = APIRouter(prefix="/auth", tags=["Admin Auth"])


@router.post("/login", response_model=AdminLoginResponse)
async def admin_login(
    req: AdminLoginRequest,
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    """
    Admin login endpoint.
    Separate from regular user login for security.
    """
    # Find admin by email
    result = await db.execute(
        select(AdminUser).where(AdminUser.email == req.email.lower())
    )
    admin = result.scalar_one_or_none()
    
    client_ip = get_client_ip(request)
    audit = AuditService(db)
    
    if not admin:
        await audit.log_action(
            admin_id=None,
            admin_email=req.email,
            action=AuditAction.ADMIN_FAILED_LOGIN.value,
            resource_type="admin",
            description="Admin not found",
            ip_address=client_ip,
            success=False,
            error_message="Admin not found"
        )
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    # Check if locked
    if admin.is_locked:
        await audit.log_action(
            admin_id=str(admin.id),
            admin_email=admin.email,
            action=AuditAction.ADMIN_FAILED_LOGIN.value,
            resource_type="admin",
            description="Account is locked",
            ip_address=client_ip,
            success=False,
            error_message="Account locked"
        )
        raise HTTPException(status_code=401, detail="Account is locked")
    
    # Verify password
    if not verify_password(req.password, admin.password_hash):
        # Increment failed attempts
        await db.execute(
            update(AdminUser)
            .where(AdminUser.id == admin.id)
            .values(failed_login_attempts=admin.failed_login_attempts + 1)
        )
        await db.commit()
        
        await audit.log_action(
            admin_id=str(admin.id),
            admin_email=admin.email,
            action=AuditAction.ADMIN_FAILED_LOGIN.value,
            resource_type="admin",
            description="Invalid password",
            ip_address=client_ip,
            success=False,
            error_message="Invalid password"
        )
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    # TODO: Check MFA if enabled
    if admin.mfa_enabled and not req.mfa_code:
        raise HTTPException(status_code=401, detail="MFA code required")
    
    # Successful login - update admin record
    await db.execute(
        update(AdminUser)
        .where(AdminUser.id == admin.id)
        .values(
            last_login_at=datetime.now(timezone.utc),
            last_login_ip=client_ip,
            failed_login_attempts=0
        )
    )
    await db.commit()
    
    # Generate tokens with admin type
    access_token = create_jwt(subject=str(admin.id), extra={"type": "admin", "role": admin.role})
    refresh_token = create_jwt(subject=str(admin.id), extra={"type": "admin_refresh"}, expires_days=7)
    
    # Log successful login
    await audit.log_action(
        admin_id=str(admin.id),
        admin_email=admin.email,
        action=AuditAction.ADMIN_LOGIN.value,
        resource_type="admin",
        resource_id=str(admin.id),
        description="Successful login",
        ip_address=client_ip,
        success=True
    )
    
    return AdminLoginResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        admin=AdminProfile(
            id=str(admin.id),
            email=admin.email,
            full_name=admin.full_name,
            role=admin.role,
            permissions=admin.permissions or {},
            mfa_enabled=admin.mfa_enabled,
        )
    )


@router.post("/refresh", response_model=AdminRefreshResponse)
async def admin_refresh_token(
    req: AdminRefreshRequest,
    db: AsyncSession = Depends(get_db),
):
    """Refresh admin access token."""
    from app.core.security import parse_jwt
    
    try:
        payload = parse_jwt(req.refresh_token)
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid refresh token")
    
    if payload.get("type") != "admin_refresh":
        raise HTTPException(status_code=401, detail="Invalid token type")
    
    admin_id = payload.get("sub")
    if not admin_id:
        raise HTTPException(status_code=401, detail="Invalid token payload")
    
    # Verify admin still exists and is active
    result = await db.execute(
        select(AdminUser).where(AdminUser.id == admin_id)
    )
    admin = result.scalar_one_or_none()
    
    if not admin or not admin.is_active or admin.is_locked:
        raise HTTPException(status_code=401, detail="Admin account not valid")
    
    # Generate new tokens
    access_token = create_jwt(subject=str(admin.id), extra={"type": "admin", "role": admin.role})
    refresh_token = create_jwt(subject=str(admin.id), extra={"type": "admin_refresh"}, expires_days=7)
    
    return AdminRefreshResponse(
        access_token=access_token,
        refresh_token=refresh_token
    )


@router.get("/me", response_model=AdminProfile)
async def get_current_admin_profile(
    admin: AdminUser = Depends(get_current_admin),
):
    """Get current admin's profile."""
    return AdminProfile(
        id=str(admin.id),
        email=admin.email,
        full_name=admin.full_name,
        role=admin.role,
        permissions=admin.permissions or {},
        mfa_enabled=admin.mfa_enabled,
    )


@router.post("/logout")
async def admin_logout(
    request: Request,
    admin: AdminUser = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """Admin logout - logs the action."""
    audit = AuditService(db)
    await audit.log_action(
        admin_id=str(admin.id),
        admin_email=admin.email,
        action=AuditAction.ADMIN_LOGOUT.value,
        resource_type="admin",
        resource_id=str(admin.id),
        ip_address=get_client_ip(request),
        success=True
    )
    
    return {"status": "OK", "message": "Logged out successfully"}


@router.post("/change-password", response_model=AdminPasswordChangeResponse)
async def admin_change_password(
    req: AdminPasswordChangeRequest,
    request: Request,
    admin: AdminUser = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """Change admin's own password."""
    
    # Verify current password
    if not verify_password(req.current_password, admin.password_hash):
        raise HTTPException(status_code=400, detail="Current password is incorrect")
    
    # Check if new password is same as old
    if req.current_password == req.new_password:
        raise HTTPException(status_code=400, detail="New password must be different")
    
    # Update password
    new_hash = hash_password(req.new_password)
    await db.execute(
        update(AdminUser)
        .where(AdminUser.id == admin.id)
        .values(
            password_hash=new_hash,
            password_changed_at=datetime.now(timezone.utc)
        )
    )
    await db.commit()
    
    # Log action
    audit = AuditService(db)
    await audit.log_action(
        admin_id=str(admin.id),
        admin_email=admin.email,
        action="password_change",
        resource_type="admin",
        resource_id=str(admin.id),
        ip_address=get_client_ip(request),
        success=True
    )
    
    return AdminPasswordChangeResponse()
