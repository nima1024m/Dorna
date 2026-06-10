import datetime as dt

import os
import io
import re
import uuid
import hashlib
import logging
import mimetypes
from pathlib import Path
from typing import Tuple

from PIL import Image, ImageOps
from fastapi import UploadFile
from sqlalchemy import select, update, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.security import verify_password, hash_password
from app.worker.user_tasks import delete_user_task, delete_personal_data_task
from app.models import (
    User, SessionToken, UserPreferences,
    TopicCategory, LearningGoal, UserTopicCategory, UserGoal
)
from sqlalchemy import select, update, func, delete, and_

UTC = dt.timezone.utc

PROFILE_DIR = Path("app/files/images/profile")
PROFILE_DIR.mkdir(parents=True, exist_ok=True)

_log = logging.getLogger("profile")

ALLOWED_MIMES = {"image/jpeg", "image/png", "image/webp"}


def _now():
    return dt.datetime.now(UTC)


def _hash_user_id_for_log(uid: int) -> str:
    return hashlib.sha256(str(uid).encode("utf-8")).hexdigest()[:12]


def full_name_valid_chars(s: str) -> bool:
    pattern = r'^[A-Za-z0-9\u0600-\u06FF _-]+$'
    return bool(re.match(pattern, s))


def _max_bytes() -> int:
    return int(settings.AVATAR_MAX_MB) * 1024 * 1024


def _safe_ext_from_mime(mime: str) -> str:
    if mime == "image/jpeg":
        return ".jpg"
    if mime == "image/png":
        return ".png"
    if mime == "image/webp":
        return ".webp"
    return ""


def _optimize_and_resize(img: Image.Image, fmt: str) -> Tuple[bytes, str]:
    img = ImageOps.exif_transpose(img)
    img = img.convert("RGB") if fmt.lower() in {"jpeg", "jpg", "webp"} else img.convert("RGBA")

    # resize
    max_side = 1024
    img.thumbnail((max_side, max_side), Image.LANCZOS)

    # save to bytes
    buf = io.BytesIO()
    save_kwargs = {}
    if fmt.lower() in {"jpeg", "jpg"}:
        fmt = "JPEG"
        save_kwargs.update(dict(quality=85, optimize=True))
    elif fmt.lower() == "png":
        fmt = "PNG"
        save_kwargs.update(dict(optimize=True))
    elif fmt.lower() == "webp":
        fmt = "WEBP"
        save_kwargs.update(dict(quality=85, method=6))
    else:
        fmt = "PNG"  # fallback

    img.save(buf, format=fmt, **save_kwargs)
    return buf.getvalue(), fmt.lower()


def _guess_mime_from_ext(path: Path) -> str:
    lower = path.suffix.lower()
    if lower == ".jpg" or lower == ".jpeg":
        return "image/jpeg"
    if lower == ".png":
        return "image/png"
    if lower == ".webp":
        return "image/webp"
    # fallback
    mt, _ = mimetypes.guess_type(str(path))
    return mt or "application/octet-stream"


async def upload_avatar(
        db: AsyncSession,
        user_id: int,
        file: UploadFile,
) -> (str, str):
    # 1) validation: single file, mime, size
    mime = (file.content_type or "").lower().strip()
    if mime not in ALLOWED_MIMES:
        raise ValueError("invalid_mime")

    data = await file.read()
    size = len(data)
    if size == 0 or size > _max_bytes():
        raise ValueError("invalid_size")

    # 2) verify image with Pillow
    try:
        img = Image.open(io.BytesIO(data))
        img.verify()  # quick check
    except Exception:
        raise ValueError("invalid_image")

    # reopen for processing after verify()
    img = Image.open(io.BytesIO(data))

    # 3) process (strip EXIF, resize, compress)
    ext = _safe_ext_from_mime(mime)
    processed_bytes, final_fmt = _optimize_and_resize(img, ext.lstrip(".") or "png")
    if final_fmt == "jpeg":
        ext = ".jpg"
    elif final_fmt == "png":
        ext = ".png"
    elif final_fmt == "webp":
        ext = ".webp"
    else:
        ext = ".png"

    # 4) filename: user_{id}.ext
    filename = f"user_{user_id}{ext}"
    out_path = PROFILE_DIR / filename

    # 5) delete previous if exists (read from DB)
    res = await db.execute(select(User).where(User.id == user_id))
    user = res.scalar_one_or_none()
    if not user or user.is_deleted or not user.is_active:
        raise ValueError("user_not_active")

    prev_path = (user.avatar_url or "").strip()
    if prev_path:
        try:
            old = Path(PROFILE_DIR / prev_path)
            if old.is_file() and old.exists() and old.resolve() != out_path.resolve():
                old.unlink(missing_ok=True)
        except Exception:
            pass

    # 6) write file (atomic-ish)
    tmp_name = f"{filename}.{uuid.uuid4().hex}.tmp"
    tmp_path = PROFILE_DIR / tmp_name
    with open(tmp_path, "wb") as f:
        f.write(processed_bytes)
    os.replace(tmp_path, out_path)

    # 7) update DB (avatar_url + updated_timestamp)
    await db.execute(
        update(User)
        .where(User.id == user_id)
        .values(avatar_url=filename, updated_timestamp=func.now())
    )
    await db.commit()

    # 8) logging/metrics
    try:
        uid_h = _hash_user_id_for_log(user_id)
        _log.info("avatar_upload user=%s size=%d mime=%s path=%s", uid_h, size, mime, out_path)
    except Exception:
        pass

    return str(out_path), filename


