"""'Buy Materials' one-click cart endpoints."""
from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.cart import CartItem
from app.models.design import Design
from app.models.user import User
from app.schemas.cart import AddToCartRequest, CartSummary
from app.utils.exceptions import NotFoundError

router = APIRouter(prefix="/cart", tags=["cart"])


async def _get_summary(db: AsyncSession, user: User) -> CartSummary:
    result = await db.execute(select(CartItem).where(CartItem.owner_id == user.id).order_by(CartItem.created_at))
    items = list(result.scalars().all())
    return CartSummary(items=items, total_cost=round(sum(i.total_price for i in items), 2))


@router.get("", response_model=CartSummary)
async def get_cart(db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)) -> CartSummary:
    return await _get_summary(db, user)


@router.post("/add", response_model=CartSummary)
async def add_design_materials_to_cart(
    payload: AddToCartRequest,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
) -> CartSummary:
    """Add every item from a design's generated shopping list into the cart in one click."""
    result = await db.execute(
        select(Design).where(Design.id == payload.design_id, Design.owner_id == user.id)
    )
    design = result.scalar_one_or_none()
    if design is None:
        raise NotFoundError("Design not found")

    for entry in design.shopping_list:
        db.add(
            CartItem(
                owner_id=user.id,
                design_id=design.id,
                name=entry["name"],
                quantity=entry["quantity"],
                unit_price=entry["unit_price"],
                total_price=entry["total_price"],
                category=entry.get("category", "material"),
            )
        )
    await db.commit()
    return await _get_summary(db, user)


@router.delete("/{item_id}", response_model=CartSummary)
async def remove_cart_item(
    item_id: str, db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)
) -> CartSummary:
    result = await db.execute(select(CartItem).where(CartItem.id == item_id, CartItem.owner_id == user.id))
    item = result.scalar_one_or_none()
    if item is None:
        raise NotFoundError("Cart item not found")
    await db.delete(item)
    await db.commit()
    return await _get_summary(db, user)


@router.delete("", response_model=CartSummary)
async def clear_cart(db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)) -> CartSummary:
    result = await db.execute(select(CartItem).where(CartItem.owner_id == user.id))
    for item in result.scalars().all():
        await db.delete(item)
    await db.commit()
    return await _get_summary(db, user)
