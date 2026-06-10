"""User management API endpoints for admin panel."""
from __future__ import annotations
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Request, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func

from app.core.database import get_db
from apps.admin.models import AdminUser
from apps.admin.api.deps import get_current_admin, require_role, get_client_ip
from apps.admin.services import AdminUserService, AuditService
from apps.admin.models.audit_log import AuditAction
from apps.admin.schemas.users import (
    UserListRequest, UserListResponse, UserSummary,
    UserProfileResponse, UserProfile,
    UserUpdateRequest, UserActionResponse,
    UserNoteRequest, UserNoteResponse, UserNotesListResponse,
    UserFlagRequest,
    UserLearningInsightsResponse,
    UserActivityResponse, UserActivityStats
)
from app.models import TokenUsageDaily

router = APIRouter(prefix="/users", tags=["Admin - Users"])


# ==========================================
# USER LISTING & SEARCH
# ==========================================

@router.get("", response_model=UserListResponse)
async def list_users(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    search: str = Query(None),
    status: str = Query(None),
    onboarding_completed: bool = Query(None),
    clb_level: str = Query(None),
    created_after: datetime = Query(None),
    created_before: datetime = Query(None),
    sort_by: str = Query("created_timestamp"),
    sort_order: str = Query("desc"),
    admin: AdminUser = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """
    List and search users.
    Supports filtering, sorting, and pagination.
    """
    service = AdminUserService(db)
    
    users, total = await service.list_users(
        page=page,
        page_size=page_size,
        search=search,
        status=status,
        onboarding_completed=onboarding_completed,
        clb_level=clb_level,
        created_after=created_after,
        created_before=created_before,
        sort_by=sort_by,
        sort_order=sort_order,
    )

    user_ids = [u.id for u in users]
    usage_map: dict[int, dict[str, int]] = {}
    cost_map: dict[int, int] = {}
    if user_ids:
        usage_rows = await db.execute(
            select(
                TokenUsageDaily.user_id,
                TokenUsageDaily.source,
                func.sum(TokenUsageDaily.total_tokens).label("total_tokens"),
                func.sum(TokenUsageDaily.cost_cents).label("total_cost_cents"),
            )
            .where(TokenUsageDaily.user_id.in_(user_ids))
            .group_by(TokenUsageDaily.user_id, TokenUsageDaily.source)
        )
        for row in usage_rows.all():
            usage_map.setdefault(row.user_id, {})[row.source] = int(row.total_tokens or 0)
            cost_map[row.user_id] = cost_map.get(row.user_id, 0) + int(row.total_cost_cents or 0)
    
    user_summaries = [
        UserSummary(
            id=u.id,
            email=u.email,
            full_name=u.full_name,
            is_active=u.is_active,
            is_deleted=u.is_deleted,
            # Map from UserPreferences
            onboarding_completed=bool(u.preferences.onboarding_completed) if u.preferences else False,
            initial_clb_level=str(u.preferences.language_level) if u.preferences else None,
            created_at=u.created_timestamp,
            updated_at=u.updated_timestamp,
            token_usage=usage_map.get(u.id, {}),
            token_cost_cents=cost_map.get(u.id, 0),
        )
        for u in users
    ]
    
    total_pages = (total + page_size - 1) // page_size
    
    return UserListResponse(
        users=user_summaries,
        total=total,
        page=page,
        page_size=page_size,
        total_pages=total_pages,
    )


@router.get("/{user_id}", response_model=UserProfileResponse)
async def get_user_profile(
    user_id: int,
    request: Request,
    admin: AdminUser = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """Get detailed user profile."""
    service = AdminUserService(db)
    user = await service.get_user_by_id(user_id)
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Log view action
    audit = AuditService(db)
    await audit.log_action(
        admin_id=str(admin.id),
        admin_email=admin.email,
        action=AuditAction.USER_VIEW.value,
        resource_type="user",
        resource_id=str(user_id),
        ip_address=get_client_ip(request),
        success=True
    )
    
    return UserProfileResponse(
        user=UserProfile(
            id=user.id,
            email=user.email,
            full_name=user.full_name,
            avatar_url=user.avatar_url,
            # Map from UserPreferences
            age=user.preferences.age if user.preferences else None,
            nationality=user.preferences.nationality if user.preferences else None,
            profession=user.preferences.profession if user.preferences else None,
            # Map from TopicCategory relationship - use id as the interest key
            interests=[t.id for t in user.topics] if user.topics else [],
            # Map from LearningGoal relationship - use key if available, else first goal's key
            learning_goal=user.learning_goals[0].key if user.learning_goals else None,
            is_active=user.is_active,
            is_deleted=user.is_deleted,
            # Map from UserPreferences
            onboarding_completed=bool(user.preferences.onboarding_completed) if user.preferences else False,
            initial_clb_level=str(user.preferences.language_level) if user.preferences else None,
            created_at=user.created_timestamp,
            updated_at=user.updated_timestamp,
        )
    )


# ==========================================
# USER ACTIONS
# ==========================================

@router.patch("/{user_id}", response_model=UserActionResponse)
async def update_user(
    user_id: int,
    req: UserUpdateRequest,
    request: Request,
    admin: AdminUser = Depends(require_role("super_admin", "admin", "moderator")),
    db: AsyncSession = Depends(get_db),
):
    """Update user profile (admin-allowed fields only)."""
    service = AdminUserService(db)
    
    # Get old state for audit
    old_user = await service.get_user_by_id(user_id)
    if not old_user:
        raise HTTPException(status_code=404, detail="User not found")
    
    old_state = {"full_name": old_user.full_name, "is_active": old_user.is_active}
    
    # Update
    updates = req.model_dump(exclude_unset=True)
    user = await service.update_user(user_id, updates)
    
    new_state = {"full_name": user.full_name, "is_active": user.is_active}
    
    # Log action
    audit = AuditService(db)
    await audit.log_action(
        admin_id=str(admin.id),
        admin_email=admin.email,
        action=AuditAction.USER_UPDATE.value,
        resource_type="user",
        resource_id=str(user_id),
        old_value=old_state,
        new_value=new_state,
        ip_address=get_client_ip(request),
        success=True
    )
    
    return UserActionResponse(message="User updated successfully", user_id=user_id)


@router.post("/{user_id}/lock", response_model=UserActionResponse)
async def lock_user(
    user_id: int,
    request: Request,
    admin: AdminUser = Depends(require_role("super_admin", "admin", "moderator")),
    db: AsyncSession = Depends(get_db),
):
    """Lock/suspend a user account."""
    service = AdminUserService(db)
    
    user = await service.get_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    await service.lock_user(user_id)
    
    audit = AuditService(db)
    await audit.log_action(
        admin_id=str(admin.id),
        admin_email=admin.email,
        action=AuditAction.USER_LOCK.value,
        resource_type="user",
        resource_id=str(user_id),
        description="User account locked",
        ip_address=get_client_ip(request),
        success=True
    )
    
    return UserActionResponse(message="User locked successfully", user_id=user_id)


@router.post("/{user_id}/unlock", response_model=UserActionResponse)
async def unlock_user(
    user_id: int,
    request: Request,
    admin: AdminUser = Depends(require_role("super_admin", "admin", "moderator")),
    db: AsyncSession = Depends(get_db),
):
    """Reactivate a locked user account."""
    service = AdminUserService(db)
    
    user = await service.get_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    await service.unlock_user(user_id)
    
    audit = AuditService(db)
    await audit.log_action(
        admin_id=str(admin.id),
        admin_email=admin.email,
        action=AuditAction.USER_UNLOCK.value,
        resource_type="user",
        resource_id=str(user_id),
        description="User account unlocked",
        ip_address=get_client_ip(request),
        success=True
    )
    
    return UserActionResponse(message="User unlocked successfully", user_id=user_id)


@router.post("/{user_id}/force-logout", response_model=UserActionResponse)
async def force_logout_user(
    user_id: int,
    request: Request,
    admin: AdminUser = Depends(require_role("super_admin", "admin")),
    db: AsyncSession = Depends(get_db),
):
    """Force logout user from all devices."""
    service = AdminUserService(db)
    
    user = await service.get_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    sessions_revoked = await service.force_logout_user(user_id)
    
    audit = AuditService(db)
    await audit.log_action(
        admin_id=str(admin.id),
        admin_email=admin.email,
        action=AuditAction.USER_FORCE_LOGOUT.value,
        resource_type="user",
        resource_id=str(user_id),
        description=f"Force logout - {sessions_revoked} sessions revoked",
        action_metadata={"sessions_revoked": sessions_revoked},
        ip_address=get_client_ip(request),
        success=True
    )
    
    return UserActionResponse(
        message=f"User logged out from {sessions_revoked} devices",
        user_id=user_id
    )


@router.delete("/{user_id}", response_model=UserActionResponse)
async def soft_delete_user(
    user_id: int,
    request: Request,
    admin: AdminUser = Depends(require_role("super_admin", "admin")),
    db: AsyncSession = Depends(get_db),
):
    """Soft delete a user account."""
    service = AdminUserService(db)
    
    user = await service.get_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    await service.soft_delete_user(user_id)
    
    audit = AuditService(db)
    await audit.log_action(
        admin_id=str(admin.id),
        admin_email=admin.email,
        action=AuditAction.USER_DELETE_SOFT.value,
        resource_type="user",
        resource_id=str(user_id),
        description="User soft deleted",
        ip_address=get_client_ip(request),
        success=True
    )
    
    return UserActionResponse(message="User deleted successfully", user_id=user_id)


@router.post("/{user_id}/flag", response_model=UserActionResponse)
async def flag_user(
    user_id: int,
    req: UserFlagRequest,
    request: Request,
    admin: AdminUser = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """Flag a user for review."""
    service = AdminUserService(db)
    
    user = await service.get_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Add a note with category "review"
    await service.add_note(
        user_id=user_id,
        admin_id=str(admin.id),
        admin_email=admin.email,
        content=f"[FLAGGED] {req.reason}",
        category="warning",
        is_pinned=True
    )
    
    audit = AuditService(db)
    await audit.log_action(
        admin_id=str(admin.id),
        admin_email=admin.email,
        action=AuditAction.USER_FLAG.value,
        resource_type="user",
        resource_id=str(user_id),
        description="User flagged for review",
        action_metadata={"reason": req.reason},
        ip_address=get_client_ip(request),
        success=True
    )
    
    return UserActionResponse(message="User flagged for review", user_id=user_id)


# ==========================================
# ADMIN NOTES
# ==========================================

@router.get("/{user_id}/notes", response_model=UserNotesListResponse)
async def get_user_notes(
    user_id: int,
    admin: AdminUser = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """Get all admin notes for a user."""
    service = AdminUserService(db)
    
    user = await service.get_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    notes = await service.get_notes_for_user(user_id)
    
    return UserNotesListResponse(
        notes=[
            UserNoteResponse(
                id=str(n.id),
                user_id=n.user_id,
                admin_email=n.admin_email,
                content=n.content,
                category=n.category,
                is_pinned=n.is_pinned,
                is_resolved=n.is_resolved,
                created_at=n.created_at,
            )
            for n in notes
        ]
    )


@router.post("/{user_id}/notes", response_model=UserNoteResponse)
async def add_user_note(
    user_id: int,
    req: UserNoteRequest,
    request: Request,
    admin: AdminUser = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """Add an admin note about a user."""
    service = AdminUserService(db)
    
    user = await service.get_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    note = await service.add_note(
        user_id=user_id,
        admin_id=str(admin.id),
        admin_email=admin.email,
        content=req.content,
        category=req.category,
        is_pinned=req.is_pinned,
    )
    
    audit = AuditService(db)
    await audit.log_action(
        admin_id=str(admin.id),
        admin_email=admin.email,
        action=AuditAction.USER_NOTE_ADD.value,
        resource_type="user",
        resource_id=str(user_id),
        description="Admin note added",
        ip_address=get_client_ip(request),
        success=True
    )
    
    return UserNoteResponse(
        id=str(note.id),
        user_id=note.user_id,
        admin_email=note.admin_email,
        content=note.content,
        category=note.category,
        is_pinned=note.is_pinned,
        is_resolved=note.is_resolved,
        created_at=note.created_at,
    )


# ==========================================
# USER INSIGHTS & STATS
# ==========================================

@router.get("/{user_id}/activity", response_model=UserActivityResponse)
async def get_user_activity(
    user_id: int,
    admin: AdminUser = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """Get user activity statistics."""
    service = AdminUserService(db)
    
    user = await service.get_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    stats = await service.get_user_activity_stats(user_id)
    
    return UserActivityResponse(
        stats=UserActivityStats(**stats)
    )


@router.get("/{user_id}/learning-insights", response_model=UserLearningInsightsResponse)
async def get_user_learning_insights(
    user_id: int,
    admin: AdminUser = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """
    Get aggregated learning insights for a user.
    NOTE: Only aggregated data is returned, not raw user content for privacy.
    """
    service = AdminUserService(db)
    
    user = await service.get_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    insights = await service.get_user_learning_insights(user_id)
    
    if not insights:
        return UserLearningInsightsResponse(
            user_id=user_id,
            estimated_clb_level=None,
        )
    
    return UserLearningInsightsResponse(**insights)
