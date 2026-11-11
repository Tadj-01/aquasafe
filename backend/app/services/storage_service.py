import os
import uuid
from fastapi import UploadFile, HTTPException, status
from app.core.config import settings

ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}
ALLOWED_CONTENT_TYPES = {"image/jpeg", "image/png", "image/webp"}
MAX_FILE_SIZE_BYTES = 15 * 1024 * 1024  # 15 MB


class StorageService:
    def __init__(self, upload_dir: str = settings.UPLOAD_DIR):
        self.upload_dir = upload_dir
        os.makedirs(self.upload_dir, exist_ok=True)

    async def save_upload_file(self, upload_file: UploadFile) -> str:
        """
        Validate, save uploaded file, and return public accessible URL.
        """
        # Validate filename and extension
        if not upload_file.filename:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Uploaded file must have a filename.",
            )

        ext = os.path.splitext(upload_file.filename)[1].lower()
        if ext not in ALLOWED_EXTENSIONS:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Unsupported file extension '{ext}'. Allowed: {', '.join(ALLOWED_EXTENSIONS)}",
            )

        if upload_file.content_type and upload_file.content_type not in ALLOWED_CONTENT_TYPES:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Unsupported content type '{upload_file.content_type}'. Must be an image.",
            )

        # Generate unique storage name
        unique_filename = f"{uuid.uuid4().hex}{ext}"
        destination_path = os.path.join(self.upload_dir, unique_filename)

        # Read and enforce file size
        contents = await upload_file.read()
        if len(contents) > MAX_FILE_SIZE_BYTES:
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail=f"File exceeds maximum allowed size of {MAX_FILE_SIZE_BYTES // (1024 * 1024)}MB.",
            )

        # Write file to disk
        with open(destination_path, "wb") as f:
            f.write(contents)

        # Return relative path or URL
        # We serve uploads at /uploads/<filename>
        return f"/uploads/{unique_filename}"


storage_service = StorageService()
