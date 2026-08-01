from app.schemas.design import BeadRecommendation, LookStyle
from app.services.shopping_list_service import build_shopping_list

_SAMPLE_BEADS = [
    BeadRecommendation(name="Antique Gold", hex_color="#B08D3F", reason="Complements warm saree tones."),
    BeadRecommendation(name="Pearl White", hex_color="#F4F1EA", reason="Adds contrast highlights."),
]


def test_build_shopping_list_includes_fixed_tailoring_items():
    items, _ = build_shopping_list(_SAMPLE_BEADS, LookStyle.LUXURY)
    item_names = {item.name for item in items}

    for expected in ("Tracing Sheet", "Carbon Sheet", "French Curve", "Blouse Cloth", "Sugar Beads"):
        assert expected in item_names


def test_build_shopping_list_estimated_cost_matches_line_items():
    items, estimated_cost = build_shopping_list(_SAMPLE_BEADS, LookStyle.LUXURY)
    assert estimated_cost == round(sum(item.total_price for item in items), 2)
    assert estimated_cost > 0


def test_bridal_look_requires_more_beads_than_minimal_look():
    minimal_items, minimal_cost = build_shopping_list(_SAMPLE_BEADS, LookStyle.MINIMAL)
    bridal_items, bridal_cost = build_shopping_list(_SAMPLE_BEADS, LookStyle.BRIDAL)

    minimal_bead_lines = sum(
        int(item.quantity.split()[0]) for item in minimal_items if item.category == "bead" and "Lines" in item.quantity
    )
    bridal_bead_lines = sum(
        int(item.quantity.split()[0]) for item in bridal_items if item.category == "bead" and "Lines" in item.quantity
    )

    assert bridal_bead_lines > minimal_bead_lines
    assert bridal_cost > minimal_cost


def test_build_shopping_list_falls_back_to_default_bead_when_none_recommended():
    items, estimated_cost = build_shopping_list([], LookStyle.TRADITIONAL)
    bead_items = [item for item in items if item.category == "bead" and "Lines" in item.quantity]

    assert len(bead_items) == 1
    assert "Antique Gold" in bead_items[0].name
    assert estimated_cost > 0
