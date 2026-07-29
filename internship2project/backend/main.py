"""
main.py — FastAPI uygulama giriş noktası.
SQLite tabloları init_db() ile oluşturulur — SQLAlchemy yok.
"""
import os
from pathlib import Path
from dotenv import load_dotenv

# .env dosyasını main.py'nin bulunduğu dizinden yükle
_env_path = Path(__file__).resolve().parent / ".env"
load_dotenv(dotenv_path=_env_path)

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

import core.events
from core.database import init_db
from api.auth.router import router as auth_router
from api.articles.router import router as articles_router
from api.feed.router import router as feed_router
from api.users.router import router as users_router
from api.stats.router import router as stats_router
from api.claps.router import router as claps_router
from api.communities.router import router as communities_router
from api.magazines.router import router as magazines_router
from api.settings.router import router as settings_router
from api.highlights.router import router as highlights_router
from api.media.router import router as media_router
from api.ai.router import router as ai_router
from api.comments.router import router as comments_router

init_db()

app = FastAPI(
    title="MyAPP API",
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

app.include_router(auth_router)
app.include_router(articles_router)
app.include_router(feed_router)
app.include_router(users_router)
app.include_router(stats_router)
app.include_router(claps_router)
app.include_router(highlights_router)
app.include_router(communities_router)
app.include_router(magazines_router)
app.include_router(settings_router)
app.include_router(media_router)
app.include_router(ai_router)
app.include_router(comments_router)


@app.get("/", tags=["Health"])
def health():
    return {"status": "ok", "message": "MyPlatform API çalışıyor"}
