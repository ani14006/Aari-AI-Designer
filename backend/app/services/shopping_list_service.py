"""Derives a concrete Aari-embroidery materials list + estimated cost from bead recommendations."""
from typing import Optional

from app.schemas.design import BeadRecommendation, LookStyle, ShoppingListItem

# Approximate per-unit market pricing (INR). Kept centralised so it's easy to tune.
BEAD_UNIT_PRICE_PER_LINE = 35.0  # per "line" (a standard stringing unit used by Aari artisans)
SUGAR_BEADS_PRICE_PER_100G = 90.0
TRACING_SHEET_PRICE = 25.0
CARBON_SHEET_PRICE = 15.0
FRENCH_CURVE_PRICE = 60.0
BLOUSE_CLOTH_PRICE_PER_METRE = 450.0
SILK_THREAD_PRICE_PER_SPOOL = 40.0
ZARI_PRICE_PER_10G = 120.0
STONES_PRICE_PER_GROSS = 150.0  # 1 gross = 144 pieces
KUNDAN_PRICE_PER_100PC = 180.0
PEARLS_PRICE_PER_LINE = 55.0

# How many bead "lines" a look style typically needs (denser looks need more material).
LOOK_STYLE_DENSITY: dict[LookStyle, int] = {
    LookStyle.MINIMAL: 10,
    LookStyle.MODERN_DESIGNER: 14,
    LookStyle.TRADITIONAL: 18,
    LookStyle.LUXURY: 22,
    LookStyle.TEMPLE_JEWELLERY: 24,
    LookStyle.BRIDAL: 30,
}

# Multiplier applied on top of look-style density based on the explicitly requested
# embroidery coverage level (order details step) — a "Light" ask should shrink materials
# even for an otherwise dense look style, and vice versa.
COVERAGE_MULTIPLIER: dict[str, float] = {
    "Light": 0.6,
    "Medium": 1.0,
    "Heavy": 1.35,
    "Full Bridal": 1.7,
}

_BASELINE_SIZE_INCHES = 36.0


def _size_multiplier(bust_inches: Optional[float]) -> float:
    """Scale material quantities to the blouse's bust size. Baseline (36in) = 1.0x, ~4%/inch either side."""
    if not bust_inches:
        return 1.0
    scale = 1.0 + (bust_inches - _BASELINE_SIZE_INCHES) * 0.04
    return max(0.7, min(scale, 1.6))


