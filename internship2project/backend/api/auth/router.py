from sqlmodel import Session
from sqlalchemy.exc import IntegrityError

from fastapi import APIRouter, Depends, HTTPException, status, Header
from sqlmodel import select

from core.database import get_db
from api.auth.schemas import UserCreate, UserLogin, TokenResponse
from api.users.schemas import UserPublic
from core.models import User, ChatMessage
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

@router.delete("/test-cleanup")
def cleanup_test_data(secret_key: str = Header(...), session: Session = Depends(get_db)):
    if secret_key != "MySuperSecretTestKey":
        raise HTTPException(status_code=403, detail="Erişim engellendi: Geçersiz secret key.")
        
    try:
        # Sadece adı test_bot_ ile başlayan mesajları sil
        messages_deleted = session.query(ChatMessage).filter(
            (ChatMessage.sender_id.like("test_bot_%")) | 
            (ChatMessage.receiver_id.like("test_bot_%"))
        ).delete(synchronize_session=False)
        
        # test_bot_ ile başlayan kullanıcıları sil
        users_deleted = session.query(User).filter(
            User.username.like("test_bot_%")
        ).delete(synchronize_session=False)
        
        session.commit()
        return {
            "status": "success", 
            "detail": f"{messages_deleted} mesaj ve {users_deleted} kullanıcı silindi."
        }
    except Exception as e:
        session.rollback()
        raise HTTPException(status_code=500, detail=f"Silme sırasında hata oluştu: {str(e)}")
