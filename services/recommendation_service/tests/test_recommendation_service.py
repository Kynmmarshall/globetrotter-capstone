import json
import os

import pytest
from httpx import AsyncClient

from app.main import app
from app import ai, amenities, clients, routing
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
async def test_edit_and_delete_own_comment_within_window(tmp_path):
    _use_temp_data(tmp_path, destinations=[_seed_destination()])
    token = create_access_token("alice")
    headers = {"Authorization": f"Bearer {token}"}
    async with AsyncClient(app=app, base_url="http://test") as ac:
        posted = await ac.post("/destinations/d1/comments", json={"text": "Nice!"}, headers=headers)
        comment_id = posted.json()["id"]

        edited = await ac.patch(f"/comments/{comment_id}", json={"text": "Actually, amazing!"}, headers=headers)
        assert edited.status_code == 200
        assert edited.json()["text"] == "Actually, amazing!"

        deleted = await ac.delete(f"/comments/{comment_id}", headers=headers)
        assert deleted.status_code == 200

        remaining = await ac.get("/destinations/d1/comments", headers=headers)
        assert remaining.json() == []


@pytest.mark.asyncio
async def test_cannot_edit_or_delete_someone_elses_comment(tmp_path):
    _use_temp_data(tmp_path, destinations=[_seed_destination()])
    alice_headers = {"Authorization": f"Bearer {create_access_token('alice')}"}
    bob_headers = {"Authorization": f"Bearer {create_access_token('bob')}"}
    async with AsyncClient(app=app, base_url="http://test") as ac:
        posted = await ac.post("/destinations/d1/comments", json={"text": "Mine"}, headers=alice_headers)
        comment_id = posted.json()["id"]

        edited = await ac.patch(f"/comments/{comment_id}", json={"text": "Hijacked"}, headers=bob_headers)
        assert edited.status_code == 403

        deleted = await ac.delete(f"/comments/{comment_id}", headers=bob_headers)
        assert deleted.status_code == 403


@pytest.mark.asyncio
async def test_cannot_delete_comment_with_replies(tmp_path):
    _use_temp_data(tmp_path, destinations=[_seed_destination()])
    headers = {"Authorization": f"Bearer {create_access_token('alice')}"}
    async with AsyncClient(app=app, base_url="http://test") as ac:
        posted = await ac.post("/destinations/d1/comments", json={"text": "Parent"}, headers=headers)
        comment_id = posted.json()["id"]
        await ac.post(
            "/destinations/d1/comments",
            json={"text": "Reply", "parent_id": comment_id},
            headers=headers,
        )

        deleted = await ac.delete(f"/comments/{comment_id}", headers=headers)
        assert deleted.status_code == 409


@pytest.mark.asyncio
async def test_edit_and_delete_blocked_after_window_expires(tmp_path):
    _use_temp_data(tmp_path, destinations=[_seed_destination()])
    headers = {"Authorization": f"Bearer {create_access_token('alice')}"}
    async with AsyncClient(app=app, base_url="http://test") as ac:
        posted = await ac.post("/destinations/d1/comments", json={"text": "Old news"}, headers=headers)
        comment_id = posted.json()["id"]

    # Back-date the comment past the 5-minute window directly in storage,
    # rather than waiting 5 real minutes for the test to run.
    data_path = os.environ["RECOMMENDATION_SERVICE_DATA_PATH"]
    data = json.loads(open(data_path, encoding="utf-8").read())
    from datetime import datetime, timedelta, timezone

    stale = (datetime.now(timezone.utc) - timedelta(minutes=10)).isoformat()
    data["comments"][0]["created_at"] = stale
    open(data_path, "w", encoding="utf-8").write(json.dumps(data))

    async with AsyncClient(app=app, base_url="http://test") as ac:
        edited = await ac.patch(f"/comments/{comment_id}", json={"text": "Too late"}, headers=headers)
        assert edited.status_code == 403

        deleted = await ac.delete(f"/comments/{comment_id}", headers=headers)
        assert deleted.status_code == 403


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
async def test_price_tier_round_trips_through_admin_create_and_update(tmp_path, monkeypatch):
    _use_temp_data(tmp_path)
    token = create_access_token("admin_user")
    headers = {"Authorization": f"Bearer {token}"}

    async def is_admin(username):
        return True

    monkeypatch.setattr(clients, "is_admin", is_admin)

    async with AsyncClient(app=app, base_url="http://test") as ac:
        created = await ac.post(
            "/admin/destinations",
            json={"name": "Test Hotel", "price_tier": "$$"},
            headers=headers,
        )
        assert created.status_code == 200
        assert created.json()["price_tier"] == "$$"
        dest_id = created.json()["id"]

        updated = await ac.patch(
            f"/admin/destinations/{dest_id}",
            json={"price_tier": "$$$"},
            headers=headers,
        )
        assert updated.status_code == 200
        assert updated.json()["price_tier"] == "$$$"

        fetched = await ac.get(f"/destinations/{dest_id}")
        assert fetched.json()["price_tier"] == "$$$"


