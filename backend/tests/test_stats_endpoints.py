from datetime import date, timedelta

import pytest

from app.main import app
from app.api.deps import get_db
from app.core.auth_deps import auth_required


class _FakeResult:
    def __init__(self, scalar=None):
        self._scalar = scalar

    def scalar_one_or_none(self):
        return self._scalar

    def scalar_one(self):
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
        res = self._results[self._idx]
        self._idx += 1
        return res

    async def commit(self):
        self.commit_calls += 1


class _DummyUser:
    def __init__(self, user_id: int):
        self.id = user_id


class _DummyStats:
    def __init__(self, **kw):
        self.streak_days = kw.get("streak_days", 6)
        self.longest_streak = kw.get("longest_streak", 6)
        self.phrases_learned = kw.get("phrases_learned", 24)
        self.conversations = kw.get("conversations", 8)
        self.briefs_heard = kw.get("briefs_heard", 12)
        self.last_active_on = kw.get("last_active_on")


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
async def test_get_stats_existing(client):
    stats = _DummyStats(last_active_on=date.today())
    fake_session = _FakeSession(
        results=[
            _FakeResult(scalar=stats),  # get_or_create
            _FakeResult(scalar=5),      # saved count
            _FakeResult(scalar=None),   # insights
        ]
    )
    _override_deps(fake_session)
    try:
        res = await client.get("/v1/stats/me")
    finally:
        _reset_overrides()

    assert res.status_code == 200
    data = res.json()
    assert data["streak_days"] == 6
    assert data["phrases_learned"] == 24
    assert data["saved_count"] == 5
    assert data["weak_areas"] == ["articles (a/an)", "past tense"]


@pytest.mark.anyio
async def test_get_stats_creates_when_missing(client):
    fake_session = _FakeSession(
        results=[
            _FakeResult(scalar=None),  # get_or_create -> create
            _FakeResult(scalar=0),     # saved count
            _FakeResult(scalar=None),  # insights
        ]
    )
    _override_deps(fake_session)
    try:
        res = await client.get("/v1/stats/me")
    finally:
        _reset_overrides()

    assert res.status_code == 200
    data = res.json()
    assert data["streak_days"] == 6  # seeded sample
    assert data["briefs_heard"] == 12
    assert data["saved_count"] == 0
    assert fake_session.commit_calls == 1
    assert len(fake_session.added) == 1


@pytest.mark.anyio
async def test_activity_increments_streak(client):
    stats = _DummyStats(
        last_active_on=date.today() - timedelta(days=1), streak_days=6, longest_streak=6
    )
    fake_session = _FakeSession(
        results=[
            _FakeResult(scalar=stats),  # record_activity get_or_create
            _FakeResult(scalar=2),      # saved count
            _FakeResult(scalar=None),   # insights
        ]
    )
    _override_deps(fake_session)
    try:
        res = await client.post("/v1/stats/activity")
    finally:
        _reset_overrides()

    assert res.status_code == 200
    data = res.json()
    assert data["streak_days"] == 7
    assert data["longest_streak"] == 7
    assert data["saved_count"] == 2
    assert fake_session.commit_calls == 1


@pytest.mark.anyio
async def test_activity_same_day_noop(client):
    stats = _DummyStats(last_active_on=date.today(), streak_days=6)
    fake_session = _FakeSession(
        results=[
            _FakeResult(scalar=stats),  # record_activity get_or_create
            _FakeResult(scalar=0),      # saved count
            _FakeResult(scalar=None),   # insights
        ]
    )
    _override_deps(fake_session)
    try:
        res = await client.post("/v1/stats/activity")
    finally:
        _reset_overrides()

    assert res.status_code == 200
    assert res.json()["streak_days"] == 6
    assert fake_session.commit_calls == 0
