"""AI colour analysis endpoint: saree + blouse + design in, bead colour recommendations out."""
from fastapi import APIRouter, Depends

from app.api.deps import get_current_user
from app.models.user import User
from app.schemas.design import ColorAnalysisRequest, ColorAnalysisResponse
from app.services import gemini_service

router = APIRouter(prefix="/analysis", tags=["analysis"])


@router.post("/colors", response_model=ColorAnalysisResponse)
async def analyze_colors(
    payload: ColorAnalysisRequest,
    _user: User = Depends(get_current_user),
) -> ColorAnalysisResponse:
    """Analyse saree colour, blouse colour and embroidery design style; recommend bead colours."""
    return await gemini_service.analyze_colors(
        saree_image_url=payload.saree_image_url,
        saree_color_hex=payload.saree_color_hex,
        blouse_image_url=payload.blouse_image_url,
        blouse_color_hex=payload.blouse_color_hex,
        embroidery_design_url=payload.embroidery_design_url,
        order_details=payload.order_details,
    )
