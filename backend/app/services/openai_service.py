"""Photorealistic preview generation via OpenAI's gpt-image-1 API.

Text-to-image only: the Images API has no image-to-image/editing mode, so the result is
generated from a text description of the detected saree/blouse colours and design style rather
than directly editing the user's uploaded photos.
"""
from functools import lru_cache
from typing import Optional

import base64

from openai import AsyncOpenAI

from app.core.config import settings
from app.schemas.design import BeadRecommendation, LookStyle
from app.schemas.visualization import GarmentAnalysis
from app.utils.exceptions import AIServiceError

LOOK_STYLE_PROMPTS: dict[LookStyle, str] = {
    LookStyle.LUXURY: (
        "opulent luxury editorial styling, radiant studio lighting, high-fashion magazine cover feel"
    ),
    LookStyle.TRADITIONAL: (
        "classic South Indian traditional styling, warm golden-hour lighting, heritage jewellery, temple backdrop feel"
    ),
    LookStyle.MINIMAL: (
        "minimal and understated elegance, soft neutral lighting, clean uncluttered composition, subtle embellishment density"
    ),
    LookStyle.BRIDAL: (
        "grand bridal styling, dense ornate embroidery coverage, rich layered jewellery, warm romantic lighting"
    ),
    LookStyle.TEMPLE_JEWELLERY: (
        "temple jewellery inspired aesthetic, motifs echoing temple architecture, antique gold tones, devotional elegance"
    ),
    LookStyle.MODERN_DESIGNER: (
        "modern fashion-forward designer styling, contemporary silhouette, editorial runway lighting, bold clean lines"
    ),
}


# DALL-E 3 has no separate negative-prompt parameter, so exclusions are folded into the main
# prompt instead of sent as a distinct field.
_AVOID_CLAUSE = (
    "Avoid: wrong saree colour, wrong blouse colour, plain unembellished blouse, western dress, "
    "generic clothing, cartoon or illustration style, low quality, blurry, deformed hands, extra "
    "limbs, text, watermark, logo."
)


@lru_cache
def get_openai_client() -> AsyncOpenAI:
    if not settings.OPENAI_API_KEY:
        raise AIServiceError("OPENAI_API_KEY is not configured on the server.")
    return AsyncOpenAI(api_key=settings.OPENAI_API_KEY)


def _build_generation_prompt(
    detected_saree_color: str,
    detected_blouse_color: str,
    detected_design_style: str,
    bead_recommendations: list[BeadRecommendation],
    look_style: LookStyle,
) -> str:
    bead_names = ", ".join(b.name for b in bead_recommendations) or "Antique Gold, Pearl White"
    style_modifier = LOOK_STYLE_PROMPTS[look_style]
    # Colour + style are stated up front, then repeated in the closing line — text-to-image
    # models weight both the earliest and the most recent tokens most heavily, and this is the
    # one place we can steer accuracy since there's no reference image to condition on.
    return (
        f"A {detected_saree_color} coloured saree, a {detected_blouse_color} coloured fitted blouse, "
        f"{detected_design_style} Aari embroidery on the blouse. "
        "Photorealistic high-fashion portrait of an Indian woman wearing exactly this outfit: "
        f"the saree is {detected_saree_color}, the blouse is {detected_blouse_color} and hand-embroidered "
        f"in a {detected_design_style} style, embellished with {bead_names} beads and sequins catching "
        "the light with realistic sheen and texture. Embroidery coverage on the blouse yoke, sleeves "
        f"and back in a symmetrical, couture-finish pattern. Overall styling: {style_modifier}. "
        "Shot like a premium fashion editorial: sharp focus on the embroidery detail, soft "
        "flattering light, elegant pose, realistic fabric drape and skin tones, no text or watermark. "
        f"The saree must be {detected_saree_color} and the blouse must be {detected_blouse_color} — "
        f"do not substitute different colours. {_AVOID_CLAUSE}"
    )


