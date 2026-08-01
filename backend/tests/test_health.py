from fastapi.testclient import TestClient

from app.main import app


def test_health_check_ok():
    with TestClient(app) as client:
        response = client.get("/health")

    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ok"
    assert body["app"] == "Aari AI Designer"


def test_protected_endpoint_rejects_missing_auth():
    with TestClient(app) as client:
        response = client.get("/api/v1/auth/me")

    assert response.status_code == 403


def test_upload_endpoint_rejects_invalid_folder_or_auth():
    with TestClient(app) as client:
        response = client.post(
            "/api/v1/uploads/not-a-real-folder",
            files={"file": ("swatch.png", b"fake-bytes", "image/png")},
            headers={"Authorization": "Bearer fake-token"},
        )

    # Auth is checked before the folder is validated, so a malformed token fails at the auth
    # dependency (401) rather than the folder check — either way it must never succeed, which
    # is what this smoke test guards against.
    assert response.status_code >= 400
