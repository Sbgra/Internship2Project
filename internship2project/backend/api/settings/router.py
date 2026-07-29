"""
settings.py — Kullanıcı ayarları endpoint'leri.
Uygulama ikonu özelleştirme gibi tercihler sadece üyeler tarafından yönetilebilir.
"""
from sqlmodel import Session

from fastapi import APIRouter, Depends, HTTPException

from core.database import get_db
from core.dependencies import get_current_user
from api.settings.schemas import UserSettingsUpdate, UserSettingsResponse, VALID_APP_ICONS
from api.settings import service as settings_service

router = APIRouter(prefix="/settings", tags=["Settings"])

@router.get(
    "/me",
    response_model=UserSettingsResponse,
    summary="Ayarlarımı getir",
    description="Sadece üyeler — giriş yapan kullanıcının ayarlarını döndürür.",
)
def get_my_settings(
    current_user = Depends(get_current_user),
    session: Session = Depends(get_db),
):
    """Kullanıcının ayarlarını döndürür."""
    return settings_service.get_user_settings(session, current_user.id)

@router.patch(
    "/me",
    response_model=UserSettingsResponse,
    summary="Ayarlarımı güncelle",
    description="Sadece üyeler — uygulama ikonu gibi tercihleri günceller. "
                "Geçerli ikonlar: default, dark, ocean, sunset, minimal.",
)
def update_my_settings(
    data: UserSettingsUpdate,
    current_user = Depends(get_current_user),
    session: Session = Depends(get_db),
):
    """Kullanıcının ayarlarını günceller."""
    if data.app_icon and data.app_icon not in VALID_APP_ICONS:
        raise HTTPException(
            status_code=400,
            detail=f"Geçersiz ikon. Geçerli seçenekler: {', '.join(VALID_APP_ICONS)}",
        )
    return settings_service.update_user_settings(
        session, current_user.id, app_icon=data.app_icon
    )
