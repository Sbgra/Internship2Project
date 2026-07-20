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

        -- Alkış kayıtları: üyeler user_id, misafirler ip ile takip
        CREATE TABLE IF NOT EXISTS claps (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            article_id  INTEGER NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
            user_id     INTEGER REFERENCES users(id) ON DELETE CASCADE,
            ip_address  TEXT,
            count       INTEGER NOT NULL DEFAULT 1,
            created_at  TEXT    DEFAULT (datetime('now'))
        );

        -- Makale istatistikleri
        CREATE TABLE IF NOT EXISTS article_stats (
            article_id  INTEGER PRIMARY KEY REFERENCES articles(id) ON DELETE CASCADE,
            view_count  INTEGER NOT NULL DEFAULT 0,
            clap_count  INTEGER NOT NULL DEFAULT 0
        );

        -- Topluluklar
        CREATE TABLE IF NOT EXISTS communities (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            name        TEXT    NOT NULL,
            description TEXT,
            created_by  INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            created_at  TEXT    DEFAULT (datetime('now'))
        );

        -- Topluluk üyelikleri
        CREATE TABLE IF NOT EXISTS community_members (
            id            INTEGER PRIMARY KEY AUTOINCREMENT,
            community_id  INTEGER NOT NULL REFERENCES communities(id) ON DELETE CASCADE,
            user_id       INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            joined_at     TEXT    DEFAULT (datetime('now')),
            UNIQUE(community_id, user_id)
        );

        -- Kullanıcı ayarları (uygulama ikonu vb.)
        CREATE TABLE IF NOT EXISTS user_settings (
            user_id   INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
            app_icon  TEXT    NOT NULL DEFAULT 'default'
        );

        -- Dijital dergiler
        CREATE TABLE IF NOT EXISTS magazines (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            title       TEXT    NOT NULL,
            description TEXT,
            owner_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            created_at  TEXT    DEFAULT (datetime('now'))
        );

        -- Dergi-makale ilişkisi
        CREATE TABLE IF NOT EXISTS magazine_articles (
            id           INTEGER PRIMARY KEY AUTOINCREMENT,
            magazine_id  INTEGER NOT NULL REFERENCES magazines(id) ON DELETE CASCADE,
            article_id   INTEGER NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
            added_at     TEXT    DEFAULT (datetime('now')),
            UNIQUE(magazine_id, article_id)
        );

        -- Çevrimdışı kayıtlı makaleler
        CREATE TABLE IF NOT EXISTS saved_articles (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id     INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            article_id  INTEGER NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
            saved_at    TEXT    DEFAULT (datetime('now')),
            UNIQUE(user_id, article_id)
        );

        -- Cümle altı çizmeleri (Highlights)
        CREATE TABLE IF NOT EXISTS highlights (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            article_id  INTEGER NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
            user_id     INTEGER REFERENCES users(id) ON DELETE CASCADE,
            ip_address  TEXT,
            start_index INTEGER NOT NULL,
            end_index   INTEGER NOT NULL,
            text        TEXT NOT NULL,
            created_at  TEXT    DEFAULT (datetime('now'))
        );
    """)

    # Geriye dönük uyumluluk: Tablolar varsa yeni kolonları ekle
    try:
        conn.execute("ALTER TABLE articles ADD COLUMN share_token TEXT;")
    except sqlite3.OperationalError:
        pass  # Kolon zaten varsa hata verir, yoksay

    try:
        conn.execute("CREATE UNIQUE INDEX IF NOT EXISTS idx_articles_share_token ON articles(share_token);")
    except sqlite3.OperationalError:
        pass

    try:
        conn.execute("ALTER TABLE users ADD COLUMN profile_picture TEXT;")
    except sqlite3.OperationalError:
        pass

    try:
        conn.execute("ALTER TABLE users ADD COLUMN profile_color TEXT;")
    except sqlite3.OperationalError:
        pass

    try:
        conn.execute("ALTER TABLE users ADD COLUMN emotes TEXT;")
    except sqlite3.OperationalError:
        pass

    conn.commit()
    conn.close()