async def generate_preview_image(
    embroidery_design_url: str,
    blouse_image_url: Optional[str],
    detected_saree_color: str,
    detected_blouse_color: str,
    detected_design_style: str,
    bead_recommendations: list[BeadRecommendation],
    look_style: LookStyle,
) -> tuple[bytes, str]:
    """Generate a photorealistic preview from a text prompt. Returns (image_bytes, prompt_used).

    `embroidery_design_url` / `blouse_image_url` are accepted for signature parity with the
    analysis step's inputs, but are not sent to the model — see module docstring.
    """
    client = get_openai_client()
    prompt = _build_generation_prompt(
        detected_saree_color, detected_blouse_color, detected_design_style, bead_recommendations, look_style
    )

    try:
        response = await client.images.generate(
            model=settings.OPENAI_IMAGE_MODEL,
            prompt=prompt,
            size="1024x1024",  # square is the cheapest size tier — portrait/landscape cost more
            quality=settings.OPENAI_IMAGE_QUALITY,
            n=1,
        )
        image_b64 = response.data[0].b64_json
        used_prompt = getattr(response.data[0], "revised_prompt", None) or prompt
        return base64.b64decode(image_b64), used_prompt
    except Exception as exc:
        raise AIServiceError(f"Preview generation failed: {exc}") from exc


