"""
magazines.py — Dijital dergi endpoint'leri.
Oluşturma/düzenleme sadece üyelere, detay görüntüleme herkese açık.
"""
from typing import List
from sqlmodel import Session

from fastapi import APIRouter, Depends, HTTPException, status

from core.database import get_db
from core.dependencies import get_current_user
from api.magazines.schemas import (
    MagazineCreate,
    MagazineAddArticle,
    MagazineResponse,
    MagazineDetailResponse,
)
from api.magazines import service as magazine_service

router = APIRouter(prefix="/magazines", tags=["Magazines"])


@router.get(
    "/my",
    response_model=List[MagazineResponse],
    summary="Kendi dergilerimi listele",
    description="Sadece üyeler — giriş yapan kullanıcının dergilerini listeler.",
)
def my_magazines(
    current_user = Depends(get_current_user),
    session: Session = Depends(get_db),
):
    """Kullanıcının kendi dergilerini döndürür."""
    return magazine_service.list_user_magazines(session, current_user.id)


@router.post(
    "",
    response_model=MagazineResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Dergi oluştur",
    description="Sadece üyeler — yeni dijital dergi oluşturur.",
)
def create_magazine(
    data: MagazineCreate,
    current_user = Depends(get_current_user),
    session: Session = Depends(get_db),
):
    """Yeni dergi oluşturur."""
    return magazine_service.create_magazine(
        session, data.title, data.description, data.image, current_user.id
    )


@router.get(
    "/{magazine_id}",
    response_model=MagazineDetailResponse,
    summary="Dergi detayı",
    description="Herkes erişebilir — derginin makale listesi ile birlikte detayını döndürür.",
)
def get_magazine(
    magazine_id: int,
    session: Session = Depends(get_db),
):
    """Dergi detayını döndürür."""
    magazine = magazine_service.get_magazine_detail(session, magazine_id)
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
    current_user = Depends(get_current_user),
    session: Session = Depends(get_db),
):
    """Dergiye makale ekler."""
    if not magazine_service.add_article_to_magazine(
        session, magazine_id, data.article_id, current_user.id
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
    current_user = Depends(get_current_user),
    session: Session = Depends(get_db),
):
    """Dergiden makale çıkarır."""
    if not magazine_service.remove_article_from_magazine(
        session, magazine_id, article_id, current_user.id
    ):
        raise HTTPException(
            status_code=400,
            detail="Makale çıkarılamadı — dergi sahibi değilsiniz veya makale bulunamadı",
        )
    return {"status": "ok", "message": "Makale dergiden çıkarıldı"}

from pydantic import BaseModel
class CommentCreate(BaseModel):
    content: str

@router.post("/{magazine_id}/comments")
def add_magazine_comment(
    magazine_id: int,
    data: CommentCreate,
    current_user = Depends(get_current_user),
    session: Session = Depends(get_db),
):
    magazine = magazine_service.get_magazine_detail(session, magazine_id)
    if not magazine:
        raise HTTPException(status_code=404, detail="Dergi bulunamadı")
        
    from core.models import MagazineComment
    from api.articles.service import sanitize_html
    
    sanitized_content = sanitize_html(data.content)
    comment = MagazineComment(
        magazine_id=magazine_id,
        user_id=current_user.id,
        content=sanitized_content
    )
    session.add(comment)
    session.commit()
    return {"status": "ok", "message": "Comment added"}

@router.get("/{magazine_id}/comments")
def get_magazine_comments(
    magazine_id: int,
    session: Session = Depends(get_db),
):
    from core.models import MagazineComment
    from sqlmodel import select
    from sqlalchemy.orm import joinedload
    
    statement = (
        select(MagazineComment)
        .where(MagazineComment.magazine_id == magazine_id)
        .options(joinedload(MagazineComment.user))
        .order_by(MagazineComment.created_at.desc())
    )
    comments = session.exec(statement).all()
    result = []
    for c in comments:
        result.append({
            "id": c.id,
            "content": c.content,
            "created_at": c.created_at,
            "user": {
                "id": c.user.id,
                "username": c.user.username,
                "profile_picture": c.user.profile_picture
            }
        })
    return result
