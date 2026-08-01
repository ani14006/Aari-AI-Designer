"""Core AI image generation endpoints: initial preview + one-click regeneration in a new look style.

The reference-image-faithful visualization pipeline (/visualize, /regenerate) runs as a
background task rather than blocking the HTTP request — real generation takes 1-5 minutes
(background removal + Gemini analysis + up to 2 rounds of OpenAI image generation + QA
scoring), which exceeds the reverse-proxy timeout on most hosting platforms' free/default
tiers if held open as a single synchronous request (confirmed in production: Render was
killing the connection before OpenAI finished). The endpoint creates the Design row
immediately with status="processing" and returns right away; the frontend polls
GET /designs/{id} and watches `status` until it's "completed" or "failed".
"""
import base64
import logging
from typing import Optional

from fastapi import APIRouter, BackgroundTasks, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.db.session import AsyncSessionLocal, get_db
from app.models.design import Design
from app.models.user import User
from app.schemas.design import (
    BeadRecommendation,
    DesignRead,
    GenerationRequest,
    LookStyle,
    OrderDetails,
    PaletteOption,
)
from app.schemas.visualization import VisualizationJob, VisualizationRequest
from app.services import cloudinary_service, gemini_service, openai_service, visualization_pipeline
from app.services.shopping_list_service import build_shopping_list
from app.utils.exceptions import NotFoundError, ValidationError

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/generation", tags=["generation"])


async def _generate_and_persist(
    db: AsyncSession,
    user: User,
    design: Optional[Design],
    embroidery_design_url: str,
    saree_image_url: Optional[str],
    saree_color_hex: Optional[str],
    blouse_image_url: Optional[str],
    blouse_color_hex: Optional[str],
    detected_saree_color: str,
    detected_blouse_color: str,
    detected_design_style: str,
    bead_recommendations: list[BeadRecommendation],
    look_style: LookStyle,
    palette_options: Optional[list[PaletteOption]] = None,
    selected_palette_index: int = 0,
    order_details: Optional[OrderDetails] = None,
) -> Design:
    """Older text-to-image flow — a single OpenAI call, fast enough to stay synchronous."""
    image_bytes, prompt_used = await openai_service.generate_preview_image(
        embroidery_design_url=embroidery_design_url,
        blouse_image_url=blouse_image_url,
        detected_saree_color=detected_saree_color,
        detected_blouse_color=detected_blouse_color,
        detected_design_style=detected_design_style,
        bead_recommendations=bead_recommendations,
        look_style=look_style,
    )

    upload = await cloudinary_service.upload_base64_image(
        base64.b64encode(image_bytes).decode("utf-8"), folder="previews"
    )

    bust = order_details.bust if order_details and order_details.bust is not None else (
        design.bust if design else None
    )
    coverage = order_details.embroidery_coverage.value if order_details and order_details.embroidery_coverage else (
        design.embroidery_coverage if design else ""
    )
    budget = order_details.budget if order_details and order_details.budget is not None else (
        design.budget if design else 0.0
    )
    shopping_list, estimated_cost = build_shopping_list(
        bead_recommendations, look_style, bust=bust, embroidery_coverage=coverage, budget=budget,
    )

    if design is None:
        design = Design(owner_id=user.id)
        db.add(design)

    design.embroidery_design_url = embroidery_design_url
    design.saree_image_url = saree_image_url or ""
    design.saree_color_hex = saree_color_hex or ""
    design.blouse_image_url = blouse_image_url or ""
    design.blouse_color_hex = blouse_color_hex or ""
    design.detected_saree_color = detected_saree_color
    design.detected_blouse_color = detected_blouse_color
    design.detected_design_style = detected_design_style
    design.bead_recommendations = [b.model_dump() for b in bead_recommendations]
    if palette_options:
        design.palette_options = [p.model_dump() for p in palette_options]
        design.selected_palette_index = selected_palette_index
    if order_details:
        design.occasion = order_details.occasion.value if order_details.occasion else ""
        design.blouse_silhouette = order_details.blouse_silhouette.value if order_details.blouse_silhouette else ""
        design.bust = order_details.bust or 0.0
        design.waist = order_details.waist or 0.0
        design.shoulder = order_details.shoulder or 0.0
        design.sleeve_length = order_details.sleeve_length or 0.0
        design.back_neck = order_details.back_neck or 0.0
        design.front_neck = order_details.front_neck or 0.0
        design.embroidery_coverage = order_details.embroidery_coverage.value if order_details.embroidery_coverage else ""
        design.budget = order_details.budget or 0.0
        design.style_preference = order_details.style_preference or ""
    design.look_style = look_style.value
    design.preview_image_url = upload.url
    design.generation_prompt = prompt_used
    design.shopping_list = [item.model_dump() for item in shopping_list]
    design.estimated_cost = estimated_cost
    design.status = "completed"

    await db.commit()
    await db.refresh(design)
    return design


