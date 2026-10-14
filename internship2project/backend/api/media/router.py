import os
import shutil
import uuid
import mimetypes
from fastapi import APIRouter, UploadFile, File, HTTPException
from fastapi.responses import FileResponse
from pathlib import Path

router = APIRouter(prefix="/media", tags=["Media"])

UPLOAD_IMAGE_DIR = Path("data/images")
UPLOAD_IMAGE_DIR.mkdir(parents=True, exist_ok=True)

UPLOAD_AUDIO_DIR = Path("data/audio")
UPLOAD_AUDIO_DIR.mkdir(parents=True, exist_ok=True)

@router.post("/upload/image")
def upload_image(file: UploadFile = File(...)):
    ext = os.path.splitext(file.filename)[1].lower() if file.filename else ".jpg"
    is_image = (file.content_type and file.content_type.startswith("image/")) or ext in [
        ".jpg", ".jpeg", ".png", ".gif", ".webp", ".bmp"
    ]
    if not is_image:
        raise HTTPException(status_code=400, detail="Only image files are allowed.")
    
    unique_filename = f"{uuid.uuid4().hex}{ext or '.jpg'}"
    file_location = UPLOAD_IMAGE_DIR / unique_filename
    
    with open(file_location, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
        
    return {"url": f"/media/images/{unique_filename}"}

@router.get("/images/{filename}")
def get_image(filename: str):
    file_path = UPLOAD_IMAGE_DIR / filename
    if not file_path.exists():
        raise HTTPException(status_code=404, detail="Image not found")
    media_type, _ = mimetypes.guess_type(str(file_path))
    return FileResponse(file_path, media_type=media_type or "image/jpeg")

@router.post("/upload/audio")
def upload_audio(file: UploadFile = File(...)):
    ext = os.path.splitext(file.filename)[1].lower() if file.filename else ".mp3"
    allowed_audio_exts = [".mp3", ".wav", ".m4a", ".aac", ".ogg", ".weba", ".flac", ".caf"]
    is_audio = (
        (file.content_type and file.content_type.startswith("audio/"))
        or ext in allowed_audio_exts
        or file.content_type in ["application/octet-stream", "video/mp4"]
    )
    if not is_audio and ext not in allowed_audio_exts:
        raise HTTPException(
            status_code=400, 
            detail="Only audio files are allowed (.mp3, .wav, .m4a, .aac, .ogg)."
        )
    
    unique_filename = f"{uuid.uuid4().hex}{ext or '.mp3'}"
    file_location = UPLOAD_AUDIO_DIR / unique_filename
    
    with open(file_location, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
        
    return {"url": f"/media/audio/{unique_filename}"}

@router.get("/audio/{filename}")
def get_audio(filename: str):
    file_path = UPLOAD_AUDIO_DIR / filename
    if not file_path.exists():
        raise HTTPException(status_code=404, detail="Audio file not found")
    media_type, _ = mimetypes.guess_type(str(file_path))
    return FileResponse(file_path, media_type=media_type or "audio/mpeg")

