# AARI VISUALIZATION PROMPT — BACKUP CHECKPOINT
#
# Saved: 2026-07-31
# Source: app/services/openai_service.py, _build_visualization_prompt()
# Status at save time: confirmed working well for image generation (user-verified).
#
# This is a REFERENCE BACKUP ONLY — not imported or used anywhere. It exists purely so that if
# future tweaks to the live prompt in openai_service.py make results worse, you can restore this
# exact known-good version by copy-pasting the function below back over
# _build_visualization_prompt() in openai_service.py (same signature, same imports needed:
# GarmentAnalysis from app.schemas.visualization, LookStyle from app.schemas.design,
# LOOK_STYLE_PROMPTS defined earlier in openai_service.py).
#
# Includes the "CRITICAL EMBROIDERY SUBSTRATE RULE" section (added to fix embroidery being
# rendered as a complete patch/appliqué instead of individual thread/bead elements stitched
# directly onto the target garment fabric) and the "EMBROIDERY PLACEMENT — YOUR DECISION"
# section (added when manual placement was removed — the model decides placement itself).


def _build_visualization_prompt(garment: "GarmentAnalysis", look_style: "LookStyle") -> str:
    """Builds the images.edit() prompt for the visualization pipeline — the standard template
    established this session. Core rule: the embroidery reference is a DESIGN-IDENTITY
    reference (motif, geometry, colours, bead/stone/pearl placement), not a flat sticker to be
    pasted — re-render it as real physical embroidery integrated into the target garment,
    preserving design identity while re-rendering only physical material interaction.

    There is no manual placement step and no pixel mask — the model decides placement, scale and
    orientation itself, as a professional embroidery designer would (both dropped this session:
    the mask because a live comparison test showed a full-image edit preserves far more
    reference detail, and manual placement because it added a UI step users didn't want).
    """
    style_modifier = LOOK_STYLE_PROMPTS[look_style]
    fold_notes = garment.fold_and_drape_notes.rstrip(".")
    structure = f"{garment.neckline} neckline, {garment.sleeve_type} sleeves"

    return f"""TASK TYPE:
REFERENCE-GUIDED EMBROIDERY VISUALIZATION.
THIS IS NOT A CREATIVE DESIGN OR IMAGE-GENERATION TASK.

============================================================
INPUT ROLES
============================================================

IMAGE 1 — TARGET GARMENT
This is the garment onto which the embroidery must be visualized.

IMAGE 2 — EMBROIDERY REFERENCE
This image contains the exact embroidery design that must be visualized on the target garment.

The embroidery reference defines WHAT must be embroidered.

The target garment defines WHAT it must be embroidered ON.

You decide WHERE and HOW LARGE it must appear (see EMBROIDERY PLACEMENT below).

Your responsibility is ONLY to visualize how the supplied embroidery would physically look if a skilled professional artisan recreated and stitched that same design directly onto the supplied garment.

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

Preserve the target garment as faithfully as possible.

Do NOT unnecessarily change:

- garment colour
- fabric identity
- garment construction
- neckline
- sleeves
- seams
- borders
- existing decorations
- folds
- wrinkles
- lighting
- shadows
- camera perspective
- background
- surrounding objects

Only introduce the physical visual changes necessary for the embroidery to appear realistically stitched onto the selected region.

============================================================
EMBROIDERY PLACEMENT — YOUR DECISION
============================================================

No manual placement was specified for this design. Decide the placement, size, and orientation
yourself, as a professional embroidery designer would when adding this specific motif to this
specific garment.

Choose whichever region is most natural and customary for a motif of this kind and size —
typically the yoke, front panel, sleeve, border, or back panel of the blouse, wherever an
experienced artisan would place it for a balanced, wearable result.

Size it proportionally to the garment so it reads as a realistic embroidery placement, not
oversized or undersized relative to the blouse.

Do NOT redesign the embroidery itself while deciding this — placement, scale, and orientation
are your decision; the design identity is not.

============================================================
EDITING BOUNDARY
============================================================

No pixel mask is supplied for this edit — you may modify whatever part of the garment is
necessary to add the embroidery realistically at the placement you choose.

Do not change the garment's fundamental colour, fabric identity, silhouette, or background — the
only substantive addition should be the embroidery itself.

Do not use this task as an opportunity to regenerate or beautify unrelated portions of the image.

============================================================
OPTIONAL OUTFIT CONTEXT
============================================================

Additional outfit/reference context may be provided:

This blouse is paired with a {garment.saree_color} saree, for overall colour-harmony context only.

This information may be used ONLY to understand the overall outfit relationship.

It must NOT override:

1. the embroidery reference,
2. or the target garment.

Do NOT redesign the embroidery to better match the outfit.

Do NOT recolour the embroidery for colour harmony.

Do NOT alter the target garment based on this context.

============================================================
FINAL OBJECTIVE
============================================================

Produce a photorealistic visualization answering ONE question:

"What would THIS supplied embroidery design actually look like if it were professionally stitched onto THIS supplied garment, placed wherever a professional artisan would naturally place it?"

The finished image should look as though the target garment was photographed AFTER a skilled artisan physically recreated and stitched the supplied embroidery design onto it.

A viewer should perceive:

REAL EMBROIDERY
+
REAL GARMENT
+
REAL PHYSICAL INTEGRATION

—not an image pasted over another image.

Preserve the embroidery's DESIGN IDENTITY.

Preserve the garment's VISUAL IDENTITY.

Re-render only the embroidery's PHYSICAL MATERIAL INTERACTION with the garment.

Fidelity is more important than creativity.

Accuracy is more important than beautification.

Do not add text.

Do not add watermarks.

Do not add unrelated objects.

Do not make unrelated modifications."""
