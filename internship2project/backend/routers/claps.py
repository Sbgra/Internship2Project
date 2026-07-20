"""
claps.py — Alkış (clap) endpoint'leri.
Herkes alkış atabilir:
  - Üyeler: user_id ile takip, makale başına 50 limit
  - Misafirler: IP adresi ile takip, makale başına 50 limit
"""
import sqlite3
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Request

from database import get_db
from dependencies import get_optional_user
from schemas.clap import ClapRequest, ClapResponse
from services import clap_service, article_service

def get_client_ip(request: Request) -> str:
    forwarded = request.headers.get("X-Forwarded-For")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return request.client.host

router = APIRouter(prefix="/articles", tags=["Claps"])


@router.post(
    "/{article_id}/clap",
    response_model=ClapResponse,
    summary="Makaleye alkış at",
    description="Herkes kullanabilir. Makale başına 50 alkış limiti uygulanır. "
                "Misafirler IP ile, üyeler user_id ile takip edilir.",
)
def clap(
    article_id: int,
    data: ClapRequest,
    request: Request,
    conn: sqlite3.Connection = Depends(get_db),
    current_user: Optional[dict] = Depends(get_optional_user),
):
    """Makaleye alkış atar. Limit aşılırsa kalan hak 0 döner."""
    article = article_service.get_article_by_id(conn, article_id)
    if not article:
        raise HTTPException(status_code=404, detail="Makale bulunamadı")

    user_id = current_user["id"] if current_user else None
    ip = get_client_ip(request) if not current_user else None

    result = clap_service.add_clap(
        conn, article_id, data.count, user_id=user_id, ip=ip
    )
    return result


@router.get(
    "/{article_id}/claps",
    response_model=ClapResponse,
    summary="Makale alkış bilgisini getir",
    description="Herkes erişebilir — makalenin toplam alkış sayısını ve "
                "kullanıcının/IP'nin bu makaleye attığı alkışları döndürür.",
)
def get_claps(
    article_id: int,
    request: Request,
    conn: sqlite3.Connection = Depends(get_db),
    current_user: Optional[dict] = Depends(get_optional_user),
):
    """Makalenin alkış bilgilerini döndürür."""
    article = article_service.get_article_by_id(conn, article_id)
    if not article:
        raise HTTPException(status_code=404, detail="Makale bulunamadı")

    total = clap_service.get_total_claps(conn, article_id)

    if current_user:
        user_claps = clap_service.get_user_claps(conn, article_id, current_user["id"])
    else:
        ip = get_client_ip(request)
        user_claps = clap_service.get_ip_claps(conn, article_id, ip)

    return {
        "article_id": article_id,
        "total_claps": total,
        "user_claps": user_claps,
        "remaining_claps": max(0, clap_service.CLAP_LIMIT_PER_ARTICLE - user_claps),
    }
