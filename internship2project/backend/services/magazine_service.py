"""
magazine_service.py — Dijital dergi CRUD işlemleri.
Sadece üyeler dergi oluşturabilir ve makale ekleyebilir.
"""
import sqlite3
from typing import List, Optional
from services.article_service import get_article_by_id


def create_magazine(
    conn: sqlite3.Connection, title: str, description: Optional[str], owner_id: int
) -> dict:
    """Yeni dijital dergi oluşturur."""
    cur = conn.execute(
        "INSERT INTO magazines (title, description, owner_id) VALUES (?, ?, ?)",
        (title, description, owner_id),
    )
    conn.commit()
    return get_magazine_by_id(conn, cur.lastrowid)


def get_magazine_by_id(conn: sqlite3.Connection, magazine_id: int) -> Optional[dict]:
    """Dergi bilgisini makale sayısıyla birlikte döndürür."""
    row = conn.execute(
        """
        SELECT m.id, m.title, m.description, m.owner_id, m.created_at,
               COUNT(ma.id) AS article_count
        FROM magazines m
        LEFT JOIN magazine_articles ma ON ma.magazine_id = m.id
        WHERE m.id = ?
        GROUP BY m.id
        """,
        (magazine_id,),
    ).fetchone()
    return dict(row) if row else None


def list_user_magazines(conn: sqlite3.Connection, user_id: int) -> List[dict]:
    """Kullanıcının kendi dergilerini listeler."""
    rows = conn.execute(
        """
        SELECT m.id, m.title, m.description, m.owner_id, m.created_at,
               COUNT(ma.id) AS article_count
        FROM magazines m
        LEFT JOIN magazine_articles ma ON ma.magazine_id = m.id
        WHERE m.owner_id = ?
        GROUP BY m.id
        ORDER BY m.created_at DESC
        """,
        (user_id,),
    ).fetchall()
    return [dict(r) for r in rows]


def get_magazine_detail(conn: sqlite3.Connection, magazine_id: int) -> Optional[dict]:
    """Dergi detayını içindeki makaleler ile birlikte döndürür."""
    magazine = get_magazine_by_id(conn, magazine_id)
    if not magazine:
        return None

    # Dergideki makaleleri getir
    rows = conn.execute(
        """
        SELECT a.id, a.title, a.content, a.summary, a.is_public,
               a.author_id, a.created_at, a.updated_at,
               u.id AS user_id, u.username, u.bio,
               u.profile_picture, u.profile_color, u.emotes,
               u.created_at AS user_created_at
        FROM magazine_articles ma
        JOIN articles a ON a.id = ma.article_id
        JOIN users u ON u.id = a.author_id
        WHERE ma.magazine_id = ?
        ORDER BY ma.added_at DESC
        """,
        (magazine_id,),
    ).fetchall()

    articles = []
    for r in rows:
        d = dict(r)
        articles.append({
            "id":         d["id"],
            "title":      d["title"],
            "summary":    d.get("summary"),
            "is_public":  bool(d["is_public"]),
            "author_id":  d["author_id"],
            "created_at": d["created_at"],
            "author": {
                "id":              d["user_id"],
                "username":        d["username"],
                "bio":             d.get("bio"),
                "profile_picture": d.get("profile_picture"),
                "profile_color":   d.get("profile_color"),
                "emotes":          d.get("emotes"),
                "created_at":      d["user_created_at"],
            },
        })

    magazine["articles"] = articles
    return magazine


def add_article_to_magazine(
    conn: sqlite3.Connection, magazine_id: int, article_id: int, owner_id: int
) -> bool:
    """Dergiye makale ekler. Sadece dergi sahibi ekleyebilir."""
    magazine = get_magazine_by_id(conn, magazine_id)
    if not magazine or magazine["owner_id"] != owner_id:
        return False
    try:
        conn.execute(
            "INSERT INTO magazine_articles (magazine_id, article_id) VALUES (?, ?)",
            (magazine_id, article_id),
        )
        conn.commit()
        return True
    except sqlite3.IntegrityError:
        return False


def remove_article_from_magazine(
    conn: sqlite3.Connection, magazine_id: int, article_id: int, owner_id: int
) -> bool:
    """Dergiden makale çıkarır. Sadece dergi sahibi çıkarabilir."""
    magazine = get_magazine_by_id(conn, magazine_id)
    if not magazine or magazine["owner_id"] != owner_id:
        return False
    cur = conn.execute(
        "DELETE FROM magazine_articles WHERE magazine_id = ? AND article_id = ?",
        (magazine_id, article_id),
    )
    conn.commit()
    return cur.rowcount > 0
