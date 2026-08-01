"""Endpoint test for /generation/visualize: TestClient + mocked pipeline internals (no real
OpenAI/Gemini/Cloudinary calls) — asserts a Design row is created with the new visualization
fields populated. Reuses conftest.py's offline HS256 auth path, same as test_auth.py."""
import time

import jwt
import pytest
from fastapi.testclient import TestClient

from app.core.config import settings
from app.main import app
from app.schemas.design import LookStyle, UploadResponse
from app.schemas.visualization import GarmentAnalysis, QAScoreBreakdown, VisualizationAttempt, VisualizationJob
from app.services import cloudinary_service, visualization_pipeline

TEST_UID = "33333333-3333-3333-3333-333333333333"


def _make_token(uid: str = TEST_UID, email: str = "visualizer@example.com") -> str:
    payload = {
        "sub": uid,
        "email": email,
        "aud": "authenticated",
        "role": "authenticated",
        "iat": int(time.time()),
        "exp": int(time.time()) + 3600,
        "user_metadata": {"full_name": "Test Visualizer"},
    }
    return jwt.encode(payload, settings.SUPABASE_JWT_SECRET, algorithm="HS256")


@pytest.fixture
def mocked_pipeline(monkeypatch):
    async def fake_run_visualization(job: VisualizationJob) -> VisualizationJob:
        job.garment = GarmentAnalysis(
            fabric_type="silk", neckline="round neck", sleeve_type="elbow-length",
            blouse_color="maroon", saree_color="green", lighting="soft studio light",
            camera_angle="front-facing", fold_and_drape_notes="minimal folds",
        )
        job.prompt = "fake prompt"
        qa = QAScoreBreakdown(
            pattern_similarity=90, color_similarity=90, bead_preservation=90,
            geometry_preservation=90, garment_preservation=90, overall_score=90,
        )
        job.attempts = [VisualizationAttempt(image_bytes=b"fake-image-bytes", qa=qa)]
        job.chosen_index = 0
        job.retry_count = 0
        return job

    async def fake_upload_bytes(data: bytes, folder: str) -> UploadResponse:
        return UploadResponse(url="https://cdn.example.com/visualization.png", public_id="viz-1")

    monkeypatch.setattr(visualization_pipeline, "run_visualization", fake_run_visualization)
    monkeypatch.setattr(cloudinary_service, "upload_bytes", fake_upload_bytes)


def _visualize_payload() -> dict:
    return {
        "embroidery_design_url": "https://cdn.example.com/embroidery.png",
        "blouse_image_url": "https://cdn.example.com/blouse.png",
        "look_style": LookStyle.TRADITIONAL.value,
    }


def test_visualize_creates_design_with_visualization_fields(mocked_pipeline):
    token = _make_token()

    with TestClient(app) as client:
        response = client.post(
            "/api/v1/generation/visualize",
            json=_visualize_payload(),
            headers={"Authorization": f"Bearer {token}"},
        )

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["preview_image_url"] == "https://cdn.example.com/visualization.png"
    assert body["garment_metadata"]["blouse_color"] == "maroon"
    assert body["qa_result"]["overall_score"] == 90
    assert body["retry_count"] == 0
    assert body["embroidery_design_url"] == "https://cdn.example.com/embroidery.png"


def test_regenerate_rejects_design_without_garment_metadata(mocked_pipeline):
    """A design created via the older /preview flow has no garment_metadata — regenerating
    it with the new pipeline must fail clearly (422), not silently do the wrong thing."""
    token = _make_token(uid="44444444-4444-4444-4444-444444444444", email="legacy@example.com")

    old_payload = {
        "embroidery_design_url": "https://cdn.example.com/embroidery.png",
        "detected_saree_color": "green",
        "detected_blouse_color": "maroon",
        "detected_design_style": "floral",
        "bead_recommendations": [{"name": "Antique Gold", "hex_color": "#cfa15b", "reason": "matches"}],
        "look_style": LookStyle.LUXURY.value,
    }

    import app.api.v1.endpoints.generation as generation_module

    async def fake_generate_preview_image(**kwargs):
        return b"legacy-bytes", "legacy prompt"

    async def fake_upload_base64_image(data_base64: str, folder: str):
        return UploadResponse(url="https://cdn.example.com/legacy.png", public_id="legacy-1")

    with pytest.MonkeyPatch.context() as mp:
        mp.setattr(generation_module.openai_service, "generate_preview_image", fake_generate_preview_image)
        mp.setattr(generation_module.cloudinary_service, "upload_base64_image", fake_upload_base64_image)

        with TestClient(app) as client:
            create_response = client.post(
                "/api/v1/generation/preview",
                json=old_payload,
                headers={"Authorization": f"Bearer {token}"},
            )
            assert create_response.status_code == 200, create_response.text
            design_id = create_response.json()["id"]

            regenerate_response = client.post(
                f"/api/v1/generation/regenerate/{design_id}",
                params={"look_style": LookStyle.BRIDAL.value},
                headers={"Authorization": f"Bearer {token}"},
            )

    assert regenerate_response.status_code == 422