async def delete_avatar(db: AsyncSession, user_id: int) -> None:
    res = await db.execute(select(User).where(User.id == user_id))
    user = res.scalar_one_or_none()
    if not user or user.is_deleted or not user.is_active:
        raise ValueError("user_not_active")

    prev_path = (user.avatar_url or "").strip()
    if prev_path:
        try:
            p = Path(PROFILE_DIR / prev_path)
            if p.is_file() and p.exists():
                p.unlink(missing_ok=True)
        except Exception:
            pass

    await db.execute(
        update(User)
        .where(User.id == user_id)
        .values(avatar_url=None, updated_timestamp=func.now())
    )
    await db.commit()

    try:
        uid_h = _hash_user_id_for_log(user_id)
        _log.info("avatar_delete user=%s prev=%s", uid_h, prev_path)
    except Exception:
        pass



from sqlalchemy.orm import joinedload

async def get_user_profile(db: AsyncSession, user_id: int) -> dict:
    stmt = (
        select(User)
        .where(User.id == user_id)
        .options(
            joinedload(User.preferences),
            joinedload(User.topics),
            joinedload(User.learning_goals),
        )
    )
    result = await db.execute(stmt)
    user = result.unique().scalar_one_or_none()

    if not user:
        return None

    # Default values if prefs don't exist
    prefs = user.preferences
    
    return {
        "id": str(user.id),
        "email": user.email,
        "full_name": user.full_name,
        "avatar_exist": bool(user.avatar_url),
        "age": prefs.age if prefs else None,
        "nationality": prefs.nationality if prefs else None,
        "profession": prefs.profession if prefs else None,
        "interests": [t.id for t in user.topics] if user.topics else [],
        "learning_goal": user.learning_goals[0].key if user.learning_goals else None,
        "onboarding_completed": prefs.onboarding_completed if prefs else False,
        "initial_clb_level": str(prefs.language_level) if prefs and prefs.language_level else None,
    }


