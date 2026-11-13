import os
import uuid
from fastapi import UploadFile, HTTPException, status
from app.core.config import settings

ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}
ALLOWED_CONTENT_TYPES = {
    "image/jpeg",
    "image/jpg",
    "image/png",
    "image/webp",
    "application/octet-stream",  # Often sent by mobile multipart clients
}
MAX_FILE_SIZE_BYTES = 15 * 1024 * 1024  # 15 MB


class StorageService:
    def __init__(self, upload_dir: str = settings.UPLOAD_DIR):
        self.upload_dir = upload_dir
        os.makedirs(self.upload_dir, exist_ok=True)

    async def save_upload_file(self, upload_file: UploadFile) -> str:
        """
        Validate, save uploaded file, and return public accessible URL.
        Accepts JPEG, PNG, and WebP, safely detecting format from magic bytes or headers.
        """
        # Read contents first to check size and magic bytes
        contents = await upload_file.read()
        if len(contents) == 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Uploaded file is empty.",
            )

        if len(contents) > MAX_FILE_SIZE_BYTES:
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail=f"File exceeds maximum allowed size of {MAX_FILE_SIZE_BYTES // (1024 * 1024)}MB.",
            )

        # Detect format from magic bytes
        detected_ext = None
        if contents.startswith(b"\xff\xd8\xff"):
            detected_ext = ".jpg"
        elif contents.startswith(b"\x89PNG\r\n\x1a\n"):
            detected_ext = ".png"
        elif contents.startswith(b"RIFF") and len(contents) >= 12 and contents[8:12] == b"WEBP":
            detected_ext = ".webp"

        # Check filename extension if provided
        raw_filename = upload_file.filename or "upload.jpg"
        file_ext = os.path.splitext(raw_filename)[1].lower()

        # Decide final extension
        if detected_ext:
            final_ext = detected_ext
        elif file_ext in ALLOWED_EXTENSIONS:
            final_ext = file_ext
        else:
            # Check content type if available
            ct = (upload_file.content_type or "").lower()
            if "png" in ct:
                final_ext = ".png"
            elif "webp" in ct:
                final_ext = ".webp"
            elif "jpeg" in ct or "jpg" in ct:
                final_ext = ".jpg"
            else:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Unsupported image format. Allowed formats: JPEG, PNG, WebP.",
                )

        # Generate unique storage name
        unique_filename = f"{uuid.uuid4().hex}{final_ext}"
        destination_path = os.path.join(self.upload_dir, unique_filename)

        # Write file to disk
        with open(destination_path, "wb") as f:
            f.write(contents)

        # Return relative path or URL
        return f"/uploads/{unique_filename}"


storage_service = StorageService()
