import hashlib
import httpx
import json
import secrets
import uuid
import jwt
import logging
from jwt import algorithms
import datetime as dt
from sqlalchemy import select, update, insert
from sqlalchemy.ext.asyncio import AsyncSession
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives import serialization

from app.core.config import settings
from app.core.security import (
    hash_password, verify_password,
    make_access_jwt, new_refresh_token, hash_refresh
)
from app.core.email.brevo import send_reset_code_email, send_signup_token_email
from app.models import User, PreAuthToken, SessionToken, PasswordResetCode, PasswordResetToken, SignupTokens

UTC = dt.timezone.utc

logger = logging.getLogger(__name__)


def _hash_code(code: str, email_l: str) -> str:
    return hashlib.sha256(f"{email_l}:{code}".encode("utf-8")).hexdigest()


def _new_5digit_code() -> str:
    return f"{secrets.randbelow(100000):05d}"


def _now():
    return dt.datetime.now(UTC)


async def create_pre_auth(db: AsyncSession, device_nonce: str | None) -> str:
    q = insert(PreAuthToken).values(device_nonce=device_nonce).returning(PreAuthToken.id)
    res = await db.execute(q)
    token_id = res.scalar_one()
    await db.commit()
    return str(token_id)


async def _consume_pre_auth(db: AsyncSession, token_id: str) -> None:
    q = select(PreAuthToken).where(PreAuthToken.id == uuid.UUID(token_id))
    res = await db.execute(q)
    tok = res.scalar_one_or_none()
    if not tok:
        raise ValueError("invalid_pre_auth")
    if tok.used_at is not None:
        raise ValueError("used_pre_auth")
    age_min = (_now() - tok.created_at).total_seconds() / 60.0
    if age_min > settings.PRE_AUTH_TTL_MIN:
        raise ValueError("expired_pre_auth")
    await db.execute(
        update(PreAuthToken).where(PreAuthToken.id == tok.id).values(used_at=_now())
    )
    await db.commit()


async def _consume_verify_token(db: AsyncSession, token_id: str) -> None:
    q = select(PasswordResetToken).where(PasswordResetToken.id == uuid.UUID(token_id))
    res = await db.execute(q)
    tok = res.scalar_one_or_none()
    if not tok:
        raise ValueError("invalid_verify_token")
    if tok.used_at is not None:
        raise ValueError("used_verify_token")
    age_min = (_now() - tok.created_at).total_seconds() / 60.0
    if age_min > settings.VERIFY_TOKEN_TTL_MIN:
        raise ValueError("expired_verify_token")
    await db.execute(
        update(PasswordResetToken).where(PasswordResetToken.id == tok.id).values(used_at=_now())
    )
    await db.commit()


async def _consume_activation_token(db: AsyncSession, token_id: str) -> int:
    q = select(SignupTokens).where(SignupTokens.id == uuid.UUID(token_id))
    res = await db.execute(q)
    tok = res.scalar_one_or_none()
    if not tok:
        raise ValueError("invalid_activation_token")
    if tok.used_at is not None:
        raise ValueError("used_activation_token")
    age_min = (_now() - tok.created_at).total_seconds() / 60.0
    if age_min > settings.SIGNUP_TOKEN_TTL_MIN:
        raise ValueError("expired_activation_token")
    await db.execute(
        update(SignupTokens).where(SignupTokens.id == tok.id).values(used_at=_now())
    )
    await db.commit()

    return tok.user_id


async def _get_user_by_email(db: AsyncSession, email: str) -> User | None:
    q = select(User).where(User.email == email.lower())
    res = await db.execute(q)
    return res.scalar_one_or_none()


async def _issue_session(db: AsyncSession, user_id: int) -> tuple[str, str]:
    access = make_access_jwt(str(user_id))
    refresh_plain = new_refresh_token()
    refresh_h = hash_refresh(refresh_plain)
    expires = _now() + dt.timedelta(days=settings.REFRESH_TTL_DAYS)

    q = insert(SessionToken).values(
        user_id=user_id,
        refresh_hash=refresh_h,
        expires_at=expires
    )
    await db.execute(q)
    await db.commit()
    return access, refresh_plain


