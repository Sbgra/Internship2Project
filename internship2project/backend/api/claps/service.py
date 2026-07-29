"""
clap_service.py — Alkış (clap) işlemleri.
Herkes alkış atabilir. Makale başına 50 alkış limiti:
  - Üyeler: user_id ile takip edilir
  - Misafirler: IP adresi ile takip edilir
"""
from typing import Optional
from sqlmodel import Session, select
from sqlalchemy import func
from core.models import Clap, ArticleStats

CLAP_LIMIT_PER_ARTICLE = 50

def get_user_claps(session: Session, article_id: int, user_id: int) -> int:
    """Üye kullanıcının bu makaleye attığı toplam alkış sayısını döndürür."""
    result = session.exec(
        select(func.coalesce(func.sum(Clap.count), 0))
        .where(Clap.article_id == article_id, Clap.user_id == user_id)
    ).first()
    return result or 0

def get_ip_claps(session: Session, article_id: int, ip: str) -> int:
    """Misafir IP'nin bu makaleye attığı toplam alkış sayısını döndürür."""
    result = session.exec(
        select(func.coalesce(func.sum(Clap.count), 0))
        .where(Clap.article_id == article_id, Clap.ip_address == ip, Clap.user_id.is_(None))
    ).first()
    return result or 0

def get_total_claps(session: Session, article_id: int) -> int:
    """Makalenin toplam alkış sayısını döndürür."""
    result = session.exec(
        select(func.coalesce(func.sum(Clap.count), 0))
        .where(Clap.article_id == article_id)
    ).first()
    return result or 0

def add_clap(
    session: Session,
    article_id: int,
    count: int,
    user_id: Optional[int] = None,
    ip: Optional[str] = None,
) -> dict:
    """
    Alkış ekler. Hem üye hem misafir için makale başına 50 limit uygulanır.
    Dönüş: {article_id, total_claps, user_claps, remaining_claps}
    """
    if user_id:
        current_claps = get_user_claps(session, article_id, user_id)
    else:
        current_claps = get_ip_claps(session, article_id, ip)

    remaining = CLAP_LIMIT_PER_ARTICLE - current_claps
    if remaining <= 0:
        return {
            "article_id": article_id,
            "total_claps": get_total_claps(session, article_id),
            "user_claps": current_claps,
            "remaining_claps": 0,
        }

    actual_count = min(count, remaining)

    # Insert clap
    clap = Clap(article_id=article_id, user_id=user_id, ip_address=ip, count=actual_count)
    session.add(clap)

    # Upsert article_stats
    stats = session.get(ArticleStats, article_id)
    if stats:
        stats.clap_count += actual_count
    else:
        stats = ArticleStats(article_id=article_id, view_count=0, clap_count=actual_count)
    session.add(stats)
    
    session.commit()

    new_user_claps = current_claps + actual_count
    return {
        "article_id": article_id,
        "total_claps": get_total_claps(session, article_id),
        "user_claps": new_user_claps,
        "remaining_claps": CLAP_LIMIT_PER_ARTICLE - new_user_claps,
    }
