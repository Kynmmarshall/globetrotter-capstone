import pytest
from httpx import AsyncClient
from app import main
from app.main import app
from app import ai, auth, google_auth


@pytest.mark.asyncio
async def test_register_and_login(tmp_path):
    # create a temporary data file so tests run in isolation
    data_file = tmp_path / "data.json"
    data_file.write_text('{"users": [], "itineraries": [], "destinations": []}')
    import os
    os.environ["GLOBETROTTER_DATA_PATH"] = str(data_file)

    async with AsyncClient(app=app, base_url="http://test") as ac:
        r = await ac.post("/register", json={"username": "alice", "password": "secret"})
        assert r.status_code == 200
        token = r.json().get("access_token")
        assert token

        r2 = await ac.post("/login", json={"username": "alice", "password": "secret"})
        assert r2.status_code == 200

        # destinations (no auth)
        r3 = await ac.get("/destinations")
        assert r3.status_code == 200

        # recommendations (requires auth)
        headers = {"Authorization": f"Bearer {token}"}
        r4 = await ac.get("/recommendations", headers=headers)
        assert r4.status_code == 200

        # create itinerary
        itin = {"title": "My Trip", "destinations": ["d1","d2"]}
        r5 = await ac.post("/itineraries", json=itin, headers=headers)
        assert r5.status_code == 200

        # list itineraries
        r6 = await ac.get("/itineraries", headers=headers)
        assert r6.status_code == 200
        assert isinstance(r6.json(), list)


@pytest.mark.asyncio
async def test_ai_chat_not_configured(tmp_path, monkeypatch):
    data_file = tmp_path / "data.json"
    data_file.write_text('{"users": [], "itineraries": [], "destinations": []}')
    import os
    os.environ["GLOBETROTTER_DATA_PATH"] = str(data_file)
    monkeypatch.setattr(ai, "GEMINI_API_KEY", None)

    async with AsyncClient(app=app, base_url="http://test") as ac:
        r = await ac.post("/register", json={"username": "bob", "password": "secret"})
        token = r.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        r2 = await ac.post("/ai/chat", json={"messages": [{"role": "user", "content": "hi"}]}, headers=headers)
        assert r2.status_code == 503


@pytest.mark.asyncio
async def test_ai_chat_and_explain(tmp_path, monkeypatch):
    data_file = tmp_path / "data.json"
    data_file.write_text(
        '{"users": [], "itineraries": [], "destinations": '
        '[{"id": "d1", "name": "Monument de la R\\u00e9union", "country": "Cameroon", '
        '"tags": ["history"], "location": "Yaound\\u00e9"}]}'
    )
    import os
    os.environ["GLOBETROTTER_DATA_PATH"] = str(data_file)
    monkeypatch.setattr(ai, "GEMINI_API_KEY", "fake-key")

    async def fake_generate(contents, system_text):
        return "This is a real, grounded answer."

    monkeypatch.setattr(ai, "_generate", fake_generate)

    async with AsyncClient(app=app, base_url="http://test") as ac:
        r = await ac.post("/register", json={"username": "carol", "password": "secret"})
        token = r.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        r2 = await ac.post("/ai/chat", json={"messages": [{"role": "user", "content": "hi"}]}, headers=headers)
        assert r2.status_code == 200
        assert r2.json()["reply"] == "This is a real, grounded answer."

        r3 = await ac.post("/ai/explain/d1", headers=headers)
        assert r3.status_code == 200
        assert r3.json()["reply"]

        r4 = await ac.post("/ai/explain/does-not-exist", headers=headers)
        assert r4.status_code == 404


@pytest.mark.asyncio
async def test_google_auth_not_configured(tmp_path, monkeypatch):
    data_file = tmp_path / "data.json"
    data_file.write_text('{"users": [], "itineraries": [], "destinations": []}')
    import os
    os.environ["GLOBETROTTER_DATA_PATH"] = str(data_file)
    monkeypatch.setattr(google_auth, "GOOGLE_OAUTH_CLIENT_ID", None)

    async with AsyncClient(app=app, base_url="http://test") as ac:
        r = await ac.post("/auth/google", json={"id_token": "whatever"})
        assert r.status_code == 401


