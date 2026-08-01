"""Pydantic schemas for the shopping cart."""
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict


class CartItemRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    design_id: Optional[str]
    name: str
    quantity: str
    unit_price: float
    total_price: float
    category: str
    created_at: datetime


class AddToCartRequest(BaseModel):
    design_id: str


class CartSummary(BaseModel):
    items: list[CartItemRead]
    total_cost: float
