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
    monkeypatch.setattr(ai, "GROQ_API_KEY", None)

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
    monkeypatch.setattr(ai, "GROQ_API_KEY", "fake-key")

    async def fake_generate(messages):
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


@pytest.mark.asyncio
async def test_ai_explain_is_cached(tmp_path, monkeypatch):
    data_file = tmp_path / "data.json"
    data_file.write_text(
        '{"users": [], "itineraries": [], "destinations": '
        '[{"id": "d1", "name": "Monument de la R\\u00e9union", "country": "Cameroon", '
        '"tags": ["history"], "location": "Yaound\\u00e9"}]}'
    )
    import os
    os.environ["GLOBETROTTER_DATA_PATH"] = str(data_file)
    monkeypatch.setattr(ai, "GROQ_API_KEY", "fake-key")

    call_count = 0

    async def fake_explain(destination):
        nonlocal call_count
        call_count += 1
        return f"Explanation number {call_count}"

    monkeypatch.setattr(ai, "explain_destination", fake_explain)

    async with AsyncClient(app=app, base_url="http://test") as ac:
        r = await ac.post("/register", json={"username": "dave", "password": "secret"})
        headers = {"Authorization": f"Bearer {r.json()['access_token']}"}

        r1 = await ac.post("/ai/explain/d1", headers=headers)
        assert r1.status_code == 200
        assert r1.json()["reply"] == "Explanation number 1"

        # Second call (even from a different user) must reuse the cached
        # explanation rather than hitting Groq again.
        r_bob = await ac.post("/register", json={"username": "bob2", "password": "secret"})
        headers_bob = {"Authorization": f"Bearer {r_bob.json()['access_token']}"}
        r2 = await ac.post("/ai/explain/d1", headers=headers_bob)
        assert r2.status_code == 200
        assert r2.json()["reply"] == "Explanation number 1"
        assert call_count == 1

        # The cache is actually persisted on the destination record.
        import json
        data = json.loads(data_file.read_text())
        assert data["destinations"][0]["ai_explanation"] == "Explanation number 1"

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


def _comments_fixture(tmp_path):
    import json
    data_file = tmp_path / "data.json"
    data_file.write_text(json.dumps({
        "users": [],
        "itineraries": [],
        "destinations": [{"id": "d1", "name": "Test Spot", "country": "Cameroon", "tags": []}],
    }))
    import os
    os.environ["GLOBETROTTER_DATA_PATH"] = str(data_file)


@pytest.mark.asyncio
async def test_comments_missing_destination_404(tmp_path):
    _comments_fixture(tmp_path)
    async with AsyncClient(app=app, base_url="http://test") as ac:
        r = await ac.post("/register", json={"username": "alice", "password": "secret"})
        headers = {"Authorization": f"Bearer {r.json()['access_token']}"}
        r2 = await ac.get("/destinations/does-not-exist/comments", headers=headers)
        assert r2.status_code == 404


