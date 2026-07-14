"""
database.py — Yerleşik sqlite3 modülüyle SQLite bağlantısı.
Tablo oluşturma ve FastAPI dependency burada tanımlanır.
"""
import sqlite3

DATABASE_PATH = "./articles.db"


def get_connection() -> sqlite3.Connection:
    conn = sqlite3.connect(DATABASE_PATH)
    conn.row_factory = sqlite3.Row   # sütun adıyla erişim: row["id"]
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


def get_db():
    """FastAPI dependency: istek boyunca tek bir bağlantı kullanılır."""
    conn = get_connection()
    try:
        yield conn
    finally:
        conn.close()


def init_db() -> None:
    """Uygulama başladığında tabloları oluşturur (yoksa)."""
    conn = get_connection()
    conn.executescript("""
        CREATE TABLE IF NOT EXISTS users (
            id               INTEGER PRIMARY KEY AUTOINCREMENT,
            username         TEXT    UNIQUE NOT NULL,
            email            TEXT    UNIQUE NOT NULL,
            hashed_password  TEXT    NOT NULL,
            bio              TEXT,
            created_at       TEXT    DEFAULT (datetime('now'))
        );

        CREATE TABLE IF NOT EXISTS articles (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            title       TEXT    NOT NULL,
            content     TEXT    NOT NULL,
            summary     TEXT,
            is_public   INTEGER NOT NULL DEFAULT 1,
            author_id   INTEGER NOT NULL
                            REFERENCES users(id) ON DELETE CASCADE,
            created_at  TEXT    DEFAULT (datetime('now')),
            updated_at  TEXT
        );
    """)
    conn.commit()
    conn.close()
