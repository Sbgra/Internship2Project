"""
dependencies.py — FastAPI dependency injection.
SQLAlchemy Session yerine sqlite3.Connection kullanılıyor.
"""
from sqlmodel import Session
from core.models import User
from typing import Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer

from core.database import get_db
from api.auth.service import decode_token, get_user_by_id

_oauth2_required = OAuth2PasswordBearer(tokenUrl="/auth/login")
_oauth2_optional = OAuth2PasswordBearer(tokenUrl="/auth/login", auto_error=False)


def get_current_user(
    token: str = Depends(_oauth2_required),
    session: Session = Depends(get_db),
) -> User:
    """Token zorunlu endpoint'ler için — geçersiz token'da 401 döner."""
    payload = decode_token(token)
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Geçersiz veya süresi dolmuş token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    user = get_user_by_id(session, int(payload["sub"]))
    if not user:
        raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı")
    return user


def get_optional_user(
    token: Optional[str] = Depends(_oauth2_optional),
    session: Session = Depends(get_db),
) -> Optional[User]:
    """Token opsiyonel — token yoksa None döner (public + auth mixed)."""
    if not token:
        return None
    payload = decode_token(token)
    if not payload:
        return None
    return get_user_by_id(session, int(payload["sub"]))
