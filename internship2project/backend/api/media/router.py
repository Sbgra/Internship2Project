import os
import shutil
import uuid
from fastapi import APIRouter, UploadFile, File, HTTPException
from fastapi.responses import FileResponse
from pathlib import Path

router = APIRouter(prefix="/media", tags=["Media"])

UPLOAD_DIR = Path("data/images")
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

@router.post("/upload/image")
def upload_image(file: UploadFile = File(...)):
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Only image files are allowed.")
    
    # Generate unique filename to prevent overwriting
    ext = os.path.splitext(file.filename)[1]
    unique_filename = f"{uuid.uuid4().hex}{ext}"
    file_location = UPLOAD_DIR / unique_filename
    
    with open(file_location, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
        
    return {"url": f"/media/images/{unique_filename}"}

@router.get("/images/{filename}")
def get_image(filename: str):
    file_path = UPLOAD_DIR / filename
    if not file_path.exists():
        raise HTTPException(status_code=404, detail="Image not found")
    return FileResponse(file_path)