@pytest.mark.asyncio
async def test_post_comment_reply_and_nesting(tmp_path):
    _comments_fixture(tmp_path)
    async with AsyncClient(app=app, base_url="http://test") as ac:
        r = await ac.post("/register", json={"username": "alice", "password": "secret"})
        headers_a = {"Authorization": f"Bearer {r.json()['access_token']}"}
        r = await ac.post("/register", json={"username": "bob", "password": "secret"})
        headers_b = {"Authorization": f"Bearer {r.json()['access_token']}"}

        # empty text rejected
        r_empty = await ac.post("/destinations/d1/comments", json={"text": "   "}, headers=headers_a)
        assert r_empty.status_code == 400

        r1 = await ac.post("/destinations/d1/comments", json={"text": "Great spot!"}, headers=headers_a)
        assert r1.status_code == 200
        top = r1.json()
        assert top["username"] == "alice"
        assert top["score"] == 0
        assert top["replies"] == []

        r2 = await ac.post(
            "/destinations/d1/comments",
            json={"text": "Agreed!", "parent_id": top["id"]},
            headers=headers_b,
        )
        assert r2.status_code == 200
        reply = r2.json()
        assert reply["parent_id"] == top["id"]

        r3 = await ac.post(
            "/destinations/d1/comments",
            json={"text": "Nested reply", "parent_id": reply["id"]},
            headers=headers_a,
        )
        assert r3.status_code == 200

        # a reply to a nonexistent comment 400s
        r4 = await ac.post(
            "/destinations/d1/comments",
            json={"text": "orphan", "parent_id": "does-not-exist"},
            headers=headers_a,
        )
        assert r4.status_code == 400

        listed = await ac.get("/destinations/d1/comments", headers=headers_a)
        tree = listed.json()
        assert len(tree) == 1
        assert tree[0]["text"] == "Great spot!"
        assert len(tree[0]["replies"]) == 1
        assert tree[0]["replies"][0]["text"] == "Agreed!"
        assert len(tree[0]["replies"][0]["replies"]) == 1
        assert tree[0]["replies"][0]["replies"][0]["text"] == "Nested reply"


@pytest.mark.asyncio
async def test_vote_comment_toggle_and_score(tmp_path):
    _comments_fixture(tmp_path)
    async with AsyncClient(app=app, base_url="http://test") as ac:
        r = await ac.post("/register", json={"username": "alice", "password": "secret"})
        headers_a = {"Authorization": f"Bearer {r.json()['access_token']}"}
        r = await ac.post("/register", json={"username": "bob", "password": "secret"})
        headers_b = {"Authorization": f"Bearer {r.json()['access_token']}"}

        r1 = await ac.post("/destinations/d1/comments", json={"text": "Great spot!"}, headers=headers_a)
        comment_id = r1.json()["id"]

        rv = await ac.post(f"/comments/{comment_id}/vote", json={"direction": "up"}, headers=headers_a)
        assert rv.status_code == 200
        assert rv.json()["score"] == 1
        assert rv.json()["user_vote"] == "up"

        rv2 = await ac.post(f"/comments/{comment_id}/vote", json={"direction": "down"}, headers=headers_b)
        assert rv2.json()["score"] == 0

        # bob viewing shows his own vote as "down", not alice's "up"
        listed = await ac.get("/destinations/d1/comments", headers=headers_b)
        assert listed.json()[0]["user_vote"] == "down"
        assert listed.json()[0]["score"] == 0

        # alice removing her vote
        rv3 = await ac.post(f"/comments/{comment_id}/vote", json={"direction": "none"}, headers=headers_a)
        assert rv3.json()["score"] == -1

        rv_bad = await ac.post(f"/comments/{comment_id}/vote", json={"direction": "sideways"}, headers=headers_a)
        assert rv_bad.status_code == 400

        rv_missing = await ac.post("/comments/does-not-exist/vote", json={"direction": "up"}, headers=headers_a)
        assert rv_missing.status_code == 404


