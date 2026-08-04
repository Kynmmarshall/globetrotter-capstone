import json
import os
from datetime import datetime, timedelta, timezone

import pytest
from httpx import AsyncClient

from app.main import app
from app import clients, email_util


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
async def test_password_reset_full_flow(tmp_path, monkeypatch):
    _use_temp_data(tmp_path)
    sent = {}

    def fake_send(to_email, code):
        sent["email"] = to_email
        sent["code"] = code

    monkeypatch.setattr(email_util, "send_password_reset_code", fake_send)

    async with AsyncClient(app=app, base_url="http://test") as ac:
        await ac.post(
            "/register",
            json={"username": "erin", "password": "old-secret", "email": "erin@example.com"},
        )

        r1 = await ac.post("/auth/request-password-reset", json={"identifier": "erin"})
        assert r1.status_code == 200
        assert sent["email"] == "erin@example.com"
        code = sent["code"]
        assert len(code) == 6

        r2 = await ac.post(
            "/auth/reset-password",
            json={"identifier": "erin", "code": code, "new_password": "new-secret"},
        )
        assert r2.status_code == 200

        # Old password no longer works, new one does.
        bad_login = await ac.post("/login", json={"username": "erin", "password": "old-secret"})
        assert bad_login.status_code == 401
        good_login = await ac.post("/login", json={"username": "erin", "password": "new-secret"})
        assert good_login.status_code == 200

        # The code is single-use - reusing it fails even with the right value.
        reuse = await ac.post(
            "/auth/reset-password",
            json={"identifier": "erin", "code": code, "new_password": "another-secret"},
        )
        assert reuse.status_code == 400


@pytest.mark.asyncio
async def test_password_reset_request_never_reveals_account_existence(tmp_path, monkeypatch):
    _use_temp_data(tmp_path)
    calls = []
    monkeypatch.setattr(
        email_util, "send_password_reset_code", lambda *a: calls.append(a)
    )

    async with AsyncClient(app=app, base_url="http://test") as ac:
        await ac.post(
            "/register",
            json={"username": "frank", "password": "secret", "email": "frank@example.com"},
        )

        real = await ac.post("/auth/request-password-reset", json={"identifier": "frank"})
        fake = await ac.post(
            "/auth/request-password-reset", json={"identifier": "nobody-registered"}
        )
        # Same status and body shape either way - only one of them actually
        # queued an email.
        assert real.status_code == fake.status_code == 200
        assert real.json() == fake.json()
        assert len(calls) == 1


@pytest.mark.asyncio
async def test_password_reset_rejects_wrong_or_expired_code(tmp_path, monkeypatch):
    _use_temp_data(tmp_path)
    sent = {}
    monkeypatch.setattr(
        email_util,
        "send_password_reset_code",
        lambda to_email, code: sent.update(email=to_email, code=code),
    )

    async with AsyncClient(app=app, base_url="http://test") as ac:
        await ac.post(
            "/register",
            json={"username": "gina", "password": "secret", "email": "gina@example.com"},
        )
        await ac.post("/auth/request-password-reset", json={"identifier": "gina"})

        wrong_code = await ac.post(
            "/auth/reset-password",
            json={"identifier": "gina", "code": "000000", "new_password": "new-secret"},
        )
        assert wrong_code.status_code == 400

        # Back-date the stored reset's expiry directly in the data file to
        # simulate the 30-minute window having passed, without waiting for
        # real time to elapse.
        data_path = os.environ["USER_SERVICE_DATA_PATH"]
        data = json.loads(open(data_path, encoding="utf-8").read())
        expired = (datetime.now(timezone.utc) - timedelta(minutes=1)).isoformat()
        data["password_resets"][0]["expires_at"] = expired
        open(data_path, "w", encoding="utf-8").write(json.dumps(data))

        expired_code = await ac.post(
            "/auth/reset-password",
            json={"identifier": "gina", "code": sent["code"], "new_password": "new-secret"},
        )
        assert expired_code.status_code == 400


@pytest.mark.asyncio
async def test_moderation_notification_flow(tmp_path, monkeypatch):
    _use_temp_data(tmp_path)

    async def no_itineraries(username):
        return []

    monkeypatch.setattr(clients, "get_itineraries_for_user", no_itineraries)

    async with AsyncClient(app=app, base_url="http://test") as ac:
        r = await ac.post("/register", json={"username": "hank", "password": "secret"})
        token = r.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # Simulates what events_consumer.py does when a
        # "destination.approved" event arrives for hank's submission.
        from app import crud

        crud.create_notification(
            username="hank",
            type_="moderation",
            title_key="notificationDestinationStatusTitle",
            body_key="notificationDestinationApprovedBody",
            body_args={"name": "Mont Febe"},
            destination_id="dest-1",
        )

        listed = await ac.get("/me/notifications", headers=headers)
        assert listed.status_code == 200
        items = listed.json()
        assert len(items) == 1
        assert items[0]["type"] == "moderation"
        assert items[0]["body_args"] == {"name": "Mont Febe"}
        assert items[0]["read"] is False

        notification_id = items[0]["id"]
        marked = await ac.post(
            f"/me/notifications/{notification_id}/read", headers=headers
        )
        assert marked.status_code == 200

        refetched = await ac.get("/me/notifications", headers=headers)
        assert refetched.json()[0]["read"] is True


@pytest.mark.asyncio
async def test_trip_reminder_notification_is_computed_from_itineraries(
    tmp_path, monkeypatch
):
    _use_temp_data(tmp_path)
    from datetime import date, timedelta as td

    upcoming_start = (date.today() + td(days=1)).isoformat()

    async def one_upcoming_itinerary(username):
        return [
            {
                "id": "itin-1",
                "user": username,
                "title": "Weekend in Yaoundé",
                "destinations": [],
                "start_date": upcoming_start,
                "end_date": upcoming_start,
            }
        ]

    monkeypatch.setattr(clients, "get_itineraries_for_user", one_upcoming_itinerary)

    async with AsyncClient(app=app, base_url="http://test") as ac:
        r = await ac.post("/register", json={"username": "iris", "password": "secret"})
        token = r.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        listed = await ac.get("/me/notifications", headers=headers)
        assert listed.status_code == 200
        items = listed.json()
        assert len(items) == 1
        assert items[0]["type"] == "trip_reminder"
        assert items[0]["id"] == "trip-itin-1"
        assert items[0]["body_args"]["title"] == "Weekend in Yaoundé"

        # A reminder has no row of its own, but the read set should still
        # let it be dismissed by its synthetic id.
        marked = await ac.post("/me/notifications/trip-itin-1/read", headers=headers)
        assert marked.status_code == 200

        refetched = await ac.get("/me/notifications", headers=headers)
        assert refetched.json()[0]["read"] is True


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
