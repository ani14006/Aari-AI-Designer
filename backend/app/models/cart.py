"""Cart item model, populated via the 'Buy Materials' one-click action."""
import uuid

from sqlalchemy import Float, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, TimestampMixin


class CartItem(Base, TimestampMixin):
    __tablename__ = "cart_items"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    owner_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    design_id: Mapped[str] = mapped_column(String(36), ForeignKey("designs.id"), nullable=True)

    name: Mapped[str] = mapped_column(String(255), nullable=False)
    quantity: Mapped[str] = mapped_column(String(64), default="1")
    unit_price: Mapped[float] = mapped_column(Float, default=0.0)
    total_price: Mapped[float] = mapped_column(Float, default=0.0)
    category: Mapped[str] = mapped_column(String(64), default="material")  # material | tool | fabric
