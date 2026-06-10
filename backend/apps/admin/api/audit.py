"""Audit log API endpoints."""
from __future__ import annotations
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from apps.admin.models import AdminUser
from apps.admin.api.deps import get_current_admin, require_role
from apps.admin.services import AuditService
from apps.admin.schemas.audit import (
    AuditLogListRequest, AuditLogListResponse, AuditLogEntry,
    AuditLogDetailResponse
)

router = APIRouter(prefix="/audit", tags=["Admin - Audit"])


@router.get("", response_model=AuditLogListResponse)
async def list_audit_logs(
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=200),
    admin_id: str = Query(None),
    action: str = Query(None),
    resource_type: str = Query(None),
    resource_id: str = Query(None),
    success: bool = Query(None),
    start_date: datetime = Query(None),
    end_date: datetime = Query(None),
    current_admin: AdminUser = Depends(require_role("super_admin", "admin")),
    db: AsyncSession = Depends(get_db),
):
    """
    List audit logs with filtering.
    Only super_admin and admin can view audit logs.
    """
    service = AuditService(db)
    
    logs, total = await service.list_logs(
        page=page,
        page_size=page_size,
        admin_id=admin_id,
        action=action,
        resource_type=resource_type,
        resource_id=resource_id,
        success=success,
        start_date=start_date,
        end_date=end_date,
    )
    
    return AuditLogListResponse(
        logs=[
            AuditLogEntry(
                id=str(log.id),
                admin_email=log.admin_email,
                action=log.action,
                resource_type=log.resource_type,
                resource_id=log.resource_id,
                description=log.description,
                ip_address=log.ip_address,
                success=log.success,
                created_at=log.created_at,
            )
            for log in logs
        ],
        total=total,
        page=page,
        page_size=page_size,
    )


@router.get("/{log_id}", response_model=AuditLogDetailResponse)
async def get_audit_log_detail(
    log_id: str,
    current_admin: AdminUser = Depends(require_role("super_admin", "admin")),
    db: AsyncSession = Depends(get_db),
):
    """Get full details of a specific audit log entry."""
    service = AuditService(db)
    
    log = await service.get_log_by_id(log_id)
    if not log:
        raise HTTPException(status_code=404, detail="Audit log not found")
    
    return AuditLogDetailResponse(
        log=AuditLogEntry(
            id=str(log.id),
            admin_email=log.admin_email,
            action=log.action,
            resource_type=log.resource_type,
            resource_id=log.resource_id,
            description=log.description,
            ip_address=log.ip_address,
            success=log.success,
            created_at=log.created_at,
        ),
        old_value=log.old_value,
        new_value=log.new_value,
        metadata=log.metadata or {},
        user_agent=log.user_agent,
    )


@router.get("/user/{user_id}", response_model=AuditLogListResponse)
async def get_user_action_history(
    user_id: int,
    current_admin: AdminUser = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """Get all admin actions performed on a specific user."""
    service = AuditService(db)
    
    logs = await service.get_user_action_history(user_id)
    
    return AuditLogListResponse(
        logs=[
            AuditLogEntry(
                id=str(log.id),
                admin_email=log.admin_email,
                action=log.action,
                resource_type=log.resource_type,
                resource_id=log.resource_id,
                description=log.description,
                ip_address=log.ip_address,
                success=log.success,
                created_at=log.created_at,
            )
            for log in logs
        ],
        total=len(logs),
        page=1,
        page_size=len(logs),
    )
