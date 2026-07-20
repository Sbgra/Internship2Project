import sqlite3
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Request

from database import get_db
from dependencies import get_optional_user
from schemas.highlight import HighlightCreate, HighlightResponse
from services import article_service

router = APIRouter(prefix="/articles", tags=["Highlights"])

def get_client_ip(request: Request) -> str:
    forwarded = request.headers.get("X-Forwarded-For")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return request.client.host

@router.post("/{article_id}/highlights", response_model=HighlightResponse)
def add_highlight(
    article_id: int,
    data: HighlightCreate,
    request: Request,
    conn: sqlite3.Connection = Depends(get_db),
    current_user: Optional[dict] = Depends(get_optional_user),
):
    """Makaleye altı çizili cümle ekler. Herkes ekleyebilir."""
    article = article_service.get_article_by_id(conn, article_id)
    if not article:
        raise HTTPException(status_code=404, detail="Makale bulunamadı")

    user_id = current_user["id"] if current_user else None
    ip = get_client_ip(request) if not current_user else None

    cur = conn.execute(
        "INSERT INTO highlights (article_id, user_id, ip_address, start_index, end_index, text) VALUES (?, ?, ?, ?, ?, ?)",
        (article_id, user_id, ip, data.start_index, data.end_index, data.text),
    )
    conn.commit()

    # Eklenen veriyi döndür
    row = conn.execute("SELECT * FROM highlights WHERE id = ?", (cur.lastrowid,)).fetchone()
    return dict(row)

@router.get("/{article_id}/highlights", response_model=List[HighlightResponse])
def get_highlights(
    article_id: int,
    conn: sqlite3.Connection = Depends(get_db),
):
    """Makalenin altı çizili cümlelerini getirir."""
    article = article_service.get_article_by_id(conn, article_id)
    if not article:
        raise HTTPException(status_code=404, detail="Makale bulunamadı")

    rows = conn.execute("SELECT * FROM highlights WHERE article_id = ?", (article_id,)).fetchall()
    return [dict(row) for row in rows]
