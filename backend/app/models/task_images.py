import uuid
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class TaskImage(Base):
    __tablename__ = "task_images"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()"),
    )
    task_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), sa.ForeignKey("tasks.id", onupdate="CASCADE", ondelete="CASCADE"),
    )
    __table_args__ = (
        sa.Index("idx_task_image_id", "task_id"),
    )
    address: Mapped[str] = mapped_column(sa.Text, nullable=False)
    is_cover: Mapped[bool] = mapped_column(sa.Boolean, nullable=False, server_default=sa.text("false"))
