"""Upload endpoints: embroidery design / saree / blouse images (camera, gallery, or PDF)."""
from fastapi import APIRouter, Depends, File, HTTPException, UploadFile

from app.api.deps import get_current_user
from app.models.user import User
from app.schemas.design import UploadResponse
from app.services import cloudinary_service

router = APIRouter(prefix="/uploads", tags=["uploads"])

_ALLOWED_FOLDERS = {"designs", "sarees", "blouses"}


@router.post("/{folder}", response_model=UploadResponse)
async def upload_image(
    folder: str,
    file: UploadFile = File(...),
    _user: User = Depends(get_current_user),
) -> UploadResponse:
    """Upload an image (or PDF, for embroidery designs) to Cloudinary storage.

    `folder` must be one of: designs, sarees, blouses.
    """
    if folder not in _ALLOWED_FOLDERS:
        raise HTTPException(status_code=400, detail=f"folder must be one of {sorted(_ALLOWED_FOLDERS)}")
    return await cloudinary_service.upload_image(file, folder)
