import pytest

from app.main import app
from app.api.deps import get_db
from app.core.auth_deps import auth_required


class _ScalarIterable:
    def __init__(self, items):
        self._items = items

    def all(self):
        return self._items

    def __iter__(self):
        return iter(self._items)


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
        res = self._results[self._idx]
        self._idx += 1
        return res

    async def commit(self):
        self.commit_calls += 1


class _DummyUser:
    def __init__(self, user_id: int):
        self.id = user_id


class _DummyPhrase:
    def __init__(self, id, text, category=None):
        self.id = id
        self.text = text
        self.ipa = None
        self.translation = None
        self.when_to_use = None
        self.example = None
        self.category = category


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
async def test_get_phrases_marks_saved(client):
    fake_session = _FakeSession(
        results=[
            _FakeResult(scalars_list=[2]),  # saved phrase ids for user
            _FakeResult(
                scalars_list=[
                    _DummyPhrase(1, "How's it going?", "greetings"),
                    _DummyPhrase(2, "Nice to meet you.", "greetings"),
                ]
            ),  # phrase rows
        ]
    )
    _override_deps(fake_session)
    try:
        res = await client.get("/v1/phrases")
    finally:
        _reset_overrides()

    assert res.status_code == 200
    data = res.json()
    assert data["total"] == 2
    by_id = {p["id"]: p for p in data["items"]}
    assert by_id[1]["saved"] is False
    assert by_id[2]["saved"] is True
    assert by_id[1]["text"] == "How's it going?"


@pytest.mark.anyio
async def test_get_saved_phrases_empty(client):
    # No saved ids → service returns [] without a second query.
    fake_session = _FakeSession(results=[_FakeResult(scalars_list=[])])
    _override_deps(fake_session)
    try:
        res = await client.get("/v1/phrases/saved")
    finally:
        _reset_overrides()

    assert res.status_code == 200
    assert res.json() == {"items": [], "total": 0}


@pytest.mark.anyio
async def test_save_phrase_idempotent(client):
    fake_session = _FakeSession(results=[_FakeResult(scalar=None)])  # not yet saved
    _override_deps(fake_session)
    try:
        res = await client.post("/v1/phrases/5/save")
    finally:
        _reset_overrides()

    assert res.status_code == 200
    assert res.json() == {"status": "OK", "phrase_id": 5, "saved": True}
    assert fake_session.commit_calls == 1
    assert len(fake_session.added) == 1


@pytest.mark.anyio
async def test_unsave_phrase(client):
    fake_session = _FakeSession(results=[_FakeResult()])  # delete result
    _override_deps(fake_session)
    try:
        res = await client.delete("/v1/phrases/5/save")
    finally:
        _reset_overrides()

    assert res.status_code == 200
    assert res.json() == {"status": "OK", "phrase_id": 5, "saved": False}
    assert fake_session.commit_calls == 1
