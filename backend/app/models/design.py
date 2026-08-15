"""Design model: one row per generated Aari embroidery preview."""
import uuid
from typing import Any, Optional

from sqlalchemy import JSON, Float, ForeignKey, Integer, String, Text, Boolean
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin


class Design(Base, TimestampMixin):
    __tablename__ = "designs"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    owner_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), nullable=False, index=True)

    # Source uploads (Cloudinary secure URLs, or hex colour if manually chosen)
    embroidery_design_url: Mapped[str] = mapped_column(String(1024), default="")
    saree_image_url: Mapped[str] = mapped_column(String(1024), default="")
    saree_color_hex: Mapped[str] = mapped_column(String(16), default="")
    blouse_image_url: Mapped[str] = mapped_column(String(1024), default="")
    blouse_color_hex: Mapped[str] = mapped_column(String(16), default="")

    # AI colour analysis output
    detected_saree_color: Mapped[str] = mapped_column(String(64), default="")
    detected_blouse_color: Mapped[str] = mapped_column(String(64), default="")
    detected_design_style: Mapped[str] = mapped_column(String(64), default="")
    bead_recommendations: Mapped[list[dict[str, Any]]] = mapped_column(JSON, default=list)

    # All 3 AI-generated colour-theory-labeled palette options, plus which one the user picked
    palette_options: Mapped[list[dict[str, Any]]] = mapped_column(JSON, default=list)
    selected_palette_index: Mapped[int] = mapped_column(Integer, default=0)

    # Order details (occasion, fit, size, coverage, budget) captured before generation
    occasion: Mapped[str] = mapped_column(String(64), default="")
    blouse_silhouette: Mapped[str] = mapped_column(String(64), default="")
    bust: Mapped[float] = mapped_column(Float, default=0.0)
    waist: Mapped[float] = mapped_column(Float, default=0.0)
    shoulder: Mapped[float] = mapped_column(Float, default=0.0)
    sleeve_length: Mapped[float] = mapped_column(Float, default=0.0)
    back_neck: Mapped[float] = mapped_column(Float, default=0.0)
    front_neck: Mapped[float] = mapped_column(Float, default=0.0)
    embroidery_coverage: Mapped[str] = mapped_column(String(32), default="")
    budget: Mapped[float] = mapped_column(Float, default=0.0)
    style_preference: Mapped[str] = mapped_column(String(256), default="")

    # Generation
    look_style: Mapped[str] = mapped_column(String(64), default="Luxury Look")
    preview_image_url: Mapped[str] = mapped_column(String(1024), default="")
    # Text, not a bounded VARCHAR — the actual prompt _build_visualization_prompt() builds runs
    # well past 4096 characters (it was originally String(4096); every completed generation's
    # final save was silently failing against Postgres with a StringDataRightTruncationError,
    # discarding a successfully generated image because this one column couldn't hold its own
    # prompt). This is debugging/reproducibility data, not something that benefits from a cap.
    generation_prompt: Mapped[str] = mapped_column(Text, default="")

    # Shopping list
    shopping_list: Mapped[list[dict[str, Any]]] = mapped_column(JSON, default=list)
    estimated_cost: Mapped[float] = mapped_column(Float, default=0.0)

    # User actions
    is_favourite: Mapped[bool] = mapped_column(Boolean, default=False)
    is_saved: Mapped[bool] = mapped_column(Boolean, default=True)

    # Visualization pipeline (edit-based, reference-image-faithful) — null for designs created
    # via the older text-to-image /generation/preview flow.
    garment_metadata: Mapped[Optional[dict[str, Any]]] = mapped_column(JSON, nullable=True, default=None)
    qa_result: Mapped[Optional[dict[str, Any]]] = mapped_column(JSON, nullable=True, default=None)
    retry_count: Mapped[int] = mapped_column(Integer, default=0)

    # "View on Mannequin" — separate optional derived asset. Null until the user requests it;
    # the original preview_image_url above is never overwritten by this feature.
    mannequin_image_url: Mapped[Optional[str]] = mapped_column(String(1024), nullable=True, default=None)

    # Visualization generation runs as a background task (real generation takes 1-5 minutes,
    # too long for a single synchronous HTTP request to survive most hosting platforms' proxy
    # timeouts) — the frontend polls GET /designs/{id} and watches this field. "completed" for
    # every design created via the old synchronous /preview flow, since those never go through
    # the pending/processing states at all.
    status: Mapped[str] = mapped_column(String(16), default="completed")
    # Same reasoning as generation_prompt above — error text (e.g. a full AI-provider error
    # payload) is variable-length diagnostic content, not something with a natural hard cap.
    error_message: Mapped[Optional[str]] = mapped_column(Text, nullable=True, default=None)

    owner: Mapped["User"] = relationship(back_populates="designs")


from app.models.user import User  # noqa: E402,F401  (needed for relationship type resolution)
