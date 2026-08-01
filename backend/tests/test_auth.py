"""Exercises the full Supabase-JWT -> local-user pipeline with a self-signed token that uses
the same secret tests/conftest.py configures — no real Supabase project needed."""
import time

import jwt
from fastapi.testclient import TestClient

from app.core.config import settings
from app.main import app

TEST_UID = "11111111-1111-1111-1111-111111111111"


def _make_token(uid: str = TEST_UID, email: str = "shopper@example.com") -> str:
    payload = {
        "sub": uid,
        "email": email,
        "aud": "authenticated",
        "role": "authenticated",
        "iat": int(time.time()),
        "exp": int(time.time()) + 3600,
        "user_metadata": {"full_name": "Test Shopper"},
    }
    return jwt.encode(payload, settings.SUPABASE_JWT_SECRET, algorithm="HS256")


def test_valid_token_creates_and_returns_local_user():
    token = _make_token()

    with TestClient(app) as client:
        response = client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {token}"})

    assert response.status_code == 200
    body = response.json()
    assert body["supabase_uid"] == TEST_UID
    assert body["email"] == "shopper@example.com"
    assert body["display_name"] == "Test Shopper"


def test_valid_token_reuses_existing_user_on_second_request():
    token = _make_token(uid="22222222-2222-2222-2222-222222222222", email="repeat@example.com")

    with TestClient(app) as client:
        first = client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {token}"})
        second = client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {token}"})

    assert first.status_code == second.status_code == 200
    assert first.json()["id"] == second.json()["id"]


def test_expired_token_is_rejected():
    payload = {
        "sub": TEST_UID,
        "email": "shopper@example.com",
        "aud": "authenticated",
        "iat": int(time.time()) - 7200,
        "exp": int(time.time()) - 3600,
    }
    expired_token = jwt.encode(payload, settings.SUPABASE_JWT_SECRET, algorithm="HS256")

    with TestClient(app) as client:
        response = client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {expired_token}"})

    assert response.status_code == 401


def test_token_signed_with_wrong_secret_is_rejected():
    payload = {"sub": TEST_UID, "email": "shopper@example.com", "aud": "authenticated"}
    forged_token = jwt.encode(payload, "not-the-real-secret", algorithm="HS256")

    with TestClient(app) as client:
        response = client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {forged_token}"})

    assert response.status_code == 401
