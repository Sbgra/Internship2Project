"""
settings.py — Kullanıcı ayarları şemaları.
Uygulama ikonu özelleştirme gibi kişisel tercihler burada tanımlanır.
"""
from typing import Annotated, Optional
from pydantic import BaseModel, Field


VALID_APP_ICONS = ["default", "dark", "ocean", "sunset", "minimal"]


class UserSettingsUpdate(BaseModel):
    """Kullanıcı ayarları güncelleme isteği."""
    app_icon: Annotated[
        Optional[str],
        Field(None, description="İkon adı: default, dark, ocean, sunset, minimal")
    ]


class UserSettingsResponse(BaseModel):
    """Kullanıcı ayarları yanıtı."""
    user_id: Annotated[int, Field(description="Kullanıcı ID")]
    app_icon: Annotated[str, Field(description="Seçili uygulama ikonu adı")]
