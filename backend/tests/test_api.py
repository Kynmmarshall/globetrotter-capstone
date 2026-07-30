import pytest
from httpx import AsyncClient
from app.main import app
from app import ai


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
