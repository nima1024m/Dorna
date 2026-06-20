import pytest

import app.services.conversation as convsvc
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


class _DummySession:
    def __init__(self, scene="networking"):
        self.id = "33333333-3333-3333-3333-333333333333"
        self.scene = scene
        self.user_id = 123


class _DummyTurn:
    def __init__(self, role, text, feedback=None):
        self.role = role
        self.text = text
        self.feedback = feedback
        self.created_at = None


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
async def test_start_conversation(client):
    fake_session = _FakeSession(results=[])
    _override_deps(fake_session)
    try:
        res = await client.post(
            "/v1/conversation/start", json={"scene": "networking"}
        )
    finally:
        _reset_overrides()

    assert res.status_code == 200
    data = res.json()
    assert data["scene"] == "networking"
    assert "brings you here" in data["opener"]
    assert fake_session.commit_calls == 2


@pytest.mark.anyio
async def test_turn_returns_reply_and_feedback(client, monkeypatch):
    async def _fake_turn(**_kw):
        return {
            "status": "OK",
            "reply": "Nice! What do you do?",
            "correction": "I am a software engineer.",
            "tip": "Add 'a' before a job.",
        }

    monkeypatch.setattr(convsvc.AI, "conversation_turn", _fake_turn)

    fake_session = _FakeSession(
        results=[
            _FakeResult(scalar=_DummySession()),  # _load_session
            _FakeResult(scalars_list=[_DummyTurn("user", "I am software engineer")]),  # _turns
        ]
    )
    _override_deps(fake_session)
    try:
        res = await client.post(
            "/v1/conversation/33333333-3333-3333-3333-333333333333/turn",
            json={"text": "I am software engineer"},
        )
    finally:
        _reset_overrides()

    assert res.status_code == 200
    data = res.json()
    assert data["reply"] == "Nice! What do you do?"
    assert data["correction"] == "I am a software engineer."
    assert data["tip"] == "Add 'a' before a job."


@pytest.mark.anyio
async def test_turn_session_not_found_404(client):
    fake_session = _FakeSession(results=[_FakeResult(scalar=None)])
    _override_deps(fake_session)
    try:
        res = await client.post(
            "/v1/conversation/33333333-3333-3333-3333-333333333333/turn",
            json={"text": "hello"},
        )
    finally:
        _reset_overrides()

    assert res.status_code == 404


@pytest.mark.anyio
async def test_history(client):
    fake_session = _FakeSession(
        results=[
            _FakeResult(scalar=_DummySession()),
            _FakeResult(
                scalars_list=[
                    _DummyTurn("assistant", "Hi!"),
                    _DummyTurn("user", "Hello"),
                ]
            ),
        ]
    )
    _override_deps(fake_session)
    try:
        res = await client.get("/v1/conversation/33333333-3333-3333-3333-333333333333")
    finally:
        _reset_overrides()

    assert res.status_code == 200
    data = res.json()
    assert data["scene"] == "networking"
    assert len(data["turns"]) == 2
    assert data["turns"][0]["role"] == "assistant"
