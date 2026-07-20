"""
settings_service.py — Kullanıcı ayarları sorguları.
Uygulama ikonu özelleştirme gibi tercihler burada yönetilir.
"""
import sqlite3
from typing import Optional


def get_user_settings(conn: sqlite3.Connection, user_id: int) -> dict:
    """Kullanıcı ayarlarını döndürür. Kayıt yoksa varsayılan oluşturur."""
    row = conn.execute(
        "SELECT user_id, app_icon FROM user_settings WHERE user_id = ?",
        (user_id,),
    ).fetchone()
    if row:
        return dict(row)

    # Varsayılan kayıt oluştur
    conn.execute(
        "INSERT INTO user_settings (user_id, app_icon) VALUES (?, 'default')",
        (user_id,),
    )
    conn.commit()
    return {"user_id": user_id, "app_icon": "default"}


def update_user_settings(
    conn: sqlite3.Connection, user_id: int, app_icon: Optional[str] = None
) -> dict:
    """Kullanıcı ayarlarını günceller."""
    # Önce kaydın var olduğundan emin ol
    get_user_settings(conn, user_id)

    if app_icon is not None:
        conn.execute(
            "UPDATE user_settings SET app_icon = ? WHERE user_id = ?",
            (app_icon, user_id),
        )
        conn.commit()

    return get_user_settings(conn, user_id)
