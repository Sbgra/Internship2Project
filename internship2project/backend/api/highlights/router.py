from typing import List, Optional
from sqlmodel import Session, select
from core.models import Highlight

from fastapi import APIRouter, Depends, HTTPException, Request

from core.database import get_db
from core.dependencies import get_optional_user
from api.highlights.schemas import HighlightCreate, HighlightResponse
from api.articles import service as article_service

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
    session: Session = Depends(get_db),
    current_user = Depends(get_optional_user),
):
    """Makaleye altı çizili cümle ekler. Herkes ekleyebilir."""
    article = article_service.get_article_by_id(session, article_id)
    if not article:
        raise HTTPException(status_code=404, detail="Makale bulunamadı")

    user_id = current_user.id if current_user else None
    ip = get_client_ip(request) if not current_user else None

    highlight = Highlight(
        article_id=article_id, 
        user_id=user_id, 
        ip_address=ip, 
        start_index=data.start_index, 
        end_index=data.end_index, 
        text=data.text
    )
    session.add(highlight)
    session.commit()
    session.refresh(highlight)

    return highlight

@router.get("/{article_id}/highlights", response_model=List[HighlightResponse])
def get_highlights(
    article_id: int,
    session: Session = Depends(get_db),
):
    """Makalenin altı çizili cümlelerini getirir."""
    article = article_service.get_article_by_id(session, article_id)
    if not article:
        raise HTTPException(status_code=404, detail="Makale bulunamadı")

    statement = select(Highlight).where(Highlight.article_id == article_id)
    highlights = session.exec(statement).all()
    return highlights