async def signup(db: AsyncSession, email: str, password: str, pre_auth: str) -> tuple[str, str]:
    await _consume_pre_auth(db, pre_auth)
    email_l = email.lower()

    existing = await _get_user_by_email(db, email_l)
    if existing:
        raise ValueError("email_exists")

    pw_hash = hash_password(password)
    q = insert(User).values(email=email_l, password=pw_hash, is_active=False).returning(User.id, User.email)
    res = await db.execute(q)
    user_id, user_email = res.one()
    await db.commit()

    q = insert(SignupTokens).values(user_id=user_id).returning(SignupTokens.id)
    signup_token = await db.execute(q)
    await db.commit()

    send_signup_token_email(user_email, str(signup_token.scalar_one()))


async def signin(db: AsyncSession, email: str, password: str, pre_auth: str) -> tuple[str, str]:
    await _consume_pre_auth(db, pre_auth)
    email_l = email.lower()

    u = await _get_user_by_email(db, email_l)
    if not u or not verify_password(password, u.password):
        raise ValueError("invalid_credentials")
    
    if not u.is_active:
        raise ValueError("inactive_account")

    return await _issue_session(db, u.id)


async def active_user(db: AsyncSession, activation_token: str) -> tuple[str, str]:
    user_id = await _consume_activation_token(db, activation_token)

    await db.execute(
        update(User)
        .where(User.id == user_id)
        .values(is_active=True)
    )
    await db.commit()

    return await _issue_session(db, user_id)


async def refresh(db: AsyncSession, refresh_plain: str) -> tuple[str, str]:
    h = hash_refresh(refresh_plain)
    q = select(SessionToken).where(SessionToken.refresh_hash == h)
    res = await db.execute(q)
    cur = res.scalar_one_or_none()
    if not cur or cur.revoked_at is not None or cur.expires_at <= _now():
        raise ValueError("invalid_refresh")

    # rotate
    new_access = make_access_jwt(str(cur.user_id))
    new_plain = new_refresh_token()
    new_hash = hash_refresh(new_plain)
    new_exp = _now() + dt.timedelta(days=settings.REFRESH_TTL_DAYS)

    # create new, revoke old
    ins = insert(SessionToken).values(
        user_id=cur.user_id, refresh_hash=new_hash, expires_at=new_exp
    ).returning(SessionToken.id)
    r2 = await db.execute(ins)
    new_id = r2.scalar_one()

    await db.execute(
        update(SessionToken)
        .where(SessionToken.id == cur.id)
        .values(revoked_at=_now(), replaced_by=new_id)
    )
    await db.commit()
    return new_access, new_plain


async def logout(db: AsyncSession, refresh_plain: str) -> None:
    h = hash_refresh(refresh_plain)
    q = select(SessionToken).where(SessionToken.refresh_hash == h)
    res = await db.execute(q)
    cur = res.scalar_one_or_none()
    if not cur:
        return
    await db.execute(
        update(SessionToken).where(SessionToken.id == cur.id).values(revoked_at=_now())
    )
    await db.commit()


async def forgot_password_send_code(db: AsyncSession, email: str) -> None:
    email_l = (email or "").lower().strip()
    res = await db.execute(select(User).where(User.email == email_l))
    user = res.scalar_one_or_none()

    if not user or user.is_deleted:
        return

    await db.execute(
        update(PasswordResetCode)
        .where(PasswordResetCode.user_id == user.id, PasswordResetCode.used_at.is_(None))
        .values(used_at=_now())
    )

    code = _new_5digit_code()
    code_h = _hash_code(code, email_l)

    await db.execute(
        update(PasswordResetCode)
        .where(PasswordResetCode.user_id == user.id)
        .values(used_at=_now())
    )
    await db.execute(insert(PasswordResetCode).values(user_id=user.id, code_hash=code_h))
    await db.commit()

    send_reset_code_email(user.email, code)


