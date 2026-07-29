from typing import List
from sqlmodel import Session

from fastapi import APIRouter, Depends, HTTPException

from core.database import get_db
from core.dependencies import get_current_user
from api.users.schemas import UserProfile, UserPublic, UserUpdateBio, UserUpdateProfile
from api.articles.schemas import ArticleListItem
from api.articles import service as article_service
from api.auth.service import get_user_by_id, update_bio, update_profile

router = APIRouter(prefix="/users", tags=["Users"])


@router.get("/me/profile", response_model=UserPublic)
def get_my_profile(current_user = Depends(get_current_user)):
    """Giriş yapan kullanıcının kendi profili."""
    return UserPublic.model_validate(current_user)


@router.get("/{user_id}/profile", response_model=UserProfile)
def get_user_profile(user_id: int, session: Session = Depends(get_db)):
    """Yazar profil bilgisi — herkese açık."""
    user = get_user_by_id(session, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı")
    public_articles = article_service.get_articles_by_author(session, user_id, public_only=True)
    return UserProfile(**user.model_dump(), article_count=len(public_articles))


@router.get("/{user_id}/articles", response_model=List[ArticleListItem])
def get_user_articles(user_id: int, session: Session = Depends(get_db)):
    """Bir yazarın herkese açık makalelerini listeler."""
    if not get_user_by_id(session, user_id):
        raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı")
    return article_service.get_articles_by_author(session, user_id, public_only=True)


@router.patch("/me/bio", response_model=UserPublic)
def update_my_bio(
    data: UserUpdateBio,
    current_user = Depends(get_current_user),
    session: Session = Depends(get_db),
):
    """Giriş yapan kullanıcının biyografisini günceller."""
    updated = update_bio(session, current_user.id, data.bio)
    return UserPublic.model_validate(updated)


@router.patch("/me/profile_customization", response_model=UserPublic)
def update_my_profile(
    data: UserUpdateProfile,
    current_user = Depends(get_current_user),
    session: Session = Depends(get_db),
):
    """Giriş yapan kullanıcının profil özelleştirmelerini (renk, resim, emote) günceller."""
    updated = update_profile(session, current_user.id, data.model_dump(exclude_unset=True))
    return UserPublic.model_validate(updated)
