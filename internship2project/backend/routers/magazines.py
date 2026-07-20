"""
magazines.py — Dijital dergi endpoint'leri.
Oluşturma/düzenleme sadece üyelere, detay görüntüleme herkese açık.
"""
import sqlite3
from typing import List

from fastapi import APIRouter, Depends, HTTPException, status

from database import get_db
from dependencies import get_current_user
from schemas.magazine import (
    MagazineCreate,
    MagazineAddArticle,
    MagazineResponse,
    MagazineDetailResponse,
)
from services import magazine_service

router = APIRouter(prefix="/magazines", tags=["Magazines"])


@router.get(
    "/my",
    response_model=List[MagazineResponse],
    summary="Kendi dergilerimi listele",
    description="Sadece üyeler — giriş yapan kullanıcının dergilerini listeler.",
)
def my_magazines(
    current_user: dict = Depends(get_current_user),
    conn: sqlite3.Connection = Depends(get_db),
):
    """Kullanıcının kendi dergilerini döndürür."""
    return magazine_service.list_user_magazines(conn, current_user["id"])


@router.post(
    "",
    response_model=MagazineResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Dergi oluştur",
    description="Sadece üyeler — yeni dijital dergi oluşturur.",
)
def create_magazine(
    data: MagazineCreate,
    current_user: dict = Depends(get_current_user),
    conn: sqlite3.Connection = Depends(get_db),
):
    """Yeni dergi oluşturur."""
    return magazine_service.create_magazine(
        conn, data.title, data.description, current_user["id"]
    )


@router.get(
    "/{magazine_id}",
    response_model=MagazineDetailResponse,
    summary="Dergi detayı",
    description="Herkes erişebilir — derginin makale listesi ile birlikte detayını döndürür.",
)
def get_magazine(
    magazine_id: int,
    conn: sqlite3.Connection = Depends(get_db),
):
    """Dergi detayını döndürür."""
    magazine = magazine_service.get_magazine_detail(conn, magazine_id)
    if not magazine:
        raise HTTPException(status_code=404, detail="Dergi bulunamadı")
    return magazine


@router.post(
    "/{magazine_id}/articles",
    summary="Dergiye makale ekle",
    description="Sadece dergi sahibi — mevcut bir makaleyi dergiye ekler.",
)
def add_article(
    magazine_id: int,
    data: MagazineAddArticle,
    current_user: dict = Depends(get_current_user),
    conn: sqlite3.Connection = Depends(get_db),
):
    """Dergiye makale ekler."""
    if not magazine_service.add_article_to_magazine(
        conn, magazine_id, data.article_id, current_user["id"]
    ):
        raise HTTPException(
            status_code=400,
            detail="Makale eklenemedi — dergi sahibi değilsiniz veya makale zaten ekli",
        )
    return {"status": "ok", "message": "Makale dergiye eklendi"}


@router.delete(
    "/{magazine_id}/articles/{article_id}",
    summary="Dergiden makale çıkar",
    description="Sadece dergi sahibi — makaleyi dergiden çıkarır.",
)
def remove_article(
    magazine_id: int,
    article_id: int,
    current_user: dict = Depends(get_current_user),
    conn: sqlite3.Connection = Depends(get_db),
):
    """Dergiden makale çıkarır."""
    if not magazine_service.remove_article_from_magazine(
        conn, magazine_id, article_id, current_user["id"]
    ):
        raise HTTPException(
            status_code=400,
            detail="Makale çıkarılamadı — dergi sahibi değilsiniz veya makale bulunamadı",
        )
    return {"status": "ok", "message": "Makale dergiden çıkarıldı"}
