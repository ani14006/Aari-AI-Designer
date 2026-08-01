"""Schemas for the "View on Mannequin" presentation feature — a completely separate,
optional post-processing step that runs only after a visualization has already succeeded.
Never touches the core visualization pipeline's schemas or logic."""
from typing import Optional

from pydantic import BaseModel


class MannequinRequest(BaseModel):
    design_id: Optional[str] = None
    completed_visualization_url: str
    saree_image_url: Optional[str] = None
    saree_color_hex: Optional[str] = None


class MannequinResponse(BaseModel):
    mannequin_image_url: str
