import httpx
import pytest

from app import amenities


class _FakeResponse:
    def __init__(self, status_code, json_data=None):
        self.status_code = status_code
        self._json = json_data or {}

    def json(self):
        return self._json


_OVERPASS_OK = {
    "elements": [
        {
            "type": "node",
            "id": 1,
            "lat": 3.87,
            "lon": 11.52,
            "tags": {"amenity": "hospital", "name": "Test Hospital"},
        },
        {
            "type": "way",
            "id": 2,
            "center": {"lat": 3.88, "lon": 11.53},
            "tags": {"amenity": "pharmacy"},
        },
    ]
}


@pytest.fixture(autouse=True)
def _clear_cache():
    amenities._cache.clear()
    yield
    amenities._cache.clear()


@pytest.mark.asyncio
async def test_get_amenities_normalizes_direct_and_center_coordinates(monkeypatch):
    async def fake_post(self, url, data=None, headers=None):
        return _FakeResponse(200, _OVERPASS_OK)

    monkeypatch.setattr(httpx.AsyncClient, "post", fake_post)

    results = await amenities.get_amenities(3.87, 11.52, 1500, ["hospital", "pharmacy"])
    assert len(results) == 2
    hospital = next(r for r in results if r["category"] == "hospital")
    assert hospital["name"] == "Test Hospital"
    assert hospital["lat"] == 3.87 and hospital["lon"] == 11.52
    pharmacy = next(r for r in results if r["category"] == "pharmacy")
    # No name tag - falls back to the category's display label rather than
    # being dropped, since an unnamed pharmacy is still worth a dot.
    assert pharmacy["name"] == "Pharmacy"
    assert pharmacy["lat"] == 3.88 and pharmacy["lon"] == 11.53


@pytest.mark.asyncio
async def test_get_amenities_retries_on_rate_limit_then_succeeds(monkeypatch):
    monkeypatch.setattr(amenities, "_RETRY_DELAYS", (0, 0))
    calls = {"count": 0}

    async def fake_post(self, url, data=None, headers=None):
        calls["count"] += 1
        if calls["count"] == 1:
            return _FakeResponse(429)
        return _FakeResponse(200, _OVERPASS_OK)

    monkeypatch.setattr(httpx.AsyncClient, "post", fake_post)

    # The fake response isn't filtered by the requested category (a real
    # Overpass query does that server-side) - it always returns both
    # elements in _OVERPASS_OK regardless of what was asked for, since this
    # test is about retry behavior, not category filtering.
    results = await amenities.get_amenities(3.87, 11.52, 1500, ["hospital"])
    assert calls["count"] == 2
    assert len(results) == 2


@pytest.mark.asyncio
async def test_get_amenities_raises_after_retries_exhausted(monkeypatch):
    monkeypatch.setattr(amenities, "_RETRY_DELAYS", (0, 0))

    async def fake_post(self, url, data=None, headers=None):
        return _FakeResponse(503)

    monkeypatch.setattr(httpx.AsyncClient, "post", fake_post)

    with pytest.raises(amenities.AmenitiesRequestError):
        await amenities.get_amenities(3.87, 11.52, 1500, ["hospital"])


@pytest.mark.asyncio
async def test_get_amenities_uses_cache_on_second_call_within_ttl(monkeypatch):
    calls = {"count": 0}

    async def fake_post(self, url, data=None, headers=None):
        calls["count"] += 1
        return _FakeResponse(200, _OVERPASS_OK)

    monkeypatch.setattr(httpx.AsyncClient, "post", fake_post)

    await amenities.get_amenities(3.87001, 11.52001, 1500, ["hospital"])
    # Rounds to the same cache key (3 decimals ~ 111m) - should not hit
    # Overpass again.
    await amenities.get_amenities(3.87002, 11.52002, 1500, ["hospital"])
    assert calls["count"] == 1


@pytest.mark.asyncio
async def test_get_amenities_cache_key_varies_by_categories(monkeypatch):
    calls = {"count": 0}

    async def fake_post(self, url, data=None, headers=None):
        calls["count"] += 1
        return _FakeResponse(200, _OVERPASS_OK)

    monkeypatch.setattr(httpx.AsyncClient, "post", fake_post)

    await amenities.get_amenities(3.87, 11.52, 1500, ["hospital"])
    await amenities.get_amenities(3.87, 11.52, 1500, ["pharmacy"])
    assert calls["count"] == 2


def test_normalize_skips_elements_with_no_recognized_category():
    el = {"type": "node", "id": 9, "lat": 3.8, "lon": 11.5, "tags": {"shop": "bakery"}}
    assert amenities._normalize(el) is None


def test_normalize_skips_elements_with_no_coordinates():
    el = {"type": "node", "id": 9, "tags": {"amenity": "hospital", "name": "No Coords"}}
    assert amenities._normalize(el) is None


def test_category_for_merges_bank_and_atm():
    assert amenities._category_for({"amenity": "bank"}) == "bank_atm"
    assert amenities._category_for({"amenity": "atm"}) == "bank_atm"
