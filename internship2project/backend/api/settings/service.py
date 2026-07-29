"""
settings_service.py — Kullanıcı ayarları sorguları.
Uygulama ikonu özelleştirme gibi tercihler burada yönetilir.
"""
from typing import Optional
from sqlmodel import Session
from core.models import UserSettings

def get_user_settings(session: Session, user_id: int) -> dict:
    """Kullanıcı ayarlarını döndürür. Kayıt yoksa varsayılan oluşturur."""
    settings = session.get(UserSettings, user_id)
    if settings:
        return settings.model_dump()

    # Varsayılan kayıt oluştur
    settings = UserSettings(user_id=user_id, app_icon='default')
    session.add(settings)
    session.commit()
    session.refresh(settings)
    return settings.model_dump()

def update_user_settings(
    session: Session, user_id: int, app_icon: Optional[str] = None
) -> dict:
    """Kullanıcı ayarlarını günceller."""
    settings = session.get(UserSettings, user_id)
    if not settings:
        settings = UserSettings(user_id=user_id, app_icon='default')

    if app_icon is not None:
        settings.app_icon = app_icon
        
    session.add(settings)
    session.commit()
    session.refresh(settings)

    return settings.model_dump()
