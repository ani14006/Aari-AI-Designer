"""Small helpers for fetching remote images and working with manually-picked hex colours, plus
the normalization/mask/background-removal utilities feeding the visualization pipeline."""
import io
from functools import lru_cache

import httpx
from PIL import Image, ImageOps


async def fetch_image_bytes(url: str) -> bytes:
    """Download an image (e.g. a Cloudinary asset) so it can be sent to the Gemini API as inline bytes."""
    async with httpx.AsyncClient(timeout=30) as client:
        response = await client.get(url)
        response.raise_for_status()
        return response.content


def hex_to_rgb(hex_color: str) -> tuple[int, int, int]:
    hex_color = hex_color.lstrip("#")
    if len(hex_color) == 3:
        hex_color = "".join(ch * 2 for ch in hex_color)
    return tuple(int(hex_color[i : i + 2], 16) for i in (0, 2, 4))  # type: ignore[return-value]


def make_color_swatch_png(hex_color: str, size: int = 512) -> bytes:
    """Render a solid-colour PNG so a manually picked colour can be fed to a vision/image model."""
    rgb = hex_to_rgb(hex_color)
    image = Image.new("RGB", (size, size), rgb)
    buffer = io.BytesIO()
    image.save(buffer, format="PNG")
    return buffer.getvalue()


def bytes_to_data_url(data: bytes, mime: str = "image/png") -> str:
    import base64

    encoded = base64.b64encode(data).decode("utf-8")
    return f"data:{mime};base64,{encoded}"


def normalize_image(image_bytes: bytes, max_dimension: int = 2048) -> bytes:
    """EXIF-correct orientation, downscale if oversized, re-encode as PNG. Applied to every
    uploaded blouse/embroidery/saree image before it reaches any AI service, so downstream
    stages never have to deal with sideways phone photos or huge originals."""
    image = Image.open(io.BytesIO(image_bytes))
    image = ImageOps.exif_transpose(image)
    if image.mode != "RGB":
        image = image.convert("RGB")
    if max(image.size) > max_dimension:
        image.thumbnail((max_dimension, max_dimension), Image.LANCZOS)
    buffer = io.BytesIO()
    image.save(buffer, format="PNG")
    return buffer.getvalue()


# gpt-image-1's images.edit() only accepts these 3 canvases. The image being edited, its mask,
# and the `size` param passed to the API must all agree exactly — a mismatch (e.g. a portrait
# photo edited with size="1024x1024") breaks mask-boundary adherence, confirmed via a live
# test this session where fixing this alone took a badly-hallucinated edit to a faithful one.
OPENAI_EDIT_CANVASES: dict[str, tuple[int, int]] = {
    "1024x1024": (1024, 1024),
    "1024x1536": (1024, 1536),
    "1536x1024": (1536, 1024),
}


def fit_to_edit_canvas(image_bytes: bytes) -> tuple[bytes, str, int, int]:
    """Resize a normalized image to whichever of OPENAI_EDIT_CANVASES is closest in aspect
    ratio, so it can be passed to images.edit() alongside a same-sized mask and a matching
    `size` param. Returns (resized_png_bytes, size_str, width, height)."""
    image = Image.open(io.BytesIO(image_bytes))
    if image.mode != "RGB":
        image = image.convert("RGB")

    source_ratio = image.size[0] / image.size[1]
    size_str = min(
        OPENAI_EDIT_CANVASES,
        key=lambda key: abs((OPENAI_EDIT_CANVASES[key][0] / OPENAI_EDIT_CANVASES[key][1]) - source_ratio),
    )
    target = OPENAI_EDIT_CANVASES[size_str]

    fitted = image.resize(target, Image.LANCZOS)
    buffer = io.BytesIO()
    fitted.save(buffer, format="PNG")
    return buffer.getvalue(), size_str, target[0], target[1]


@lru_cache
def _get_rembg_session():
    from rembg import new_session

    return new_session("u2net")


def remove_background(image_bytes: bytes) -> bytes:
    """Strip the background from an uploaded embroidery photo, producing the canonical
    transparent embroidery_asset.png that every downstream pipeline stage uses instead of the
    raw upload. Model weights are downloaded once on first call and cached on disk."""
    from rembg import remove

    return remove(image_bytes, session=_get_rembg_session())
