import uuid
from datetime import datetime, timedelta, timezone

import jwt
import pytest
from fastapi.testclient import TestClient

from app.config import settings
from app.main import app, limiter


@pytest.fixture(scope="module")
def client():
    with TestClient(app) as c:
        yield c


@pytest.fixture(autouse=True)
def _reset_rate_limits():
    limiter.reset()
    yield
    limiter.reset()


def unique_email() -> str:
    return f"tutor-{uuid.uuid4().hex[:10]}@test.local"


def register(client, email, password="supersegura123"):
    return client.post(
        "/api/auth/register",
        json={
            "email": email,
            "display_name": "Tutor Prueba",
            "password": password,
        },
    )


def login(client, email, password="supersegura123"):
    return client.post(
        "/api/auth/login", json={"email": email, "password": password}
    )


def auth_headers(client, email):
    register(client, email)
    resp = login(client, email)
    assert resp.status_code == 200
    return {"Authorization": f"Bearer {resp.json()['accessToken']}"}


def mint_token(subject, role):
    now = datetime.now(timezone.utc)
    return jwt.encode(
        {
            "sub": subject,
            "role": role,
            "iat": now,
            "exp": now + timedelta(minutes=5),
        },
        settings.jwt_secret,
        algorithm=settings.jwt_algorithm,
    )


def test_health(client):
    resp = client.get("/api/health")
    assert resp.status_code == 200
    body = resp.json()
    assert body["status"] == "ok"
    assert body["version"] == settings.app_version


def test_activities_are_public(client):
    resp = client.get("/api/activities")
    assert resp.status_code == 200
    body = resp.json()
    assert len(body) == 4
    assert all("prompts" in item for item in body)


def test_protected_route_requires_token(client):
    resp = client.post(
        "/api/children", json={"name": "Luna", "avatar": "estelar"}
    )
    assert resp.status_code == 401
    assert resp.json()["error"]["code"] == 401


def test_register_creates_tutor(client):
    email = unique_email()
    resp = register(client, email)
    assert resp.status_code == 201
    body = resp.json()
    assert body["id"].startswith("tutor_")
    assert body["email"] == email
    assert "passwordHash" not in body


def test_register_duplicate_conflicts(client):
    email = unique_email()
    assert register(client, email).status_code == 201
    resp = register(client, email)
    assert resp.status_code == 409
    assert resp.json()["error"]["code"] == 409


def test_login_rejects_wrong_password(client):
    email = unique_email()
    register(client, email)
    resp = login(client, email, password="incorrecta")
    assert resp.status_code == 401


def test_login_returns_token(client):
    email = unique_email()
    register(client, email)
    resp = login(client, email)
    assert resp.status_code == 200
    body = resp.json()
    assert body["tokenType"] == "bearer"
    assert body["expiresIn"] == settings.access_token_expire_minutes * 60
    assert body["accessToken"]


def test_invalid_token_is_rejected(client):
    resp = client.get(
        "/api/children/child_nope",
        headers={"Authorization": "Bearer not-a-jwt"},
    )
    assert resp.status_code == 401


def test_unknown_subject_is_rejected(client):
    token = mint_token("tutor_unknown", "tutor")
    resp = client.get(
        "/api/children/child_nope",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 401


def test_non_tutor_role_is_forbidden(client):
    email = unique_email()
    register(client, email)
    token = mint_token("whatever", "student")
    resp = client.post(
        "/api/children",
        json={"name": "Luna", "avatar": "estelar"},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 403
    assert resp.json()["error"]["code"] == 403


def test_child_flow_with_token(client):
    email = unique_email()
    headers = auth_headers(client, email)
    resp = client.post(
        "/api/children",
        json={"name": "Luna", "avatar": "estelar"},
        headers=headers,
    )
    assert resp.status_code == 201
    child_id = resp.json()["id"]

    got = client.get(f"/api/children/{child_id}", headers=headers)
    assert got.status_code == 200
    assert got.json()["name"] == "Luna"

    missing = client.get("/api/children/child_nope", headers=headers)
    assert missing.status_code == 404


def test_session_flow_with_token(client):
    email = unique_email()
    headers = auth_headers(client, email)
    child = client.post(
        "/api/children",
        json={"name": "Luna", "avatar": "estelar"},
        headers=headers,
    ).json()

    resp = client.post(
        "/api/sessions",
        json={
            "childId": child["id"],
            "activityId": "act_001",
            "score": 80,
            "durationSeconds": 120,
            "interactions": [
                {
                    "promptIndex": 0,
                    "selectedIndex": 1,
                    "correct": True,
                    "responseTimeMs": 3500,
                }
            ],
        },
        headers=headers,
    )
    assert resp.status_code == 201
    assert resp.json()["id"].startswith("sess_")

    bad_child = client.post(
        "/api/sessions",
        json={
            "childId": "child_nope",
            "activityId": "act_001",
            "score": 1,
            "durationSeconds": 1,
            "interactions": [],
        },
        headers=headers,
    )
    assert bad_child.status_code == 404

    progress = client.get(
        f"/api/children/{child['id']}/progress", headers=headers
    )
    assert progress.status_code == 200
    body = progress.json()
    assert body["totalSessions"] == 1
    assert body["averageScore"] == 80.0
    assert body["totalSeconds"] == 120


def test_validation_error_is_standardized(client):
    resp = client.post(
        "/api/auth/register",
        json={"email": "bad", "display_name": "X", "password": "short"},
    )
    assert resp.status_code == 422
    assert resp.json()["error"]["code"] == 422
    assert "details" in resp.json()["error"]


def test_register_rate_limit(client):
    statuses = []
    for _ in range(6):
        resp = register(client, unique_email())
        statuses.append(resp.status_code)
        if resp.status_code == 429:
            break
    assert statuses.count(201) == 5
    assert statuses[-1] == 429
