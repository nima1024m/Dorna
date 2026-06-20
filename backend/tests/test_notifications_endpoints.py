import pytest

from app.main import app
from app.api.deps import get_db
from app.core.auth_deps import auth_required


class _FakeResult:
    def __init__(self, scalar=None):
        self._scalar = scalar

    def scalar_one_or_none(self):
        return self._scalar


class _FakeSession:
    def __init__(self, results):
        self._results = results
        self._idx = 0
        self.added = []
        self.commit_calls = 0

    def add(self, obj):
        self.added.append(obj)

    async def execute(self, *_args, **_kwargs):
        res = self._results[self._idx] if self._idx < len(self._results) else _FakeResult()
        self._idx += 1
        return res

    async def commit(self):
        self.commit_calls += 1


class _DummyUser:
    def __init__(self, user_id: int):
        self.id = user_id


class _DummyToken:
    def __init__(self):
        self.user_id = 1
        self.platform = "android"
        self.is_active = False


def _override_deps(fake_session, user_id: int = 123):
    async def _get_db_override():
        yield fake_session

    async def _auth_override():
        return _DummyUser(user_id=user_id)

    app.dependency_overrides[get_db] = _get_db_override
    app.dependency_overrides[auth_required] = _auth_override


def _reset_overrides():
    app.dependency_overrides.pop(get_db, None)
    app.dependency_overrides.pop(auth_required, None)


@pytest.mark.anyio
async def test_register_new_token(client):
    fake_session = _FakeSession(results=[_FakeResult(scalar=None)])
    _override_deps(fake_session)
    try:
        res = await client.post(
            "/v1/notifications/register-token",
            json={"token": "abc123", "platform": "android"},
        )
    finally:
        _reset_overrides()

    assert res.status_code == 200
    assert res.json() == {"status": "OK", "registered": True}
    assert fake_session.commit_calls == 1
    assert len(fake_session.added) == 1


@pytest.mark.anyio
async def test_register_existing_token_rebinds(client):
    token = _DummyToken()
    fake_session = _FakeSession(results=[_FakeResult(scalar=token)])
    _override_deps(fake_session, user_id=123)
    try:
        res = await client.post(
            "/v1/notifications/register-token",
            json={"token": "abc123", "platform": "ios"},
        )
    finally:
        _reset_overrides()

    assert res.status_code == 200
    assert res.json()["registered"] is True
    assert token.user_id == 123
    assert token.is_active is True
    assert len(fake_session.added) == 0


@pytest.mark.anyio
async def test_unregister_token(client):
    fake_session = _FakeSession(results=[_FakeResult()])
    _override_deps(fake_session)
    try:
        res = await client.request(
            "DELETE",
            "/v1/notifications/register-token",
            json={"token": "abc123"},
        )
    finally:
        _reset_overrides()

    assert res.status_code == 200
    assert res.json() == {"status": "OK", "registered": False}
    assert fake_session.commit_calls == 1
