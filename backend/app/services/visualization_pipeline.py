"""Orchestrates the embroidery visualization pipeline: normalize -> remove background ->
analyze garment -> fit canvas -> generate (+ single retry) -> QA score -> pick the
higher-scoring attempt. Replaces the old parameter-sprawl generation flow with a single
VisualizationJob object that's progressively filled in by each stage.

Final rendering objective: a complete boutique product photograph (blouse + saree + embroidery
on a premium display mannequin), not a close-up of the blouse alone. The saree reference (photo
or colour swatch) is now a primary preserved asset sent to OpenAI alongside the blouse and
embroidery — previously it was only used as colour-harmony context for Gemini's garment
analysis.
"""
from app.core.config import settings
from app.schemas.visualization import VisualizationAttempt, VisualizationJob
from app.services import gemini_service, openai_service
from app.utils.image_utils import fetch_image_bytes, fit_to_edit_canvas, make_color_swatch_png, normalize_image, remove_background


async def run_visualization(job: VisualizationJob) -> VisualizationJob:
    """Mutates and returns `job`. Only `job.chosen_attempt`'s bytes/QA result are meant to be
    uploaded/persisted by the caller — the other attempt (if a retry happened) is discarded."""
    blouse_raw = await fetch_image_bytes(job.blouse_image_url)
    embroidery_raw = await fetch_image_bytes(job.embroidery_design_url)

    blouse_normalized = normalize_image(blouse_raw)
    embroidery_normalized = normalize_image(embroidery_raw)

    job.embroidery_asset_bytes = remove_background(embroidery_normalized)

    canvas_bytes, canvas_size_str, _, _ = fit_to_edit_canvas(blouse_normalized)
    job.blouse_bytes = canvas_bytes

    saree_bytes = None
    if job.saree_image_url:
        saree_raw = await fetch_image_bytes(job.saree_image_url)
        saree_bytes = normalize_image(saree_raw)
    elif job.saree_color_hex:
        saree_bytes = make_color_swatch_png(job.saree_color_hex)

    job.garment = await gemini_service.analyze_garment(
        blouse_image_url=job.blouse_image_url,
        saree_image_url=job.saree_image_url,
        saree_color_hex=job.saree_color_hex,
    )

    job.prompt = openai_service._build_visualization_prompt(job.garment, job.look_style, has_saree_reference=saree_bytes is not None)

    first_bytes = await openai_service.generate_visualization(
        job.blouse_bytes, job.embroidery_asset_bytes, saree_bytes, job.prompt, canvas_size_str,
    )
    first_qa = await gemini_service.score_visualization(job.embroidery_asset_bytes, first_bytes)
    job.attempts.append(VisualizationAttempt(image_bytes=first_bytes, qa=first_qa))

    if first_qa.overall_score >= settings.VISUALIZATION_QA_ACCEPT_THRESHOLD:
        job.chosen_index = 0
        return job

    # One retry only (same prompt — a stochastic variance safety net, not a QA-informed
    # re-prompt), then keep whichever of the two attempts scored higher.
    job.retry_count = 1
    retry_bytes = await openai_service.generate_visualization(
        job.blouse_bytes, job.embroidery_asset_bytes, saree_bytes, job.prompt, canvas_size_str,
    )
    retry_qa = await gemini_service.score_visualization(job.embroidery_asset_bytes, retry_bytes)
    job.attempts.append(VisualizationAttempt(image_bytes=retry_bytes, qa=retry_qa))

    job.chosen_index = 0 if first_qa.overall_score >= retry_qa.overall_score else 1
    return job
