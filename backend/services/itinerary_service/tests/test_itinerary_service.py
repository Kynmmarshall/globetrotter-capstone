import os

import pytest
from httpx import AsyncClient

from app.main import app
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
