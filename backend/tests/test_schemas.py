from app.schemas.cart import AddToCartRequest
from app.schemas.design import DesignUpdate, GenerationRequest, LookStyle, ShoppingListItem

# Must stay in sync with frontend/lib/core/constants/app_constants.dart LookStyles — these
# strings are sent as-is over the wire and used as regenerate query params / bead-density keys.
EXPECTED_LOOK_STYLES = {
    "Luxury Look",
    "Traditional Look",
    "Minimal Look",
    "Bridal Look",
    "Temple Jewellery Style",
    "Modern Designer Look",
}


def test_look_style_values_match_frontend_contract():
    assert {style.value for style in LookStyle} == EXPECTED_LOOK_STYLES


def test_generation_request_defaults_to_luxury_look():
    request = GenerationRequest(embroidery_design_url="https://example.com/design.png")
    assert request.look_style == LookStyle.LUXURY
    assert request.bead_recommendations == []


def test_design_update_allows_partial_fields():
    update = DesignUpdate(is_favourite=True)
    assert update.is_favourite is True
    assert update.is_saved is None
    assert update.look_style is None


def test_add_to_cart_request_requires_design_id():
    request = AddToCartRequest(design_id="abc-123")
    assert request.design_id == "abc-123"


def test_shopping_list_item_defaults_category_to_material():
    item = ShoppingListItem(name="Blouse Cloth", quantity="1.5 metre", unit_price=450.0, total_price=675.0)
    assert item.category == "material"
