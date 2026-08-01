"""Mannequin presentation service: "View on Mannequin" — a completely separate, optional
post-processing step that runs only after the core visualization has already succeeded.

Presentation-only. The already-generated visualization is the visual source of truth; this
service must never regenerate, redesign, or reinterpret the embroidery — it only shows the
exact finished garment worn/draped on a mannequin as a product photograph.

Deliberately isolated from openai_service.py / visualization_pipeline.py (the stable core
pipeline) — those files are untouched by this feature. Reuses their shared infrastructure
(the OpenAI client, image normalization/canvas-fitting helpers) rather than duplicating it.
"""
import base64
from typing import Optional

from app.core.config import settings
from app.services.openai_service import get_openai_client
from app.utils.exceptions import AIServiceError
from app.utils.image_utils import fetch_image_bytes, fit_to_edit_canvas, make_color_swatch_png, normalize_image


def _build_mannequin_prompt() -> str:
    """Presentation-only prompt: the supplied visualization is the source of truth, never to be
    regenerated or reinterpreted — only re-photographed as worn on a mannequin."""
    return """TASK TYPE:
PRESENTATION-ONLY MANNEQUIN VISUALIZATION.
THIS IS NOT A REDESIGN, REGENERATION, OR REINTERPRETATION TASK.

============================================================
CRITICAL RULE
============================================================

The FIRST supplied image (the completed garment visualization) is the VISUAL SOURCE OF TRUTH.

Your ONLY job is to show this exact garment being professionally worn/draped on a realistic fashion mannequin, as a premium product photograph.

Do NOT regenerate, redesign, reinterpret, simplify, add to, or remove from the embroidery.

Do NOT recolour the garment.

Do NOT invent a different blouse or saree.

============================================================
PRESERVE EXACTLY
============================================================

- exact blouse colour
- exact saree colour
- saree border
- saree pattern
- blouse construction
- embroidery motif
- embroidery geometry
- embroidery colours
- embroidery bead arrangement
- embroidery materials
- embroidery placement
- embroidery proportions

============================================================
PRESENTATION
============================================================

Use a neutral, elegant fashion mannequin.

Correctly drape the saree around the mannequin in a realistic, traditional style. If a second
reference image of the saree is supplied, use it only for saree colour/border/pattern fidelity —
the garment and embroidery still come from the first image.

The blouse should appear naturally fitted to the mannequin's form.

The embroidery must follow the blouse's physical curvature naturally, while remaining visually
faithful to the first supplied image — same motif, same colours, same bead arrangement, same
placement, same proportions.

Render realistic fabric folds, garment tension, stitching depth, shadows, highlights, and
material reflections consistent with a professional product photograph.

The mannequin itself must NOT be the visual focus — it is only a presentation surface. The
GARMENT DESIGN remains the focus of the image.

Use a clean, premium studio/product-photography presentation: soft even lighting, neutral
background, no text, no watermark."""


async def generate_mannequin_image(
    visualization_bytes: bytes,
    saree_bytes: Optional[bytes],
    prompt: str,
    size: str,
) -> bytes:
    """Core mannequin call: edits the completed visualization image, optionally using a saree
    reference for colour/border/pattern fidelity. No mask — full-image edit, consistent with
    what the core visualization pipeline found preserves the most reference detail."""
    client = get_openai_client()

    images = [("visualization.png", visualization_bytes, "image/png")]
    if saree_bytes:
        images.append(("saree.png", saree_bytes, "image/png"))

    try:
        response = await client.images.edit(
            model=settings.OPENAI_EDIT_MODEL,
            image=images,
            prompt=prompt,
            size=size,
            quality=settings.OPENAI_MANNEQUIN_QUALITY,
            input_fidelity="high",
            n=1,
        )
        image_b64 = response.data[0].b64_json
        return base64.b64decode(image_b64)
    except Exception as exc:
        raise AIServiceError(f"Mannequin visualization failed: {exc}") from exc


async def run_mannequin_visualization(
    visualization_url: str,
    saree_url: Optional[str] = None,
    saree_color_hex: Optional[str] = None,
) -> bytes:
    """Orchestrates the mannequin stage: fetch + normalize + fit canvas -> build prompt ->
    generate. No garment/QA analysis, no retry logic — this is presentation-only, running once
    on an already-approved visualization."""
    visualization_raw = await fetch_image_bytes(visualization_url)
    visualization_normalized = normalize_image(visualization_raw)
    canvas_bytes, canvas_size_str, _, _ = fit_to_edit_canvas(visualization_normalized)

    saree_bytes = None
    if saree_url:
        saree_raw = await fetch_image_bytes(saree_url)
        saree_bytes = normalize_image(saree_raw)
    elif saree_color_hex:
        saree_bytes = make_color_swatch_png(saree_color_hex)

    prompt = _build_mannequin_prompt()
    return await generate_mannequin_image(canvas_bytes, saree_bytes, prompt, canvas_size_str)
