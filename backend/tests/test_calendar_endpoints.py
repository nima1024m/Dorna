import pytest

import app.services.calendar as calsvc
from app.main import app
from app.api.deps import get_db
from app.core.auth_deps import auth_required


class _ScalarIterable:
    def __init__(self, items):
        self._items = items

    def all(self):
        return self._items


class _FakeResult:
    def __init__(self, scalar=None, scalars_list=None):
        self._scalar = scalar
        self._scalars_list = scalars_list or []

    def scalar_one_or_none(self):
        return self._scalar

    def scalars(self):
        return _ScalarIterable(self._scalars_list)


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

    async def refresh(self, _obj):
        return None


class _DummyUser:
    def __init__(self, user_id: int):
        self.id = user_id


class _DummyEvent:
    def __init__(self, eid="e1", title="Networking event"):
        self.id = "22222222-2222-2222-2222-222222222222"
        self.provider = "apple_device"
        self.external_event_id = eid
        self.title = title
        self.description = None
        self.location = "Downtown"
        self.starts_at = None
        self.ends_at = None
        self.is_all_day = False


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
async def test_sync_device_events(client):
    fake_session = _FakeSession(
        results=[
            _FakeResult(scalar=None),  # connection lookup -> create
            _FakeResult(scalar=None),  # event lookup -> add
        ]
    )
    _override_deps(fake_session)
    try:
        res = await client.post(
            "/v1/calendar/events/sync",
            json={
                "provider": "apple_device",
                "events": [
                    {"external_event_id": "e1", "title": "Coffee with Sara"}
                ],
            },
        )
    finally:
        _reset_overrides()

    assert res.status_code == 200
    assert res.json() == {"status": "OK", "synced": 1}
    assert fake_session.commit_calls >= 1


@pytest.mark.anyio
async def test_list_events(client):
    fake_session = _FakeSession(
        results=[_FakeResult(scalars_list=[_DummyEvent()])]
    )
    _override_deps(fake_session)
    try:
        res = await client.get("/v1/calendar/events")
    finally:
        _reset_overrides()

    assert res.status_code == 200
    data = res.json()
    assert data["total"] == 1
    assert data["events"][0]["title"] == "Networking event"
    assert data["events"][0]["provider"] == "apple_device"


@pytest.mark.anyio
async def test_event_prep(client, monkeypatch):
    async def _fake_prep(**_kw):
        return {
            "status": "OK",
            "summary": "You'll do great.",
            "openers": ["So, what brings you here?"],
            "tips": ["Smile and ask one question."],
        }

    monkeypatch.setattr(calsvc.AI, "generate_event_prep", _fake_prep)

    fake_session = _FakeSession(results=[_FakeResult(scalar=_DummyEvent())])
    _override_deps(fake_session)
    try:
        res = await client.post(
            "/v1/calendar/events/22222222-2222-2222-2222-222222222222/prep"
        )
    finally:
        _reset_overrides()

    assert res.status_code == 200
    data = res.json()
    assert data["summary"] == "You'll do great."
    assert data["openers"] == ["So, what brings you here?"]
    assert data["tips"] == ["Smile and ask one question."]
