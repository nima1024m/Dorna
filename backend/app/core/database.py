from enum import Enum
from sqlalchemy import MetaData
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase
from sqlalchemy.types import UserDefinedType
from .config import settings

engine = create_async_engine(settings.DB_URL, future=True, echo=False)
AsyncSessionLocal = async_sessionmaker(engine, expire_on_commit=False)


# Deterministic names for indexes and constraints. Without this, autogenerate
# can't reliably emit ALTER/DROP for unnamed constraints. Existing objects are
# brought in line by the "align constraint names to convention" migration; see
# alembic/README.md. Always give NEW multi-column unique/check constraints an
# explicit name — the single-column templates below don't disambiguate them.
NAMING_CONVENTION = {
    "ix": "ix_%(column_0_label)s",
    "uq": "uq_%(table_name)s_%(column_0_name)s",
    "ck": "ck_%(table_name)s_%(constraint_name)s",
    "fk": "fk_%(table_name)s_%(column_0_name)s_%(referred_table_name)s",
    "pk": "pk_%(table_name)s",
}


class Base(DeclarativeBase):
    metadata = MetaData(naming_convention=NAMING_CONVENTION)


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


class DailyBriefStatus(str, Enum):
    QUEUED = "QUEUED"            # Brief requested, not started
    GENERATING = "GENERATING"    # Segments being generated
    COMPLETED = "COMPLETED"      # Brief ready
    FAILED = "FAILED"            # Generation failed


async def get_db():
    async with AsyncSessionLocal() as session:
        yield session
