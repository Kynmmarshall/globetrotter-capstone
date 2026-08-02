import httpx
import pytest

from app import routing


class _FakeResponse:
    def __init__(self, status_code, json_data=None):
        self.status_code = status_code
        self._json = json_data or {}

    def raise_for_status(self):
        if self.status_code >= 400:
            raise httpx.HTTPError(f"status {self.status_code}")

    def json(self):
        return self._json


_GEOJSON_OK = {
    "features": [
        {
            "geometry": {"coordinates": [[11.5, 3.8], [11.6, 3.9]]},
            "properties": {"summary": {"distance": 1000.0, "duration": 120.0}},
        }
    ]
}


@pytest.mark.asyncio
async def test_get_route_retries_on_rate_limit_then_succeeds(monkeypatch):
    monkeypatch.setattr(routing, "ORS_API_KEY", "test-key")
    monkeypatch.setattr(routing, "_RETRY_DELAYS", (0, 0))

    calls = {"count": 0}

    async def fake_post(self, url, headers=None, json=None):
        calls["count"] += 1
        if calls["count"] == 1:
            return _FakeResponse(429)
        return _FakeResponse(200, _GEOJSON_OK)

    monkeypatch.setattr(httpx.AsyncClient, "post", fake_post)

    result = await routing.get_route([(3.8, 11.5), (3.9, 11.6)])
    assert calls["count"] == 2
    assert result["distance_meters"] == 1000.0
    assert result["duration_seconds"] == 120.0


@pytest.mark.asyncio
async def test_get_route_gives_up_after_retries_exhausted(monkeypatch):
    monkeypatch.setattr(routing, "ORS_API_KEY", "test-key")
    monkeypatch.setattr(routing, "_RETRY_DELAYS", (0, 0))

    calls = {"count": 0}

    async def fake_post(self, url, headers=None, json=None):
        calls["count"] += 1
        return _FakeResponse(503)

    monkeypatch.setattr(httpx.AsyncClient, "post", fake_post)

    with pytest.raises(routing.RoutingRequestError):
        await routing.get_route([(3.8, 11.5), (3.9, 11.6)])
    # Two retries plus the final attempt.
    assert calls["count"] == 3


@pytest.mark.asyncio
async def test_get_route_fails_fast_on_non_retryable_status(monkeypatch):
    monkeypatch.setattr(routing, "ORS_API_KEY", "test-key")
    monkeypatch.setattr(routing, "_RETRY_DELAYS", (0, 0))

    calls = {"count": 0}

    async def fake_post(self, url, headers=None, json=None):
        calls["count"] += 1
        return _FakeResponse(400)

    monkeypatch.setattr(httpx.AsyncClient, "post", fake_post)

    with pytest.raises(routing.RoutingRequestError):
        await routing.get_route([(3.8, 11.5), (3.9, 11.6)])
    # 400 isn't in _RETRYABLE_STATUSES, so it should raise on the first
    # attempt rather than burning through every retry slot.
    assert calls["count"] == 1


@pytest.mark.asyncio
async def test_get_route_not_configured_without_api_key(monkeypatch):
    monkeypatch.setattr(routing, "ORS_API_KEY", None)
    with pytest.raises(routing.RoutingNotConfiguredError):
        await routing.get_route([(3.8, 11.5), (3.9, 11.6)])


@pytest.mark.asyncio
async def test_get_route_requires_two_waypoints(monkeypatch):
    monkeypatch.setattr(routing, "ORS_API_KEY", "test-key")
    with pytest.raises(routing.RoutingRequestError):
        await routing.get_route([(3.8, 11.5)])
