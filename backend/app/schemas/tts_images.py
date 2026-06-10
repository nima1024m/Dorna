from typing import List
from uuid import UUID
from pydantic import BaseModel

class ImageMetadata(BaseModel):
    image_id: UUID          # TaskImage.id
    image_url: str          # Public URL you construct from TaskImage.address
    is_cover: bool

class TaskImagesResponse(BaseModel):
    task_id: UUID           # Task.id
    images: List[ImageMetadata]