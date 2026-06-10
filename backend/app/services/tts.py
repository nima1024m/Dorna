import os
from typing import List, Dict, Any

from fastapi import UploadFile
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
import mimetypes
from pathlib import Path

from app.core.config import settings
from app.core.database import TaskStatus
from app.models import Task, TaskImage
from app.schemas.tts import TTSAddIn
from app.worker.tts_tasks import enqueue_pipeline

ALLOWED_IMAGE_EXTS = {".jpg", ".jpeg", ".png", ".webp"}
IMAGE_SAVE_DIR = "app/files/images/tts"
VOICE_DIR = Path("app/files/voice/tts")


def _guess_mime_from_ext(path: Path) -> str:
    mt, _ = mimetypes.guess_type(str(path))
    return mt or "application/octet-stream"


class TTSService:
    @staticmethod
    async def add_tts(db: AsyncSession, files: List[UploadFile], data: TTSAddIn) -> dict:
        try:
            if not files or len(files) == 0:
                return {"status": "ERROR", "message": "no files provided"}
            if len(files) > settings.TTS_MAX_UPLOAD_IMAGES:
                return {"status": "ERROR", "message": f"too many files; max is {settings.TTS_MAX_UPLOAD_IMAGES}"}

            names: list[str] = []
            for f in files:
                name = (f.filename or "").strip()
                _, ext = os.path.splitext(name.lower())
                if ext not in ALLOWED_IMAGE_EXTS:
                    return {"status": "ERROR", "message": f"unsupported file type: {ext}"}
                names.append(name)

            # Task: CREATED
            task = Task(
                user_id=data.user_id,
                cover_title=data.cover_title,
                status=TaskStatus.CREATED,
            )
            db.add(task)
            await db.commit()
            task_id = task.id

            # Save files + TaskImage
            saved_addresses: list[str] = []
            for idx, item in enumerate(zip(files, names)):
                f, name = item
                file_name, ext = os.path.splitext(name.lower())
                new_name = f"{task_id}_{idx}{ext}"

                save_path = os.path.join(IMAGE_SAVE_DIR, new_name)
                content = await f.read()
                with open(save_path, "wb") as out:
                    out.write(content)
                db.add(TaskImage(task_id=task_id, address=save_path, is_cover=(idx == 0)))
                saved_addresses.append(save_path)
            await db.commit()

            # pipeline
            enqueue_pipeline(task_id)

            return {"status": "OK", "task_id": str(task_id), "files": saved_addresses}

        except Exception as e:
            await db.rollback()
            return {"status": "ERROR", "message": str(e)}

    @staticmethod
    async def list_tts(db: AsyncSession, user_id: int) -> List[Dict[str, Any]]:
        res = await db.execute(
            select(Task, TaskImage.address)
            .outerjoin(
                TaskImage,
                (TaskImage.task_id == Task.id) & (TaskImage.is_cover == True),
            )
            .where(Task.user_id == user_id)
            .order_by(Task.created_timestamp.asc())
        )
        out = []
        for task, cover_address in res.all():
            cover_filename = (
                Path(cover_address).name if cover_address else None
            )
            cover_url = (
                f"/v1/tts/images/{task.id}/{cover_filename}"
                if cover_filename
                else None
            )
            out.append(
                {
                    "id": task.id,
                    "status": task.status,
                    "created_timestamp": getattr(task, "created_timestamp", None),
                    "updated_timestamp": getattr(task, "updated_timestamp", None),
                    "cover_title": task.cover_title,
                    "cover_url": cover_url,
                }
            )
        return out

    @staticmethod
    async def get_tts(db: AsyncSession, user_id: int, task_id: str) -> Dict[str, Any]:
        # Task
        res = await db.execute(
            select(Task).where(Task.id == task_id, Task.user_id == user_id)
        )
        task = res.scalar_one_or_none()
        if not task:
            return {"status": "ERROR", "message": "not found"}

        # Images
        res2 = await db.execute(
            select(TaskImage).where(TaskImage.task_id == task_id)
        )
        images = res2.scalars().all()

        return {
            "status": "OK",
            "task": {
                "id": task.id,
                "status": task.status,
                "voice_address": getattr(task, "voice_address", None),
                "ocr_text": getattr(task, "ocr_text", None),
                "cover_title": task.cover_title,
                "created_timestamp": getattr(task, "created_timestamp", None),
                "updated_timestamp": getattr(task, "updated_timestamp", None),
            },
            "images": [{"address": img.address} for img in images],
        }

    @staticmethod
    async def get_tts_voice(db: AsyncSession, user_id: int, task_id: str) -> tuple[Path, str]:
        task_obj = await TTSService.get_tts(db, user_id, task_id)
        if not task_obj or task_obj['status'] == 'ERROR' or task_obj.get('task', {}).get('voice_address', '') is None:
            raise FileNotFoundError("tts_not_found")

        p = Path(task_obj['task'].get('voice_address', ''))
        if not p.exists() or not p.is_file():
            raise FileNotFoundError("tts_not_found")

        mime = _guess_mime_from_ext(p)
        return p, mime