def _apply_visualization_result(
    design: Design, job: VisualizationJob, preview_url: str, order_details: Optional[OrderDetails] = None
) -> None:
    """Copies a completed VisualizationJob's chosen attempt onto `design`. Does not commit —
    callers persist alongside setting `status`."""
    chosen = job.chosen_attempt

    design.embroidery_design_url = job.embroidery_design_url
    design.saree_image_url = job.saree_image_url or ""
    design.saree_color_hex = job.saree_color_hex or ""
    design.blouse_image_url = job.blouse_image_url
    design.detected_saree_color = job.garment.saree_color
    design.detected_blouse_color = job.garment.blouse_color

    if order_details:
        design.occasion = order_details.occasion.value if order_details.occasion else design.occasion
        design.blouse_silhouette = (
            order_details.blouse_silhouette.value if order_details.blouse_silhouette else design.blouse_silhouette
        )
        design.bust = order_details.bust if order_details.bust is not None else design.bust
        design.waist = order_details.waist if order_details.waist is not None else design.waist
        design.shoulder = order_details.shoulder if order_details.shoulder is not None else design.shoulder
        design.sleeve_length = (
            order_details.sleeve_length if order_details.sleeve_length is not None else design.sleeve_length
        )
        design.back_neck = order_details.back_neck if order_details.back_neck is not None else design.back_neck
        design.front_neck = order_details.front_neck if order_details.front_neck is not None else design.front_neck
        design.embroidery_coverage = (
            order_details.embroidery_coverage.value if order_details.embroidery_coverage else design.embroidery_coverage
        )
        design.budget = order_details.budget if order_details.budget is not None else design.budget
        design.style_preference = order_details.style_preference or design.style_preference

    design.look_style = job.look_style.value
    design.preview_image_url = preview_url
    design.generation_prompt = job.prompt or ""
    design.garment_metadata = job.garment.model_dump()
    design.qa_result = chosen.qa.model_dump()
    design.retry_count = job.retry_count


async def _run_visualization_background(design_id: str, user_id: str, payload: VisualizationRequest) -> None:
    """Runs the full visualization pipeline and persists the result, using its own DB session
    since the request-scoped one is already closed by the time a background task executes."""
    async with AsyncSessionLocal() as db:
        result = await db.execute(select(Design).where(Design.id == design_id, Design.owner_id == user_id))
        design = result.scalar_one_or_none()
        if design is None:
            return  # deleted mid-flight — nothing to persist to

        try:
            job = VisualizationJob(
                design_id=design_id,
                embroidery_design_url=payload.embroidery_design_url,
                blouse_image_url=payload.blouse_image_url,
                saree_image_url=payload.saree_image_url,
                saree_color_hex=payload.saree_color_hex,
                look_style=payload.look_style,
            )
            job = await visualization_pipeline.run_visualization(job)
            upload = await cloudinary_service.upload_bytes(job.chosen_attempt.image_bytes, folder="visualizations")

            _apply_visualization_result(design, job, upload.url, order_details=payload.order_details)
            design.status = "completed"
            design.error_message = None
            await db.commit()
        except Exception as exc:
            logger.exception("Background visualization failed for design %s", design_id)
            design.status = "failed"
            design.error_message = str(exc)[:2048]
            await db.commit()


async def _run_regenerate_background(design_id: str, user_id: str, look_style: LookStyle) -> None:
    async with AsyncSessionLocal() as db:
        result = await db.execute(select(Design).where(Design.id == design_id, Design.owner_id == user_id))
        design = result.scalar_one_or_none()
        if design is None:
            return

        try:
            job = VisualizationJob(
                design_id=design.id,
                embroidery_design_url=design.embroidery_design_url,
                blouse_image_url=design.blouse_image_url,
                saree_image_url=design.saree_image_url or None,
                saree_color_hex=design.saree_color_hex or None,
                look_style=look_style,
            )
            job = await visualization_pipeline.run_visualization(job)
            upload = await cloudinary_service.upload_bytes(job.chosen_attempt.image_bytes, folder="visualizations")

            _apply_visualization_result(design, job, upload.url)
            design.status = "completed"
            design.error_message = None
            await db.commit()
        except Exception as exc:
            logger.exception("Background regenerate failed for design %s", design_id)
            design.status = "failed"
            design.error_message = str(exc)[:2048]
            await db.commit()


