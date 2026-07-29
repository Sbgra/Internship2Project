"""
stats.py — Makale istatistik endpoint'leri.
Herkes makale istatistiklerini görüntüleyebilir.
"""
from sqlmodel import Session

from fastapi import APIRouter, Depends, HTTPException

from core.database import get_db
from api.stats.schemas import ArticleStatsResponse
from api.stats import service as stats_service
from api.articles import service as article_service

router = APIRouter(prefix="/stats", tags=["Statistics"])

@router.get(
    "/{article_id}",
    response_model=ArticleStatsResponse,
    summary="Makale istatistiklerini getir",
    description="Herkes erişebilir — makale görüntülenme ve alkış sayılarını döndürür.",
)
def get_stats(article_id: int, session: Session = Depends(get_db)):
    """Makale istatistiklerini döndürür. Makale yoksa 404."""
    article = article_service.get_article_by_id(session, article_id)
    if not article:
        raise HTTPException(status_code=404, detail="Makale bulunamadı")
    stats = stats_service.get_article_stats(session, article_id)
    return stats

@router.post(
    "/{article_id}/view",
    summary="Görüntülenme kaydet",
    description="Makale her açıldığında çağrılır — görüntülenme sayacını artırır.",
)
def record_view(article_id: int, session: Session = Depends(get_db)):
    """Makale görüntülenme sayacını artırır."""
    article = article_service.get_article_by_id(session, article_id)
    if not article:
        raise HTTPException(status_code=404, detail="Makale bulunamadı")
    stats_service.record_view(session, article_id)
    return {"status": "ok"}
