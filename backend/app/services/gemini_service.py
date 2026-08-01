"""Gemini-backed colour/style vision analysis.

Image generation lives in openai_service.py instead: Gemini's own image models require billing
(confirmed — free tier has a hard zero quota for image generation), so preview generation uses
OpenAI's DALL-E 3 instead.
"""
import asyncio
import json
from functools import lru_cache
from typing import Optional

from google import genai
from google.genai import types

from app.core.config import settings
from app.schemas.design import ColorAnalysisResponse, OrderDetails, PaletteOption
from app.schemas.visualization import GarmentAnalysis, QAScoreBreakdown
from app.utils.exceptions import AIServiceError
from app.utils.image_utils import fetch_image_bytes, make_color_swatch_png

# Curated bead palette the model is asked to choose from (keeps recommendations on-brand).
BEAD_PALETTE = [
    "Antique Gold", "Pearl White", "Ruby Red", "Emerald Green",
    "Crystal", "Copper", "Silver", "Black", "Rose Gold",
]


@lru_cache
def get_gemini_client() -> genai.Client:
    if not settings.GEMINI_API_KEY:
        raise AIServiceError("GEMINI_API_KEY is not configured on the server.")
    return genai.Client(api_key=settings.GEMINI_API_KEY)


_HARMONY_SCHEMES = ["Complementary", "Analogous", "Triadic"]

_BEAD_ITEM_SCHEMA = {
    "type": "object",
    "properties": {
        "name": {"type": "string", "enum": BEAD_PALETTE},
        "hex_color": {"type": "string"},
        "reason": {
            "type": "string",
            "description": "1-2 sentences explaining why this bead colour complements the saree/blouse/design",
        },
    },
    "required": ["name", "hex_color", "reason"],
}

COLOR_ANALYSIS_SCHEMA = {
    "type": "object",
    "properties": {
        "detected_saree_color": {"type": "string"},
        "detected_blouse_color": {"type": "string"},
        "detected_design_style": {
            "type": "string",
            "description": "e.g. floral Aari, peacock motif, geometric zardosi, paisley, temple-border",
        },
        "palette_options": {
            "type": "array",
            "minItems": 3,
            "maxItems": 3,
            "description": (
                "Exactly 3 distinct bead-colour palettes, one built on each colour-harmony scheme: "
                "Complementary, Analogous and Triadic — in that order."
            ),
            "items": {
                "type": "object",
                "properties": {
                    "scheme": {"type": "string", "enum": _HARMONY_SCHEMES},
                    "title": {
                        "type": "string",
                        "description": "A short evocative name for this palette, e.g. 'Royal Contrast'",
                    },
                    "description": {
                        "type": "string",
                        "description": "1-2 sentences on the overall look and why this harmony scheme suits the outfit",
                    },
                    "bead_recommendations": {
                        "type": "array",
                        "minItems": 3,
                        "maxItems": 5,
                        "items": _BEAD_ITEM_SCHEMA,
                    },
                },
                "required": ["scheme", "title", "description", "bead_recommendations"],
            },
        },
    },
    "required": [
        "detected_saree_color",
        "detected_blouse_color",
        "detected_design_style",
        "palette_options",
    ],
}


async def _resolve_image_part(url: Optional[str], hex_color: Optional[str]) -> Optional[types.Part]:
    """Build a Gemini image part from either an uploaded image URL or a hex colour swatch."""
    if url:
        image_bytes = await fetch_image_bytes(url)
        return types.Part.from_bytes(data=image_bytes, mime_type="image/png")
    if hex_color:
        swatch = make_color_swatch_png(hex_color)
        return types.Part.from_bytes(data=swatch, mime_type="image/png")
    return None


_MAX_ANALYSIS_ATTEMPTS = 3


