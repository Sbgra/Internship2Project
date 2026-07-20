"""
clap.py — Alkış (clap) şemaları.
Herkes alkış atabilir: misafirler IP ile, üyeler user_id ile takip edilir.
Makale başına 50 alkış limiti herkes için geçerlidir.
"""
from typing import Annotated
from pydantic import BaseModel, Field


class ClapRequest(BaseModel):
    """Alkış gönderme isteği."""
    count: Annotated[int, Field(ge=1, le=50, description="Tek seferde gönderilecek alkış sayısı (1-50)")]


class ClapResponse(BaseModel):
    """Alkış sonucu — frontend bu modele göre UI günceller."""
    article_id: Annotated[int, Field(description="Alkış atılan makale ID")]
    total_claps: Annotated[int, Field(ge=0, description="Makalenin toplam alkış sayısı")]
    user_claps: Annotated[int, Field(ge=0, description="Bu kullanıcı/IP'nin bu makaleye attığı toplam alkış")]
    remaining_claps: Annotated[int, Field(ge=0, description="Kalan alkış hakkı (makale başına 50)")]
