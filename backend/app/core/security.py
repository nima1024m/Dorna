import time
import uuid
import hashlib
import jwt
from argon2 import PasswordHasher
from argon2.low_level import Type
from app.core.config import settings

_pwd = PasswordHasher(time_cost=2, memory_cost=102400, parallelism=8, hash_len=32, type=Type.ID)


def hash_password(pw: str) -> str:
    return _pwd.hash(pw)


def verify_password(pw: str, pw_hash: str) -> bool:
    try:
        return _pwd.verify(pw_hash, pw)
    except Exception:
        return False


def make_access_jwt(user_id: str) -> str:
    now = int(time.time())
    exp = now + settings.ACCESS_TTL_MIN * 60
    payload = {"sub": user_id, "iat": now, "exp": exp, "typ": "access"}
    return jwt.encode(payload, settings.JWT_SECRET, algorithm=settings.JWT_ALGO)


# ============================================================================
# ADMIN PANEL AUTH - Used by apps/admin/ for admin user authentication
# ============================================================================

def create_jwt(subject: str, extra: dict = None, expires_days: int = None) -> str:
    """
    Create a JWT token with optional extra claims.
    Used by admin panel for tokens with role/type metadata.

    Args:
        subject: The subject (user/admin ID)
        extra: Additional claims to include in the token (e.g., {"type": "admin", "role": "super_admin"})
        expires_days: Custom expiry in days (default: ACCESS_TTL_MIN in minutes)
    """
    now = int(time.time())
    if expires_days:
        exp = now + expires_days * 24 * 60 * 60
    else:
        exp = now + settings.ACCESS_TTL_MIN * 60

    payload = {"sub": subject, "iat": now, "exp": exp}
    if extra:
        payload.update(extra)

    return jwt.encode(payload, settings.JWT_SECRET, algorithm=settings.JWT_ALGO)


def parse_jwt(token: str) -> dict:
    return jwt.decode(token, settings.JWT_SECRET, algorithms=[settings.JWT_ALGO])


def new_refresh_token() -> str:
    return str(uuid.uuid4()) + str(uuid.uuid4())


def hash_refresh(tok: str) -> str:
    return hashlib.sha256(tok.encode("utf-8")).hexdigest()