def _build_visualization_prompt(
    garment: GarmentAnalysis, look_style: LookStyle, has_saree_reference: bool
) -> str:
    """Builds the images.edit() prompt for the visualization pipeline. Final rendering
    objective: a complete boutique product photograph — the supplied blouse, saree and
    embroidery shown on a premium display mannequin, not a close-up of the blouse alone. Core
    rule unchanged from the previous close-up version: the embroidery reference is a
    DESIGN-IDENTITY reference (motif, geometry, colours, bead/stone/pearl placement), not a flat
    sticker to be pasted — re-render it as real physical embroidery integrated into the blouse,
    preserving design identity while re-rendering only physical material interaction. The saree
    is now a primary preserved asset (colour, border, pallu unchanged), not just colour-harmony
    context for Gemini's garment analysis.

    There is no manual placement step and no pixel mask — the model decides embroidery
    placement, scale and orientation itself, as a professional embroidery designer would (both
    dropped earlier this session: the mask because a live comparison test showed a full-image
    edit preserves far more reference detail, and manual placement because it added a UI step
    users didn't want).
    """
    style_modifier = LOOK_STYLE_PROMPTS[look_style]
    fold_notes = garment.fold_and_drape_notes.rstrip(".")
    structure = f"{garment.neckline} neckline, {garment.sleeve_type} sleeves"

    if has_saree_reference:
        saree_role = (
            "IMAGE 3 — SAREE REFERENCE\n"
            "This image shows the exact saree (or, if a plain colour swatch, the exact saree "
            "colour) to be paired with the blouse in the final photograph."
        )
        saree_instruction = (
            "Drape the saree shown in IMAGE 3 around the mannequin, correctly paired with the "
            "blouse, in a realistic traditional style."
        )
    else:
        saree_role = (
            "No saree reference image was supplied. Pair the blouse with a saree in a colour "
            "that harmonises naturally with the blouse and embroidery — this is the one "
            "exception to the \"never invent\" rule below, since a complete outfit photograph "
            "requires a saree and none was given."
        )
        saree_instruction = (
            "Drape a naturally complementary saree around the mannequin, correctly paired with "
            "the blouse, in a realistic traditional style."
        )

    return f"""TASK TYPE:
REFERENCE-GUIDED BOUTIQUE PRODUCT PHOTOGRAPH VISUALIZATION.
THIS IS NOT A CREATIVE DESIGN OR IMAGE-GENERATION TASK.

============================================================
INPUT ROLES
============================================================

IMAGE 1 — TARGET BLOUSE
This is the blouse onto which the embroidery must be visualized.

IMAGE 2 — EMBROIDERY REFERENCE
This image contains the exact embroidery design that must be visualized on the target blouse.

{saree_role}

The embroidery reference defines WHAT must be embroidered.

The target blouse defines WHAT it must be embroidered ON.

You decide WHERE and HOW LARGE the embroidery must appear (see EMBROIDERY PLACEMENT below).

Your responsibility is to visualize how the supplied embroidery would physically look if a skilled professional artisan recreated and stitched that same design directly onto the supplied blouse, and to present that blouse — paired with the saree — as a complete outfit worn on a premium boutique display mannequin, as a bridal boutique catalogue photograph.

The blouse alone, without the saree and without the mannequin presentation, is NOT an acceptable final output.

============================================================
CORE VISUALIZATION RULE
============================================================

DO NOT treat the embroidery reference as a flat image, sticker, decal, texture, print, patch, or photograph that should simply be pasted onto the garment.

The embroidery reference is a DESIGN-IDENTITY REFERENCE.

Re-render the embroidery design as REAL PHYSICAL EMBROIDERY integrated into the target garment.

The reference photograph's pixels do not need to remain identical.

The DESIGN represented by those pixels must remain faithful.

Preserve DESIGN IDENTITY.

Re-render PHYSICAL MATERIAL APPEARANCE.

============================================================
CRITICAL EMBROIDERY SUBSTRATE RULE
============================================================

The target garment fabric itself must be the base/substrate of the embroidery.

DO NOT reconstruct the reference embroidery as one complete physical object, patch, appliqué, badge, panel, cutout, or detachable ornament.

Instead, reconstruct the INDIVIDUAL embroidery components directly on the existing target garment fabric.

The target garment fabric must remain naturally visible:

- between separate embroidery elements,
- inside open spaces in the motif,
- around thread paths,
- between bead clusters,
- and wherever the original embroidery design contains exposed substrate.

Do NOT transfer the original reference image's underlying fabric/background onto the target garment.

Do NOT create a new backing layer beneath the embroidery.

For every location in the reference, distinguish between:

A) ACTUAL EMBROIDERY MATERIAL: thread, zari, beads, stones, pearls, sequins and other stitched decoration.

B) ORIGINAL REFERENCE SUBSTRATE: the fabric/background visible behind and between those materials.

Transfer ONLY category A.

Category B must NOT be transferred.

Where the reference contains exposed background/fabric, the corresponding area in the result must show the TARGET GARMENT'S ORIGINAL FABRIC.

The final construction should therefore be:

TARGET GARMENT FABRIC
+
INDIVIDUAL THREAD / BEAD / STONE / ZARI ELEMENTS
+
REALISTIC CONTACT, DEPTH AND SHADOW

NOT:

TARGET GARMENT
+
COMPLETE EMBROIDERY CUTOUT/PATCH.

The result must look as if an artisan took the bare target garment and individually stitched the supplied reference design directly into that existing fabric.

============================================================
DESIGN FIDELITY — MUST BE PRESERVED
============================================================

Faithfully preserve all visible design characteristics present in the supplied embroidery reference, including where applicable:

- motif identity
- overall composition
- major shapes
- minor shapes
- internal arrangement
- relative geometry
- proportions
- spacing
- symmetry or asymmetry
- orientation
- colour relationships
- thread colours
- zari colours
- bead placement
- bead colours
- stone placement
- stone colours
- pearl placement
- sequin placement
- decorative element placement
- borders
- curves
- line structure
- density
- recognizable internal details

If a listed material or feature is NOT present in the reference, DO NOT introduce it.

Do not redesign the embroidery.

Do not reinterpret the embroidery.

Do not simplify the embroidery.

Do not embellish the embroidery.

Do not replace the embroidery with a similar design.

Do not create an "inspired by" version.

Do not invent additional motifs, flowers, leaves, birds, animals, patterns, beads, stones, pearls, sequins, borders, lines, or decorative elements.

The supplied embroidery reference is the authoritative source of truth.

============================================================
PHYSICAL EMBROIDERY RE-RENDERING
============================================================

Reconstruct the supplied design as physically plausible embroidery directly attached to the target garment.

Use ONLY the materials and construction characteristics visually supported by the reference image.

Where present in the reference, realistically render characteristics such as:

- embroidery thread
- Aari stitching
- zari or metallic thread
- beads
- stones
- crystals
- pearls
- sequins
- raised embroidery
- layered embroidery
- thread thickness
- stitch density
- material depth
- reflective highlights
- metallic reflections
- bead reflections
- tiny contact shadows
- thread shadows
- stitch-level surface texture
- natural handmade material variation

Do not introduce materials that are absent from the reference.

The embroidery must appear physically stitched into or attached through the garment fabric rather than floating above it.

============================================================
EMBROIDERY CONSTRUCTION ANALYSIS
============================================================

Before rendering the garment, carefully analyse the supplied embroidery reference image.

Do not analyse only the colours and visible pattern.

Also analyse the physical construction of the embroidery.

Determine whether the embroidery is:

- Flat thread embroidery
- Raised embroidery
- 3D embossed embroidery
- Layered embroidery
- Appliqué work
- Bead embroidery
- Pearl work
- Stone work
- Kundan work
- Mirror work
- Zari work
- Sequins
- Foam-backed embroidery
- Mixed construction

The physical construction visible in the reference image is part of the design itself.

It is NOT optional.

It must be preserved exactly.

Never flatten a raised embroidery.

Never convert embossed embroidery into printed embroidery.

Never convert layered embroidery into flat stitching.

Never simplify the construction.

If the supplied embroidery visibly projects above the garment surface, the generated result must preserve the same raised three-dimensional appearance.

The output should accurately reproduce the same depth, layering, protrusion, bead height, thread thickness, shadowing and physical volume visible in the supplied embroidery reference.

============================================================
THREE-DIMENSIONAL EMBROIDERY PRESERVATION
============================================================

If the reference embroidery contains three-dimensional or embossed elements, these must remain physically raised after being stitched onto the blouse.

Raised embroidery should visibly project above the fabric surface exactly as genuine handcrafted Aari embroidery would.

Preserve:

- embroidery thickness
- bead height
- pearl height
- layered petals
- raised peacock necks
- raised wings
- raised feathers
- raised floral elements
- overlapping components
- stitched depth
- physical volume

Generate realistic depth using:

- natural shadows
- ambient occlusion
- soft edge shadows
- realistic highlights
- thread reflections
- pearl reflections
- bead reflections

The embroidery must appear as an object attached onto the blouse rather than a flat printed texture.

If the embroidery is flat in the reference image, it must remain flat.

If the embroidery is raised in the reference image, it must remain raised.

Do not invent additional depth where none exists.

Do not remove depth where it already exists.

Preserve the construction exactly as observed.

The embroidery reference is the complete source of truth.

Faithfully preserve not only the visual appearance of the embroidery but also its physical construction.

The embroidery's geometry, proportions, colours, bead placement, stitch layout, material composition, layering, and three-dimensional structure are all part of the design and must remain unchanged.

If the supplied embroidery is visibly embossed, raised or layered, the generated result must preserve that same three-dimensional handcrafted appearance on the blouse.

Only adapt the embroidery to the natural curvature, folds, lighting and perspective of the garment.

Never reinterpret the construction.

============================================================
FABRIC AND SURFACE INTEGRATION
============================================================

Adapt ONLY the physical rendering of the embroidery to the actual garment surface.

The embroidery should naturally respond to the garment's:

- surface orientation
- curvature
- folds
- wrinkles
- seams
- drape
- perspective
- camera angle
- lighting
- highlights
- shadows
- local surface deformation

When the embroidery crosses a fold, curve, seam, or changing surface orientation, make it follow that physical surface naturally while preserving the underlying design identity and relative structure.

Create convincing physical contact between embroidery and fabric.

The result must NOT look like:

- a sticker
- a decal
- a printed graphic
- a digital overlay
- a pasted photograph
- a floating object
- a flat texture
- an artificial patch unless the reference itself is actually a patch

============================================================
TARGET GARMENT CONTEXT
============================================================

The following information describes the CURRENT user's target garment.

Garment type:
Blouse

Garment fabric/material:
{garment.fabric_type}

Garment base colour:
{garment.blouse_color}

Garment surface/texture:
{garment.fabric_type}

Garment structure/details:
{structure}

Camera/view angle:
{garment.camera_angle}

Lighting:
{garment.lighting}

Visible folds/drape:
{fold_notes}

Additional garment observations:
Desired styling mood: {style_modifier}. This affects only how realistically the stitching, thread sheen and beadwork catch the light — it must never change the embroidery design itself.

These values describe the supplied garment.

They must NOT be interpreted as permission to redesign it.

============================================================
GARMENT PRESERVATION
============================================================

Preserve the target blouse as faithfully as possible.

Do NOT unnecessarily change:

- blouse colour
- fabric identity
- blouse construction
- neckline
- sleeves
- seams
- borders
- existing decorations

Only introduce the physical visual changes necessary for the embroidery to appear realistically stitched onto the blouse, and for the blouse to appear naturally worn on the mannequin as part of the final photograph.

============================================================
SAREE PRESERVATION
============================================================

{saree_instruction}

Do NOT unnecessarily change:

- saree colour
- saree border
- saree pallu
- saree pattern

Only introduce the physical visual changes necessary for the saree to appear naturally draped on the mannequin.

============================================================
EMBROIDERY PLACEMENT — YOUR DECISION
============================================================

No manual placement was specified for this design. Decide the placement, size, and orientation
yourself, as a professional embroidery designer would when adding this specific motif to this
specific blouse.

Choose whichever region is most natural and customary for a motif of this kind and size —
typically the yoke, front panel, sleeve, border, or back panel of the blouse, wherever an
experienced artisan would place it for a balanced, wearable result.

Size it proportionally to the blouse so it reads as a realistic embroidery placement, not
oversized or undersized.

Do NOT redesign the embroidery itself while deciding this — placement, scale, and orientation
are your decision; the design identity is not.

============================================================
MANNEQUIN REQUIREMENTS
============================================================

Use a premium, elegant, neutral bridal boutique display mannequin.

No facial features.

No makeup.

No hairstyle.

No jewellery or other accessories.

No fashion redesign of the mannequin itself.

The mannequin exists ONLY as a presentation surface for the blouse and saree — it must NEVER
become the visual focus. The GARMENT DESIGN — the blouse, the saree, and above all the
embroidery — remains the focus of the photograph at all times.

============================================================
PRESENTATION STYLE
============================================================

Generate a luxury bridal boutique catalogue photograph:

- professional studio lighting
- luxury showroom presentation
- soft realistic shadows
- high-end commercial product photography
- natural silk reflections
- realistic embroidery thread sheen
- natural bead reflections
- photorealistic quality

Overall styling mood: {style_modifier} — this affects only lighting/atmosphere, never the
embroidery design, the blouse, or the saree themselves.

No text, no watermark, no logo.

============================================================
FINAL OBJECTIVE
============================================================

Produce a photorealistic BOUTIQUE PRODUCT PHOTOGRAPH answering ONE question:

"What would the complete outfit — THIS supplied blouse, embroidered with THIS supplied embroidery design, paired with THIS supplied saree — actually look like displayed on a premium boutique mannequin, exactly as a bridal boutique catalogue would photograph it?"

The finished image should look as though this exact outfit was professionally tailored, embroidered by a skilled artisan, dressed onto the mannequin, and photographed in a premium boutique studio.

A viewer should immediately understand exactly how the complete outfit will look when worn.

This application is NOT an AI fashion designer. It is NOT generating a new garment, a new
embroidery, or a new saree. It is a visualization engine — the output must faithfully visualize
the exact user-provided assets as they would appear in a professional bridal boutique display.

Preserve the embroidery's DESIGN IDENTITY.

Preserve the blouse's VISUAL IDENTITY.

Preserve the saree's VISUAL IDENTITY.

Re-render only the physical material interaction and the boutique presentation — never the
designs themselves.

Fidelity is more important than creativity.

Accuracy is more important than beautification.

Do not add text.

Do not add watermarks.

Do not add unrelated objects.

Do not make unrelated modifications."""


