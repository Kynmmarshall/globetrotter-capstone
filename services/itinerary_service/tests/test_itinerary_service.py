import os

import pytest
from httpx import AsyncClient

from app.main import app
from app import clients
from app.auth import create_access_token, INTERNAL_SERVICE_TOKEN


def _use_temp_data(tmp_path):
    data_file = tmp_path / "itineraries.json"
    data_file.write_text('{"itineraries": []}')
    os.environ["ITINERARY_SERVICE_DATA_PATH"] = str(data_file)


@pytest.mark.asyncio
async def test_create_list_delete_itinerary(tmp_path):
    _use_temp_data(tmp_path)
    token = create_access_token("alice")
    headers = {"Authorization": f"Bearer {token}"}

    async with AsyncClient(app=app, base_url="http://test") as ac:
        r = await ac.post(
            "/itineraries",
            json={"title": "My Yaoundé weekend", "destinations": ["d1", "d2"]},
            headers=headers,
        )
        assert r.status_code == 200
        itin_id = r.json()["id"]
        assert r.json()["user"] == "alice"

        r2 = await ac.get("/itineraries", headers=headers)
        assert r2.status_code == 200
        assert len(r2.json()) == 1

        # another user can't see or delete it
        other_token = create_access_token("bob")
        other_headers = {"Authorization": f"Bearer {other_token}"}
        r3 = await ac.get("/itineraries", headers=other_headers)
        assert r3.json() == []

        r4 = await ac.delete(f"/itineraries/{itin_id}", headers=other_headers)
        assert r4.status_code == 404

        r5 = await ac.delete(f"/itineraries/{itin_id}", headers=headers)
        assert r5.status_code == 200

        r6 = await ac.get("/itineraries", headers=headers)
        assert r6.json() == []


@pytest.mark.asyncio
async def test_update_itinerary_destinations_and_title(tmp_path):
    _use_temp_data(tmp_path)
    token = create_access_token("alice")
    headers = {"Authorization": f"Bearer {token}"}

    async with AsyncClient(app=app, base_url="http://test") as ac:
        r = await ac.post(
            "/itineraries",
            json={"title": "My Yaoundé weekend", "destinations": ["d1"]},
            headers=headers,
        )
        itin_id = r.json()["id"]

        r2 = await ac.patch(
            f"/itineraries/{itin_id}",
            json={"destinations": ["d1", "d2", "d3"]},
            headers=headers,
        )
        assert r2.status_code == 200
        assert r2.json()["destinations"] == ["d1", "d2", "d3"]
        assert r2.json()["title"] == "My Yaoundé weekend"

        r3 = await ac.patch(
            f"/itineraries/{itin_id}",
            json={"title": "Renamed"},
            headers=headers,
        )
        assert r3.status_code == 200
        assert r3.json()["title"] == "Renamed"
        assert r3.json()["destinations"] == ["d1", "d2", "d3"]

        # another user can't update it
        other_token = create_access_token("bob")
        other_headers = {"Authorization": f"Bearer {other_token}"}
        r4 = await ac.patch(
            f"/itineraries/{itin_id}",
            json={"title": "Hijacked"},
            headers=other_headers,
        )
        assert r4.status_code == 404

        r5 = await ac.patch(
            "/itineraries/does-not-exist",
            json={"title": "Nope"},
            headers=headers,
        )
        assert r5.status_code == 404


@pytest.mark.asyncio
async def test_internal_itineraries_endpoint(tmp_path):
    _use_temp_data(tmp_path)
    token = create_access_token("carla")
    headers = {"Authorization": f"Bearer {token}"}

    async with AsyncClient(app=app, base_url="http://test") as ac:
        await ac.post(
            "/itineraries",
            json={"title": "Trip", "destinations": ["d5"]},
            headers=headers,
        )

        unauthorized = await ac.get("/internal/itineraries/carla")
        assert unauthorized.status_code == 403

        authorized = await ac.get(
            "/internal/itineraries/carla", headers={"X-Internal-Token": INTERNAL_SERVICE_TOKEN}
        )
        assert authorized.status_code == 200
        assert len(authorized.json()) == 1


@pytest.mark.asyncio
async def test_share_itinerary_is_idempotent_and_owner_only(tmp_path):
    _use_temp_data(tmp_path)
    token = create_access_token("alice")
    headers = {"Authorization": f"Bearer {token}"}

    async with AsyncClient(app=app, base_url="http://test") as ac:
        r = await ac.post(
            "/itineraries",
            json={"title": "Trip", "destinations": ["d1"]},
            headers=headers,
        )
        itin_id = r.json()["id"]

        r2 = await ac.post(f"/itineraries/{itin_id}/share", headers=headers)
        assert r2.status_code == 200
        token1 = r2.json()["share_token"]
        assert token1

        # Re-sharing returns the same token rather than minting a new one.
        r3 = await ac.post(f"/itineraries/{itin_id}/share", headers=headers)
        assert r3.json()["share_token"] == token1

        # Another user can't share someone else's itinerary.
        other_token = create_access_token("bob")
        other_headers = {"Authorization": f"Bearer {other_token}"}
        r4 = await ac.post(f"/itineraries/{itin_id}/share", headers=other_headers)
        assert r4.status_code == 404


