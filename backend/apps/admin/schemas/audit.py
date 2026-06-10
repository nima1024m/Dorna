"""Audit log schemas."""
from __future__ import annotations
from typing import Optional, List
from datetime import datetime
from pydantic import BaseModel, Field


class AuditLogEntry(BaseModel):
    id: str
    admin_email: str
    action: str
    resource_type: str
    resource_id: Optional[str] = None
    description: Optional[str] = None
    ip_address: Optional[str] = None
    success: bool
    created_at: datetime


class AuditLogListRequest(BaseModel):
    page: int = Field(default=1, ge=1)
    page_size: int = Field(default=50, ge=1, le=200)
    
    # Filters
    admin_id: Optional[str] = None
    action: Optional[str] = None
    resource_type: Optional[str] = None
    resource_id: Optional[str] = None
    success: Optional[bool] = None
    
    # Date range
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None


class AuditLogListResponse(BaseModel):
    status: str = "OK"
    logs: List[AuditLogEntry]
    total: int
    page: int
    page_size: int


class AuditLogDetailResponse(BaseModel):
    status: str = "OK"
    log: AuditLogEntry
    old_value: Optional[dict] = None
    new_value: Optional[dict] = None
    metadata: dict = {}
    user_agent: Optional[str] = None
