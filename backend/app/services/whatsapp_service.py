"""Composes a shareable WhatsApp text summary for a generated design."""
from app.models.design import Design


def build_whatsapp_message(design: Design) -> str:
    lines = ["*Aari AI Designer* — my custom blouse design ✨", ""]

    if design.occasion:
        lines.append(f"Occasion: {design.occasion}")
    lines.append(f"Look: {design.look_style}")
    if design.detected_saree_color:
        lines.append(f"Saree: {design.detected_saree_color}")
    if design.detected_blouse_color:
        lines.append(f"Blouse: {design.detected_blouse_color}")
    if design.detected_design_style:
        lines.append(f"Embroidery style: {design.detected_design_style}")

    if design.bead_recommendations:
        bead_names = ", ".join(b["name"] for b in design.bead_recommendations)
        lines.append(f"Bead colours: {bead_names}")

    if design.shopping_list:
        lines.append("")
        lines.append("*Materials needed:*")
        for item in design.shopping_list:
            lines.append(f"- {item['name']} ({item['quantity']}) — ₹{item['total_price']:.0f}")

    lines.append("")
    lines.append(f"Estimated cost: ₹{design.estimated_cost:.0f}")
    if design.preview_image_url:
        lines.append("")
        lines.append(f"Preview: {design.preview_image_url}")

    return "\n".join(lines)
