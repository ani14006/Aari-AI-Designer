"""Cloudinary upload/storage service for embroidery, saree, blouse and generated preview images."""
import cloudinary
import cloudinary.uploader
from fastapi import UploadFile

from app.core.config import settings
from app.schemas.design import UploadResponse
from app.utils.exceptions import UploadError

_configured = False


def _ensure_configured() -> None:
    global _configured
    if _configured:
        return
    cloudinary.config(
        cloud_name=settings.CLOUDINARY_CLOUD_NAME,
        api_key=settings.CLOUDINARY_API_KEY,
        api_secret=settings.CLOUDINARY_API_SECRET,
        secure=True,
    )
    _configured = True


ALLOWED_CONTENT_TYPES = {
    "image/png",
    "image/jpeg",
    "image/jpg",
    "image/webp",
    "application/pdf",
}


async def upload_image(file: UploadFile, folder: str) -> UploadResponse:
    """Upload a design/saree/blouse image (or PDF) to Cloudinary and return its public metadata."""
    _ensure_configured()

    if file.content_type not in ALLOWED_CONTENT_TYPES:
        raise UploadError(f"Unsupported file type: {file.content_type}")

    contents = await file.read()
    try:
        result = cloudinary.uploader.upload(
            contents,
            folder=f"aari-ai-designer/{folder}",
            resource_type="auto",
            overwrite=True,
            unique_filename=True,
        )
    except Exception as exc:
        raise UploadError(f"Cloudinary upload failed: {exc}") from exc
    return UploadResponse(
        url=result["secure_url"],
        public_id=result["public_id"],
        width=result.get("width"),
        height=result.get("height"),
        format=result.get("format"),
    )


async def upload_base64_image(data_base64: str, folder: str) -> UploadResponse:
    """Upload a base64-encoded image (e.g. an AI-generated preview) to Cloudinary."""
    _ensure_configured()
    try:
        result = cloudinary.uploader.upload(
            f"data:image/png;base64,{data_base64}",
            folder=f"aari-ai-designer/{folder}",
            resource_type="image",
            overwrite=True,
            unique_filename=True,
        )
    except Exception as exc:
        raise UploadError(f"Cloudinary upload failed: {exc}") from exc
    return UploadResponse(
        url=result["secure_url"],
        public_id=result["public_id"],
        width=result.get("width"),
        height=result.get("height"),
        format=result.get("format"),
    )


async def upload_bytes(data: bytes, folder: str) -> UploadResponse:
    """Upload raw PNG bytes (e.g. a visualization pipeline result) to Cloudinary, avoiding a
    base64-encode round trip for images already in memory as bytes."""
    _ensure_configured()
    try:
        result = cloudinary.uploader.upload(
            data,
            folder=f"aari-ai-designer/{folder}",
            resource_type="image",
            overwrite=True,
            unique_filename=True,
        )
    except Exception as exc:
        raise UploadError(f"Cloudinary upload failed: {exc}") from exc
    return UploadResponse(
        url=result["secure_url"],
        public_id=result["public_id"],
        width=result.get("width"),
        height=result.get("height"),
        format=result.get("format"),
    )


def delete_asset(public_id: str) -> None:
    _ensure_configured()
    cloudinary.uploader.destroy(public_id)
