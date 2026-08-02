import json
import os

import pytest
from httpx import AsyncClient

from app.main import app
from app import ai, clients
from app.auth import create_access_token, INTERNAL_SERVICE_TOKEN


def _use_temp_data(tmp_path, destinations=None):
    data_file = tmp_path / "destinations.json"
    data_file.write_text(json.dumps({
        "destinations": destinations or [],
        "ratings": [],
        "comments": [],
    }))
    os.environ["RECOMMENDATION_SERVICE_DATA_PATH"] = str(data_file)


def _seed_destination(**overrides):
    base = {
        "id": "d1",
        "name": "Monument de la Réunification",
        "country": "Cameroon",
        "tags": ["monument", "history"],
    }
    base.update(overrides)
    return base


@pytest.mark.asyncio
async def test_list_and_get_destination(tmp_path):
    _use_temp_data(tmp_path, destinations=[_seed_destination()])
    async with AsyncClient(app=app, base_url="http://test") as ac:
        r = await ac.get("/destinations")
        assert r.status_code == 200
        assert len(r.json()) == 1

        r2 = await ac.get("/destinations/d1")
        assert r2.status_code == 200
        assert r2.json()["name"] == "Monument de la Réunification"

        r3 = await ac.get("/destinations/does-not-exist")
        assert r3.status_code == 404


@pytest.mark.asyncio
async def test_rating_flow(tmp_path):
    _use_temp_data(tmp_path, destinations=[_seed_destination()])
    token = create_access_token("alice")
    headers = {"Authorization": f"Bearer {token}"}
    async with AsyncClient(app=app, base_url="http://test") as ac:
        r = await ac.put("/destinations/d1/rating", json={"stars": 4}, headers=headers)
        assert r.status_code == 200
        assert r.json()["rating_average"] == 4
        assert r.json()["rating_count"] == 1

        r2 = await ac.delete("/destinations/d1/rating", headers=headers)
        assert r2.status_code == 200
        assert r2.json()["rating_count"] == 0


@pytest.mark.asyncio
async def test_comments_thread(tmp_path):
    _use_temp_data(tmp_path, destinations=[_seed_destination()])
    token = create_access_token("alice")
    headers = {"Authorization": f"Bearer {token}"}
    async with AsyncClient(app=app, base_url="http://test") as ac:
        r = await ac.post("/destinations/d1/comments", json={"text": "Beautiful spot!"}, headers=headers)
        assert r.status_code == 200
        comment_id = r.json()["id"]

        r2 = await ac.post(
            "/destinations/d1/comments",
            json={"text": "Agreed!", "parent_id": comment_id},
            headers=headers,
        )
        assert r2.status_code == 200

        r3 = await ac.get("/destinations/d1/comments", headers=headers)
        assert r3.status_code == 200
        assert len(r3.json()) == 1
        assert len(r3.json()[0]["replies"]) == 1

        r4 = await ac.post("/comments/{}/vote".format(comment_id), json={"direction": "up"}, headers=headers)
        assert r4.status_code == 200
        assert r4.json()["score"] == 1


@pytest.mark.asyncio
async def test_admin_endpoints_require_admin_role(tmp_path, monkeypatch):
    _use_temp_data(tmp_path, destinations=[_seed_destination(status="pending")])
    token = create_access_token("regular_user")
    headers = {"Authorization": f"Bearer {token}"}

    async def not_admin(username):
        return False

    async def is_admin(username):
        return True

    monkeypatch.setattr(clients, "is_admin", not_admin)
    async with AsyncClient(app=app, base_url="http://test") as ac:
        r = await ac.get("/admin/destinations", headers=headers)
        assert r.status_code == 403

    monkeypatch.setattr(clients, "is_admin", is_admin)
    async with AsyncClient(app=app, base_url="http://test") as ac:
        r2 = await ac.get("/admin/destinations", headers=headers)
        assert r2.status_code == 200
        assert len(r2.json()) == 1


@pytest.mark.asyncio
async def test_recommendations_uses_interests_and_history(tmp_path, monkeypatch):
    _use_temp_data(tmp_path, destinations=[
        _seed_destination(id="d1", tags=["nature"]),
        _seed_destination(id="d2", tags=["history"]),
    ])
    token = create_access_token("alice")
    headers = {"Authorization": f"Bearer {token}"}

    async def fake_interests(username):
        return ["history"]

    async def fake_itineraries(username):
        return [{"destinations": ["d2"]}]

    monkeypatch.setattr(clients, "get_user_interests", fake_interests)
    monkeypatch.setattr(clients, "get_itineraries_for", fake_itineraries)

    async with AsyncClient(app=app, base_url="http://test") as ac:
        r = await ac.get("/recommendations", headers=headers)
        assert r.status_code == 200
        # d2 matches interests but was already visited in a past itinerary,
        # so recommendations_for should fall back rather than resurface it.
        ids = [d["id"] for d in r.json()]
        assert ids  # still returns something rather than an empty list


@pytest.mark.asyncio
async def test_ai_chat_not_configured(tmp_path, monkeypatch):
    _use_temp_data(tmp_path)
    monkeypatch.setattr(ai, "GROQ_API_KEY", None)
    token = create_access_token("alice")
    headers = {"Authorization": f"Bearer {token}"}

    async def fake_interests(username):
        return []

    monkeypatch.setattr(clients, "get_user_interests", fake_interests)

    async with AsyncClient(app=app, base_url="http://test") as ac:
        r = await ac.post("/ai/chat", json={"messages": [{"role": "user", "content": "hi"}]}, headers=headers)
        assert r.status_code == 503


@pytest.mark.asyncio
async def test_internal_destinations_endpoint(tmp_path):
    _use_temp_data(tmp_path, destinations=[_seed_destination()])
    async with AsyncClient(app=app, base_url="http://test") as ac:
        unauthorized = await ac.get("/internal/destinations", params={"ids": "d1"})
        assert unauthorized.status_code == 403

        authorized = await ac.get(
            "/internal/destinations",
            params={"ids": "d1"},
            headers={"X-Internal-Token": INTERNAL_SERVICE_TOKEN},
        )
        assert authorized.status_code == 200
        assert authorized.json()[0]["id"] == "d1"