@pytest.mark.asyncio
async def test_favorites_add_remove_list(tmp_path):
    import json
    data_file = tmp_path / "data.json"
    data_file.write_text(json.dumps({
        "users": [],
        "itineraries": [],
        "destinations": [
            {"id": "d1", "name": "Spot One", "country": "Cameroon", "tags": []},
            {"id": "d2", "name": "Spot Two", "country": "Cameroon", "tags": []},
        ],
    }))
    import os
    os.environ["GLOBETROTTER_DATA_PATH"] = str(data_file)

    async with AsyncClient(app=app, base_url="http://test") as ac:
        r = await ac.post("/register", json={"username": "alice", "password": "secret"})
        headers = {"Authorization": f"Bearer {r.json()['access_token']}"}

        # unknown destination 404s
        r0 = await ac.post("/me/favorites/does-not-exist", headers=headers)
        assert r0.status_code == 404

        r1 = await ac.post("/me/favorites/d1", headers=headers)
        assert r1.status_code == 200
        assert r1.json()["favorite_ids"] == ["d1"]

        # adding twice is idempotent, not duplicated
        r1b = await ac.post("/me/favorites/d1", headers=headers)
        assert r1b.json()["favorite_ids"] == ["d1"]

        r2 = await ac.post("/me/favorites/d2", headers=headers)
        # most-recently-favorited first
        assert r2.json()["favorite_ids"] == ["d2", "d1"]

        listed = await ac.get("/me/favorites", headers=headers)
        assert listed.status_code == 200
        assert [d["id"] for d in listed.json()] == ["d2", "d1"]

        r3 = await ac.delete("/me/favorites/d2", headers=headers)
        assert r3.status_code == 200
        assert r3.json()["favorite_ids"] == ["d1"]

        # /me reflects the same favorite_ids
        me = await ac.get("/me", headers=headers)
        assert me.json()["favorite_ids"] == ["d1"]


def _moderation_fixture(tmp_path):
    """Two destinations, and a helper to promote a user to admin."""
    import json
    data_file = tmp_path / "data.json"
    data_file.write_text(json.dumps({
        "users": [],
        "itineraries": [],
        "destinations": [
            {"id": "d1", "name": "Spot One", "country": "Cameroon", "tags": ["nature"]},
            {"id": "d2", "name": "Spot Two", "country": "Cameroon", "tags": ["food"]},
        ],
    }))
    import os
    os.environ["GLOBETROTTER_DATA_PATH"] = str(data_file)
    return data_file


def _promote_to_admin(data_file, username):
    import json
    data = json.loads(data_file.read_text(encoding="utf-8"))
    for u in data["users"]:
        if u["username"] == username:
            u["role"] = "admin"
    data_file.write_text(json.dumps(data), encoding="utf-8")


@pytest.mark.asyncio
async def test_rating_average_and_own_rating(tmp_path):
    _moderation_fixture(tmp_path)
    async with AsyncClient(app=app, base_url="http://test") as ac:
        r = await ac.post("/register", json={"username": "alice", "password": "secret"})
        headers_a = {"Authorization": f"Bearer {r.json()['access_token']}"}
        r = await ac.post("/register", json={"username": "bob", "password": "secret"})
        headers_b = {"Authorization": f"Bearer {r.json()['access_token']}"}

        # out-of-range rejected
        bad = await ac.put("/destinations/d1/rating", json={"stars": 6}, headers=headers_a)
        assert bad.status_code == 400

        r1 = await ac.put("/destinations/d1/rating", json={"stars": 5}, headers=headers_a)
        assert r1.status_code == 200
        assert r1.json()["rating_average"] == 5.0
        assert r1.json()["rating_count"] == 1
        assert r1.json()["user_rating"] == 5

        r2 = await ac.put("/destinations/d1/rating", json={"stars": 3}, headers=headers_b)
        assert r2.json()["rating_average"] == 4.0
        assert r2.json()["rating_count"] == 2

        # re-rating replaces rather than stacking
        r3 = await ac.put("/destinations/d1/rating", json={"stars": 1}, headers=headers_a)
        assert r3.json()["rating_count"] == 2
        assert r3.json()["rating_average"] == 2.0
        assert r3.json()["user_rating"] == 1

        # listing carries the aggregate + the caller's own rating
        listed = await ac.get("/destinations", headers=headers_b)
        d1 = next(d for d in listed.json() if d["id"] == "d1")
        assert d1["rating_average"] == 2.0
        assert d1["rating_count"] == 2
        assert d1["user_rating"] == 3  # bob's, not alice's

        # anonymous callers still see the average, but no personal rating
        anon = await ac.get("/destinations")
        d1_anon = next(d for d in anon.json() if d["id"] == "d1")
        assert d1_anon["rating_average"] == 2.0
        assert d1_anon["user_rating"] is None

        cleared = await ac.delete("/destinations/d1/rating", headers=headers_a)
        assert cleared.json()["rating_count"] == 1
        assert cleared.json()["user_rating"] is None

        missing = await ac.put("/destinations/nope/rating", json={"stars": 4}, headers=headers_a)
        assert missing.status_code == 404


