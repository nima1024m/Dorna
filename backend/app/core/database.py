from enum import Enum
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase
from sqlalchemy.types import UserDefinedType
from .config import settings

engine = create_async_engine(settings.DB_URL, future=True, echo=False)
AsyncSessionLocal = async_sessionmaker(engine, expire_on_commit=False)


class Base(DeclarativeBase):
    pass


class CITEXT(UserDefinedType):
    """PostgreSQL citext (case-insensitive text) type."""
    cache_ok = True

    def get_col_spec(self):
        return "CITEXT"


class AIStatus(str, Enum):
    OK = "OK"
    ERROR = "ERROR"


class ActionStatus(str, Enum):
    APPROVED = "APPROVED"
    REJECTED = "REJECTED"


class TaskStatus(str, Enum):
    CREATED = "CREATED"
    IN_PROGRESS = "IN_PROGRESS"
    FAILED = "FAILED"
    COMPLETED = "COMPLETED"


class PodcastJobStatus(str, Enum):
    QUEUED = "QUEUED"
    GENERATING_SCRIPT = "GENERATING_SCRIPT"
    GENERATING_AUDIO = "GENERATING_AUDIO"
    COMPLETED = "COMPLETED"
    FAILED = "FAILED"


class FeedItemStatus(str, Enum):
    SUGGESTED = "SUGGESTED"      # Topic suggested, podcast not generated
    GENERATING = "GENERATING"    # Podcast is being generated
    READY = "READY"              # Podcast ready to play
    LISTENED = "LISTENED"        # User has listened
    ARCHIVED = "ARCHIVED"        # User dismissed/archived


async def get_db():
    async with AsyncSessionLocal() as session:
        yield session