async def analyze_colors(
    saree_image_url: Optional[str],
    saree_color_hex: Optional[str],
    blouse_image_url: Optional[str],
    blouse_color_hex: Optional[str],
    embroidery_design_url: Optional[str],
    order_details: Optional[OrderDetails] = None,
) -> ColorAnalysisResponse:
    """Use Gemini's vision understanding to analyse saree/blouse colour + design style and recommend
    3 distinct bead-colour palettes, each labeled by the colour-harmony scheme it's built on.

    Retries on two failure modes we've observed under free-tier load: the API returning a
    transient 5xx/429, and — more insidiously — a 200 response whose JSON is well-formed but
    has the colour/style fields silently blank. The latter doesn't raise, so it must be
    validated explicitly or it silently produces a prompt like "wearing a  saree" downstream.
    """
    client = get_gemini_client()

    contents: list = [
        "You are an expert Aari embroidery colour consultant for a premium bridal fashion "
        "studio. Analyse the attached saree colour, blouse colour and embroidery design style. "
        "Every field is required and must be non-empty — never return an empty string. "
        f"Recommend exactly 3 distinct bead-colour palettes, each drawing 3 to 5 bead colours "
        f"strictly from this palette: {', '.join(BEAD_PALETTE)}. Build the first palette on a "
        "Complementary colour scheme, the second on an Analogous scheme, and the third on a "
        "Triadic scheme relative to the saree/blouse colours. Give each palette a short evocative "
        "title and a 1-2 sentence description of the overall look. For each recommended bead "
        "colour explain WHY it complements the saree, blouse and design style, referencing "
        "colour harmony and cultural/occasion fit."
    ]

    if order_details:
        details_bits = []
        if order_details.occasion:
            details_bits.append(f"occasion: {order_details.occasion.value}")
        if order_details.embroidery_coverage:
            details_bits.append(f"desired embroidery coverage: {order_details.embroidery_coverage.value}")
        if order_details.style_preference:
            details_bits.append(f"style preference: {order_details.style_preference}")
        if order_details.budget:
            details_bits.append(f"materials budget: roughly ₹{order_details.budget:.0f}")
        if details_bits:
            contents.append(
                "Additional order context to factor into your recommendations — "
                + "; ".join(details_bits) + "."
            )

    saree_part = await _resolve_image_part(saree_image_url, saree_color_hex)
    blouse_part = await _resolve_image_part(blouse_image_url, blouse_color_hex)
    if saree_part:
        contents.append("Saree reference:")
        contents.append(saree_part)
    if blouse_part:
        contents.append("Blouse reference:")
        contents.append(blouse_part)
    if embroidery_design_url:
        design_bytes = await fetch_image_bytes(embroidery_design_url)
        contents.append("Embroidery design reference:")
        contents.append(types.Part.from_bytes(data=design_bytes, mime_type="image/png"))

    last_error: Optional[Exception] = None
    for attempt in range(_MAX_ANALYSIS_ATTEMPTS):
        try:
            response = await client.aio.models.generate_content(
                model=settings.GEMINI_TEXT_MODEL,
                contents=contents,
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    response_schema=COLOR_ANALYSIS_SCHEMA,
                    temperature=0.4,
                ),
            )
            payload = json.loads(response.text)

            missing = [
                field
                for field in ("detected_saree_color", "detected_blouse_color", "detected_design_style")
                if not payload.get(field, "").strip()
            ]
            if not payload.get("palette_options"):
                missing.append("palette_options")
            if missing:
                raise AIServiceError(f"Gemini returned empty analysis fields: {missing}")

            return ColorAnalysisResponse(
                detected_saree_color=payload["detected_saree_color"],
                detected_blouse_color=payload["detected_blouse_color"],
                detected_design_style=payload["detected_design_style"],
                palette_options=[PaletteOption(**p) for p in payload["palette_options"]],
            )
        except Exception as exc:
            last_error = exc
            if attempt < _MAX_ANALYSIS_ATTEMPTS - 1:
                await asyncio.sleep(2 * (attempt + 1))

    raise AIServiceError(f"Colour analysis failed after {_MAX_ANALYSIS_ATTEMPTS} attempts: {last_error}")


GARMENT_ANALYSIS_SCHEMA = {
    "type": "object",
    "properties": {
        "fabric_type": {"type": "string", "description": "e.g. silk, georgette, crepe, cotton, velvet"},
        "neckline": {"type": "string", "description": "e.g. sweetheart, round, boat neck, V-neck"},
        "sleeve_type": {"type": "string", "description": "e.g. elbow-length, three-quarter, sleeveless, full sleeve"},
        "blouse_color": {"type": "string"},
        "saree_color": {"type": "string"},
        "lighting": {"type": "string", "description": "e.g. soft diffused studio light, warm golden-hour, harsh flash"},
        "camera_angle": {"type": "string", "description": "e.g. front-facing chest-level shot, slight side angle, close-up"},
        "fold_and_drape_notes": {
            "type": "string",
            "description": "How the fabric folds/creases/drapes over the body in this specific photo, relevant to rendering embroidery realistically onto its curved surface",
        },
    },
    "required": [
        "fabric_type", "neckline", "sleeve_type", "blouse_color", "saree_color",
        "lighting", "camera_angle", "fold_and_drape_notes",
    ],
}


