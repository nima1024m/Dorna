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
    def __init__(self, scalar=None, scalars_list=None, all_list=None):
        self._scalar = scalar
        self._scalars_list = scalars_list or []
        self._all_list = all_list or []

    def scalar_one_or_none(self):
        return self._scalar

    def scalars(self):
        return _ScalarIterable(self._scalars_list)

    def all(self):
        return self._all_list


class _FakeSession:
    def __init__(self, results):
        self._results = results
        self._idx = 0
        self.added = []
        self.commit_calls = 0
        self.rollback_calls = 0

    def add(self, obj):
        self.added.append(obj)

    async def execute(self, *_args, **_kwargs):
        res = self._results[self._idx]
        self._idx += 1
        return res

    async def commit(self):
        self.commit_calls += 1

    async def rollback(self):
        self.rollback_calls += 1


class _DummyUser:
    def __init__(self, user_id: int):
        self.id = user_id


class _DummyPref:
    def __init__(self, language_level: int):
        self.language_level = language_level


class _DummyCategory:
    def __init__(self, id: str, label: str):
        self.id = id
        self.label = label


class _DummyGoal:
    def __init__(self, id: int, key: str, title: str, description: str):
        self.id = id
        self.key = key
        self.title = title
        self.description = description


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
async def test_get_preferences_unset_returns_defaults(client):
    fake_session = _FakeSession(
        results=[
            _FakeResult(scalar=None),          # UserPodcastPreference
            _FakeResult(all_list=[]),          # categories join tuples
            _FakeResult(scalars_list=[]),      # goal_ids
        ]
    )

    _override_deps(fake_session)
    try:
        res = await client.get("/v1/podcast/preferences")
    finally:
        _reset_overrides()

    assert res.status_code == 200
    data = res.json()
    assert data["language_level"] is None
    assert data["categories"] == []
    assert data["goal_ids"] == []


@pytest.mark.anyio
async def test_put_preferences_first_time_save(client):
    pref = _DummyPref(language_level=6)
    fake_session = _FakeSession(
        results=[
            _FakeResult(scalars_list=["internet"]),                 # validate categories
            _FakeResult(scalars_list=[1, 2]),                       # validate goals
            _FakeResult(scalar=None),                               # existing pref lookup
            _FakeResult(),                                          # delete categories
            _FakeResult(),                                          # delete goals
            _FakeResult(scalar=pref),                               # get prefs: pref
            _FakeResult(all_list=[("internet", "Internet Mysteries")]),  # get prefs: categories join
            _FakeResult(scalars_list=[1, 2]),                       # get prefs: goal_ids
        ]
    )

    payload = {
        "language_level": 6,
        "categories": [{"id": "internet", "label": "Internet Mysteries"}],
        "goal_ids": [1, 2],
    }

    _override_deps(fake_session)
    try:
        res = await client.put("/v1/podcast/preferences", json=payload)
    finally:
        _reset_overrides()

    assert res.status_code == 200
    data = res.json()
    assert data["language_level"] == 6
    assert data["categories"] == [{"id": "internet", "label": "Internet Mysteries"}]
    assert data["goal_ids"] == [1, 2]
    assert fake_session.commit_calls == 1
    assert fake_session.rollback_calls == 0
    assert len(fake_session.added) >= 1


@pytest.mark.anyio
async def test_put_preferences_updates_existing_preferences(client):
    existing_pref = _DummyPref(language_level=5)
    fake_session = _FakeSession(
        results=[
            _FakeResult(scalars_list=["internet"]),                 # validate categories
            _FakeResult(scalars_list=[1]),                          # validate goals
            _FakeResult(scalar=existing_pref),                      # existing pref lookup
            _FakeResult(),                                          # delete categories
            _FakeResult(),                                          # delete goals
            _FakeResult(scalar=existing_pref),                      # get prefs: pref
            _FakeResult(all_list=[("internet", "Internet Mysteries")]),  # get prefs: categories join
            _FakeResult(scalars_list=[1]),                          # get prefs: goal_ids
        ]
    )

    payload = {
        "language_level": 7,
        "categories": [{"id": "internet", "label": "Internet Mysteries"}],
        "goal_ids": [1],
    }

    _override_deps(fake_session)
    try:
        res = await client.put("/v1/podcast/preferences", json=payload)
    finally:
        _reset_overrides()

    assert res.status_code == 200
    data = res.json()
    assert data["language_level"] == 7
    assert existing_pref.language_level == 7
    assert fake_session.commit_calls == 1
    assert fake_session.rollback_calls == 0
    assert existing_pref in fake_session.added


@pytest.mark.anyio
async def test_put_preferences_invalid_category_ids_returns_400(client):
    fake_session = _FakeSession(
        results=[
            _FakeResult(scalars_list=["internet"]),  # validate categories (missing "bad")
        ]
    )

    payload = {
        "language_level": 6,
        "categories": [
            {"id": "internet", "label": "Internet Mysteries"},
            {"id": "bad", "label": "Bad"},
        ],
        "goal_ids": [1],
    }

    _override_deps(fake_session)
    try:
        res = await client.put("/v1/podcast/preferences", json=payload)
    finally:
        _reset_overrides()

    assert res.status_code == 400
    body = res.json()
    assert "Invalid category_ids" in (body.get("detail") or "")
    assert fake_session.commit_calls == 0
    assert fake_session.rollback_calls == 1


@pytest.mark.anyio
async def test_put_preferences_invalid_goal_ids_returns_400(client):
    fake_session = _FakeSession(
        results=[
            _FakeResult(scalars_list=["internet"]),  # validate categories
            _FakeResult(scalars_list=[1]),           # validate goals (missing 999)
        ]
    )

    payload = {
        "language_level": 6,
        "categories": [{"id": "internet", "label": "Internet Mysteries"}],
        "goal_ids": [1, 999],
    }

    _override_deps(fake_session)
    try:
        res = await client.put("/v1/podcast/preferences", json=payload)
    finally:
        _reset_overrides()

    assert res.status_code == 400
    body = res.json()
    assert "Invalid goal_ids" in (body.get("detail") or "")
    assert fake_session.commit_calls == 0
    assert fake_session.rollback_calls == 1


@pytest.mark.anyio
async def test_put_preferences_rejects_empty_lists(client):
    fake_session = _FakeSession(results=[])
    payload = {
        "language_level": 6,
        "categories": [],
        "goal_ids": [],
    }

    _override_deps(fake_session)
    try:
        res = await client.put("/v1/podcast/preferences", json=payload)
    finally:
        _reset_overrides()

    assert res.status_code == 400
    body = res.json()
    # One of these should fire first; both are 400s.
    assert "must not be empty" in (body.get("detail") or "")
    assert fake_session.commit_calls == 0
    assert fake_session.rollback_calls == 1


@pytest.mark.anyio
async def test_get_categories_and_goals(client):
    fake_session = _FakeSession(
        results=[
            _FakeResult(scalars_list=[_DummyCategory("internet", "Internet Mysteries")]),
            _FakeResult(scalars_list=[_DummyGoal(1, "fluency", "Improve fluency", "desc")]),
        ]
    )

    _override_deps(fake_session)
    try:
        res1 = await client.get("/v1/podcast/categories")
        res2 = await client.get("/v1/podcast/goals")
    finally:
        _reset_overrides()

    assert res1.status_code == 200
    assert res1.json()["categories"] == [{"id": "internet", "label": "Internet Mysteries"}]

    assert res2.status_code == 200
    assert res2.json()["goals"] == [
        {"id": 1, "key": "fluency", "title": "Improve fluency", "description": "desc"}
    ]

