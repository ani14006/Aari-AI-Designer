"""Design history: list, fetch, favourite/save, delete previously generated designs."""
from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.design import Design
from app.models.user import User
from app.schemas.design import DesignRead, DesignUpdate, WhatsappMessageResponse
from app.services.whatsapp_service import build_whatsapp_message
from app.utils.exceptions import NotFoundError

router = APIRouter(prefix="/designs", tags=["designs"])


@router.get("", response_model=list[DesignRead])
async def list_designs(
    favourites_only: bool = False,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
) -> list[Design]:
    """Design History: every design the user has generated, newest first."""
    query = select(Design).where(Design.owner_id == user.id).order_by(Design.created_at.desc())
    if favourites_only:
        query = query.where(Design.is_favourite.is_(True))
    result = await db.execute(query)
    return list(result.scalars().all())


@router.get("/{design_id}", response_model=DesignRead)
async def get_design(
    design_id: str,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
) -> Design:
    result = await db.execute(select(Design).where(Design.id == design_id, Design.owner_id == user.id))
    design = result.scalar_one_or_none()
    if design is None:
        raise NotFoundError("Design not found")
    return design


@router.get("/{design_id}/whatsapp-message", response_model=WhatsappMessageResponse)
async def get_whatsapp_message(
    design_id: str,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
) -> WhatsappMessageResponse:
    """Pre-composed WhatsApp share text: design details, materials list and estimated cost."""
    result = await db.execute(select(Design).where(Design.id == design_id, Design.owner_id == user.id))
    design = result.scalar_one_or_none()
    if design is None:
        raise NotFoundError("Design not found")
    return WhatsappMessageResponse(message=build_whatsapp_message(design))


@router.patch("/{design_id}", response_model=DesignRead)
async def update_design(
    design_id: str,
    payload: DesignUpdate,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
) -> Design:
    """Toggle favourite/saved state or persist a chosen look style."""
    result = await db.execute(select(Design).where(Design.id == design_id, Design.owner_id == user.id))
    design = result.scalar_one_or_none()
    if design is None:
        raise NotFoundError("Design not found")

    if payload.is_favourite is not None:
        design.is_favourite = payload.is_favourite
    if payload.is_saved is not None:
        design.is_saved = payload.is_saved
    if payload.look_style is not None:
        design.look_style = payload.look_style.value

    await db.commit()
    await db.refresh(design)
    return design


@router.delete("/{design_id}", status_code=204)
async def delete_design(
    design_id: str,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
) -> None:
    result = await db.execute(select(Design).where(Design.id == design_id, Design.owner_id == user.id))
    design = result.scalar_one_or_none()
    if design is None:
        raise NotFoundError("Design not found")
    await db.delete(design)
    await db.commit()