async def update_profile(db: AsyncSession, user_id: int, profile_data: dict) -> dict:
    # 1. Get User with all relationships
    stmt = (
        select(User)
        .where(User.id == user_id)
        .options(
            joinedload(User.preferences),
            joinedload(User.topics),
            joinedload(User.learning_goals),
        )
    )
    result = await db.execute(stmt)
    user = result.unique().scalar_one_or_none()
    
    if not user or user.is_deleted:
        raise ValueError("user_not_active")

    # 2. Update User fields (full_name)
    if "full_name" in profile_data:
        new_name = (profile_data["full_name"] or "").strip()
        if len(new_name) < 2 or len(new_name) > 100:
            raise ValueError("invalid_name_length")
        if not full_name_valid_chars(new_name):
            raise ValueError("invalid_name_characters")
        user.full_name = new_name

    # 3. Update/Create UserPreferences
    prefs = user.preferences
    if not prefs:
        prefs = UserPreferences(user_id=user_id, language_level=4) # Default safe level
        db.add(prefs)
        
    if "age" in profile_data:
        prefs.age = profile_data["age"]
    if "nationality" in profile_data:
        prefs.nationality = profile_data["nationality"]
    if "profession" in profile_data:
        prefs.profession = profile_data["profession"]
    if "onboarding_completed" in profile_data:
        prefs.onboarding_completed = profile_data["onboarding_completed"]
    if "initial_clb_level" in profile_data:
        try:
            val = int(profile_data["initial_clb_level"])
            if 4 <= val <= 9:
                prefs.language_level = val
        except (ValueError, TypeError):
            pass

    # 4. Update Interests (Topics)
    if "interests" in profile_data:
        # Clear existing
        user.topics = []
        # Add new
        if profile_data["interests"]:
            # Verify topics exist
            topic_ids = profile_data["interests"]
            topics_res = await db.execute(select(TopicCategory).where(TopicCategory.id.in_(topic_ids)))
            topics = topics_res.scalars().all()
            user.topics = list(topics)

    # 5. Update Learning Goals
    if "learning_goal" in profile_data and profile_data["learning_goal"]:
        # Clear existing
        user.learning_goals = []
        # Add new
        goal_key = profile_data["learning_goal"]
        goal_res = await db.execute(select(LearningGoal).where(LearningGoal.key == goal_key))
        goal = goal_res.scalar_one_or_none()
        if goal:
            user.learning_goals = [goal]

    user.updated_timestamp = func.now()
    await db.commit()
    await db.refresh(user)

    # Return updated profile using the getter to ensure consistent format
    # Note: refresh might not reload all relationships, so we might need to re-fetch if we want to be strictly safe,
    # but for now we construct response manually or re-fetch.
    # Re-fetching is safer for relationships.
    return await get_user_profile(db, user_id)


async def update_full_name(db: AsyncSession, user_id: int, name: str) -> dict:
    new_name = (name or "").strip()
    if len(new_name) < 2 or len(new_name) > 30:
        raise ValueError("invalid_name_length")

    if not full_name_valid_chars(new_name):
        raise ValueError("invalid_name_characters")

    res = await db.execute(select(User).where(User.id == user_id))
    user = res.scalar_one_or_none()
    if not user or user.is_deleted or not user.is_active:
        raise ValueError("user_not_active")

    old = user.full_name or ""

    await db.execute(
        update(User)
        .where(User.id == user_id)
        .values(
            full_name=new_name,
            updated_timestamp=func.now()
        )
    )
    await db.commit()

    try:
        user_hash = _hash_user_id_for_log(user_id)
        import logging
        logging.getLogger("profile").info(
            "profile_name_changed user=%s old='%s' new='%s'",
            user_hash, old, new_name
        )
    except Exception:
        pass

    return {
        "id": str(user.id),
        "email": user.email,
        "full_name": new_name,
    }


async def get_avatar_fileinfo(db: AsyncSession, user_id: int) -> tuple[Path, str]:
    res = await db.execute(select(User).where(User.id == user_id))
    user = res.scalar_one_or_none()
    if not user or user.is_deleted or not user.is_active:
        raise ValueError("user_not_active")

    raw = (user.avatar_url or "").strip()
    if not raw:
        raise FileNotFoundError("no_avatar")

    p = Path(PROFILE_DIR / raw)
    if not p.exists() or not p.is_file():
        raise FileNotFoundError("no_avatar")

    mime = _guess_mime_from_ext(p)
    return p, mime


async def change_password(db: AsyncSession, user_id: int, old_pw: str, new_pw: str) -> None:
    res = await db.execute(select(User).where(User.id == user_id))
    user = res.scalar_one_or_none()
    if not user or user.is_deleted or not user.is_active:
        raise ValueError("user_not_active")

    if not verify_password(old_pw, user.password):
        raise ValueError("invalid_old_password")

    if old_pw == new_pw:
        raise ValueError("same_password")

    # update password
    new_hash = hash_password(new_pw)
    await db.execute(
        update(User)
        .where(User.id == user_id)
        .values(password=new_hash, updated_timestamp=func.now())
    )

    # revoke all refresh tokens for this user (rotation on next login)
    await db.execute(
        update(SessionToken)
        .where(SessionToken.user_id == user_id)
        .values(revoked_at=func.now())
    )

    await db.commit()

    try:
        import logging
        logging.getLogger("security").info("password_changed user=%s", _hash_user_id_for_log(user_id))
    except Exception:
        pass


async def delete_user(user_id: int) -> None:
    delete_user_task.apply_async(args=[user_id], queue="user")


async def delete_personal_data(user_id: int) -> None:
    delete_personal_data_task.apply_async(args=[user_id], queue="user")