@pytest.mark.asyncio
async def test_get_shared_itinerary_hydrates_destinations_in_order(tmp_path, monkeypatch):
    _use_temp_data(tmp_path)
    token = create_access_token("alice")
    headers = {"Authorization": f"Bearer {token}"}

    async def fake_get_destinations_by_ids(ids):
        # Return them out of order to prove the endpoint re-sorts to match
        # the itinerary's own stop order rather than trusting this order.
        by_id = {"d1": {"id": "d1", "name": "First"}, "d2": {"id": "d2", "name": "Second"}}
        return [by_id[i] for i in reversed(ids)]

    monkeypatch.setattr(clients, "get_destinations_by_ids", fake_get_destinations_by_ids)

    async with AsyncClient(app=app, base_url="http://test") as ac:
        r = await ac.post(
            "/itineraries",
            json={"title": "Trip", "destinations": ["d1", "d2"]},
            headers=headers,
        )
        itin_id = r.json()["id"]
        share = await ac.post(f"/itineraries/{itin_id}/share", headers=headers)
        share_token = share.json()["share_token"]

        r2 = await ac.get(f"/shared/itineraries/{share_token}")
        assert r2.status_code == 200
        body = r2.json()
        assert body["title"] == "Trip"
        assert [d["id"] for d in body["destinations"]] == ["d1", "d2"]

        missing = await ac.get("/shared/itineraries/does-not-exist")
        assert missing.status_code == 404


@pytest.mark.asyncio
async def test_unshare_itinerary_revokes_token(tmp_path):
    _use_temp_data(tmp_path)
    token = create_access_token("alice")
    headers = {"Authorization": f"Bearer {token}"}

    async with AsyncClient(app=app, base_url="http://test") as ac:
        r = await ac.post(
            "/itineraries",
            json={"title": "Trip", "destinations": ["d1"]},
            headers=headers,
        )
        itin_id = r.json()["id"]
        share = await ac.post(f"/itineraries/{itin_id}/share", headers=headers)
        share_token = share.json()["share_token"]

        r2 = await ac.delete(f"/itineraries/{itin_id}/share", headers=headers)
        assert r2.status_code == 200

        r3 = await ac.get(f"/shared/itineraries/{share_token}")
        assert r3.status_code == 404


@pytest.mark.asyncio
async def test_claim_shared_itinerary_copies_into_claiming_users_account(tmp_path):
    _use_temp_data(tmp_path)
    alice_headers = {"Authorization": f"Bearer {create_access_token('alice')}"}
    bob_headers = {"Authorization": f"Bearer {create_access_token('bob')}"}

    async with AsyncClient(app=app, base_url="http://test") as ac:
        r = await ac.post(
            "/itineraries",
            json={"title": "Weekend in Yaoundé", "destinations": ["d1", "d2"]},
            headers=alice_headers,
        )
        itin_id = r.json()["id"]
        share = await ac.post(f"/itineraries/{itin_id}/share", headers=alice_headers)
        share_token = share.json()["share_token"]

        claimed = await ac.post(
            f"/itineraries/claim/{share_token}", headers=bob_headers
        )
        assert claimed.status_code == 200
        body = claimed.json()
        assert body["user"] == "bob"
        assert body["title"] == "Weekend in Yaoundé"
        assert body["destinations"] == ["d1", "d2"]
        assert body["id"] != itin_id

        # bob now has his own independent copy, alice's is untouched
        bob_list = await ac.get("/itineraries", headers=bob_headers)
        assert len(bob_list.json()) == 1
        alice_list = await ac.get("/itineraries", headers=alice_headers)
        assert len(alice_list.json()) == 1

        # the token is still valid - a second friend can claim their own copy
        carla_headers = {"Authorization": f"Bearer {create_access_token('carla')}"}
        claimed2 = await ac.post(
            f"/itineraries/claim/{share_token}", headers=carla_headers
        )
        assert claimed2.status_code == 200
        assert claimed2.json()["id"] != body["id"]

        missing = await ac.post(
            "/itineraries/claim/does-not-exist", headers=bob_headers
        )
        assert missing.status_code == 404


@pytest.mark.asyncio
async def test_claim_own_shared_itinerary_does_not_duplicate(tmp_path):
    _use_temp_data(tmp_path)
    headers = {"Authorization": f"Bearer {create_access_token('alice')}"}

    async with AsyncClient(app=app, base_url="http://test") as ac:
        r = await ac.post(
            "/itineraries",
            json={"title": "Trip", "destinations": ["d1"]},
            headers=headers,
        )
        itin_id = r.json()["id"]
        share = await ac.post(f"/itineraries/{itin_id}/share", headers=headers)
        share_token = share.json()["share_token"]

        claimed = await ac.post(f"/itineraries/claim/{share_token}", headers=headers)
        assert claimed.status_code == 200
        assert claimed.json()["id"] == itin_id

        alice_list = await ac.get("/itineraries", headers=headers)
        assert len(alice_list.json()) == 1
