"""Mocked tests for the visualization orchestrator's retry/best-of-two decision logic. No
network calls — every pipeline stage (fetch, normalize, background removal, garment analysis,
generation, QA scoring) is patched so only run_visualization()'s own control flow is under
test."""
import io

import pytest
from PIL import Image

from app.schemas.design import LookStyle
from app.schemas.visualization import GarmentAnalysis, QAScoreBreakdown, VisualizationJob
from app.services import visualization_pipeline as pipeline


def _tiny_png() -> bytes:
    buffer = io.BytesIO()
    Image.new("RGB", (10, 10), (200, 100, 50)).save(buffer, format="PNG")
    return buffer.getvalue()


def _tiny_rgba_png() -> bytes:
    buffer = io.BytesIO()
    Image.new("RGBA", (10, 10), (200, 100, 50, 255)).save(buffer, format="PNG")
    return buffer.getvalue()


def _garment() -> GarmentAnalysis:
    return GarmentAnalysis(
        fabric_type="silk", neckline="round neck", sleeve_type="elbow-length",
        blouse_color="maroon", saree_color="green", lighting="soft studio light",
        camera_angle="front-facing", fold_and_drape_notes="minimal folds",
    )


def _qa(score: float) -> QAScoreBreakdown:
    return QAScoreBreakdown(
        pattern_similarity=score, color_similarity=score, bead_preservation=score,
        geometry_preservation=score, garment_preservation=score, overall_score=score,
    )


def _job() -> VisualizationJob:
    return VisualizationJob(
        embroidery_design_url="http://x/embroidery.png",
        blouse_image_url="http://x/blouse.png",
        look_style=LookStyle.LUXURY,
    )


@pytest.fixture(autouse=True)
def _patch_common_stages(monkeypatch):
    """Patches every stage except generate_visualization/score_visualization, which each test
    configures itself to drive the retry/best-of-two logic under test."""

    async def fake_fetch(url):
        return _tiny_png()

    def fake_normalize(data, max_dimension=2048):
        return data

    def fake_remove_background(data):
        return _tiny_rgba_png()

    def fake_fit_to_edit_canvas(data):
        return data, "1024x1024", 1024, 1024

    async def fake_analyze_garment(**kwargs):
        return _garment()

    def fake_build_prompt(garment, look_style, has_saree_reference=False):
        return "fake prompt"

    monkeypatch.setattr(pipeline, "fetch_image_bytes", fake_fetch)
    monkeypatch.setattr(pipeline, "normalize_image", fake_normalize)
    monkeypatch.setattr(pipeline, "remove_background", fake_remove_background)
    monkeypatch.setattr(pipeline, "fit_to_edit_canvas", fake_fit_to_edit_canvas)
    monkeypatch.setattr(pipeline.gemini_service, "analyze_garment", fake_analyze_garment)
    monkeypatch.setattr(pipeline.openai_service, "_build_visualization_prompt", fake_build_prompt)


@pytest.mark.asyncio
async def test_no_retry_when_first_attempt_passes(monkeypatch):
    async def fake_generate(*args, **kwargs):
        return b"attempt-1-bytes"

    async def fake_score(reference_bytes, generated_bytes):
        return _qa(90.0)

    monkeypatch.setattr(pipeline.openai_service, "generate_visualization", fake_generate)
    monkeypatch.setattr(pipeline.gemini_service, "score_visualization", fake_score)

    job = await pipeline.run_visualization(_job())

    assert job.retry_count == 0
    assert len(job.attempts) == 1
    assert job.chosen_index == 0
    assert job.chosen_attempt.image_bytes == b"attempt-1-bytes"


@pytest.mark.asyncio
async def test_retry_chosen_when_it_scores_higher(monkeypatch):
    call_count = {"n": 0}

    async def fake_generate(*args, **kwargs):
        call_count["n"] += 1
        return f"attempt-{call_count['n']}".encode()

    scores = iter([40.0, 85.0])

    async def fake_score(reference_bytes, generated_bytes):
        return _qa(next(scores))

    monkeypatch.setattr(pipeline.openai_service, "generate_visualization", fake_generate)
    monkeypatch.setattr(pipeline.gemini_service, "score_visualization", fake_score)

    job = await pipeline.run_visualization(_job())

    assert job.retry_count == 1
    assert len(job.attempts) == 2
    assert job.chosen_index == 1
    assert job.chosen_attempt.image_bytes == b"attempt-2"


@pytest.mark.asyncio
async def test_first_attempt_kept_when_retry_scores_lower(monkeypatch):
    """The easiest nuance to get wrong: a retry happening does NOT mean the retry wins — the
    higher-scoring attempt is kept, even if that's the original."""
    call_count = {"n": 0}

    async def fake_generate(*args, **kwargs):
        call_count["n"] += 1
        return f"attempt-{call_count['n']}".encode()

    scores = iter([50.0, 30.0])

    async def fake_score(reference_bytes, generated_bytes):
        return _qa(next(scores))

    monkeypatch.setattr(pipeline.openai_service, "generate_visualization", fake_generate)
    monkeypatch.setattr(pipeline.gemini_service, "score_visualization", fake_score)

    job = await pipeline.run_visualization(_job())

    assert job.retry_count == 1
    assert len(job.attempts) == 2
    assert job.chosen_index == 0
    assert job.chosen_attempt.image_bytes == b"attempt-1"
