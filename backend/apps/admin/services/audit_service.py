"""Audit logging service."""
from __future__ import annotations
from typing import Optional, List, Tuple
from datetime import datetime
import uuid

from sqlalchemy import select, func, and_
from sqlalchemy.ext.asyncio import AsyncSession

from apps.admin.models import AuditLog
from apps.admin.models.audit_log import AuditAction


class AuditService:
    """Service for creating and querying audit logs."""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def log_action(
        self,
        admin_id: Optional[str],
        admin_email: str,
        action: str,
        resource_type: str,
        resource_id: Optional[str] = None,
        description: Optional[str] = None,
        old_value: Optional[dict] = None,
        new_value: Optional[dict] = None,
        action_metadata: Optional[dict] = None,
        ip_address: Optional[str] = None,
        user_agent: Optional[str] = None,
        request_id: Optional[str] = None,
        success: bool = True,
        error_message: Optional[str] = None,
    ) -> AuditLog:
        """Create an audit log entry."""
        
        log = AuditLog(
            admin_id=uuid.UUID(admin_id) if admin_id else None,
            admin_email=admin_email,
            action=action,
            resource_type=resource_type,
            resource_id=resource_id,
            description=description,
            old_value=old_value,
            new_value=new_value,
            action_metadata=action_metadata or {},
            ip_address=ip_address,
            user_agent=user_agent,
            request_id=request_id,
            success=success,
            error_message=error_message,
        )
        
        self.db.add(log)
        await self.db.commit()
        await self.db.refresh(log)
        
        return log
    
    async def list_logs(
        self,
        page: int = 1,
        page_size: int = 50,
        admin_id: Optional[str] = None,
        action: Optional[str] = None,
        resource_type: Optional[str] = None,
        resource_id: Optional[str] = None,
        success: Optional[bool] = None,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
    ) -> Tuple[List[AuditLog], int]:
        """List audit logs with filtering."""
        
        query = select(AuditLog)
        
        if admin_id:
            query = query.where(AuditLog.admin_id == uuid.UUID(admin_id))
        
        if action:
            query = query.where(AuditLog.action == action)
        
        if resource_type:
            query = query.where(AuditLog.resource_type == resource_type)
        
        if resource_id:
            query = query.where(AuditLog.resource_id == resource_id)
        
        if success is not None:
            query = query.where(AuditLog.success == success)
        
        if start_date:
            query = query.where(AuditLog.created_at >= start_date)
        
        if end_date:
            query = query.where(AuditLog.created_at <= end_date)
        
        # Count
        count_query = select(func.count()).select_from(query.subquery())
        total = await self.db.scalar(count_query) or 0
        
        # Order and paginate
        query = query.order_by(AuditLog.created_at.desc())
        offset = (page - 1) * page_size
        query = query.offset(offset).limit(page_size)
        
        result = await self.db.execute(query)
        logs = list(result.scalars().all())
        
        return logs, total
    
    async def get_log_by_id(self, log_id: str) -> Optional[AuditLog]:
        """Get a single audit log entry."""
        result = await self.db.execute(
            select(AuditLog).where(AuditLog.id == uuid.UUID(log_id))
        )
        return result.scalar_one_or_none()
    
    async def get_user_action_history(self, user_id: int, limit: int = 50) -> List[AuditLog]:
        """Get all admin actions performed on a specific user."""
        result = await self.db.execute(
            select(AuditLog)
            .where(
                and_(
                    AuditLog.resource_type == "user",
                    AuditLog.resource_id == str(user_id)
                )
            )
            .order_by(AuditLog.created_at.desc())
            .limit(limit)
        )
        return list(result.scalars().all())
