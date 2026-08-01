"""Mannequin presentation endpoint: "View on Mannequin" — a completely separate, optional
post-processing step that runs only after a visualization has already succeeded. Fully isolated
from generation.py/openai_service.py/visualization_pipeline.py (the stable core pipeline) by
design: this file never imports or calls into them, and never modifies their behaviour.
"""
from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.design import Design
from app.models.user import User
from app.schemas.mannequin import MannequinRequest, MannequinResponse
from app.services import cloudinary_service, mannequin_service
from app.utils.exceptions import NotFoundError

router = APIRouter(prefix="/generation", tags=["mannequin"])


@router.post("/mannequin", response_model=MannequinResponse)
async def visualize_on_mannequin(
    payload: MannequinRequest,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
) -> MannequinResponse:
    """Presentation-only: shows an already-completed, faithful visualization worn/draped on a
    mannequin as a product photograph. The completed visualization is the visual source of
    truth — this never regenerates, redesigns, or reinterprets the embroidery.

    `design_id` is optional: if supplied (and owned by the caller), the result is stored as a
    separate derived asset (`mannequin_image_url`) alongside — never overwriting — the design's
    original `preview_image_url`.
    """
    design = None
    if payload.design_id:
        result = await db.execute(
            select(Design).where(Design.id == payload.design_id, Design.owner_id == user.id)
        )
        design = result.scalar_one_or_none()
        if design is None:
            raise NotFoundError("Design not found")

    mannequin_bytes = await mannequin_service.run_mannequin_visualization(
        visualization_url=payload.completed_visualization_url,
        saree_url=payload.saree_image_url,
        saree_color_hex=payload.saree_color_hex,
    )
    upload = await cloudinary_service.upload_bytes(mannequin_bytes, folder="mannequin")

    if design is not None:
        design.mannequin_image_url = upload.url
        await db.commit()

    return MannequinResponse(mannequin_image_url=upload.url)