async def resend_activation(db: AsyncSession, email: str) -> None:
    email_l = (email or "").lower().strip()
    user = await _get_user_by_email(db, email_l)

    # Silently return if user doesn't exist or is already active
    if not user or user.is_active:
        return

    # Invalidate existing signup tokens for this user
    await db.execute(
        update(SignupTokens)
        .where(SignupTokens.user_id == user.id, SignupTokens.used_at.is_(None))
        .values(used_at=_now())
    )

    # Create new signup token
    q = insert(SignupTokens).values(user_id=user.id).returning(SignupTokens.id)
    result = await db.execute(q)
    await db.commit()

    # Send activation email
    send_signup_token_email(user.email, str(result.scalar_one()))


async def verify_reset_password_token(db: AsyncSession, email: str, code: str) -> str:
    email_l = (email or "").lower().strip()
    res = await db.execute(select(User).where(User.email == email_l))
    user = res.scalar_one_or_none()
    if not user or user.is_deleted:
        raise ValueError("invalid_token")

    q = select(PasswordResetCode).where(
        PasswordResetCode.user_id == user.id,
        PasswordResetCode.used_at.is_(None),
    ).order_by(PasswordResetCode.created_at.desc())
    r = await db.execute(q)
    prc = r.scalars().first()
    if not prc:
        raise ValueError("invalid_token")

    age_min = (_now() - prc.created_at).total_seconds() / 60.0
    if age_min > settings.RESET_TTL_MIN:
        raise ValueError("expired_token")

    code = (code or "").strip()
    if len(code) != 5 or not code.isdigit():
        raise ValueError("invalid_token")

    if _hash_code(code, email_l) != prc.code_hash:
        raise ValueError("invalid_token")

    await db.execute(
        update(PasswordResetCode)
        .where(PasswordResetCode.id == prc.id)
        .values(used_at=_now())
    )
    await db.execute(
        update(PasswordResetToken)
        .where(PasswordResetToken.user_id == user.id)
        .values(used_at=_now())
    )
    q = insert(PasswordResetToken).values(user_id=user.id).returning(PasswordResetToken.id)
    res = await db.execute(q)
    await db.commit()

    try:
        import logging
        uid_h = hashlib.sha256(str(user.id).encode("utf-8")).hexdigest()[:12]
        logging.getLogger("security").info("verify_reset_password_token user=%s", uid_h)
    except Exception:
        pass

    return str(res.scalar_one())


async def reset_password_with_code(db: AsyncSession, email: str, new_password: str, verify_token: str) -> tuple[
    str | None, str | None]:
    await _consume_verify_token(db, verify_token)
    email_l = (email or "").lower().strip()
    res = await db.execute(select(User).where(User.email == email_l))
    user = res.scalar_one_or_none()
    if not user or user.is_deleted:
        raise ValueError("invalid_token")

    new_hash = hash_password(new_password)
    was_active = user.is_active
    await db.execute(
        update(User)
        .where(User.id == user.id)
        .values(password=new_hash, updated_timestamp=_now())
    )
    await db.commit()

    try:
        import logging
        uid_h = hashlib.sha256(str(user.id).encode("utf-8")).hexdigest()[:12]
        logging.getLogger("security").info("password_reset_code user=%s", uid_h)
    except Exception:
        pass
    if was_active:
        return await _issue_session(db, user.id)

    return None, None


async def google_signin(db: AsyncSession, id_token_str: str) -> tuple[str, str]:
    try:
        from google.oauth2 import id_token
        from google.auth.transport import requests as g_requests

        req = g_requests.Request()
        payload = id_token.verify_oauth2_token(id_token_str, req, settings.GOOGLE_OAUTH_CLIENT_ID)
    except Exception:
        raise ValueError("invalid_google_token")

    aud = str(payload.get("aud") or "")
    if aud != settings.GOOGLE_OAUTH_CLIENT_ID:
        raise ValueError("aud_mismatch")

    iss = str(payload.get("iss") or "")
    if iss not in {"accounts.google.com", "https://accounts.google.com"}:
        raise ValueError("invalid_google_token")

    email = (payload.get("email") or "").strip().lower()
    if not email:
        raise ValueError("invalid_google_token")

    if not payload.get("email_verified", False):
        raise ValueError("email_not_verified")

    q = select(User).where(User.email == email)
    res = await db.execute(q)
    u = res.scalar_one_or_none()

    if not u:
        random_pw = secrets.token_urlsafe(32)
        pw_hash = hash_password(random_pw)
        full_name = (payload.get("name") or "").strip() or None

        ins = insert(User).values(
            email=email,
            password=pw_hash,
            is_active=True,
            is_deleted=False,
            full_name=full_name,
        ).returning(User.id)
        r = await db.execute(ins)
        user_id = int(r.scalar_one())
        await db.commit()
    else:
        user_id = u.id

    try:
        await db.execute(
            update(User).where(User.id == user_id).values(updated_timestamp=_now())
        )
        await db.commit()
    except Exception:
        pass

    return await _issue_session(db, user_id)


