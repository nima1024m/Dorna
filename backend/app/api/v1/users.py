from fastapi import UploadFile, File, HTTPException
from fastapi import APIRouter, Depends
from starlette.responses import FileResponse
from sqlalchemy.ext.asyncio import AsyncSession
from app.schemas.users import AvatarUploadRes, AvatarDeleteRes, MeRes, UserDeleteRes, DataDeleteRes
from app.core.auth_deps import auth_required
from app.core.database import get_db
from app.models import User
from app.schemas.users import UpdateProfileReq, PatchMeRes, ChangePasswordReq, ChangePasswordRes
from app.services import users as user_service
from app.core.config import settings

router = APIRouter()


def _bad_request(code: str, message: str):
    raise HTTPException(status_code=400, detail={"status": "ERROR", "code": code, "message": message})


def _err(status: int, code: str, message: str):
    raise HTTPException(status_code=status, detail={"status": "ERROR", "code": code, "message": message})


@router.get("/me", response_model=MeRes)
async def me(
    current_user: User = Depends(auth_required),
    db: AsyncSession = Depends(get_db),
):
    profile = await user_service.get_user_profile(db, current_user.id)
    if not profile:
        # Should not happen for auth user, but fallback
        return {
            "id": str(current_user.id),
            "email": current_user.email,
            "full_name": current_user.full_name,
            "avatar_exist": bool(current_user.avatar_url),
            "onboarding_completed": False
        }
    return profile


@router.patch("/me", response_model=PatchMeRes)
async def patch_me_profile(
        body: UpdateProfileReq,
        current_user: User = Depends(auth_required),
        db: AsyncSession = Depends(get_db),
):
    try:
        return await user_service.update_profile(db, current_user.id, body.model_dump(exclude_unset=True))
    except ValueError as e:
        code = str(e)
        if code == "invalid_name_length":
            _bad_request(code, "name must be 2..100 chars after trimming")
        if code == "invalid_name_characters":
            _bad_request(code, "name contains invalid characters")
        if code == "user_not_active":
            raise HTTPException(status_code=403, detail={"status": "ERROR", "code": code, "message": "inactive user"})
        raise


@router.post("/me/avatar", response_model=AvatarUploadRes)
async def upload_avatar(
        file: UploadFile = File(...),
        current_user: User = Depends(auth_required),
        db: AsyncSession = Depends(get_db),
):
    try:
        path, filename = await user_service.upload_avatar(db, current_user.id, file)
        return {"avatar_url": filename}
    except ValueError as e:
        code = str(e)
        if code == "invalid_mime":
            _bad_request(code, "unsupported file type (allowed: image/jpeg, image/png, image/webp)")
        if code == "invalid_size":
            _bad_request(code, f"file too large (max {settings.AVATAR_MAX_MB} MB)")
        if code == "invalid_image":
            _bad_request(code, "corrupted or invalid image")
        if code == "user_not_active":
            raise HTTPException(status_code=403, detail={"status": "ERROR", "code": code, "message": "inactive user"})
        raise


@router.delete("/me/avatar", response_model=AvatarDeleteRes)
async def delete_avatar(
        current_user: User = Depends(auth_required),
        db: AsyncSession = Depends(get_db),
):
    try:
        await user_service.delete_avatar(db, current_user.id)
        return {"status": "OK"}
    except ValueError as e:
        code = str(e)
        if code == "user_not_active":
            raise HTTPException(status_code=403, detail={"status": "ERROR", "code": code, "message": "inactive user"})
        raise


@router.get("/me/avatar")
async def get_my_avatar(
        current_user: User = Depends(auth_required),
        db: AsyncSession = Depends(get_db),
):
    try:
        path, mime = await user_service.get_avatar_fileinfo(db, current_user.id)
        return FileResponse(path, media_type=mime, filename=path.name)
    except FileNotFoundError:
        _err(404, "no_avatar", "avatar not set")
    except ValueError as e:
        if str(e) == "user_not_active":
            _err(403, "inactive_user", "user is not active")
        raise


@router.post("/me/password", response_model=ChangePasswordRes)
async def change_my_password(
        body: ChangePasswordReq,
        current_user: User = Depends(auth_required),
        db: AsyncSession = Depends(get_db),
):
    try:
        await user_service.change_password(db, current_user.id, body.old_password, body.new_password)
        return {"status": "OK"}
    except ValueError as e:
        code = str(e)
        if code == "user_not_active":
            _err(403, code, "user is not active")
        if code == "invalid_old_password":
            _err(400, code, "old password is incorrect")
        if code == "same_password":
            _err(400, code, "new password must differ from old password")
        _err(400, code, "could not change password")


@router.delete("/me/delete", response_model=UserDeleteRes)
async def delete_user(
        current_user: User = Depends(auth_required)
):
    await user_service.delete_user(current_user.id)
    return {"status": "Start deleting user"}


@router.delete("/data/delete", response_model=DataDeleteRes)
async def delete_personal_data(
        current_user: User = Depends(auth_required)
):
    await user_service.delete_personal_data(current_user.id)
    return {"status": "Start deleting data"}
