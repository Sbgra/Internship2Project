"""
database.py — Yerleşik sqlite3 modülüyle SQLite bağlantısı.
Tablo oluşturma ve FastAPI dependency burada tanımlanır.
"""
import sqlite3
from sqlmodel import SQLModel, create_engine, Session
from sqlalchemy import event
from sqlalchemy.engine import Engine
import core.models  # Modellerin belleğe yüklenmesi için gerekli

DATABASE_URL = "sqlite:///./data/articles.db"

engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})

@event.listens_for(Engine, "connect")
def set_sqlite_pragma(dbapi_connection, connection_record):
    cursor = dbapi_connection.cursor()
    cursor.execute("PRAGMA foreign_keys=ON")
    cursor.close()

def get_db():
    """FastAPI dependency: SQLModel Session döndürür."""
    with Session(engine) as session:
        yield session

def init_db() -> None:
    """Uygulama başladığında tabloları oluşturur."""
    SQLModel.metadata.create_all(engine)
    try:
        with engine.connect() as conn:
            from sqlalchemy import text
            conn.execute(text("ALTER TABLE magazines ADD COLUMN image TEXT;"))
            conn.commit()
    except Exception:
        pass
        
    # Sabit kategorileri ekle
    from core.models import Category
    from sqlmodel import select
    
    fixed_categories = [
        "Teknoloji", "Bilim", "Sağlık", "Sanat", "Spor",
        "Tarih", "Seyahat", "Yemek", "Müzik", "Eğitim",
        "Yaşam Tarzı", "İş ve Ekonomi", "Eğlence", "Oyun", "Moda"
    ]
    
    with Session(engine) as session:
        for cat_name in fixed_categories:
            existing = session.exec(select(Category).where(Category.name == cat_name)).first()
            if not existing:
                session.add(Category(name=cat_name))
        session.commit()
