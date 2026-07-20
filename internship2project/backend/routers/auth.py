import sqlite3

from fastapi import APIRouter, Depends, HTTPException, status

from database import get_db
from schemas.user import UserCreate, UserLogin, TokenResponse, UserPublic
from services.auth_service import (
    create_user, authenticate_user, create_access_token,
    get_user_by_email, get_user_by_username,
)

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
def register(data: UserCreate, conn: sqlite3.Connection = Depends(get_db)):
    if get_user_by_email(conn, data.email) or get_user_by_username(conn, data.username):
        raise HTTPException(status_code=400, detail="Bu e-posta veya kullanıcı adı zaten kullanımda")
    try:
        user = create_user(conn, data.username, data.email, data.password)
    except sqlite3.IntegrityError:
        raise HTTPException(status_code=400, detail="Bu e-posta veya kullanıcı adı zaten kullanımda")
    token = create_access_token({"sub": str(user["id"])})
    return TokenResponse(access_token=token, user=UserPublic(**user))


@router.post("/login", response_model=TokenResponse)
def login(data: UserLogin, conn: sqlite3.Connection = Depends(get_db)):
    user = authenticate_user(conn, data.email, data.password)
    if not user:
        raise HTTPException(status_code=401, detail="Hatalı e-posta veya şifre")
    token = create_access_token({"sub": str(user["id"])})
    return TokenResponse(access_token=token, user=UserPublic(**user))