@pytest.mark.asyncio
async def test_submission_stays_hidden_until_approved(tmp_path):
    data_file = _moderation_fixture(tmp_path)
    async with AsyncClient(app=app, base_url="http://test") as ac:
        r = await ac.post("/register", json={"username": "alice", "password": "secret"})
        headers_a = {"Authorization": f"Bearer {r.json()['access_token']}"}
        r = await ac.post("/register", json={"username": "root", "password": "secret"})
        headers_admin = {"Authorization": f"Bearer {r.json()['access_token']}"}
        _promote_to_admin(data_file, "root")

        # blank name rejected
        blank = await ac.post("/destinations/submit", json={"name": "   "}, headers=headers_a)
        assert blank.status_code == 400

        sub = await ac.post(
            "/destinations/submit",
            json={"name": "Hidden Gem", "description": "A real place", "tags": ["food"]},
            headers=headers_a,
        )
        assert sub.status_code == 200
        new_id = sub.json()["id"]
        assert sub.json()["status"] == "pending"
        assert sub.json()["submitted_by"] == "alice"

        # invisible in the public catalog, and not directly fetchable
        listed = await ac.get("/destinations")
        assert new_id not in [d["id"] for d in listed.json()]
        assert (await ac.get(f"/destinations/{new_id}")).status_code == 404

        # the submitter can still track it
        mine = await ac.get("/me/submissions", headers=headers_a)
        assert [d["id"] for d in mine.json()] == [new_id]

        # non-admins are locked out of the queue
        assert (await ac.get("/admin/destinations", headers=headers_a)).status_code == 403
        # ...and out of destructive admin actions
        assert (await ac.delete(f"/admin/destinations/{new_id}", headers=headers_a)).status_code == 403

        pending = await ac.get("/admin/destinations?status=pending", headers=headers_admin)
        assert pending.status_code == 200
        assert [d["id"] for d in pending.json()] == [new_id]

        approved = await ac.patch(
            f"/admin/destinations/{new_id}",
            json={"status": "approved"},
            headers=headers_admin,
        )
        assert approved.status_code == 200
        listed = await ac.get("/destinations")
        assert new_id in [d["id"] for d in listed.json()]


@pytest.mark.asyncio
async def test_admin_edit_create_delete(tmp_path):
    data_file = _moderation_fixture(tmp_path)
    async with AsyncClient(app=app, base_url="http://test") as ac:
        r = await ac.post("/register", json={"username": "root", "password": "secret"})
        headers_admin = {"Authorization": f"Bearer {r.json()['access_token']}"}
        _promote_to_admin(data_file, "root")
        r = await ac.post("/register", json={"username": "alice", "password": "secret"})
        headers_a = {"Authorization": f"Bearer {r.json()['access_token']}"}

        # /me exposes the role so clients can show/hide admin UI
        assert (await ac.get("/me", headers=headers_admin)).json()["role"] == "admin"
        assert (await ac.get("/me", headers=headers_a)).json().get("role") in (None, "user")

        edited = await ac.patch(
            "/admin/destinations/d1",
            json={"description": "Updated copy"},
            headers=headers_admin,
        )
        assert edited.status_code == 200
        assert edited.json()["description"] == "Updated copy"
        assert edited.json()["name"] == "Spot One"  # untouched fields survive

        bad_status = await ac.patch(
            "/admin/destinations/d1", json={"status": "sideways"}, headers=headers_admin
        )
        assert bad_status.status_code == 400

        # admin-created destinations skip the review queue
        created = await ac.post(
            "/admin/destinations",
            json={"name": "Straight To Live"},
            headers=headers_admin,
        )
        assert created.status_code == 200
        assert created.json()["status"] == "approved"
        assert created.json()["id"] in [d["id"] for d in (await ac.get("/destinations")).json()]

        # deleting cleans up dependent records
        await ac.put("/destinations/d2/rating", json={"stars": 4}, headers=headers_a)
        await ac.post("/me/favorites/d2", headers=headers_a)
        await ac.post("/destinations/d2/comments", json={"text": "nice"}, headers=headers_a)

        deleted = await ac.delete("/admin/destinations/d2", headers=headers_admin)
        assert deleted.status_code == 200
        assert "d2" not in [d["id"] for d in (await ac.get("/destinations")).json()]
        assert (await ac.get("/me/favorites", headers=headers_a)).json() == []

        import json
        data = json.loads(data_file.read_text(encoding="utf-8"))
        assert [r for r in data.get("ratings", []) if r["destination_id"] == "d2"] == []
        assert [c for c in data.get("comments", []) if c["destination_id"] == "d2"] == []

        assert (await ac.delete("/admin/destinations/nope", headers=headers_admin)).status_code == 404


