"""
magazine_service.py — Dijital dergi CRUD işlemleri.
Sadece üyeler dergi oluşturabilir ve makale ekleyebilir.
"""
from typing import List, Optional
from sqlmodel import Session, select
from sqlalchemy import func
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import joinedload
from core.models import Magazine, MagazineArticle, Article


def create_magazine(
    session: Session, title: str, description: Optional[str], image: Optional[str], owner_id: int
) -> dict:
    # Aynı isimde dergi var mı?
    magazine = Magazine(title=title, description=description, image=image, owner_id=owner_id)
    session.add(magazine)
    session.commit()
    session.refresh(magazine)
    return get_magazine_by_id(session, magazine.id)


def get_magazine_by_id(session: Session, magazine_id: int) -> Optional[dict]:
    """Dergi bilgisini makale sayısıyla birlikte döndürür."""
    statement = (
        select(Magazine, func.count(MagazineArticle.id).label("article_count"))
        .outerjoin(MagazineArticle, MagazineArticle.magazine_id == Magazine.id)
        .where(Magazine.id == magazine_id)
        .group_by(Magazine.id)
    )
    result = session.exec(statement).first()
    if not result:
        return None
    
    mag, count = result
    return {
        **mag.model_dump(),
        "article_count": count
    }


def list_user_magazines(session: Session, user_id: int) -> List[dict]:
    """Kullanıcının kendi dergilerini listeler."""
    statement = (
        select(Magazine, func.count(MagazineArticle.id).label("article_count"))
        .outerjoin(MagazineArticle, MagazineArticle.magazine_id == Magazine.id)
        .where(Magazine.owner_id == user_id)
        .group_by(Magazine.id)
        .order_by(Magazine.created_at.desc())
    )
    results = session.exec(statement).all()
    return [
        {
            **mag.model_dump(),
            "article_count": count
        }
        for mag, count in results
    ]


def get_magazine_detail(session: Session, magazine_id: int) -> Optional[dict]:
    """Dergi detayını içindeki makaleler ile birlikte döndürür."""
    magazine_data = get_magazine_by_id(session, magazine_id)
    if not magazine_data:
        return None

    # Dergideki makaleleri getir
    statement = (
        select(MagazineArticle, Article)
        .join(Article, MagazineArticle.article_id == Article.id)
        .options(joinedload(Article.author))
        .where(MagazineArticle.magazine_id == magazine_id)
        .order_by(MagazineArticle.added_at.desc())
    )
    results = session.exec(statement).all()

    articles = []
    for ma, article in results:
        articles.append(article)

    magazine_data["articles"] = articles
    return magazine_data


def add_article_to_magazine(
    session: Session, magazine_id: int, article_id: int, owner_id: int
) -> bool:
    """Dergiye makale ekler. Sadece dergi sahibi ekleyebilir."""
    magazine = session.get(Magazine, magazine_id)
    if not magazine or magazine.owner_id != owner_id:
        return False
    try:
        ma = MagazineArticle(magazine_id=magazine_id, article_id=article_id)
        session.add(ma)
        session.commit()
        return True
    except IntegrityError:
        session.rollback()
        return False


def remove_article_from_magazine(
    session: Session, magazine_id: int, article_id: int, owner_id: int
) -> bool:
    """Dergiden makale çıkarır. Sadece dergi sahibi çıkarabilir."""
    magazine = session.get(Magazine, magazine_id)
    if not magazine or magazine.owner_id != owner_id:
        return False
        
    ma = session.exec(
        select(MagazineArticle).where(
            MagazineArticle.magazine_id == magazine_id,
            MagazineArticle.article_id == article_id
        )
    ).first()
    
    if not ma:
        return False
        
    session.delete(ma)
    session.commit()
    return True
