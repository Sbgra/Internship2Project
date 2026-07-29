"""
stats_service.py — Makale istatistik sorguları.
Görüntülenme sayacı ve istatistik okuma işlemleri.
"""
from typing import Optional
from sqlmodel import Session
from core.models import ArticleStats

def ensure_stats_row(session: Session, article_id: int) -> ArticleStats:
    """article_stats satırı yoksa oluşturur."""
    stats = session.get(ArticleStats, article_id)
    if not stats:
        stats = ArticleStats(article_id=article_id, view_count=0, clap_count=0)
        session.add(stats)
        session.commit()
        session.refresh(stats)
    return stats

def record_view(session: Session, article_id: int) -> None:
    """Makale görüntülenme sayacını 1 artırır."""
    stats = ensure_stats_row(session, article_id)
    stats.view_count += 1
    session.add(stats)
    session.commit()

def get_article_stats(session: Session, article_id: int) -> Optional[dict]:
    """Makale istatistiklerini döndürür. Satır yoksa oluşturup varsayılan döner."""
    stats = ensure_stats_row(session, article_id)
    return stats.model_dump()
