import pytest
from fastapi.testclient import TestClient
from sqlalchemy import text

from app.main import create_app
from app.models import Role

from conftest import Api, add_institution, add_user, db_session, make_settings


def test_security_headers_on_every_response(client):
    r = client.get("/api/health")
    h = r.headers
    assert h["x-content-type-options"] == "nosniff"
    assert h["x-frame-options"] == "DENY"
    assert h["referrer-policy"] == "no-referrer"
    assert "default-src 'none'" in h["content-security-policy"]
    assert h["cache-control"] == "no-store"
    assert "server" not in h


def _prod_app(**kw):
    s = make_settings(environment="production", public_base_url="https://testserver",
                      database_url="postgresql+psycopg://u:p@127.0.0.1:1/x", **kw)
    return create_app(s)


def test_production_enforces_https_and_sends_hsts():
    app = _prod_app()
    http = TestClient(app, base_url="http://testserver")
    assert http.get("/api/health").status_code == 400
    https = TestClient(app, base_url="https://testserver")
    r = https.get("/api/health")
    assert r.status_code == 200
    assert "max-age=63072000" in r.headers["strict-transport-security"]


def test_production_trusts_forwarded_proto_only_from_proxy():
    app = _prod_app(trusted_proxies=["10.9.9.9"])  # the test client is not this proxy
    c = TestClient(app, base_url="http://testserver")
    assert c.get("/api/health", headers={"X-Forwarded-Proto": "https"}).status_code == 400


def test_production_hides_api_docs_and_rejects_foreign_host():
    app = _prod_app()
    c = TestClient(app, base_url="https://testserver")
    assert c.get("/api/docs").status_code == 404
    assert c.get("/api/openapi.json").status_code == 404
    evil = TestClient(app, base_url="https://evil.example")
    assert evil.get("/api/health").status_code == 400


def test_csrf_custom_header_and_origin_and_token(api, app, client):
    add_user(app, "c@maktab.uz")
    # No custom header -> blocked before reaching the route
    r = client.post("/api/auth/login", json={"email": "c@maktab.uz", "password": "x"})
    assert r.status_code == 403
    # Foreign Origin -> blocked
    app.state.ctx.settings.allowed_origins.append("https://individ.uz")
    r = api.post("/api/auth/login", {"email": "c@maktab.uz", "password": "x"},
                 headers={"Origin": "https://evil.example"})
    assert r.status_code == 403
    app.state.ctx.settings.allowed_origins.clear()
    # Logged in, but state-changing request without the CSRF token -> blocked
    api.login("c@maktab.uz")
    token, api.csrf = api.csrf, ""
    assert api.post("/api/auth/password/change/request").status_code == 403
    api.csrf = "forged" + token[6:]
    assert api.post("/api/auth/password/change/request").status_code == 403
    api.csrf = token
    assert api.post("/api/auth/password/change/request").status_code == 200


def test_cors_closed_by_default_and_allowlist_only():
    closed = TestClient(create_app(make_settings()))
    pre = closed.options("/api/auth/login", headers={
        "Origin": "https://evil.example", "Access-Control-Request-Method": "POST"})
    assert "access-control-allow-origin" not in pre.headers

    open_ = TestClient(create_app(make_settings(allowed_origins=["https://individ.uz"])))
    ok = open_.options("/api/auth/login", headers={
        "Origin": "https://individ.uz", "Access-Control-Request-Method": "POST"})
    assert ok.headers.get("access-control-allow-origin") == "https://individ.uz"
    bad = open_.options("/api/auth/login", headers={
        "Origin": "https://evil.example", "Access-Control-Request-Method": "POST"})
    assert bad.headers.get("access-control-allow-origin") != "https://evil.example"


def test_request_body_size_limit(api):
    r = api.post("/api/auth/login", {"email": "a@b.uz", "password": "x" * 1_100_000})
    assert r.status_code == 413


def test_validation_rejects_unknown_fields_and_never_echoes_input(api):
    r = api.post("/api/auth/login", {"email": "a@b.uz", "password": "SecretValue123", "role": "SUPER_ADMIN"})
    assert r.status_code == 422
    assert "SecretValue123" not in r.text
    r = api.post("/api/auth/login", {"email": "not-an-email", "password": "x"})
    assert r.status_code == 422


def _teacher(app):
    inst = add_institution(app)
    add_user(app, "tch@maktab.uz", Role.TEACHER, inst)
    return inst


def test_markup_in_work_data_is_returned_as_inert_json(api, app):
    _teacher(app)
    api.login("tch@maktab.uz")
    note = '<img src=x onerror="alert(1)">'
    r = api.post("/api/records/batch", {"ops": [
        {"op": "put", "kind": "student", "id": "s1", "data": {"firstName": "<script>x</script>", "lastName": "Ali"}},
        {"op": "put", "kind": "assessment", "id": "a1", "data": {"studentId": "s1", "notes": note}},
    ]})
    assert r.status_code == 200
    got = api.get("/api/records")
    assert got.headers["content-type"].startswith("application/json")
    assert "default-src 'none'" in got.headers["content-security-policy"]
    assert got.json()["items"]["assessment"][0]["notes"] == note  # text, never rendered as HTML


def test_injection_payloads_in_ids_are_refused_and_data_is_data(api, app):
    _teacher(app)
    api.login("tch@maktab.uz")
    for bad in ["' OR '1'='1", "x; DROP TABLE records; --", "../etc", "a" * 65]:
        r = api.post("/api/records/batch", {"ops": [{"op": "put", "kind": "student", "id": bad, "data": {}}]})
        assert r.status_code == 422, bad
    payload = "'; DROP TABLE records; --"
    r = api.post("/api/records/batch", {"ops": [
        {"op": "put", "kind": "student", "id": "s1", "data": {"firstName": payload}}]})
    assert r.status_code == 200
    assert api.get("/api/records").json()["items"]["student"][0]["firstName"] == payload  # table intact
    r = api.post("/api/auth/login", {"email": "x' OR 1=1 --@a.uz", "password": "x"})
    assert r.status_code in (401, 422)


def test_work_data_encrypted_at_rest_and_bound_to_its_column(api, app):
    _teacher(app)
    api.login("tch@maktab.uz")
    api.post("/api/records/batch", {"ops": [{"op": "put", "kind": "student", "id": "s1",
                                              "data": {"firstName": "Dilnoza", "diagnosis": "F84.0 autizm"}}]})
    with db_session(app) as db:
        raw = db.execute(text("SELECT data FROM records")).scalar_one()
        before = db.execute(text("SELECT after FROM record_changes")).scalar_one()
    assert raw.startswith("enc2:") and "Dilnoza" not in raw and "F84" not in raw
    assert before.startswith("enc2:") and "Dilnoza" not in before
    from app import crypto
    with pytest.raises(Exception):
        crypto.decrypt(raw, "users.profile")  # moved to another column: refused
    assert "Dilnoza" in crypto.decrypt(raw, "records.data")


def test_unknown_routes_and_errors_leak_nothing(client):
    r = client.get("/api/does-not-exist")
    assert r.status_code == 404
    assert r.json() == {"code": "not_found", "message": "Topilmadi"}


def test_general_api_rate_limit(app):
    c = TestClient(create_app(make_settings(api_per_minute=5)))
    codes = [c.get("/api/health").status_code for _ in range(8)]
    assert 429 in codes
