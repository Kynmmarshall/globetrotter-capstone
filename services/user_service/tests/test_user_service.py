import os

import pytest
from httpx import AsyncClient

from app.main import app
from app import clients


def _use_temp_data(tmp_path):
    data_file = tmp_path / "users.json"
    data_file.write_text('{"users": []}')
    os.environ["USER_SERVICE_DATA_PATH"] = str(data_file)


@pytest.mark.asyncio
async def test_register_login_and_me(tmp_path):
    _use_temp_data(tmp_path)
    async with AsyncClient(app=app, base_url="http://test") as ac:
        r = await ac.post("/register", json={"username": "alice", "password": "secret"})
        assert r.status_code == 200
        token = r.json()["access_token"]

        r2 = await ac.post("/login", json={"username": "alice", "password": "secret"})
        assert r2.status_code == 200

        r3 = await ac.get("/me", headers={"Authorization": f"Bearer {token}"})
        assert r3.status_code == 200
        assert r3.json()["username"] == "alice"


@pytest.mark.asyncio
async def test_duplicate_register_rejected(tmp_path):
    _use_temp_data(tmp_path)
    async with AsyncClient(app=app, base_url="http://test") as ac:
        await ac.post("/register", json={"username": "bob", "password": "secret"})
        r = await ac.post("/register", json={"username": "bob", "password": "secret"})
        assert r.status_code == 400


@pytest.mark.asyncio
async def test_interests_and_favorites(tmp_path, monkeypatch):
    _use_temp_data(tmp_path)

    async def fake_get_destinations_by_ids(ids, viewer=None):
        return [{"id": did, "name": f"Destination {did}", "country": "Cameroon"} for did in ids]

    monkeypatch.setattr(clients, "get_destinations_by_ids", fake_get_destinations_by_ids)

    async with AsyncClient(app=app, base_url="http://test") as ac:
        r = await ac.post("/register", json={"username": "carla", "password": "secret"})
        token = r.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        r2 = await ac.put("/me/interests", json={"interests": ["nature", "food"]}, headers=headers)
        assert r2.status_code == 200
        assert r2.json()["interests"] == ["nature", "food"]

        r3 = await ac.post("/me/favorites/d1", headers=headers)
        assert r3.status_code == 200
        assert "d1" in r3.json()["favorite_ids"]

        r4 = await ac.get("/me/favorites", headers=headers)
        assert r4.status_code == 200
        assert r4.json()[0]["id"] == "d1"

        r5 = await ac.delete("/me/favorites/d1", headers=headers)
        assert r5.status_code == 200
        assert "d1" not in r5.json()["favorite_ids"]


@pytest.mark.asyncio
async def test_internal_endpoint_requires_service_token(tmp_path):
    _use_temp_data(tmp_path)
    async with AsyncClient(app=app, base_url="http://test") as ac:
        await ac.post("/register", json={"username": "dave", "password": "secret"})

        unauthorized = await ac.get("/internal/users/dave")
        assert unauthorized.status_code == 403

        from app.auth import INTERNAL_SERVICE_TOKEN

        authorized = await ac.get(
            "/internal/users/dave", headers={"X-Internal-Token": INTERNAL_SERVICE_TOKEN}
        )
        assert authorized.status_code == 200
        assert authorized.json()["username"] == "dave"
        assert authorized.json()["is_admin"] is False


@pytest.mark.asyncio
async def test_internal_user_count_route_not_shadowed_by_username_route(tmp_path):
    # Regression test: /internal/users/count must be registered before
    # /internal/users/{username} in main.py, or FastAPI matches "count" as
    # a literal username instead and this 404s.
    _use_temp_data(tmp_path)
    from app.auth import INTERNAL_SERVICE_TOKEN

    async with AsyncClient(app=app, base_url="http://test") as ac:
        await ac.post("/register", json={"username": "alice", "password": "secret"})
        await ac.post("/register", json={"username": "bob", "password": "secret"})

        r = await ac.get(
            "/internal/users/count", headers={"X-Internal-Token": INTERNAL_SERVICE_TOKEN}
        )
        assert r.status_code == 200
        assert r.json() == {"count": 2}
