from typing import List
from pathlib import Path as PathlibPath
from uuid import UUID

from fastapi import APIRouter, Depends, UploadFile, File, Form, Path, HTTPException
from starlette.responses import FileResponse
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.tts import TTSAddIn
from app.schemas.tts_images import ImageMetadata, TaskImagesResponse
from app.api.deps import get_db
from app.core.auth_deps import auth_required
from app.models import User, TaskImage, Task
from app.services.tts import TTSService

import mimetypes

router = APIRouter()


def _err(status: int, code: str, message: str):
    raise HTTPException(status_code=status, detail={"status": "ERROR", "code": code, "message": message})


@router.post("/add")
async def add_tts(
        files: List[UploadFile] = File(...),
        cover_title: str = Form(...),
        db: AsyncSession = Depends(get_db),
        current_user: User = Depends(auth_required)
):
    normalized_title = cover_title.strip()
    if not normalized_title:
        _err(422, "invalid_cover_title", "cover_title is required")

    tts_in = TTSAddIn(cover_title=normalized_title, user_id=current_user.id)
    res = await TTSService.add_tts(db, files, tts_in)
    return {"res": res}


@router.get("/list")
async def list_tts(db: AsyncSession = Depends(get_db), current_user: User = Depends(auth_required)):
    rows = await TTSService.list_tts(db, current_user.id)
    return {"status": "OK", "items": rows}


@router.get("/{task_id}")
async def get_tts(
        task_id: str = Path(...),
        db: AsyncSession = Depends(get_db),
        current_user: User = Depends(auth_required)
):
    res = await TTSService.get_tts(db, current_user.id, task_id)
    return res


@router.get("/voice/{task_id}")
async def get_tts_voice(
        task_id: str = Path(...),
        db: AsyncSession = Depends(get_db),
        current_user: User = Depends(auth_required)
):
    try:
        path, mime = await TTSService.get_tts_voice(db, current_user.id, task_id)
        return FileResponse(path, media_type=mime, filename=path.name)
    except FileNotFoundError:
        _err(404, "tts_not_found", "tts not found")



@router.get(
    "/images/{task_id}/",
    summary="Returns metadata and URLs for all images related to a task.",
    response_model=TaskImagesResponse,
)
async def get_task_images(
    task_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(auth_required),
):
    # Make sure the task exists and belongs to the current user
    task_res = await db.execute(select(Task).where(Task.id == task_id, Task.user_id == current_user.id))
    task = task_res.scalar_one_or_none()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    # Fetch images for the task
    rows = await db.execute(select(TaskImage).where(TaskImage.task_id == task_id))
    images = rows.scalars().all()

    base_url = f"/v1/tts/images/{task_id}/"  # matches get_image_file route
    images_list = []
    for img in images:
        filename = PathlibPath(img.address).name  # e.g., 9c..._0.jpg
        images_list.append(
            ImageMetadata(
                image_id=img.id,
                image_url=base_url + filename,
                is_cover=img.is_cover,
            )
        )

    return TaskImagesResponse(task_id=task_id, images=images_list)


# This endpoint handles the image URL from the JSON response
@router.get("/images/{task_id}/{image_name}")
async def get_image_file(
    task_id: UUID,
    image_name: str,
    db: AsyncSession = Depends(get_db),
):
    # Ensure the task exists
    task_res = await db.execute(
        select(Task.id).where(Task.id == task_id)
    )
    if not task_res.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Task not found")

    # Find the TaskImage whose filename matches the requested image_name
    img_res = await db.execute(select(TaskImage).where(TaskImage.task_id == task_id))
    img = next(
        (row for row in img_res.scalars() if PathlibPath(row.address).name == image_name),
        None,
    )
    if not img:
        raise HTTPException(status_code=404, detail="Image file not found.")

    file_path = PathlibPath(img.address)
    if not file_path.exists():
        raise HTTPException(status_code=404, detail="Image file not found.")

    media_type, _ = mimetypes.guess_type(str(file_path))
    return FileResponse(path=file_path, media_type=media_type or "application/octet-stream")