async def analyze_garment(
    blouse_image_url: str,
    saree_image_url: Optional[str] = None,
    saree_color_hex: Optional[str] = None,
) -> GarmentAnalysis:
    """Garment-ONLY analysis for the visualization pipeline. Deliberately never sees the
    embroidery reference image — OpenAI's edit call sees that directly, so describing it here
    would just risk Gemini's paraphrase drifting from the actual reference and contaminating
    the "copy exactly" instruction with a second, less faithful description.
    """
    client = get_gemini_client()

    contents: list = [
        "You are an expert fashion-photography analyst preparing notes for a photorealistic "
        "garment-rendering pipeline. Analyse ONLY the attached blouse (and saree, for colour "
        "context) — do not describe or invent any embroidery or embellishment, this photo may "
        "be a plain blouse. Every field is required and must be non-empty. Describe the fabric "
        "type, neckline, sleeve type, blouse colour, saree colour, lighting conditions, camera "
        "angle, and how the fabric folds/drapes/creases over the body in this specific photo — "
        "these notes will guide how a new design is rendered onto this exact garment photo."
    ]

    blouse_bytes = await fetch_image_bytes(blouse_image_url)
    contents.append("Blouse reference:")
    contents.append(types.Part.from_bytes(data=blouse_bytes, mime_type="image/png"))

    saree_part = await _resolve_image_part(saree_image_url, saree_color_hex)
    if saree_part:
        contents.append("Saree reference (colour context only):")
        contents.append(saree_part)

    last_error: Optional[Exception] = None
    for attempt in range(_MAX_ANALYSIS_ATTEMPTS):
        try:
            response = await client.aio.models.generate_content(
                model=settings.GEMINI_TEXT_MODEL,
                contents=contents,
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    response_schema=GARMENT_ANALYSIS_SCHEMA,
                    temperature=0.2,
                ),
            )
            payload = json.loads(response.text)

            missing = [field for field in GARMENT_ANALYSIS_SCHEMA["required"] if not payload.get(field, "").strip()]
            if missing:
                raise AIServiceError(f"Gemini returned empty garment-analysis fields: {missing}")

            return GarmentAnalysis(**payload)
        except Exception as exc:
            last_error = exc
            if attempt < _MAX_ANALYSIS_ATTEMPTS - 1:
                await asyncio.sleep(2 * (attempt + 1))

    raise AIServiceError(f"Garment analysis failed after {_MAX_ANALYSIS_ATTEMPTS} attempts: {last_error}")


QA_SCORE_SCHEMA = {
    "type": "object",
    "properties": {
        "pattern_similarity": {"type": "number", "description": "0-100: how closely the stitched pattern's outline/geometry matches the reference"},
        "color_similarity": {"type": "number", "description": "0-100: how closely the thread/bead colours match the reference"},
        "bead_preservation": {"type": "number", "description": "0-100: whether individual bead shapes/count/arrangement were preserved, not invented or dropped"},
        "geometry_preservation": {"type": "number", "description": "0-100: whether the design's proportions and orientation were preserved, not distorted"},
        "garment_preservation": {"type": "number", "description": "0-100: whether everything outside the embroidery region (fabric colour, folds, background) stayed unchanged"},
        "overall_score": {"type": "number", "description": "0-100: your overall fidelity verdict weighing all the above"},
        "notes": {"type": "string", "description": "1-2 sentences on the most significant fidelity issue found, or 'No significant issues' if none"},
    },
    "required": [
        "pattern_similarity", "color_similarity", "bead_preservation",
        "geometry_preservation", "garment_preservation", "overall_score", "notes",
    ],
}


async def score_visualization(reference_bytes: bytes, generated_bytes: bytes) -> QAScoreBreakdown:
    """Soft AI-reviewer fidelity check: does the generated visualization faithfully preserve
    the reference embroidery, not a precise pixel-accuracy metric. Used to pick between at most
    two generation attempts (see visualization_pipeline.py) — never to block generation outright.
    """
    client = get_gemini_client()

    contents: list = [
        "You are a strict quality reviewer for an Aari embroidery visualization pipeline. "
        "The FIRST image is the original embroidery reference (source of truth). The SECOND "
        "image is a photorealistic render of that exact embroidery stitched onto a blouse. "
        "Score, from 0 to 100, how faithfully the second image preserves the first image's "
        "embroidery design — NOT how beautiful or realistic it looks in general. A gorgeous "
        "render that invents a different pattern, changes bead colours, or alters the garment "
        "outside the embroidery region must score low. Every numeric field is required.",
        "Reference embroidery design:",
        types.Part.from_bytes(data=reference_bytes, mime_type="image/png"),
        "Generated visualization:",
        types.Part.from_bytes(data=generated_bytes, mime_type="image/png"),
    ]

    last_error: Optional[Exception] = None
    for attempt in range(_MAX_ANALYSIS_ATTEMPTS):
        try:
            response = await client.aio.models.generate_content(
                model=settings.GEMINI_TEXT_MODEL,
                contents=contents,
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    response_schema=QA_SCORE_SCHEMA,
                    temperature=0.1,
                ),
            )
            payload = json.loads(response.text)

            missing = [
                field
                for field in QA_SCORE_SCHEMA["required"]
                if field != "notes" and payload.get(field) is None
            ]
            if missing:
                raise AIServiceError(f"Gemini returned missing QA-score fields: {missing}")

            return QAScoreBreakdown(**payload)
        except Exception as exc:
            last_error = exc
            if attempt < _MAX_ANALYSIS_ATTEMPTS - 1:
                await asyncio.sleep(2 * (attempt + 1))

    raise AIServiceError(f"QA scoring failed after {_MAX_ANALYSIS_ATTEMPTS} attempts: {last_error}")
