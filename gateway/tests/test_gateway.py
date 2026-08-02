import os

import httpx
import pytest
from httpx import AsyncClient

from app.proxy import resolve_target, USER_SERVICE_URL, ITINERARY_SERVICE_URL, RECOMMENDATION_SERVICE_URL


def test_routing_table_prefers_specific_me_routes_over_generic():
    assert resolve_target("/me/submissions") == RECOMMENDATION_SERVICE_URL
    assert resolve_target("/me/favorites") == USER_SERVICE_URL
    assert resolve_target("/me/favorites/d1") == USER_SERVICE_URL
    assert resolve_target("/me") == USER_SERVICE_URL
    assert resolve_target("/me/interests") == USER_SERVICE_URL


def test_routing_table_covers_every_service():
    assert resolve_target("/register") == USER_SERVICE_URL
    assert resolve_target("/itineraries") == ITINERARY_SERVICE_URL
    assert resolve_target("/itineraries/abc-123") == ITINERARY_SERVICE_URL
    assert resolve_target("/destinations") == RECOMMENDATION_SERVICE_URL
    assert resolve_target("/destinations/d1/comments") == RECOMMENDATION_SERVICE_URL
    assert resolve_target("/admin/destinations") == RECOMMENDATION_SERVICE_URL
    assert resolve_target("/ai/chat") == RECOMMENDATION_SERVICE_URL
    assert resolve_target("/route") == RECOMMENDATION_SERVICE_URL


def test_unknown_path_has_no_target():
    assert resolve_target("/") is None
    assert resolve_target("/some/random/page") is None


@pytest.mark.asyncio
async def test_internal_paths_are_never_proxied():
    from app.main import app

    async with AsyncClient(app=app, base_url="http://test") as ac:
        r = await ac.get("/internal/users/alice")
        assert r.status_code == 404


@pytest.mark.asyncio
async def test_unmatched_get_falls_back_to_website_static_files(tmp_path, monkeypatch):
    website_dir = tmp_path / "website"
    website_dir.mkdir()
    (website_dir / "index.html").write_text("<html>hello</html>")
    (website_dir / "downloads").mkdir()
    (website_dir / "webapp").mkdir()

    monkeypatch.setenv("WEBSITE_DIR", str(website_dir))
    # Reload so module-level _website_dir picks up the env var.
    import importlib
    from app import main as gateway_main
    importlib.reload(gateway_main)

    async with AsyncClient(app=gateway_main.app, base_url="http://test") as ac:
        r = await ac.get("/")
        assert r.status_code == 200
        assert "hello" in r.text

        r2 = await ac.get("/does-not-exist.html")
        assert r2.status_code == 404


@pytest.mark.asyncio
async def test_proxy_forwards_to_resolved_service(monkeypatch):
    from app import proxy as gateway_proxy
    from app.main import app

    class FakeResponse:
        status_code = 200
        headers = {"content-type": "application/json"}
        content = b'{"ok": true}'

    class FakeAsyncClient:
        def __init__(self, *args, **kwargs):
            pass

        async def __aenter__(self):
            return self

        async def __aexit__(self, *exc_info):
            return False

        async def request(self, method, url, params=None, headers=None, content=None):
            assert url == f"{RECOMMENDATION_SERVICE_URL}/destinations"
            assert method == "GET"
            return FakeResponse()

    # Patches only the httpx.AsyncClient reference the Gateway's own proxy
    # module sees - the outer test client below (a separate AsyncClient,
    # talking to the app over httpx's ASGI transport) is unaffected.
    monkeypatch.setattr(gateway_proxy.httpx, "AsyncClient", FakeAsyncClient)

    async with AsyncClient(app=app, base_url="http://test") as ac:
        r = await ac.get("/destinations")
        assert r.status_code == 200
        assert r.json() == {"ok": True}
