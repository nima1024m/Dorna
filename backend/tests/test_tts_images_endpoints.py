import mimetypes
from uuid import uuid4, UUID
from pathlib import Path as PathlibPath

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

    async def execute(self, *_args, **_kwargs):
        res = self._results[self._idx]
        self._idx += 1
        return res


class _DummyUser:
    def __init__(self, user_id: int):
        self.id = user_id


class _DummyTask:
    def __init__(self, task_id: UUID, user_id: int):
        self.id = task_id
        self.user_id = user_id


class _DummyTaskImage:
    def __init__(self, image_id: UUID, task_id: UUID, address: str, is_cover: bool):
        self.id = image_id
        self.task_id = task_id
        self.address = address
        self.is_cover = is_cover


def _override_deps(fake_session):
    async def _get_db_override():
        yield fake_session

    async def _auth_override():
        return _DummyUser(user_id=123)

    app.dependency_overrides[get_db] = _get_db_override
    app.dependency_overrides[auth_required] = _auth_override


def _reset_overrides():
    app.dependency_overrides.pop(get_db, None)
    app.dependency_overrides.pop(auth_required, None)


@pytest.mark.anyio
async def test_get_task_images_returns_db_backed_urls(client, tmp_path):
    task_id = uuid4()
    img1_path = tmp_path / "img1.jpg"
    img1_path.write_bytes(b"image1")
    img2_path = tmp_path / "img2.png"
    img2_path.write_bytes(b"image2")

    task = _DummyTask(task_id=task_id, user_id=123)
    images = [
        _DummyTaskImage(uuid4(), task_id, str(img1_path), True),
        _DummyTaskImage(uuid4(), task_id, str(img2_path), False),
    ]

    fake_session = _FakeSession(
        results=[
            _FakeResult(scalar=task),          # task lookup
            _FakeResult(scalars_list=images),  # images lookup
        ]
    )

    _override_deps(fake_session)
    try:
        res = await client.get(f"/v1/tts/images/{task_id}/")
    finally:
        _reset_overrides()

    assert res.status_code == 200
    data = res.json()
    assert data["task_id"] == str(task_id)
    urls = {item["image_url"] for item in data["images"]}
    assert urls == {
        f"/v1/tts/images/{task_id}/{img1_path.name}",
        f"/v1/tts/images/{task_id}/{img2_path.name}",
    }


@pytest.mark.anyio
async def test_get_image_file_serves_existing_file(client, tmp_path):
    task_id = uuid4()
    img_path = tmp_path / "cover.jpg"
    content = b"cover-bytes"
    img_path.write_bytes(content)
    task = _DummyTask(task_id=task_id, user_id=123)
    image = _DummyTaskImage(uuid4(), task_id, str(img_path), True)

    fake_session = _FakeSession(
        results=[
            _FakeResult(scalar=task),          # task lookup
            _FakeResult(scalars_list=[image]), # image lookup
        ]
    )

    _override_deps(fake_session)
    try:
        res = await client.get(f"/v1/tts/images/{task_id}/{img_path.name}")
    finally:
        _reset_overrides()

    assert res.status_code == 200
    assert res.content == content
    expected_mime, _ = mimetypes.guess_type(str(img_path))
    assert res.headers["content-type"] == (expected_mime or "application/octet-stream")


@pytest.mark.anyio
async def test_get_image_file_404_when_not_found(client, tmp_path):
    task_id = uuid4()
    task = _DummyTask(task_id=task_id, user_id=123)
    # No matching image with requested name
    image = _DummyTaskImage(uuid4(), task_id, str(tmp_path / "other.png"), False)

    fake_session = _FakeSession(
        results=[
            _FakeResult(scalar=task),          # task lookup
            _FakeResult(scalars_list=[image]), # image lookup
        ]
    )

    _override_deps(fake_session)
    try:
        res = await client.get(f"/v1/tts/images/{task_id}/missing.png")
    finally:
        _reset_overrides()

    assert res.status_code == 404
    assert res.json()["detail"] == "Image file not found."

