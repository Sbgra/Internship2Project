import sqlite3
from typing import List

from fastapi import APIRouter, Depends

from database import get_db
from dependencies import get_current_user
from schemas.article import ArticleListItem
from services import article_service

router = APIRouter(prefix="/feed", tags=["Feed"])


@router.get("/random", response_model=List[ArticleListItem])
def random_feed(limit: int = 10, conn: sqlite3.Connection = Depends(get_db)):
    """Rastgele herkese açık makale akışı. Oturum gerekmez."""
    return article_service.get_random_feed(conn, limit)


@router.get("/personalized", response_model=List[ArticleListItem])
def personalized_feed(
    limit: int = 10,
    current_user: dict = Depends(get_current_user),
    conn: sqlite3.Connection = Depends(get_db)
):
    """Üyelere özel kişiselleştirilmiş akış. Oturum zorunludur."""
    return article_service.get_personalized_feed(conn, current_user["id"], limit)
