import sqlite3
from typing import List

from fastapi import APIRouter, Depends, HTTPException

from database import get_db
from dependencies import get_current_user
from schemas.user import UserProfile, UserPublic, UserUpdateBio, UserUpdateProfile
from schemas.article import ArticleListItem
from services import article_service
from services.auth_service import get_user_by_id, update_bio, update_profile

router = APIRouter(prefix="/users", tags=["Users"])


@router.get("/{user_id}/profile", response_model=UserProfile)
def get_user_profile(user_id: int, conn: sqlite3.Connection = Depends(get_db)):
    """Yazar profil bilgisi — herkese açık."""
    user = get_user_by_id(conn, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı")
    public_articles = article_service.get_articles_by_author(conn, user_id, public_only=True)
    return UserProfile(**user, article_count=len(public_articles))


@router.get("/{user_id}/articles", response_model=List[ArticleListItem])
def get_user_articles(user_id: int, conn: sqlite3.Connection = Depends(get_db)):
    """Bir yazarın herkese açık makalelerini listeler."""
    if not get_user_by_id(conn, user_id):
        raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı")
    return article_service.get_articles_by_author(conn, user_id, public_only=True)


@router.get("/me/profile", response_model=UserPublic)
def get_my_profile(current_user: dict = Depends(get_current_user)):
    """Giriş yapan kullanıcının kendi profili."""
    return UserPublic(**current_user)


@router.patch("/me/bio", response_model=UserPublic)
def update_my_bio(
    data: UserUpdateBio,
    current_user: dict = Depends(get_current_user),
    conn: sqlite3.Connection = Depends(get_db),
):
    """Giriş yapan kullanıcının biyografisini günceller."""
    updated = update_bio(conn, current_user["id"], data.bio)
    return UserPublic(**updated)


@router.patch("/me/profile_customization", response_model=UserPublic)
def update_my_profile(
    data: UserUpdateProfile,
    current_user: dict = Depends(get_current_user),
    conn: sqlite3.Connection = Depends(get_db),
):
    """Giriş yapan kullanıcının profil özelleştirmelerini (renk, resim, emote) günceller."""
    updated = update_profile(conn, current_user["id"], data.model_dump(exclude_unset=True))
    return UserPublic(**updated)