async def apple_signin(db: AsyncSession, identity_token: str) -> tuple[str, str]:
    """
    Verify Apple identity_token, create or sign-in the user, and return (access, refresh).
    """
    try:
        async with httpx.AsyncClient() as client:
            r = await client.get("https://appleid.apple.com/auth/keys", timeout=5)
            r.raise_for_status()
            apple_keys = r.json().get("keys", [])
    except httpx.HTTPError as exc:
        logger.exception("Error fetching Apple public keys")
        raise ValueError("invalid_apple_token") from exc

    try:
        headers = jwt.get_unverified_header(identity_token)
    except jwt.DecodeError as exc:
        logger.exception("Invalid Apple identity token header")
        raise ValueError("invalid_apple_token") from exc

    kid = headers.get("kid")
    alg = headers.get("alg")
    if not kid or not alg:
        logger.error("Apple identity token missing kid or alg: kid=%s alg=%s", kid, alg)
        raise ValueError("invalid_apple_token_missing_kid_alg")

    key = next((k for k in apple_keys if k.get("kid") == kid), None)
    if not key:
        logger.error("Apple public key not found for kid=%s", kid)
        raise ValueError("invalid_apple_token_no_pubkey_match")

    try:
        public_key = algorithms.RSAAlgorithm.from_jwk(json.dumps(key))
    except (jwt.InvalidKeyError, ValueError) as exc:
        logger.exception("Failed to build RSA public key for kid=%s", kid)
        raise ValueError("invalid_apple_token_bad_pubkey") from exc

    try:
        payload = jwt.decode(
            identity_token,
            public_key,
            algorithms=[alg],
            audience=settings.APPLE_CLIENT_ID,
            issuer="https://appleid.apple.com",
        )
    except jwt.ExpiredSignatureError as exc:
        logger.warning("Apple identity token expired for kid=%s", kid)
        raise ValueError("invalid_apple_token: expired") from exc
    except jwt.InvalidAudienceError as exc:
        logger.warning("Apple identity token audience mismatch for kid=%s", kid)
        raise ValueError("invalid_apple_token: aud_mismatch") from exc
    except jwt.InvalidIssuerError as exc:
        logger.warning("Apple identity token issuer mismatch for kid=%s", kid)
        raise ValueError("invalid_apple_token: iss_mismatch") from exc
    except jwt.InvalidTokenError as exc:
        logger.exception("JWT decode failed for kid=%s", kid)
        raise ValueError(f"invalid_apple_token: {exc}") from exc

    # Extract claims
    email = (payload.get("email") or "").lower()
    sub = payload.get("sub")
    email_verified = str(payload.get("email_verified", "false")).lower() == "true"

    if not email:
        # Apple might not always include email if user already granted before
        # in that case we must rely on sub (unique Apple user ID)
        email = f"{sub}@apple.anonymous"

    # Find or create user
    q = select(User).where(User.email == email)
    res = await db.execute(q)
    u = res.scalar_one_or_none()

    if not u:
        random_pw = secrets.token_urlsafe(32)
        pw_hash = hash_password(random_pw)
        full_name = None
        ins = insert(User).values(
            email=email,
            password=pw_hash,
            is_active=True,
            is_deleted=False,
            full_name=full_name,
        ).returning(User.id)
        r = await db.execute(ins)
        user_id = int(r.scalar_one())
        await db.commit()
    else:
        user_id = u.id

    try:
        await db.execute(
            update(User).where(User.id == user_id).values(updated_timestamp=_now())
        )
        await db.commit()
    except Exception:
        pass

    return await _issue_session(db, user_id)
