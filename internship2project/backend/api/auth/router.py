from sqlmodel import Session
from sqlalchemy.exc import IntegrityError

from fastapi import APIRouter, Depends, HTTPException, status

from core.database import get_db
from api.auth.schemas import UserCreate, UserLogin, TokenResponse
from api.users.schemas import UserPublic
from api.auth.service import (
    create_user, authenticate_user, create_access_token,
    get_user_by_email, get_user_by_username,
)

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
def register(data: UserCreate, session: Session = Depends(get_db)):
    if get_user_by_email(session, data.email) or get_user_by_username(session, data.username):
        raise HTTPException(status_code=400, detail="Bu e-posta veya kullanıcı adı zaten kullanımda")
    try:
        user = create_user(session, data.username, data.email, data.password)
    except IntegrityError:
        session.rollback()
        raise HTTPException(status_code=400, detail="Bu e-posta veya kullanıcı adı zaten kullanımda")
    token = create_access_token({"sub": str(user.id)})
    return TokenResponse(access_token=token, user=UserPublic.model_validate(user))


@router.post("/login", response_model=TokenResponse)
def login(data: UserLogin, session: Session = Depends(get_db)):
    user = authenticate_user(session, data.email, data.password)
    if not user:
        raise HTTPException(status_code=401, detail="Hatalı e-posta veya şifre")
    token = create_access_token({"sub": str(user.id)})
    return TokenResponse(access_token=token, user=UserPublic.model_validate(user))
