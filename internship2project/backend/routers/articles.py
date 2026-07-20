import sqlite3
import secrets
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, status

from database import get_db
from dependencies import get_current_user, get_optional_user
from schemas.article import ArticleCreate, ArticleUpdate, ArticleDetail, ArticleListItem
from services import article_service

router = APIRouter(prefix="/articles", tags=["Articles"])


@router.get("/public", response_model=List[ArticleListItem])
def list_public(skip: int = 0, limit: int = 20, conn: sqlite3.Connection = Depends(get_db)):
    return article_service.get_public_articles(conn, skip, limit)


@router.get("/my", response_model=List[ArticleListItem])
def my_articles(
    current_user: dict = Depends(get_current_user),
    conn: sqlite3.Connection = Depends(get_db),
):
    return article_service.get_articles_by_author(conn, current_user["id"], public_only=False)


@router.get("/{article_id}", response_model=ArticleDetail)
def get_article(
    article_id: int,
    share_token: Optional[str] = None,
    conn: sqlite3.Connection = Depends(get_db),
    current_user: Optional[dict] = Depends(get_optional_user),
):
    article = article_service.get_article_by_id(conn, article_id)
    if not article:
        raise HTTPException(status_code=404, detail="Makale bulunamadı")
    if not article["is_public"]:
        is_author = current_user and current_user["id"] == article["author_id"]
        valid_token = share_token and article.get("share_token") == share_token
        if not (is_author or valid_token):
            raise HTTPException(status_code=403, detail="Erişim yetkiniz yok")
    return article


@router.post("", response_model=ArticleDetail, status_code=status.HTTP_201_CREATED)
def create_article(
    data: ArticleCreate,
    current_user: dict = Depends(get_current_user),
    conn: sqlite3.Connection = Depends(get_db),
):
    return article_service.create_article(
        conn, data.title, data.content, data.summary, data.is_public, current_user["id"]
    )


@router.put("/{article_id}", response_model=ArticleDetail)
def update_article(
    article_id: int,
    data: ArticleUpdate,
    current_user: dict = Depends(get_current_user),
    conn: sqlite3.Connection = Depends(get_db),
):
    updated = article_service.update_article(
        conn, article_id, current_user["id"], data.model_dump(exclude_unset=True)
    )
    if not updated:
        raise HTTPException(status_code=404, detail="Makale bulunamadı veya yetkiniz yok")
    return updated


@router.delete("/{article_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_article(
    article_id: int,
    current_user: dict = Depends(get_current_user),
    conn: sqlite3.Connection = Depends(get_db),
):
    if not article_service.delete_article(conn, article_id, current_user["id"]):
        raise HTTPException(status_code=404, detail="Makale bulunamadı veya yetkiniz yok")

@router.post("/{article_id}/share")
def generate_share_token(
    article_id: int,
    current_user: dict = Depends(get_current_user),
    conn: sqlite3.Connection = Depends(get_db),
):
    """Makale için paylaşım bağlantısı token'ı üretir (Sadece yazar)."""
    article = article_service.get_article_by_id(conn, article_id)
    if not article or article["author_id"] != current_user["id"]:
        raise HTTPException(status_code=404, detail="Makale bulunamadı veya yetkiniz yok")
    
    token = secrets.token_urlsafe(16)
    conn.execute("UPDATE articles SET share_token = ? WHERE id = ?", (token, article_id))
    conn.commit()
    return {"share_token": token}


@router.post("/{article_id}/offline")
def save_offline(
    article_id: int,
    current_user: dict = Depends(get_current_user),
    conn: sqlite3.Connection = Depends(get_db),
):
    """Makaleyi çevrimdışı okumak için kaydeder (Sadece üyeler)."""
    article = article_service.get_article_by_id(conn, article_id)
    if not article:
        raise HTTPException(status_code=404, detail="Makale bulunamadı")
    try:
        conn.execute("INSERT INTO saved_articles (user_id, article_id) VALUES (?, ?)", (current_user["id"], article_id))
        conn.commit()
    except sqlite3.IntegrityError:
        pass # Zaten kaydedilmiş
    return {"status": "ok", "message": "Makale çevrimdışı okuma için kaydedildi"}


@router.get("/{article_id}/audio")
def get_audio_stream(
    article_id: int,
    current_user: dict = Depends(get_current_user),
    conn: sqlite3.Connection = Depends(get_db),
):
    """Makaleyi sesli dinleme özelliği (Sadece üyeler)."""
    article = article_service.get_article_by_id(conn, article_id)
    if not article:
        raise HTTPException(status_code=404, detail="Makale bulunamadı")
    return {"status": "ok", "audio_url": f"https://mock-audio-service.com/articles/{article_id}/listen"}
