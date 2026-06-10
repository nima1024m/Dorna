"""User management service for admin panel."""
from __future__ import annotations
from typing import Optional, List, Tuple
from datetime import datetime, timezone
import hashlib

from sqlalchemy import select, update, func, or_, and_, delete, String
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import joinedload, selectinload

from app.models import User, SessionToken, GrammarSuggestion, TranslateTexts, ToneAdjustments
from app.models import UserLearningInsights
from app.models.user_preferences import UserPreferences
from apps.admin.models import AdminNote, AuditLog
from apps.admin.models.audit_log import AuditAction


class AdminUserService:
    """Service for admin user management operations."""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    # ==========================================
    # USER LISTING & SEARCH
    # ==========================================
    
    async def list_users(
        self,
        page: int = 1,
        page_size: int = 20,
        search: Optional[str] = None,
        status: Optional[str] = None,
        onboarding_completed: Optional[bool] = None,
        clb_level: Optional[str] = None,
        created_after: Optional[datetime] = None,
        created_before: Optional[datetime] = None,
        sort_by: str = "created_timestamp",
        sort_order: str = "desc",
    ) -> Tuple[List[User], int]:
        """List users with filtering and pagination."""
        
        # Base query with eager loading of preferences
        query = select(User).options(joinedload(User.preferences))
        
        # Track if we need to join preferences for filtering
        needs_pref_join = onboarding_completed is not None or clb_level is not None
        if needs_pref_join:
            query = query.outerjoin(UserPreferences, User.id == UserPreferences.user_id)
        
        # Search filter
        if search:
            search_pattern = f"%{search}%"
            query = query.where(
                or_(
                    User.email.ilike(search_pattern),
                    User.full_name.ilike(search_pattern),
                    func.cast(User.id, String).like(search_pattern)
                )
            )
        
        # Status filter
        if status == "active":
            query = query.where(and_(User.is_active == True, User.is_deleted == False))
        elif status == "inactive":
            query = query.where(User.is_active == False)
        elif status == "deleted":
            query = query.where(User.is_deleted == True)
        
        # Onboarding filter - now uses UserPreferences
        if onboarding_completed is not None:
            query = query.where(UserPreferences.onboarding_completed == onboarding_completed)
        
        # CLB level filter - convert string to int for language_level
        if clb_level:
            try:
                level_int = int(clb_level)
                query = query.where(UserPreferences.language_level == level_int)
            except ValueError:
                pass  # Ignore invalid clb_level values
        
        # Date filters
        if created_after:
            query = query.where(User.created_timestamp >= created_after)
        if created_before:
            query = query.where(User.created_timestamp <= created_before)
        
        # Get total count
        count_query = select(func.count()).select_from(query.subquery())
        total = await self.db.scalar(count_query) or 0
        
        # Sorting
        sort_column = getattr(User, sort_by, User.created_timestamp)
        if sort_order == "asc":
            query = query.order_by(sort_column.asc())
        else:
            query = query.order_by(sort_column.desc())
        
        # Pagination
        offset = (page - 1) * page_size
        query = query.offset(offset).limit(page_size)
        
        result = await self.db.execute(query)
        users = list(result.scalars().all())
        
        return users, total
    
    async def get_user_by_id(self, user_id: int) -> Optional[User]:
        """Get a single user by ID with all profile-related relationships loaded."""
        result = await self.db.execute(
            select(User)
            .options(
                joinedload(User.preferences),
                selectinload(User.topics),
                selectinload(User.learning_goals),
            )
            .where(User.id == user_id)
        )
        return result.unique().scalar_one_or_none()
    
    # ==========================================
    # USER ACTIONS
    # ==========================================
    
    async def update_user(self, user_id: int, updates: dict) -> Optional[User]:
        """Update user fields (admin-allowed only)."""
        allowed_fields = {"full_name", "is_active"}
        safe_updates = {k: v for k, v in updates.items() if k in allowed_fields and v is not None}
        
        if not safe_updates:
            return await self.get_user_by_id(user_id)
        
        safe_updates["updated_timestamp"] = func.now()
        
        await self.db.execute(
            update(User).where(User.id == user_id).values(**safe_updates)
        )
        await self.db.commit()
        
        return await self.get_user_by_id(user_id)
    
    async def lock_user(self, user_id: int) -> bool:
        """Lock/suspend a user account."""
        await self.db.execute(
            update(User)
            .where(User.id == user_id)
            .values(is_active=False, updated_timestamp=func.now())
        )
        await self.db.commit()
        return True
    
    async def unlock_user(self, user_id: int) -> bool:
        """Reactivate a user account."""
        await self.db.execute(
            update(User)
            .where(User.id == user_id)
            .values(is_active=True, updated_timestamp=func.now())
        )
        await self.db.commit()
        return True
    
    async def soft_delete_user(self, user_id: int) -> bool:
        """Soft delete a user (mark as deleted)."""
        await self.db.execute(
            update(User)
            .where(User.id == user_id)
            .values(is_deleted=True, is_active=False, updated_timestamp=func.now())
        )
        await self.db.commit()
        return True
    
    async def force_logout_user(self, user_id: int) -> int:
        """Revoke all sessions for a user."""
        result = await self.db.execute(
            update(SessionToken)
            .where(
                and_(
                    SessionToken.user_id == user_id,
                    SessionToken.revoked_at.is_(None)
                )
            )
            .values(revoked_at=func.now())
        )
        await self.db.commit()
        return result.rowcount
    
    # ==========================================
    # ADMIN NOTES
    # ==========================================
    
    async def add_note(
        self,
        user_id: int,
        admin_id: str,
        admin_email: str,
        content: str,
        category: Optional[str] = None,
        is_pinned: bool = False
    ) -> AdminNote:
        """Add an internal admin note about a user."""
        note = AdminNote(
            user_id=user_id,
            admin_id=admin_id,
            admin_email=admin_email,
            content=content,
            category=category,
            is_pinned=is_pinned
        )
        self.db.add(note)
        await self.db.commit()
        await self.db.refresh(note)
        return note
    
    async def get_notes_for_user(self, user_id: int) -> List[AdminNote]:
        """Get all admin notes for a user."""
        result = await self.db.execute(
            select(AdminNote)
            .where(AdminNote.user_id == user_id)
            .order_by(AdminNote.is_pinned.desc(), AdminNote.created_at.desc())
        )
        return list(result.scalars().all())
    
    async def resolve_note(self, note_id: str, admin_id: str) -> bool:
        """Mark a note as resolved."""
        await self.db.execute(
            update(AdminNote)
            .where(AdminNote.id == note_id)
            .values(
                is_resolved=True,
                resolved_at=func.now(),
                resolved_by=admin_id
            )
        )
        await self.db.commit()
        return True
    
    # ==========================================
    # USER ACTIVITY STATS
    # ==========================================
    
    async def get_user_activity_stats(self, user_id: int) -> dict:
        """Get usage statistics for a user."""
        
        # Grammar corrections count
        grammar_count = await self.db.scalar(
            select(func.count()).select_from(GrammarSuggestion).where(GrammarSuggestion.user_id == user_id)
        ) or 0
        
        # Translation count
        translate_count = await self.db.scalar(
            select(func.count()).select_from(TranslateTexts).where(TranslateTexts.user_id == user_id)
        ) or 0
        
        # Tone adjustments count (includes polish — stored as target_tone='polish')
        tone_count = await self.db.scalar(
            select(func.count()).select_from(ToneAdjustments).where(ToneAdjustments.user_id == user_id)
        ) or 0
        
        return {
            "user_id": user_id,
            "total_grammar_corrections": grammar_count,
            "total_translations": translate_count,
            "total_tone_adjustments": tone_count,
        }
    
    # ==========================================
    # LEARNING INSIGHTS (AGGREGATED - NO RAW CONTENT)
    # ==========================================
    
    async def get_user_learning_insights(self, user_id: int) -> Optional[dict]:
        """Get aggregated learning insights for a user (no raw content)."""
        result = await self.db.execute(
            select(UserLearningInsights).where(UserLearningInsights.user_id == user_id)
        )
        insights = result.scalar_one_or_none()
        
        if not insights:
            return None
        
        # Return only aggregated data, not raw user content
        return {
            "user_id": user_id,
            "estimated_clb_level": insights.estimated_clb_level,
            "grammar_issues": insights.grammar_issues or {},
            "misspelled_word_count": len(insights.misspelled_words or {}),
            "top_misspelled_categories": [],  # Derived, not raw
            "linguistic_patterns": insights.linguistic_profile or [],
            "learning_path": insights.learning_path or [],
            "overall_summary": insights.overall_summary,
            "last_processed_at": insights.last_processed_at,
        }


# Import for type hints
from sqlalchemy import String
