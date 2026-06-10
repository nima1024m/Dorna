"""Admin API routers."""
from .auth import router as auth_router
from .users import router as users_router
from .topics import router as topics_router
from .analytics import router as analytics_router
from .audit import router as audit_router
