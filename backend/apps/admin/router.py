"""
Admin Panel Router
==================

Main router that combines all admin API endpoints.
Mount this in main.py at /admin prefix.
"""
from fastapi import APIRouter

from apps.admin.api import (
    auth_router,
    users_router, 
    topics_router,
    analytics_router,
    audit_router,
)

admin_router = APIRouter()

# Include all admin routers
admin_router.include_router(auth_router)
admin_router.include_router(users_router)
admin_router.include_router(topics_router)
admin_router.include_router(analytics_router)
admin_router.include_router(audit_router)
