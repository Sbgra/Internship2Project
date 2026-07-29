"""
service.py — Kullanıcı işlemleri ve JWT yönetimi.
"""
from sqlmodel import Session, select
from core.models import User
from datetime import datetime, timedelta, timezone
from typing import Optional

from passlib.context import CryptContext
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
from jose import JWTError, jwt

SECRET_KEY = "change-this-in-production-very-secret-key-2024"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24  # 24 saat

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain: str, hashed: str) -> bool:
    try:
        return pwd_context.verify(plain, hashed)
    except Exception:
        return False

def create_access_token(data: dict) -> str:
    to_encode = data.copy()
    to_encode["exp"] = datetime.now(timezone.utc) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

def decode_token(token: str) -> Optional[dict]:
    try:
        return jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
    except JWTError:
        return None

def create_user(session: Session, username: str, email: str, password: str) -> User:
    hashed = hash_password(password)
    user = User(username=username, email=email, hashed_password=hashed)
    session.add(user)
    session.commit()
    session.refresh(user)
    return user

def get_user_by_id(session: Session, user_id: int) -> Optional[User]:
    return session.get(User, user_id)

def get_user_by_email(session: Session, email: str) -> Optional[User]:
    return session.exec(select(User).where(User.email == email)).first()

def get_user_by_username(session: Session, username: str) -> Optional[User]:
    return session.exec(select(User).where(User.username == username)).first()

def authenticate_user(session: Session, email: str, password: str) -> Optional[User]:
    user = get_user_by_email(session, email)
    if not user or not verify_password(password, user.hashed_password):
        return None
    return user

def update_bio(session: Session, user_id: int, bio: Optional[str]) -> User:
    user = get_user_by_id(session, user_id)
    if user:
        user.bio = bio
        session.add(user)
        session.commit()
        session.refresh(user)
    return user

def update_profile(session: Session, user_id: int, data: dict) -> User:
    user = get_user_by_id(session, user_id)
    if user:
        if "profile_picture" in data:
            user.profile_picture = data["profile_picture"]
        if "profile_color" in data:
            user.profile_color = data["profile_color"]
        if "emotes" in data:
            user.emotes = data["emotes"]
        session.add(user)
        session.commit()
        session.refresh(user)
    return user