async def generate_visualization(
    blouse_bytes: bytes,
    embroidery_asset_bytes: bytes,
    saree_bytes: Optional[bytes],
    prompt: str,
    size: str,
) -> bytes:
    """Core visualization call: composes the final boutique product photograph (blouse + saree +
    embroidery on a display mannequin), using the blouse, embroidery and — when available —
    saree images as references. No mask — a live comparison test showed a full-image edit
    preserves reference detail (bead/pearl borders, exact background colour) far better than a
    masked edit, so the model is trusted to compose the scene based on the prompt alone.

    `size` MUST match the actual pixel dimensions of `blouse_bytes` (one of
    image_utils.OPENAI_EDIT_CANVASES) — images.edit() requires one of its 3 supported canvases.
    """
    client = get_openai_client()

    images = [
        ("blouse.png", blouse_bytes, "image/png"),
        ("embroidery.png", embroidery_asset_bytes, "image/png"),
    ]
    if saree_bytes:
        images.append(("saree.png", saree_bytes, "image/png"))

    try:
        response = await client.images.edit(
            model=settings.OPENAI_EDIT_MODEL,
            image=images,
            prompt=prompt,
            size=size,
            quality=settings.OPENAI_EDIT_QUALITY,
            input_fidelity="high",
            n=1,
        )
        image_b64 = response.data[0].b64_json
        return base64.b64decode(image_b64)
    except Exception as exc:
        raise AIServiceError(f"Visualization generation failed: {exc}") from exc
