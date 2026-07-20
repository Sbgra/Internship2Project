"""
article_service.py — Makale CRUD işlemleri için ham sqlite3 sorguları.
Tüm sorgular JOIN ile yazar bilgisini de getirir.
"""
import sqlite3
import random
from typing import List, Optional


# ── Yardımcı: sqlite3.Row → makale dict'i ─────────────────────────

def _build(row) -> dict:
    """JOIN sonucu gelen satırı router'ların anlayacağı dict yapısına çevirir."""
    d = dict(row)
    return {
        "id":         d["id"],
        "title":      d["title"],
        "content":    d.get("content"),
        "summary":    d.get("summary"),
        "is_public":  bool(d["is_public"]),
        "share_token":d.get("share_token"),
        "author_id":  d["author_id"],
        "created_at": d["created_at"],
        "updated_at": d.get("updated_at"),
        "author": {
            "id":              d["user_id"],
            "username":        d["username"],
            "bio":             d.get("bio"),
            "profile_picture": d.get("profile_picture"),
            "profile_color":   d.get("profile_color"),
            "emotes":          d.get("emotes"),
            "created_at":      d["user_created_at"],
        },
    }


_SELECT = """
    SELECT
        a.id, a.title, a.content, a.summary, a.is_public, a.share_token,
        a.author_id, a.created_at, a.updated_at,
        u.id   AS user_id,
        u.username,
        u.bio,
        u.profile_picture,
        u.profile_color,
        u.emotes,
        u.created_at AS user_created_at
    FROM articles a
    JOIN users u ON u.id = a.author_id
"""


# ── Sorgular ──────────────────────────────────────────────────────

def get_public_articles(conn: sqlite3.Connection, skip: int = 0, limit: int = 20) -> List[dict]:
    rows = conn.execute(
        _SELECT + "WHERE a.is_public = 1 ORDER BY a.created_at DESC LIMIT ? OFFSET ?",
        (limit, skip),
    ).fetchall()
    return [_build(r) for r in rows]


def get_random_feed(conn: sqlite3.Connection, limit: int = 10) -> List[dict]:
    all_public = get_public_articles(conn, limit=1000)
    return random.sample(all_public, min(limit, len(all_public)))


def get_personalized_feed(conn: sqlite3.Connection, user_id: int, limit: int = 10) -> List[dict]:
    # Basit bir kişiselleştirilmiş akış: Rastgele herkese açık makaleler, ama yazarın kendi makaleleri hariç
    sql = _SELECT + "WHERE a.is_public = 1 AND a.author_id != ? ORDER BY RANDOM() LIMIT ?"
    rows = conn.execute(sql, (user_id, limit)).fetchall()
    return [_build(r) for r in rows]


def get_article_by_id(conn: sqlite3.Connection, article_id: int) -> Optional[dict]:
    row = conn.execute(
        _SELECT + "WHERE a.id = ?", (article_id,)
    ).fetchone()
    return _build(row) if row else None


def get_articles_by_author(
    conn: sqlite3.Connection, author_id: int, public_only: bool = False
) -> List[dict]:
    sql = _SELECT + "WHERE a.author_id = ?"
    params: tuple = (author_id,)
    if public_only:
        sql += " AND a.is_public = 1"
    sql += " ORDER BY a.created_at DESC"
    rows = conn.execute(sql, params).fetchall()
    return [_build(r) for r in rows]


def create_article(
    conn: sqlite3.Connection,
    title: str,
    content: str,
    summary: Optional[str],
    is_public: bool,
    author_id: int,
) -> dict:
    cur = conn.execute(
        "INSERT INTO articles (title, content, summary, is_public, author_id) VALUES (?, ?, ?, ?, ?)",
        (title, content, summary, int(is_public), author_id),
    )
    conn.commit()
    return get_article_by_id(conn, cur.lastrowid)


def update_article(
    conn: sqlite3.Connection,
    article_id: int,
    author_id: int,
    data: dict,
) -> Optional[dict]:
    """Yalnızca gönderilen alanları günceller (partial update)."""
    allowed = {"title", "content", "summary", "is_public"}
    fields = {k: v for k, v in data.items() if k in allowed and v is not None}
    if not fields:
        return get_article_by_id(conn, article_id)

    # is_public bool → int dönüşümü
    if "is_public" in fields:
        fields["is_public"] = int(fields["is_public"])

    set_parts = [f"{k} = ?" for k in fields] + ["updated_at = datetime('now')"]
    values = list(fields.values()) + [article_id, author_id]

    cur = conn.execute(
        f"UPDATE articles SET {', '.join(set_parts)} WHERE id = ? AND author_id = ?",
        values,
    )
    conn.commit()
    if cur.rowcount == 0:
        return None
    return get_article_by_id(conn, article_id)


def delete_article(conn: sqlite3.Connection, article_id: int, author_id: int) -> bool:
    cur = conn.execute(
        "DELETE FROM articles WHERE id = ? AND author_id = ?",
        (article_id, author_id),
    )
    conn.commit()
    return cur.rowcount > 0