@pytest.mark.asyncio
async def test_google_auth_creates_and_reuses_user(tmp_path, monkeypatch):
    data_file = tmp_path / "data.json"
    data_file.write_text('{"users": [], "itineraries": [], "destinations": []}')
    import os
    os.environ["GLOBETROTTER_DATA_PATH"] = str(data_file)
    monkeypatch.setattr(google_auth, "GOOGLE_OAUTH_CLIENT_ID", "test-client-id")

    async def fake_verify(id_token):
        return {
            "sub": "google-sub-123",
            "email": "dora@example.com",
            "name": "Dora Explorer",
            "aud": "test-client-id",
            "iss": "accounts.google.com",
            "email_verified": "true",
        }

    monkeypatch.setattr(google_auth, "verify_id_token", fake_verify)

    async with AsyncClient(app=app, base_url="http://test") as ac:
        r1 = await ac.post("/auth/google", json={"id_token": "fake"})
        assert r1.status_code == 200
        token1 = r1.json()["access_token"]

        headers = {"Authorization": f"Bearer {token1}"}
        r2 = await ac.get("/me", headers=headers)
        assert r2.status_code == 200
        assert r2.json()["username"] == "dora"
        assert r2.json()["email"] == "dora@example.com"

        # Signing in again with the same Google account should reuse the
        # same user, not create a second "dora2" account.
        r3 = await ac.post("/auth/google", json={"id_token": "fake"})
        assert r3.status_code == 200
        headers3 = {"Authorization": f"Bearer {r3.json()['access_token']}"}
        r4 = await ac.get("/me", headers=headers3)
        assert r4.json()["username"] == "dora"


@pytest.mark.asyncio
async def test_google_only_account_rejects_password_login(tmp_path, monkeypatch):
    data_file = tmp_path / "data.json"
    data_file.write_text('{"users": [], "itineraries": [], "destinations": []}')
    import os
    os.environ["GLOBETROTTER_DATA_PATH"] = str(data_file)
    monkeypatch.setattr(google_auth, "GOOGLE_OAUTH_CLIENT_ID", "test-client-id")

    async def fake_verify(id_token):
        return {
            "sub": "google-sub-456",
            "email": "bob@example.com",
            "name": "Bob",
            "aud": "test-client-id",
            "iss": "accounts.google.com",
            "email_verified": "true",
        }

    monkeypatch.setattr(google_auth, "verify_id_token", fake_verify)

    async with AsyncClient(app=app, base_url="http://test") as ac:
        await ac.post("/auth/google", json={"id_token": "fake"})
        r = await ac.post("/login", json={"username": "bob", "password": "anything"})
        assert r.status_code == 401


def test_access_token_defaults_to_one_week():
    token = auth.create_access_token("alice")
    payload = auth.decode_token(token)
    assert payload["exp"] - payload["iat"] == 7 * 24 * 3600


@pytest.mark.asyncio
async def test_avatar_upload_and_serving(tmp_path, monkeypatch):
    data_file = tmp_path / "data.json"
    data_file.write_text('{"users": [], "itineraries": [], "destinations": []}')
    import os
    os.environ["GLOBETROTTER_DATA_PATH"] = str(data_file)

    avatars_dir = tmp_path / "avatars"
    avatars_dir.mkdir()
    monkeypatch.setattr(main, "_avatars_dir", avatars_dir)

    async with AsyncClient(app=app, base_url="http://test") as ac:
        r = await ac.post("/register", json={"username": "eve", "password": "secret"})
        token = r.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        r2 = await ac.post(
            "/me/avatar",
            headers=headers,
            files={"file": ("avatar.png", b"\x89PNG\r\n fake bytes", "image/png")},
        )
        assert r2.status_code == 200
        avatar_url = r2.json()["avatar_url"]
        assert avatar_url.startswith("/static/avatars/")
        saved_files = list(avatars_dir.iterdir())
        assert len(saved_files) == 1

        r3 = await ac.get("/me", headers=headers)
        assert r3.json()["avatar_url"] == avatar_url


@pytest.mark.asyncio
async def test_avatar_upload_rejects_bad_type(tmp_path, monkeypatch):
    data_file = tmp_path / "data.json"
    data_file.write_text('{"users": [], "itineraries": [], "destinations": []}')
    import os
    os.environ["GLOBETROTTER_DATA_PATH"] = str(data_file)

    avatars_dir = tmp_path / "avatars"
    avatars_dir.mkdir()
    monkeypatch.setattr(main, "_avatars_dir", avatars_dir)

    async with AsyncClient(app=app, base_url="http://test") as ac:
        r = await ac.post("/register", json={"username": "frank", "password": "secret"})
        token = r.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        r2 = await ac.post(
            "/me/avatar",
            headers=headers,
            files={"file": ("notes.txt", b"hello", "text/plain")},
        )
        assert r2.status_code == 400
        assert not list(avatars_dir.iterdir())
