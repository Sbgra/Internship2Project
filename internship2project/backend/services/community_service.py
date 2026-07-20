"""
community_service.py — Topluluk CRUD işlemleri.
Sadece üyeler topluluk oluşturabilir ve katılabilir.
"""
import sqlite3
from typing import List, Optional


def create_community(
    conn: sqlite3.Connection, name: str, description: Optional[str], creator_id: int
) -> dict:
    """Yeni topluluk oluşturur ve kurucuyu otomatik üye yapar."""
    cur = conn.execute(
        "INSERT INTO communities (name, description, created_by) VALUES (?, ?, ?)",
        (name, description, creator_id),
    )
    community_id = cur.lastrowid
    # Kurucuyu otomatik üye yap
    conn.execute(
        "INSERT INTO community_members (community_id, user_id) VALUES (?, ?)",
        (community_id, creator_id),
    )
    conn.commit()
    return get_community_detail(conn, community_id, creator_id)


def list_communities(
    conn: sqlite3.Connection, skip: int = 0, limit: int = 20
) -> List[dict]:
    """Tüm toplulukları listeler, üye sayısı ile birlikte."""
    rows = conn.execute(
        """
        SELECT c.id, c.name, c.description, c.created_at,
               COUNT(cm.id) AS member_count
        FROM communities c
        LEFT JOIN community_members cm ON cm.community_id = c.id
        GROUP BY c.id
        ORDER BY c.created_at DESC
        LIMIT ? OFFSET ?
        """,
        (limit, skip),
    ).fetchall()
    return [dict(r) for r in rows]


def get_community_detail(
    conn: sqlite3.Connection, community_id: int, user_id: Optional[int] = None
) -> Optional[dict]:
    """Topluluk detayını döndürür. user_id verilirse is_member hesaplanır."""
    row = conn.execute(
        """
        SELECT c.id, c.name, c.description, c.created_by, c.created_at,
               COUNT(cm.id) AS member_count
        FROM communities c
        LEFT JOIN community_members cm ON cm.community_id = c.id
        WHERE c.id = ?
        GROUP BY c.id
        """,
        (community_id,),
    ).fetchone()
    if not row:
        return None

    result = dict(row)
    # Üyelik durumu kontrolü
    if user_id:
        member_row = conn.execute(
            "SELECT 1 FROM community_members WHERE community_id = ? AND user_id = ?",
            (community_id, user_id),
        ).fetchone()
        result["is_member"] = member_row is not None
    else:
        result["is_member"] = False

    return result


def join_community(conn: sqlite3.Connection, community_id: int, user_id: int) -> bool:
    """Kullanıcıyı topluluğa ekler. Zaten üyeyse False döner."""
    try:
        conn.execute(
            "INSERT INTO community_members (community_id, user_id) VALUES (?, ?)",
            (community_id, user_id),
        )
        conn.commit()
        return True
    except sqlite3.IntegrityError:
        return False


def leave_community(conn: sqlite3.Connection, community_id: int, user_id: int) -> bool:
    """Kullanıcıyı topluluktan çıkarır. Üye değilse False döner."""
    cur = conn.execute(
        "DELETE FROM community_members WHERE community_id = ? AND user_id = ?",
        (community_id, user_id),
    )
    conn.commit()
    return cur.rowcount > 0
