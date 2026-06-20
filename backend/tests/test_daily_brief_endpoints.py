from datetime import date

import pytest

from app.main import app
from app.api.deps import get_db
from app.core.auth_deps import auth_required
from app.core.database import DailyBriefStatus


class _FakeResult:
    def __init__(self, scalar=None):
        self._scalar = scalar

    def scalar_one_or_none(self):
        return self._scalar


class _FakeSession:
    def __init__(self, results):
        self._results = results
        self._idx = 0

    async def execute(self, *_args, **_kwargs):
        res = self._results[self._idx]
        self._idx += 1
        return res


class _DummyUser:
    def __init__(self, user_id: int):
        self.id = user_id


class _DummyBrief:
    def __init__(self, status, content_json=None, progress=100, current_step=None):
        self.id = "11111111-1111-1111-1111-111111111111"
        self.brief_date = date.today()
        self.status = status
        self.content_json = content_json
        self.progress = progress
        self.current_step = current_step
        self.error_message = None


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
async def test_today_returns_brief(client):
    content = {"date": "Monday, Jun 1", "segments": [{"id": "weather", "label": "Weather", "transcript": "Sunny."}]}
    brief = _DummyBrief(status=DailyBriefStatus.COMPLETED, content_json=content)
    fake_session = _FakeSession(results=[_FakeResult(scalar=brief)])
    _override_deps(fake_session)
    try:
        res = await client.get("/v1/daily-brief/today")
    finally:
        _reset_overrides()

    assert res.status_code == 200
    data = res.json()
    assert data["status"] == "completed"
    assert data["content"] == content


@pytest.mark.anyio
async def test_today_status(client):
    brief = _DummyBrief(
        status=DailyBriefStatus.GENERATING, progress=40, current_step="Generating…"
    )
    fake_session = _FakeSession(results=[_FakeResult(scalar=brief)])
    _override_deps(fake_session)
    try:
        res = await client.get("/v1/daily-brief/today/status")
    finally:
        _reset_overrides()

    assert res.status_code == 200
    data = res.json()
    assert data["status"] == "generating"
    assert data["progress"] == 40


@pytest.mark.anyio
async def test_today_status_missing_404(client):
    fake_session = _FakeSession(results=[_FakeResult(scalar=None)])
    _override_deps(fake_session)
    try:
        res = await client.get("/v1/daily-brief/today/status")
    finally:
        _reset_overrides()

    assert res.status_code == 404
