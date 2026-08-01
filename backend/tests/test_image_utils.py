import io

from PIL import Image

from app.utils.image_utils import OPENAI_EDIT_CANVASES, fit_to_edit_canvas, normalize_image


def _make_png(width: int, height: int, mode: str = "RGB") -> bytes:
    image = Image.new(mode, (width, height), (200, 100, 50) if mode == "RGB" else 128)
    buffer = io.BytesIO()
    image.save(buffer, format="PNG")
    return buffer.getvalue()


def test_normalize_image_returns_valid_png():
    result = normalize_image(_make_png(100, 100))
    image = Image.open(io.BytesIO(result))
    assert image.format == "PNG"
    assert image.mode == "RGB"


def test_normalize_image_downscales_oversized_images():
    result = normalize_image(_make_png(3000, 1500), max_dimension=1000)
    image = Image.open(io.BytesIO(result))
    assert max(image.size) <= 1000
    assert image.size[0] / image.size[1] == 2000 / 1000 or abs(image.size[0] / image.size[1] - 2.0) < 0.05


def test_normalize_image_leaves_small_images_unchanged_dimensions():
    result = normalize_image(_make_png(400, 300), max_dimension=2048)
    image = Image.open(io.BytesIO(result))
    assert image.size == (400, 300)


def test_fit_to_edit_canvas_returns_a_supported_canvas_size():
    resized_bytes, size_str, width, height = fit_to_edit_canvas(_make_png(684, 1024))
    assert size_str in OPENAI_EDIT_CANVASES
    assert (width, height) == OPENAI_EDIT_CANVASES[size_str]
    image = Image.open(io.BytesIO(resized_bytes))
    assert image.size == (width, height)


def test_fit_to_edit_canvas_picks_portrait_for_tall_images():
    _, size_str, _, _ = fit_to_edit_canvas(_make_png(600, 1000))
    assert size_str == "1024x1536"


def test_fit_to_edit_canvas_picks_landscape_for_wide_images():
    _, size_str, _, _ = fit_to_edit_canvas(_make_png(1000, 600))
    assert size_str == "1536x1024"


def test_fit_to_edit_canvas_picks_square_for_square_images():
    _, size_str, _, _ = fit_to_edit_canvas(_make_png(800, 800))
    assert size_str == "1024x1024"
