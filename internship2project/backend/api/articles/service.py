"""
service.py — Makale CRUD işlemleri.
Tüm sorgular JOIN ile yazar bilgisini de getirir.
"""
from typing import List, Optional
import re
import random
from sqlmodel import Session, select
from sqlalchemy.orm import joinedload
from core.models import Article, Category, ArticleCategory
from sqlalchemy import func


# ── XSS Koruması ──────────────────────────────────────────────
# HTML içeriği kaydetmeden önce zararlı etiketleri temizler.
# <script>, <iframe>, onclick gibi tehlikeli içerikleri siler,
# sadece formatlama etiketlerine (b, i, span vb.) izin verir.

_ALLOWED_TAGS = {'b', 'i', 'u', 'strong', 'em', 'p', 'br', 'span',
                 'h1', 'h2', 'h3', 'ul', 'ol', 'li', 'a', 'div'}

_ALLOWED_ATTRS = {'style', 'class', 'href', 'target'}

# style attribute'unda izin verilen CSS özellikleri
_ALLOWED_STYLES = {'color', 'background-color', 'font-size', 'text-align',
                   'font-weight', 'font-style', 'text-decoration'}


def _is_safe_style(style_value: str) -> str:
    """style attribute'undaki CSS değerlerini filtreler."""
    safe_parts = []
    for part in style_value.split(';'):
        part = part.strip()
        if not part:
            continue
        prop_val = part.split(':', 1)
        if len(prop_val) == 2:
            prop = prop_val[0].strip().lower()
            if prop in _ALLOWED_STYLES:
                safe_parts.append(part)
    return '; '.join(safe_parts) if safe_parts else ''


def sanitize_html(content: str) -> str:
    """
    Basit ve güvenli HTML sanitizer — bleach'e bağımlılık olmadan çalışır.
    Sadece izin verilen etiketleri ve attribute'ları bırakır, geri kalanı siler.
    """
    try:
        import bleach
        from bleach.css_sanitizer import CSSSanitizer
        css_sanitizer = CSSSanitizer(allowed_css_properties=list(_ALLOWED_STYLES))
        return bleach.clean(
            content,
            tags=list(_ALLOWED_TAGS),
            attributes={tag: list(_ALLOWED_ATTRS) for tag in _ALLOWED_TAGS},
            css_sanitizer=css_sanitizer,
            strip=True,
        )
    except ImportError:
        # bleach yüklü değilse fallback: tehlikeli etiketleri regex ile temizle
        # script, iframe, object, embed, form etiketlerini ve on* event handler'larını sil
        cleaned = re.sub(r'<\s*script[^>]*>.*?</\s*script\s*>', '', content, flags=re.DOTALL | re.IGNORECASE)
        cleaned = re.sub(r'<\s*iframe[^>]*>.*?</\s*iframe\s*>', '', cleaned, flags=re.DOTALL | re.IGNORECASE)
        cleaned = re.sub(r'<\s*object[^>]*>.*?</\s*object\s*>', '', cleaned, flags=re.DOTALL | re.IGNORECASE)
        cleaned = re.sub(r'<\s*embed[^>]*/?>', '', cleaned, flags=re.IGNORECASE)
        cleaned = re.sub(r'<\s*form[^>]*>.*?</\s*form\s*>', '', cleaned, flags=re.DOTALL | re.IGNORECASE)
        # on* event handler'larını sil (onclick, onerror vb.)
        cleaned = re.sub(r'\s+on\w+\s*=\s*["\'][^"\']*["\']', '', cleaned, flags=re.IGNORECASE)
        cleaned = re.sub(r'\s+on\w+\s*=\s*\S+', '', cleaned, flags=re.IGNORECASE)
        # javascript: protokolünü sil
        cleaned = re.sub(r'javascript\s*:', '', cleaned, flags=re.IGNORECASE)
        return cleaned


def get_public_articles(session: Session, skip: int = 0, limit: int = 20, categories: List[str] = None) -> List[Article]:
    statement = (
        select(Article)
        .where(Article.is_public == True)
        .options(joinedload(Article.author))
        .order_by(Article.created_at.desc())
    )
    
    if categories:
        for cat in categories:
            statement = statement.where(
                Article.id.in_(
                    select(ArticleCategory.article_id)
                    .join(Category, Category.id == ArticleCategory.category_id)
                    .where(Category.name == cat)
                )
            )
            
    statement = statement.offset(skip).limit(limit)
    return session.exec(statement).unique().all()

def get_random_feed(session: Session, limit: int = 10, categories: List[str] = None) -> List[Article]:
    all_public = get_public_articles(session, limit=1000, categories=categories)
    return random.sample(list(all_public), min(limit, len(all_public)))

def get_personalized_feed(session: Session, user_id: int, limit: int = 10) -> List[Article]:
    statement = (
        select(Article)
        .where(Article.is_public == True, Article.author_id != user_id)
        .options(joinedload(Article.author))
        .order_by(func.random())
        .limit(limit)
    )
    return session.exec(statement).all()

def get_article_by_id(session: Session, article_id: int) -> Optional[Article]:
    statement = select(Article).where(Article.id == article_id).options(joinedload(Article.author), joinedload(Article.translations))
    return session.exec(statement).first()

def get_articles_by_author(session: Session, author_id: int, public_only: bool = False) -> List[Article]:
    statement = select(Article).where(Article.author_id == author_id).options(joinedload(Article.author)).order_by(Article.created_at.desc())
    if public_only:
        statement = statement.where(Article.is_public == True)
    return session.exec(statement).all()

def create_article(
    session: Session,
    title: str,
    content: str,
    summary: Optional[str],
    cover_image: Optional[str],
    is_public: bool,
    author_id: int,
    categories: Optional[List[str]] = None,
    target_languages: Optional[List[str]] = None,
) -> Article:
    sanitized_content = sanitize_html(content)

    article = Article(
        title=title,
        content=sanitized_content,
        summary=summary,
        cover_image=cover_image,
        is_public=is_public,
        author_id=author_id
    )
    session.add(article)
    session.commit()
    session.refresh(article)
    
    if categories:
        for cat_name in categories:
            cat_name = cat_name.strip()
            cat = session.exec(select(Category).where(Category.name == cat_name)).first()
            if not cat:
                cat = Category(name=cat_name)
                session.add(cat)
                session.commit()
                session.refresh(cat)
            ac = ArticleCategory(article_id=article.id, category_id=cat.id)
            session.add(ac)
        session.commit()
        
    if target_languages:
        # Artık çeviriler makale oluşturulduğunda toplu olarak yapılmıyor.
        # İlgili dil UI'dan ilk kez seçildiğinde (GET /articles/{id}?lang=...)
        # on-demand olarak anlık çevrilip kaydedilecek. 
        pass

    return get_article_by_id(session, article.id)

def update_article(
    session: Session,
    article_id: int,
    author_id: int,
    data: dict,
) -> Optional[Article]:
    article = session.get(Article, article_id)
    if not article or article.author_id != author_id:
        return None

    allowed = {"title", "content", "summary", "cover_image", "is_public"}
    for key, value in data.items():
        if key in allowed and value is not None:
            if key == "content":
                value = sanitize_html(value)
            setattr(article, key, value)

    session.add(article)
    session.commit()
    session.refresh(article)
    return get_article_by_id(session, article_id)

def delete_article(session: Session, article_id: int, author_id: int) -> bool:
    article = session.get(Article, article_id)
    if not article or article.author_id != author_id:
        return False
    session.delete(article)
    session.commit()
    return True


