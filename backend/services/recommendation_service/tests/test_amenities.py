import json

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
def _reset_state(tmp_path, monkeypatch):
    # Isolates every test from both the module-level in-memory cache and
    # the real on-disk cache file.
    amenities._all_amenities = None
    monkeypatch.setattr(amenities, "_cache_file_path", lambda: tmp_path / "amenities_cache.json")
    yield
    amenities._all_amenities = None


@pytest.mark.asyncio
async def test_refresh_all_populates_memory_and_disk_on_success(monkeypatch):
    async def fake_post(self, url, data=None, headers=None):
        return _FakeResponse(200, _OVERPASS_OK)

    monkeypatch.setattr(httpx.AsyncClient, "post", fake_post)

    ok = await amenities._refresh_all()
    assert ok is True
    assert len(amenities._all_amenities) == 2

    on_disk = json.loads(amenities._cache_file_path().read_text(encoding="utf-8"))
    assert len(on_disk["results"]) == 2
    assert "fetched_at" in on_disk


@pytest.mark.asyncio
async def test_refresh_all_keeps_last_known_data_on_failure(monkeypatch):
    monkeypatch.setattr(amenities, "_RETRY_DELAYS", (0, 0))
    amenities._all_amenities = [{"id": "node/1", "name": "Old", "category": "hospital", "lat": 1, "lon": 1}]

    async def fake_post(self, url, data=None, headers=None):
        return _FakeResponse(503)

    monkeypatch.setattr(httpx.AsyncClient, "post", fake_post)

    ok = await amenities._refresh_all()
    assert ok is False
    # Untouched - a failed refresh must never wipe out already-good data.
    assert amenities._all_amenities[0]["name"] == "Old"


@pytest.mark.asyncio
async def test_get_amenities_loads_from_disk_when_memory_empty(monkeypatch):
    amenities._write_disk_cache(
        [{"id": "node/1", "name": "From Disk", "category": "hospital", "lat": 1, "lon": 1}]
    )
    assert amenities._all_amenities is None  # sanity: nothing in memory yet

    async def fake_post(self, url, data=None, headers=None):
        raise AssertionError("should not hit the network - disk cache should satisfy this")

    monkeypatch.setattr(httpx.AsyncClient, "post", fake_post)

    results = await amenities.get_amenities(["hospital"])
    assert results[0]["name"] == "From Disk"


@pytest.mark.asyncio
async def test_get_amenities_attempts_live_fetch_on_true_cold_start(monkeypatch):
    # Nothing in memory, nothing on disk.
    async def fake_post(self, url, data=None, headers=None):
        return _FakeResponse(200, _OVERPASS_OK)

    monkeypatch.setattr(httpx.AsyncClient, "post", fake_post)

    results = await amenities.get_amenities(["hospital", "pharmacy"])
    assert len(results) == 2


@pytest.mark.asyncio
async def test_get_amenities_returns_empty_when_cold_start_fetch_also_fails(monkeypatch):
    monkeypatch.setattr(amenities, "_RETRY_DELAYS", (0, 0))

    async def fake_post(self, url, data=None, headers=None):
        return _FakeResponse(503)

    monkeypatch.setattr(httpx.AsyncClient, "post", fake_post)

    results = await amenities.get_amenities(["hospital"])
    assert results == []


@pytest.mark.asyncio
async def test_get_amenities_filters_by_requested_categories(monkeypatch):
    async def fake_post(self, url, data=None, headers=None):
        return _FakeResponse(200, _OVERPASS_OK)

    monkeypatch.setattr(httpx.AsyncClient, "post", fake_post)

    results = await amenities.get_amenities(["pharmacy"])
    assert len(results) == 1
    assert results[0]["category"] == "pharmacy"


@pytest.mark.asyncio
async def test_get_amenities_falls_back_to_second_host_when_first_is_down(monkeypatch):
    monkeypatch.setattr(amenities, "_RETRY_DELAYS", (0, 0))
    calls = []

    async def fake_post(self, url, data=None, headers=None):
        calls.append(url)
        if url == amenities.OVERPASS_URLS[0]:
            return _FakeResponse(504)
        return _FakeResponse(200, _OVERPASS_OK)

    monkeypatch.setattr(httpx.AsyncClient, "post", fake_post)

    results = await amenities.get_amenities(["hospital", "pharmacy"])
    assert len(results) == 2
    # Exhausted every retry against the first host before trying the second.
    assert calls.count(amenities.OVERPASS_URLS[0]) == len(amenities._RETRY_DELAYS) + 1
    assert calls[-1] == amenities.OVERPASS_URLS[1]


def test_build_query_covers_the_full_yaounde_bbox_and_every_category():
    query = amenities._build_query()
    bbox = ",".join(str(v) for v in amenities.YAOUNDE_BBOX)
    assert bbox in query
    assert "around:" not in query
    for tag in amenities.CATEGORY_TAGS.values():
        assert tag in query


def test_normalize_skips_elements_with_no_recognized_category():
    el = {"type": "node", "id": 9, "lat": 3.8, "lon": 11.5, "tags": {"shop": "bakery"}}
    assert amenities._normalize(el) is None


def test_normalize_skips_elements_with_no_coordinates():
    el = {"type": "node", "id": 9, "tags": {"amenity": "hospital", "name": "No Coords"}}
    assert amenities._normalize(el) is None


def test_category_for_merges_bank_and_atm():
    assert amenities._category_for({"amenity": "bank"}) == "bank_atm"
    assert amenities._category_for({"amenity": "atm"}) == "bank_atm"


def test_read_disk_cache_returns_none_when_file_missing():
    assert amenities._read_disk_cache() is None


def test_read_disk_cache_returns_none_on_corrupt_file():
    path = amenities._cache_file_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("not valid json", encoding="utf-8")
    assert amenities._read_disk_cache() is None
