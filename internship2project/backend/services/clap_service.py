"""
clap_service.py — Alkış (clap) işlemleri.
Herkes alkış atabilir. Makale başına 50 alkış limiti:
  - Üyeler: user_id ile takip edilir
  - Misafirler: IP adresi ile takip edilir
"""
import sqlite3
from typing import Optional

CLAP_LIMIT_PER_ARTICLE = 50


def get_user_claps(conn: sqlite3.Connection, article_id: int, user_id: int) -> int:
    """Üye kullanıcının bu makaleye attığı toplam alkış sayısını döndürür."""
    row = conn.execute(
        "SELECT COALESCE(SUM(count), 0) AS total FROM claps WHERE article_id = ? AND user_id = ?",
        (article_id, user_id),
    ).fetchone()
    return row["total"] if row else 0


def get_ip_claps(conn: sqlite3.Connection, article_id: int, ip: str) -> int:
    """Misafir IP'nin bu makaleye attığı toplam alkış sayısını döndürür."""
    row = conn.execute(
        "SELECT COALESCE(SUM(count), 0) AS total FROM claps WHERE article_id = ? AND ip_address = ? AND user_id IS NULL",
        (article_id, ip),
    ).fetchone()
    return row["total"] if row else 0


def get_total_claps(conn: sqlite3.Connection, article_id: int) -> int:
    """Makalenin toplam alkış sayısını döndürür."""
    row = conn.execute(
        "SELECT COALESCE(SUM(count), 0) AS total FROM claps WHERE article_id = ?",
        (article_id,),
    ).fetchone()
    return row["total"] if row else 0


def add_clap(
    conn: sqlite3.Connection,
    article_id: int,
    count: int,
    user_id: Optional[int] = None,
    ip: Optional[str] = None,
) -> dict:
    """
    Alkış ekler. Hem üye hem misafir için makale başına 50 limit uygulanır.
    Dönüş: {article_id, total_claps, user_claps, remaining_claps}
    """
    # Mevcut alkış sayısını hesapla
    if user_id:
        current_claps = get_user_claps(conn, article_id, user_id)
    else:
        current_claps = get_ip_claps(conn, article_id, ip)

    remaining = CLAP_LIMIT_PER_ARTICLE - current_claps
    if remaining <= 0:
        total = get_total_claps(conn, article_id)
        return {
            "article_id": article_id,
            "total_claps": total,
            "user_claps": current_claps,
            "remaining_claps": 0,
        }

    # Limit aşımını engelle
    actual_count = min(count, remaining)

    # Alkış kaydı ekle
    conn.execute(
        "INSERT INTO claps (article_id, user_id, ip_address, count) VALUES (?, ?, ?, ?)",
        (article_id, user_id, ip, actual_count),
    )

    # article_stats güncelle
    conn.execute(
        "INSERT INTO article_stats (article_id, view_count, clap_count) VALUES (?, 0, ?) "
        "ON CONFLICT(article_id) DO UPDATE SET clap_count = clap_count + ?",
        (article_id, actual_count, actual_count),
    )
    conn.commit()

    new_user_claps = current_claps + actual_count
    total = get_total_claps(conn, article_id)

    return {
        "article_id": article_id,
        "total_claps": total,
        "user_claps": new_user_claps,
        "remaining_claps": CLAP_LIMIT_PER_ARTICLE - new_user_claps,
    }
