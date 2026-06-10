import uuid
from datetime import datetime
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID, ENUM as PgEnum
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base, TaskStatus


class Task(Base):
    __tablename__ = "tasks"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()"),
    )
    user_id: Mapped[int] = mapped_column(
        sa.ForeignKey("users.id", onupdate="CASCADE", ondelete="CASCADE"),
    )
    __table_args__ = (
        sa.Index("idx_tasks_user_id", "user_id"),
    )
    status: Mapped[TaskStatus] = mapped_column(PgEnum(TaskStatus, name="task_status"),
                                               server_default=TaskStatus.CREATED, nullable=False)
    cover_title: Mapped[str] = mapped_column(sa.Text, nullable=True)
    voice_address: Mapped[str] = mapped_column(sa.Text, nullable=True)
    ocr_text: Mapped[str] = mapped_column(sa.Text, nullable=True)
    created_timestamp: Mapped[datetime] = mapped_column(sa.DateTime(timezone=True), server_default=sa.func.now())
    updated_timestamp: Mapped[datetime] = mapped_column(sa.DateTime(timezone=True), server_default=sa.func.now())