@pytest.mark.asyncio
async def test_submission_image_upload_ownership(tmp_path, monkeypatch):
    data_file = _moderation_fixture(tmp_path)

    images_dir = tmp_path / "destinations_images"
    images_dir.mkdir()
    monkeypatch.setattr(main, "_destinations_images_dir", images_dir)

    async with AsyncClient(app=app, base_url="http://test") as ac:
        r = await ac.post("/register", json={"username": "alice", "password": "secret"})
        headers_a = {"Authorization": f"Bearer {r.json()['access_token']}"}
        r = await ac.post("/register", json={"username": "bob", "password": "secret"})
        headers_b = {"Authorization": f"Bearer {r.json()['access_token']}"}
        r = await ac.post("/register", json={"username": "root", "password": "secret"})
        headers_admin = {"Authorization": f"Bearer {r.json()['access_token']}"}
        _promote_to_admin(data_file, "root")

        sub = await ac.post(
            "/destinations/submit",
            json={"name": "Hidden Gem"},
            headers=headers_a,
        )
        new_id = sub.json()["id"]

        # a stranger can't attach an image to someone else's pending submission
        stolen = await ac.post(
            f"/destinations/{new_id}/image",
            headers=headers_b,
            files={"file": ("photo.png", b"\x89PNG fake bytes", "image/png")},
        )
        assert stolen.status_code == 403

        # bad content type rejected
        bad = await ac.post(
            f"/destinations/{new_id}/image",
            headers=headers_a,
            files={"file": ("notes.txt", b"hello", "text/plain")},
        )
        assert bad.status_code == 400

        # the original submitter can attach one
        uploaded = await ac.post(
            f"/destinations/{new_id}/image",
            headers=headers_a,
            files={"file": ("photo.png", b"\x89PNG fake bytes", "image/png")},
        )
        assert uploaded.status_code == 200
        assert uploaded.json()["image_url"] == f"/static/destinations/{new_id}.png"
        saved = list(images_dir.iterdir())
        assert len(saved) == 1

        # an admin can also attach/replace an image on someone else's submission
        replaced = await ac.post(
            f"/destinations/{new_id}/image",
            headers=headers_admin,
            files={"file": ("photo.jpg", b"\xff\xd8\xff fake jpeg", "image/jpeg")},
        )
        assert replaced.status_code == 200
        assert replaced.json()["image_url"] == f"/static/destinations/{new_id}.jpg"
        # old .png was cleaned up, not left behind alongside the new .jpg
        assert [p.name for p in images_dir.iterdir()] == [f"{new_id}.jpg"]

        missing = await ac.post(
            "/destinations/does-not-exist/image",
            headers=headers_a,
            files={"file": ("photo.png", b"\x89PNG fake bytes", "image/png")},
        )
        assert missing.status_code == 404
