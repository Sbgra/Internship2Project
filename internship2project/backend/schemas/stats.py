"""
stats.py — Makale istatistik şemaları.
Tüm alanlar Annotated ile type-annotated — frontend uyumsuzluğunu önler.
"""
from typing import Annotated
from pydantic import BaseModel, Field


class ArticleStatsResponse(BaseModel):
    """Herkes görebilir: makale istatistikleri."""
    article_id: Annotated[int, Field(description="Makale ID")]
    view_count: Annotated[int, Field(ge=0, description="Toplam görüntülenme sayısı")]
    clap_count: Annotated[int, Field(ge=0, description="Toplam alkış sayısı")]
