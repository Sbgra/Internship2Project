"""
auth_service.py — Kullanıcı işlemleri için ham sqlite3 sorguları.
JWT oluşturma/doğrulama ve şifre hash işlemleri de burada.
"""
import sqlite3
from datetime import datetime, timedelta, timezone
from typing import Optional

from jose import JWTError, jwt
from passlib.context import CryptContext

SECRET_KEY = "change-this-in-production-very-secret-key-2024"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24  # 24 saat

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


# ── Şifre ─────────────────────────────────────────────────────────

def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)


# ── JWT ───────────────────────────────────────────────────────────

def create_access_token(data: dict) -> str:
    to_encode = data.copy()
    to_encode["exp"] = datetime.now(timezone.utc) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


def decode_token(token: str) -> Optional[dict]:
    try:
        return jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
    except JWTError:
        return None


# ── Veritabanı sorguları ──────────────────────────────────────────

def create_user(conn: sqlite3.Connection, username: str, email: str, password: str) -> dict:
    hashed = hash_password(password)
    cur = conn.execute(
        "INSERT INTO users (username, email, hashed_password) VALUES (?, ?, ?)",
        (username, email, hashed),
    )
    conn.commit()
    return get_user_by_id(conn, cur.lastrowid)


def get_user_by_id(conn: sqlite3.Connection, user_id: int) -> Optional[dict]:
    row = conn.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
    return dict(row) if row else None


def get_user_by_email(conn: sqlite3.Connection, email: str) -> Optional[dict]:
    row = conn.execute("SELECT * FROM users WHERE email = ?", (email,)).fetchone()
    return dict(row) if row else None


def get_user_by_username(conn: sqlite3.Connection, username: str) -> Optional[dict]:
    row = conn.execute("SELECT * FROM users WHERE username = ?", (username,)).fetchone()
    return dict(row) if row else None


def authenticate_user(conn: sqlite3.Connection, email: str, password: str) -> Optional[dict]:
    user = get_user_by_email(conn, email)
    if not user or not verify_password(password, user["hashed_password"]):
        return None
    return user


def update_bio(conn: sqlite3.Connection, user_id: int, bio: Optional[str]) -> dict:
    conn.execute("UPDATE users SET bio = ? WHERE id = ?", (bio, user_id))
    conn.commit()
    return get_user_by_id(conn, user_id)
