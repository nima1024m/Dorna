# tests/conftest.py
import os
import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app

os.environ.setdefault("ASSISTANT_LANGS", '["en","fa"]')
os.environ.setdefault("ASSISTANT_TONES", '["formal","friendly","concise","polish"]')

from app.api.deps import get_db
from app.core.auth_deps import auth_required


class _DummyUser:
    def __init__(self, user_id: int = 1):
        self.id = user_id


class _DummyResult:
    def all(self):
        return []

    def scalar_one_or_none(self):
        return None

    def scalars(self):
        return self


class _DummyDB:
    def add(self, _obj):
        return None

    async def commit(self):
        return None

    async def rollback(self):
        return None

    async def execute(self, *_args, **_kwargs):
        return _DummyResult()


@pytest.fixture
def fake_db():
    return _DummyDB()


@pytest.fixture(scope="session")
def anyio_backend():
    return "asyncio"


@pytest.fixture
async def client(fake_db):
    async def _override_get_db():
        yield fake_db

    async def _override_auth_required():
        return _DummyUser(1)

    app.dependency_overrides[get_db] = _override_get_db
    app.dependency_overrides[auth_required] = _override_auth_required

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac

    app.dependency_overrides.clear()
