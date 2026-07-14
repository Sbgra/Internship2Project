"""
main.py — FastAPI uygulama giriş noktası.
SQLite tabloları init_db() ile oluşturulur — SQLAlchemy yok.
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from database import init_db
from routers import auth, articles, feed, users

# Uygulama başlarken tabloları oluştur
init_db()

app = FastAPI(
    title="Inkwell API",
    description="Makale platformu — sqlite3 + FastAPI",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(articles.router)
app.include_router(feed.router)
app.include_router(users.router)


@app.get("/", tags=["Health"])
def health():
    return {"status": "ok", "message": "Inkwell API çalışıyor"}
