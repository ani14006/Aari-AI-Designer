"""Schemas for the embroidery visualization pipeline (edit-based, reference-image-faithful).

Kept separate from design.py: this is a genuinely new subsystem sitting alongside the existing
Design Intelligence (colour analysis / shopping list) pipeline, not replacing it.
"""
from typing import Optional

from pydantic import BaseModel, Field

from app.schemas.design import BeadRecommendation, LookStyle, OrderDetails, PaletteOption


class GarmentAnalysis(BaseModel):
    """Gemini's garment-ONLY analysis, feeding the visualization prompt. Never references the
    embroidery itself — OpenAI sees that image directly, so describing it here would risk
    Gemini's description drifting from the actual reference."""

    fabric_type: str
    neckline: str
    sleeve_type: str
    blouse_color: str
    saree_color: str
    lighting: str
    camera_angle: str
    fold_and_drape_notes: str


class QAScoreBreakdown(BaseModel):
    """Gemini's soft-reviewer fidelity assessment of one generated visualization attempt."""

    pattern_similarity: float
    color_similarity: float
    bead_preservation: float
    geometry_preservation: float
    garment_preservation: float
    overall_score: float
    notes: str = ""


class VisualizationAttempt(BaseModel):
    """One generate+score cycle within a VisualizationJob. Not persisted on its own — only the
    chosen attempt's data ends up on the Design row."""

    image_bytes: Optional[bytes] = None
    qa: Optional[QAScoreBreakdown] = None

    model_config = {"arbitrary_types_allowed": True}


class VisualizationJob(BaseModel):
    """Runtime-only pipeline state, built from a VisualizationRequest and progressively filled
    in by each stage. Never persisted directly — its final chosen attempt + garment analysis +
    qa result are what get written onto the Design row at the end of the pipeline."""

    model_config = {"arbitrary_types_allowed": True}

    design_id: Optional[str] = None
    embroidery_design_url: str
    blouse_image_url: str
    saree_image_url: Optional[str] = None
    saree_color_hex: Optional[str] = None
    look_style: LookStyle = LookStyle.LUXURY

    blouse_bytes: Optional[bytes] = None
    embroidery_asset_bytes: Optional[bytes] = None
    garment: Optional[GarmentAnalysis] = None
    prompt: Optional[str] = None

    attempts: list[VisualizationAttempt] = Field(default_factory=list)
    chosen_index: Optional[int] = None
    retry_count: int = 0

    @property
    def chosen_attempt(self) -> Optional[VisualizationAttempt]:
        if self.chosen_index is None:
            return None
        return self.attempts[self.chosen_index]


class VisualizationRequest(BaseModel):
    """Request for the new edit-based visualization pipeline. bead_recommendations/
    palette_options are Design-Intelligence-only data (the user's palette pick from the
    earlier /analysis/colors step) — never fed into the AI visualization pipeline itself, only
    used to compute the shopping list/estimated cost alongside the generated image."""

    design_id: Optional[str] = None
    embroidery_design_url: str
    blouse_image_url: str
    saree_image_url: Optional[str] = None
    saree_color_hex: Optional[str] = None
    look_style: LookStyle = LookStyle.LUXURY
    order_details: Optional[OrderDetails] = None
    bead_recommendations: list[BeadRecommendation] = Field(default_factory=list)
    palette_options: list[PaletteOption] = Field(default_factory=list)
    selected_palette_index: int = 0
