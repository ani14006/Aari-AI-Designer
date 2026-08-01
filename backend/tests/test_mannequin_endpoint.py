"""Endpoint test for /generation/mannequin: TestClient + mocked service internals (no real
OpenAI/Cloudinary calls). Confirms the mannequin feature is reachable, persists as a separate
derived asset without touching the design's original preview_image_url, and works with no
design_id at all (a completely stateless call). Reuses conftest.py's offline HS256 auth path."""
import time

import jwt
from fastapi.testclient import TestClient

from app.core.config import settings
from app.main import app
from app.schemas.design import UploadResponse
from app.services import cloudinary_service, mannequin_service

TEST_UID = "66666666-6666-6666-6666-666666666666"


def _make_token(uid: str = TEST_UID, email: str = "mannequin@example.com") -> str:
    payload = {
        "sub": uid,
        "email": email,
        "aud": "authenticated",
        "role": "authenticated",
        "iat": int(time.time()),
        "exp": int(time.time()) + 3600,
        "user_metadata": {"full_name": "Test Mannequin User"},
    }
    return jwt.encode(payload, settings.SUPABASE_JWT_SECRET, algorithm="HS256")


def _mock_service(monkeypatch):
    async def fake_run_mannequin_visualization(**kwargs):
        return b"fake-mannequin-bytes"

    async def fake_upload_bytes(data: bytes, folder: str) -> UploadResponse:
        assert folder == "mannequin"
        return UploadResponse(url="https://cdn.example.com/mannequin.png", public_id="mannequin-1")

    monkeypatch.setattr(mannequin_service, "run_mannequin_visualization", fake_run_mannequin_visualization)
    monkeypatch.setattr(cloudinary_service, "upload_bytes", fake_upload_bytes)


def test_mannequin_endpoint_works_without_a_design_id(monkeypatch):
    """Fully stateless call: just a completed_visualization_url, no design to persist against."""
    _mock_service(monkeypatch)
    token = _make_token()

    with TestClient(app) as client:
        response = client.post(
            "/api/v1/generation/mannequin",
            json={"completed_visualization_url": "https://cdn.example.com/visualization.png"},
            headers={"Authorization": f"Bearer {token}"},
        )

    assert response.status_code == 200, response.text
    assert response.json() == {"mannequin_image_url": "https://cdn.example.com/mannequin.png"}


def test_mannequin_endpoint_persists_as_separate_asset_on_design(monkeypatch):
    """When a design_id is supplied, the mannequin result is stored on mannequin_image_url —
    the design's original preview_image_url must remain untouched."""
    import app.api.v1.endpoints.generation as generation_module

    async def fake_generate_preview_image(**kwargs):
        return b"original-preview-bytes", "original prompt"

    async def fake_upload_base64_image(data_base64: str, folder: str):
        return UploadResponse(url="https://cdn.example.com/original-preview.png", public_id="preview-1")

    _mock_service(monkeypatch)
    token = _make_token(uid="77777777-7777-7777-7777-777777777777", email="mannequin-design@example.com")

    with monkeypatch.context() as mp:
        mp.setattr(generation_module.openai_service, "generate_preview_image", fake_generate_preview_image)
        mp.setattr(generation_module.cloudinary_service, "upload_base64_image", fake_upload_base64_image)

        with TestClient(app) as client:
            create_response = client.post(
                "/api/v1/generation/preview",
                json={
                    "embroidery_design_url": "https://cdn.example.com/embroidery.png",
                    "detected_saree_color": "green",
                    "detected_blouse_color": "maroon",
                    "detected_design_style": "floral",
                    "bead_recommendations": [
                        {"name": "Antique Gold", "hex_color": "#cfa15b", "reason": "matches"}
                    ],
                },
                headers={"Authorization": f"Bearer {token}"},
            )
            assert create_response.status_code == 200, create_response.text
            design_id = create_response.json()["id"]

            mannequin_response = client.post(
                "/api/v1/generation/mannequin",
                json={
                    "design_id": design_id,
                    "completed_visualization_url": "https://cdn.example.com/original-preview.png",
                },
                headers={"Authorization": f"Bearer {token}"},
            )
            assert mannequin_response.status_code == 200, mannequin_response.text

            design_response = client.get(
                f"/api/v1/designs/{design_id}",
                headers={"Authorization": f"Bearer {token}"},
            )

    design_body = design_response.json()
    assert design_body["mannequin_image_url"] == "https://cdn.example.com/mannequin.png"
    assert design_body["preview_image_url"] == "https://cdn.example.com/original-preview.png"
