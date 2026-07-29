"""
magazine.py — Dijital dergi şemaları.
Sadece üyeler dergi oluşturabilir ve makale ekleyebilir.
"""
from typing import Annotated, List, Optional
from pydantic import BaseModel, Field
from datetime import datetime
from api.articles.schemas import ArticleListItem


class MagazineCreate(BaseModel):
    """Dergi oluşturma isteği — sadece üyeler."""
    title: Annotated[str, Field(min_length=1, max_length=200, description="Dergi başlığı")]
    description: Annotated[Optional[str], Field(None, max_length=500, description="Dergi açıklaması")]
    image: Annotated[Optional[str], Field(None, description="Dergi kapak resmi URL'i")]


class MagazineAddArticle(BaseModel):
    """Dergiye makale ekleme isteği."""
    article_id: Annotated[int, Field(description="Eklenecek makale ID")]


class MagazineResponse(BaseModel):
    model_config = {"from_attributes": True}
    
    """Dergi özet bilgisi."""
    id: Annotated[int, Field(description="Dergi ID")]
    title: Annotated[str, Field(description="Dergi başlığı")]
    description: Annotated[Optional[str], Field(description="Dergi açıklaması")]
    image: Annotated[Optional[str], Field(description="Dergi kapak resmi URL'i")]
    owner_id: Annotated[int, Field(description="Sahibi kullanıcı ID")]
    article_count: Annotated[int, Field(ge=0, description="Dergi içindeki makale sayısı")]
    created_at: Annotated[datetime, Field(description="Oluşturulma tarihi")]


class MagazineDetailResponse(MagazineResponse):
    """Dergi detayı — içindeki makaleler ile birlikte."""
    articles: Annotated[List[ArticleListItem], Field(description="Dergideki makaleler")]
