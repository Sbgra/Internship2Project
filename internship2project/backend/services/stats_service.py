"""
stats_service.py — Makale istatistik sorguları.
Görüntülenme sayacı ve istatistik okuma işlemleri.
"""
import sqlite3
from typing import Optional


def ensure_stats_row(conn: sqlite3.Connection, article_id: int) -> None:
    """article_stats satırı yoksa oluşturur."""
    conn.execute(
        "INSERT OR IGNORE INTO article_stats (article_id, view_count, clap_count) VALUES (?, 0, 0)",
        (article_id,),
    )
    conn.commit()


def record_view(conn: sqlite3.Connection, article_id: int) -> None:
    """Makale görüntülenme sayacını 1 artırır."""
    ensure_stats_row(conn, article_id)
    conn.execute(
        "UPDATE article_stats SET view_count = view_count + 1 WHERE article_id = ?",
        (article_id,),
    )
    conn.commit()


def get_article_stats(conn: sqlite3.Connection, article_id: int) -> Optional[dict]:
    """Makale istatistiklerini döndürür. Satır yoksa oluşturup varsayılan döner."""
    ensure_stats_row(conn, article_id)
    row = conn.execute(
        "SELECT article_id, view_count, clap_count FROM article_stats WHERE article_id = ?",
        (article_id,),
    ).fetchone()
    return dict(row) if row else None