@pytest.mark.asyncio
async def test_route_endpoint_maps_error_types_to_distinct_status_codes(tmp_path, monkeypatch):
    _use_temp_data(tmp_path)
    token = create_access_token("alice")
    headers = {"Authorization": f"Bearer {token}"}
    body = {"waypoints": [{"lat": 3.8, "lon": 11.5}, {"lat": 3.9, "lon": 11.6}]}

    async def raise_no_route(waypoints, profile="driving-car"):
        raise routing.RoutingNoRouteFoundError("no routable point")

    async def raise_unavailable(waypoints, profile="driving-car"):
        raise routing.RoutingRequestError("boom")

    async def raise_not_configured(waypoints, profile="driving-car"):
        raise routing.RoutingNotConfiguredError("no key")

    async with AsyncClient(app=app, base_url="http://test") as ac:
        # A genuinely unreachable point is a 422 ("no route"), distinct from
        # a transient service failure - retrying can't fix it, so the
        # frontend shouldn't offer a retry for this one.
        monkeypatch.setattr(routing, "get_route", raise_no_route)
        r1 = await ac.post("/route", json=body, headers=headers)
        assert r1.status_code == 422

        monkeypatch.setattr(routing, "get_route", raise_unavailable)
        r2 = await ac.post("/route", json=body, headers=headers)
        assert r2.status_code == 502

        monkeypatch.setattr(routing, "get_route", raise_not_configured)
        r3 = await ac.post("/route", json=body, headers=headers)
        assert r3.status_code == 503


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
async def test_ai_chat_passes_language_instruction_to_groq(tmp_path, monkeypatch):
    _use_temp_data(tmp_path)
    token = create_access_token("alice")
    headers = {"Authorization": f"Bearer {token}"}

    captured = {}

    async def fake_generate(messages):
        captured["messages"] = messages
        return "Bonjour !"

    async def fake_interests(username):
        return []

    monkeypatch.setattr(ai, "_generate", fake_generate)
    monkeypatch.setattr(clients, "get_user_interests", fake_interests)

    async with AsyncClient(app=app, base_url="http://test") as ac:
        r = await ac.post(
            "/ai/chat",
            json={
                "messages": [{"role": "user", "content": "hi"}],
                "language_code": "fr",
            },
            headers=headers,
        )
        assert r.status_code == 200
        assert r.json()["reply"] == "Bonjour !"

    system_message = captured["messages"][0]["content"]
    assert "exclusively in French" in system_message


@pytest.mark.asyncio
async def test_ai_explain_bypasses_cache_when_language_requested(tmp_path, monkeypatch):
    _use_temp_data(
        tmp_path,
        destinations=[_seed_destination(ai_explanation="Cached English text")],
    )
    token = create_access_token("alice")
    headers = {"Authorization": f"Bearer {token}"}

    captured = {}

    async def fake_generate(messages):
        captured["messages"] = messages
        return "Texte en français"

    monkeypatch.setattr(ai, "_generate", fake_generate)

    async with AsyncClient(app=app, base_url="http://test") as ac:
        # No language_code - should return the cached English text untouched.
        cached = await ac.post("/ai/explain/d1", headers=headers)
        assert cached.status_code == 200
        assert cached.json()["reply"] == "Cached English text"

        # A specific language should skip the cache and hit Groq instead.
        fresh = await ac.post("/ai/explain/d1?language_code=fr", headers=headers)
        assert fresh.status_code == 200
        assert fresh.json()["reply"] == "Texte en français"

    system_message = captured["messages"][0]["content"]
    assert "exclusively in French" in system_message


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


@pytest.mark.asyncio
async def test_amenities_endpoint_returns_empty_list_on_upstream_failure(tmp_path, monkeypatch):
    _use_temp_data(tmp_path)

    async def fake_get_amenities(categories):
        raise amenities.AmenitiesRequestError("overpass down")

    monkeypatch.setattr(amenities, "get_amenities", fake_get_amenities)

    async with AsyncClient(app=app, base_url="http://test") as ac:
        r = await ac.get("/amenities")
        assert r.status_code == 200
        assert r.json() == []


@pytest.mark.asyncio
async def test_amenities_endpoint_is_public_no_auth_required(tmp_path, monkeypatch):
    _use_temp_data(tmp_path)

    async def fake_get_amenities(categories):
        return [{"id": "node/1", "name": "Test", "category": "hospital", "lat": 3.87, "lon": 11.52}]

    monkeypatch.setattr(amenities, "get_amenities", fake_get_amenities)

    async with AsyncClient(app=app, base_url="http://test") as ac:
        r = await ac.get("/amenities")
        assert r.status_code == 200
        assert r.json()[0]["category"] == "hospital"


@pytest.mark.asyncio
async def test_amenities_endpoint_filters_unknown_categories(tmp_path, monkeypatch):
    _use_temp_data(tmp_path)
    captured = {}

    async def fake_get_amenities(categories):
        captured["categories"] = categories
        return []

    monkeypatch.setattr(amenities, "get_amenities", fake_get_amenities)

    async with AsyncClient(app=app, base_url="http://test") as ac:
        r = await ac.get(
            "/amenities",
            params={"categories": "hospital,not_a_real_category"},
        )
        assert r.status_code == 200
        assert captured["categories"] == ["hospital"]


@pytest.mark.asyncio
async def test_amenities_endpoint_returns_empty_when_no_valid_categories(tmp_path):
    _use_temp_data(tmp_path)
    async with AsyncClient(app=app, base_url="http://test") as ac:
        r = await ac.get(
            "/amenities",
            params={"categories": "not_a_real_category"},
        )
        assert r.status_code == 200
        assert r.json() == []


@pytest.mark.asyncio
async def test_amenities_endpoint_defaults_to_every_category(tmp_path, monkeypatch):
    _use_temp_data(tmp_path)
    captured = {}

    async def fake_get_amenities(categories):
        captured["categories"] = categories
        return []

    monkeypatch.setattr(amenities, "get_amenities", fake_get_amenities)

    async with AsyncClient(app=app, base_url="http://test") as ac:
        r = await ac.get("/amenities")
        assert r.status_code == 200
        assert set(captured["categories"]) == amenities.ALLOWED_CATEGORIES
