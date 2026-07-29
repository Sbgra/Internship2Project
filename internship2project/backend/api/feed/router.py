from typing import List
from sqlmodel import Session

from fastapi import APIRouter, Depends, Query

from core.database import get_db
from core.dependencies import get_current_user
from api.articles.schemas import ArticleListItem
from api.articles import service as article_service

router = APIRouter(prefix="/feed", tags=["Feed"])


@router.get("/random", response_model=List[ArticleListItem])
def random_feed(limit: int = 10, categories: List[str] = Query(None), session: Session = Depends(get_db)):
    """Rastgele herkese açık makale akışı. Oturum gerekmez."""
    return article_service.get_random_feed(session, limit, categories)


@router.get("/personalized", response_model=List[ArticleListItem])
def personalized_feed(
    limit: int = 10,
    current_user = Depends(get_current_user),
    session: Session = Depends(get_db)
):
    """Üyelere özel kişiselleştirilmiş akış. Oturum zorunludur."""
    return article_service.get_personalized_feed(session, current_user.id, limit)