def _build_items(
    beads: list[BeadRecommendation], look_style: LookStyle, scale: float
) -> list[ShoppingListItem]:
    total_lines = max(round(LOOK_STYLE_DENSITY.get(look_style, 18) * scale), 4)
    items: list[ShoppingListItem] = []

    # Split total lines across the top recommended bead colours, largest allocation first.
    per_bead_lines = max(total_lines // len(beads), 4)
    for i, bead in enumerate(beads):
        size_mm = 4 if i == 0 else (5 if i == 1 else 6)
        lines = per_bead_lines + (4 if i == 0 else 0)
        unit_price = BEAD_UNIT_PRICE_PER_LINE * (1.4 if "Gold" in bead.name or "Silver" in bead.name else 1.0)
        items.append(
            ShoppingListItem(
                name=f"{size_mm}mm Round {bead.name}",
                quantity=f"{lines} Lines",
                unit_price=round(unit_price, 2),
                total_price=round(unit_price * lines, 2),
                category="bead",
            )
        )

    sugar_beads_grams = max(round((150 if look_style in (LookStyle.MINIMAL, LookStyle.MODERN_DESIGNER) else 250) * scale), 50)
    sugar_beads_cost = SUGAR_BEADS_PRICE_PER_100G * (sugar_beads_grams / 100)
    items.append(
        ShoppingListItem(
            name="Sugar Beads",
            quantity=f"{sugar_beads_grams}g",
            unit_price=round(SUGAR_BEADS_PRICE_PER_100G, 2),
            total_price=round(sugar_beads_cost, 2),
            category="bead",
        )
    )

    # Richer material catalogue: silk thread, zari (gold thread), stones, kundan, pearls —
    # all scaled with look-style density, blouse size and requested embroidery coverage.
    silk_spools = max(round(2 * scale), 1)
    items.append(
        ShoppingListItem(
            name="Silk Embroidery Thread", quantity=f"{silk_spools} Spools",
            unit_price=SILK_THREAD_PRICE_PER_SPOOL,
            total_price=round(SILK_THREAD_PRICE_PER_SPOOL * silk_spools, 2),
            category="thread",
        )
    )

    zari_units_10g = max(round(3 * scale), 1)
    items.append(
        ShoppingListItem(
            name="Zari (Gold Thread)", quantity=f"{zari_units_10g * 10}g",
            unit_price=ZARI_PRICE_PER_10G,
            total_price=round(ZARI_PRICE_PER_10G * zari_units_10g, 2),
            category="thread",
        )
    )

    stones_gross = max(round(1 * scale * 10) / 10, 0.5)
    items.append(
        ShoppingListItem(
            name="Embellishment Stones", quantity=f"{stones_gross:g} Gross",
            unit_price=STONES_PRICE_PER_GROSS,
            total_price=round(STONES_PRICE_PER_GROSS * stones_gross, 2),
            category="embellishment",
        )
    )

    kundan_units_100 = max(round(1 * scale * 10) / 10, 0.5)
    items.append(
        ShoppingListItem(
            name="Kundan Stones", quantity=f"{round(kundan_units_100 * 100)} pcs",
            unit_price=KUNDAN_PRICE_PER_100PC,
            total_price=round(KUNDAN_PRICE_PER_100PC * kundan_units_100, 2),
            category="embellishment",
        )
    )

    pearl_lines = max(round(6 * scale), 2)
    items.append(
        ShoppingListItem(
            name="Pearl Strings", quantity=f"{pearl_lines} Lines",
            unit_price=PEARLS_PRICE_PER_LINE,
            total_price=round(PEARLS_PRICE_PER_LINE * pearl_lines, 2),
            category="embellishment",
        )
    )

    items.extend(
        [
            ShoppingListItem(
                name="Tracing Sheet", quantity="1", unit_price=TRACING_SHEET_PRICE,
                total_price=TRACING_SHEET_PRICE, category="tool",
            ),
            ShoppingListItem(
                name="Carbon Sheet", quantity="1", unit_price=CARBON_SHEET_PRICE,
                total_price=CARBON_SHEET_PRICE, category="tool",
            ),
            ShoppingListItem(
                name="French Curve", quantity="1", unit_price=FRENCH_CURVE_PRICE,
                total_price=FRENCH_CURVE_PRICE, category="tool",
            ),
            ShoppingListItem(
                name="Blouse Cloth", quantity="1.5 metre",
                unit_price=BLOUSE_CLOTH_PRICE_PER_METRE,
                total_price=round(BLOUSE_CLOTH_PRICE_PER_METRE * 1.5, 2),
                category="fabric",
            ),
        ]
    )

    return items


def build_shopping_list(
    bead_recommendations: list[BeadRecommendation],
    look_style: LookStyle,
    bust: Optional[float] = None,
    embroidery_coverage: Optional[str] = None,
    budget: Optional[float] = None,
) -> tuple[list[ShoppingListItem], float]:
    """Build the itemised materials list: beads, thread, zari, stones, kundan and pearls, sized to
    the look style's base density, the blouse's bust size, and the requested embroidery coverage.

    If a `budget` is supplied and the resulting cost would exceed it, quantities are scaled back
    (down to a 40% floor) so the total lands close to budget — fixed tools/fabric costs are left
    untouched since those are needed regardless of embroidery density.
    """
    beads = bead_recommendations[:3] or [
        BeadRecommendation(name="Antique Gold", hex_color="#C9A24B", reason="Default premium base tone.")
    ]
    scale = _size_multiplier(bust) * COVERAGE_MULTIPLIER.get(embroidery_coverage or "", 1.0)

    items = _build_items(beads, look_style, scale)
    estimated_cost = round(sum(item.total_price for item in items), 2)

    if budget and budget > 0 and estimated_cost > budget:
        fixed_cost = sum(item.total_price for item in items if item.category in ("tool", "fabric"))
        variable_cost = estimated_cost - fixed_cost
        if variable_cost > 0 and budget > fixed_cost:
            budget_scale = max((budget - fixed_cost) / variable_cost, 0.4)
            scale = scale * budget_scale
            items = _build_items(beads, look_style, scale)
            estimated_cost = round(sum(item.total_price for item in items), 2)

    return items, estimated_cost