@router.post("/visualize", response_model=DesignRead)
async def visualize_design(
    payload: VisualizationRequest,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
) -> Design:
    """Reference-image-faithful visualization: renders the user's exact uploaded embroidery
    stitched onto their exact uploaded blouse. The model decides placement, scale and
    orientation itself — there's no manual placement step. Independent of the Design
    Intelligence colour/shopping-list pipeline (bead_recommendations/palette_options are
    untouched by this endpoint).

    Returns immediately with status="processing" — the actual generation runs in the
    background. Poll GET /designs/{id} until status is "completed" or "failed"."""
    design = None
    if payload.design_id:
        result = await db.execute(
            select(Design).where(Design.id == payload.design_id, Design.owner_id == user.id)
        )
        design = result.scalar_one_or_none()
        if design is None:
            raise NotFoundError("Design not found")

    if design is None:
        design = Design(owner_id=user.id)
        db.add(design)

    design.embroidery_design_url = payload.embroidery_design_url
    design.blouse_image_url = payload.blouse_image_url
    design.saree_image_url = payload.saree_image_url or design.saree_image_url or ""
    design.saree_color_hex = payload.saree_color_hex or design.saree_color_hex or ""
    design.look_style = payload.look_style.value
    design.status = "processing"
    design.error_message = None

    await db.commit()
    await db.refresh(design)

    background_tasks.add_task(
        _run_visualization_background, design_id=design.id, user_id=user.id, payload=payload,
    )

    return design


@router.post("/preview", response_model=DesignRead)
async def generate_preview(
    payload: GenerationRequest,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
) -> Design:
    """Run full colour analysis (if bead recommendations weren't supplied) then generate the preview.

    Normally the frontend already ran `/analysis/colors`, let the user pick one of the 3 returned
    palette options, and sends that palette's beads here alongside `palette_options` (all 3, for
    history/display) and `selected_palette_index`. If `bead_recommendations` is omitted entirely
    (e.g. a direct API call), analysis runs here and the first (Complementary) palette is used.

    Unlike /visualize, this stays synchronous — a single OpenAI text-to-image call is fast
    enough to not need the background-task treatment.
    """
    bead_recommendations = payload.bead_recommendations
    palette_options = payload.palette_options
    selected_palette_index = payload.selected_palette_index
    detected_saree_color = payload.detected_saree_color or ""
    detected_blouse_color = payload.detected_blouse_color or ""
    detected_design_style = payload.detected_design_style or ""

    if not bead_recommendations:
        analysis = await gemini_service.analyze_colors(
            saree_image_url=payload.saree_image_url,
            saree_color_hex=payload.saree_color_hex,
            blouse_image_url=payload.blouse_image_url,
            blouse_color_hex=payload.blouse_color_hex,
            embroidery_design_url=payload.embroidery_design_url,
            order_details=payload.order_details,
        )
        palette_options = analysis.palette_options
        selected_palette_index = 0
        bead_recommendations = analysis.palette_options[0].bead_recommendations
        detected_saree_color = analysis.detected_saree_color
        detected_blouse_color = analysis.detected_blouse_color
        detected_design_style = analysis.detected_design_style

    design = None
    if payload.design_id:
        result = await db.execute(
            select(Design).where(Design.id == payload.design_id, Design.owner_id == user.id)
        )
        design = result.scalar_one_or_none()
        if design is None:
            raise NotFoundError("Design not found")
        detected_saree_color = detected_saree_color or design.detected_saree_color
        detected_blouse_color = detected_blouse_color or design.detected_blouse_color
        detected_design_style = detected_design_style or design.detected_design_style

    return await _generate_and_persist(
        db, user, design,
        embroidery_design_url=payload.embroidery_design_url,
        saree_image_url=payload.saree_image_url,
        saree_color_hex=payload.saree_color_hex,
        blouse_image_url=payload.blouse_image_url,
        blouse_color_hex=payload.blouse_color_hex,
        detected_saree_color=detected_saree_color,
        detected_blouse_color=detected_blouse_color,
        detected_design_style=detected_design_style,
        bead_recommendations=bead_recommendations,
        look_style=payload.look_style,
        palette_options=palette_options,
        selected_palette_index=selected_palette_index,
        order_details=payload.order_details,
    )


@router.post("/regenerate/{design_id}", response_model=DesignRead)
async def regenerate_preview(
    design_id: str,
    look_style: LookStyle,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
) -> Design:
    """Re-render an existing design's preview in a different look style, using the same
    embroidery and the same blouse — never a different design. The model re-decides placement
    itself each time, same as the initial generation.

    Requires the design to carry saved `garment_metadata` (i.e. it was created via /visualize).
    Designs from the older /preview flow have no garment analysis to reuse; regenerating one of
    those raises a 422 rather than silently falling back to text-to-image generation.

    Returns immediately with status="processing", same polling contract as /visualize."""
    result = await db.execute(select(Design).where(Design.id == design_id, Design.owner_id == user.id))
    design = result.scalar_one_or_none()
    if design is None:
        raise NotFoundError("Design not found")

    if not design.garment_metadata:
        raise ValidationError(
            "This design was created before the visualization pipeline existed and can't be "
            "regenerated with it — create a new design instead."
        )

    design.status = "processing"
    design.error_message = None
    design.look_style = look_style.value

    await db.commit()
    await db.refresh(design)

    background_tasks.add_task(
        _run_regenerate_background, design_id=design.id, user_id=user.id, look_style=look_style,
    )

    return design
