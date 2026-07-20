"""
communities.py — Topluluk endpoint'leri.
Listeleme herkese açık, oluşturma/katılma/ayrılma sadece üyelere.
"""
import sqlite3
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, status

from database import get_db
from dependencies import get_current_user, get_optional_user
from schemas.community import CommunityCreate, CommunityListItem, CommunityResponse
from services import community_service

router = APIRouter(prefix="/communities", tags=["Communities"])


@router.get(
    "",
    response_model=List[CommunityListItem],
    summary="Toplulukları listele",
    description="Herkes erişebilir — tüm toplulukları üye sayıları ile listeler.",
)
def list_communities(
    skip: int = 0,
    limit: int = 20,
    conn: sqlite3.Connection = Depends(get_db),
):
    """Tüm toplulukları listeler."""
    return community_service.list_communities(conn, skip, limit)


@router.post(
    "",
    response_model=CommunityResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Topluluk oluştur",
    description="Sadece üyeler — yeni topluluk oluşturur ve kurucuyu otomatik üye yapar.",
)
def create_community(
    data: CommunityCreate,
    current_user: dict = Depends(get_current_user),
    conn: sqlite3.Connection = Depends(get_db),
):
    """Yeni topluluk oluşturur."""
    return community_service.create_community(
        conn, data.name, data.description, current_user["id"]
    )


@router.get(
    "/{community_id}",
    response_model=CommunityResponse,
    summary="Topluluk detayı",
    description="Herkes erişebilir — topluluk bilgilerini ve üyelik durumunu döndürür.",
)
def get_community(
    community_id: int,
    conn: sqlite3.Connection = Depends(get_db),
    current_user: Optional[dict] = Depends(get_optional_user),
):
    """Topluluk detayını döndürür."""
    user_id = current_user["id"] if current_user else None
    community = community_service.get_community_detail(conn, community_id, user_id)
    if not community:
        raise HTTPException(status_code=404, detail="Topluluk bulunamadı")
    return community


@router.post(
    "/{community_id}/join",
    summary="Topluluğa katıl",
    description="Sadece üyeler — topluluğa katılır.",
)
def join_community(
    community_id: int,
    current_user: dict = Depends(get_current_user),
    conn: sqlite3.Connection = Depends(get_db),
):
    """Kullanıcıyı topluluğa ekler."""
    community = community_service.get_community_detail(conn, community_id)
    if not community:
        raise HTTPException(status_code=404, detail="Topluluk bulunamadı")
    if not community_service.join_community(conn, community_id, current_user["id"]):
        raise HTTPException(status_code=400, detail="Zaten bu topluluğun üyesisiniz")
    return {"status": "ok", "message": "Topluluğa katıldınız"}


@router.delete(
    "/{community_id}/leave",
    summary="Topluluktan ayrıl",
    description="Sadece üyeler — topluluktan ayrılır.",
)
def leave_community(
    community_id: int,
    current_user: dict = Depends(get_current_user),
    conn: sqlite3.Connection = Depends(get_db),
):
    """Kullanıcıyı topluluktan çıkarır."""
    if not community_service.leave_community(conn, community_id, current_user["id"]):
        raise HTTPException(status_code=400, detail="Bu topluluğun üyesi değilsiniz")
    return {"status": "ok", "message": "Topluluktan ayrıldınız"}
