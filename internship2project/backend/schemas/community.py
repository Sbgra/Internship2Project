"""
community.py — Topluluk şemaları.
Sadece üyeler topluluk oluşturabilir ve katılabilir.
"""
from typing import Annotated, Optional
from pydantic import BaseModel, Field


class CommunityCreate(BaseModel):
    """Topluluk oluşturma isteği — sadece üyeler."""
    name: Annotated[str, Field(min_length=2, max_length=100, description="Topluluk adı")]
    description: Annotated[Optional[str], Field(None, max_length=500, description="Topluluk açıklaması")]


class CommunityListItem(BaseModel):
    """Topluluk listesi öğesi — herkes görebilir."""
    id: Annotated[int, Field(description="Topluluk ID")]
    name: Annotated[str, Field(description="Topluluk adı")]
    description: Annotated[Optional[str], Field(description="Topluluk açıklaması")]
    member_count: Annotated[int, Field(ge=0, description="Üye sayısı")]
    created_at: Annotated[str, Field(description="Oluşturulma tarihi")]


class CommunityResponse(BaseModel):
    """Topluluk detayı — is_member alanı isteği yapanın üyelik durumunu belirtir."""
    id: Annotated[int, Field(description="Topluluk ID")]
    name: Annotated[str, Field(description="Topluluk adı")]
    description: Annotated[Optional[str], Field(description="Topluluk açıklaması")]
    member_count: Annotated[int, Field(ge=0, description="Üye sayısı")]
    created_by: Annotated[int, Field(description="Kurucu kullanıcı ID")]
    created_at: Annotated[str, Field(description="Oluşturulma tarihi")]
    is_member: Annotated[bool, Field(description="İsteği yapan kullanıcı üye mi")]
