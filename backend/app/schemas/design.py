"""Pydantic schemas for the design pipeline: upload -> analysis -> generation -> shopping list."""
from datetime import datetime
from enum import Enum
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


class LookStyle(str, Enum):
    LUXURY = "Luxury Look"
    TRADITIONAL = "Traditional Look"
    MINIMAL = "Minimal Look"
    BRIDAL = "Bridal Look"
    TEMPLE_JEWELLERY = "Temple Jewellery Style"
    MODERN_DESIGNER = "Modern Designer Look"


class Occasion(str, Enum):
    WEDDING = "Wedding"
    RECEPTION = "Reception"
    ENGAGEMENT = "Engagement"
    FESTIVAL = "Festival"
    PARTY = "Party"
    CASUAL = "Casual"


class BlouseSilhouette(str, Enum):
    PRINCESS_CUT = "Princess Cut"
    SWEETHEART = "Sweetheart Neck"
    BOAT_NECK = "Boat Neck"
    HALTER = "Halter Neck"
    OFF_SHOULDER = "Off-Shoulder"
    ROUND_NECK = "Traditional Round Neck"
    HIGH_NECK = "High Neck"
    DEEP_V = "Deep-V Neck"
    BACKLESS = "Backless"


class EmbroideryCoverage(str, Enum):
    LIGHT = "Light"
    MEDIUM = "Medium"
    HEAVY = "Heavy"
    FULL_BRIDAL = "Full Bridal"


class ColorHarmonyScheme(str, Enum):
    COMPLEMENTARY = "Complementary"
    ANALOGOUS = "Analogous"
    TRIADIC = "Triadic"


class OrderDetails(BaseModel):
    occasion: Optional[Occasion] = None
    blouse_silhouette: Optional[BlouseSilhouette] = None
    # Detailed blouse measurements (inches), all optional. `bust` drives material-quantity
    # scaling in shopping_list_service; the rest are captured for the artisan's stitching
    # reference but don't otherwise affect the AI recommendations.
    bust: Optional[float] = None
    waist: Optional[float] = None
    shoulder: Optional[float] = None
    sleeve_length: Optional[float] = None
    back_neck: Optional[float] = None
    front_neck: Optional[float] = None
    embroidery_coverage: Optional[EmbroideryCoverage] = None
    budget: Optional[float] = None
    style_preference: Optional[str] = None


class UploadResponse(BaseModel):
    """Returned after a file is uploaded to Cloudinary."""
    url: str
    public_id: str
    width: Optional[int] = None
    height: Optional[int] = None
    format: Optional[str] = None


class BeadRecommendation(BaseModel):
    name: str
    hex_color: str
    reason: str


class PaletteOption(BaseModel):
    scheme: ColorHarmonyScheme
    title: str
    description: str
    bead_recommendations: list[BeadRecommendation]


class ColorAnalysisRequest(BaseModel):
    saree_image_url: Optional[str] = None
    saree_color_hex: Optional[str] = None
    blouse_image_url: Optional[str] = None
    blouse_color_hex: Optional[str] = None
    embroidery_design_url: Optional[str] = None
    order_details: Optional[OrderDetails] = None


class ColorAnalysisResponse(BaseModel):
    detected_saree_color: str
    detected_blouse_color: str
    detected_design_style: str
    palette_options: list[PaletteOption]


class GenerationRequest(BaseModel):
    design_id: Optional[str] = None
    embroidery_design_url: str
    saree_image_url: Optional[str] = None
    saree_color_hex: Optional[str] = None
    blouse_image_url: Optional[str] = None
    blouse_color_hex: Optional[str] = None
    # Populated by the frontend from the earlier /analysis/colors call — required whenever
    # bead_recommendations is already supplied (i.e. analysis ran as a separate step), since
    # otherwise the generation prompt loses the detected colours/style entirely.
    detected_saree_color: Optional[str] = None
    detected_blouse_color: Optional[str] = None
    detected_design_style: Optional[str] = None
    bead_recommendations: list[BeadRecommendation] = Field(default_factory=list)
    palette_options: list[PaletteOption] = Field(default_factory=list)
    selected_palette_index: int = 0
    look_style: LookStyle = LookStyle.LUXURY
    order_details: Optional[OrderDetails] = None


class GenerationResponse(BaseModel):
    design_id: str
    preview_image_url: str
    look_style: LookStyle


class ShoppingListItem(BaseModel):
    name: str
    quantity: str
    unit_price: float
    total_price: float
    category: str = "material"


class ShoppingListResponse(BaseModel):
    items: list[ShoppingListItem]
    estimated_cost: float


class DesignCreate(BaseModel):
    embroidery_design_url: str = ""
    saree_image_url: str = ""
    saree_color_hex: str = ""
    blouse_image_url: str = ""
    blouse_color_hex: str = ""


class DesignRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    owner_id: str
    embroidery_design_url: str
    saree_image_url: str
    saree_color_hex: str
    blouse_image_url: str
    blouse_color_hex: str
    detected_saree_color: str
    detected_blouse_color: str
    detected_design_style: str
    bead_recommendations: list[dict]
    palette_options: list[dict]
    selected_palette_index: int
    look_style: str
    preview_image_url: str
    shopping_list: list[dict]
    estimated_cost: float
    occasion: str
    blouse_silhouette: str
    bust: float
    waist: float
    shoulder: float
    sleeve_length: float
    back_neck: float
    front_neck: float
    embroidery_coverage: str
    budget: float
    style_preference: str
    is_favourite: bool
    is_saved: bool
    garment_metadata: Optional[dict] = None
    qa_result: Optional[dict] = None
    retry_count: int = 0
    mannequin_image_url: Optional[str] = None
    status: str = "completed"
    error_message: Optional[str] = None
    created_at: datetime
    updated_at: datetime


class WhatsappMessageResponse(BaseModel):
    message: str


class DesignUpdate(BaseModel):
    is_favourite: Optional[bool] = None
    is_saved: Optional[bool] = None
    look_style: Optional[LookStyle] = None
