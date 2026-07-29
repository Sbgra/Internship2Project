from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select
from typing import List
from pydantic import BaseModel

from core.database import get_db
from core.dependencies import get_current_user
from core.models import User, ArticleComment, MagazineComment, Article, Magazine

router = APIRouter(prefix="/comments", tags=["Comments"])

class CommentCreate(BaseModel):
    content: str

class CommentResponse(BaseModel):
    id: int
    content: str
    created_at: str
    user_id: int
    username: str
    profile_picture: str | None = None

@router.post("/articles/{article_id}", response_model=CommentResponse)
def add_article_comment(article_id: int, request: CommentCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    article = db.get(Article, article_id)
    if not article:
        raise HTTPException(status_code=404, detail="Makale bulunamadı")
        
    comment = ArticleComment(
        article_id=article_id,
        user_id=current_user.id,
        content=request.content
    )
    db.add(comment)
    db.commit()
    db.refresh(comment)
    
    return {
        "id": comment.id,
        "content": comment.content,
        "created_at": comment.created_at.isoformat(),
        "user_id": current_user.id,
        "username": current_user.username,
        "profile_picture": current_user.profile_picture
    }

@router.get("/articles/{article_id}", response_model=List[CommentResponse])
def get_article_comments(article_id: int, db: Session = Depends(get_db)):
    comments = db.exec(
        select(ArticleComment).where(ArticleComment.article_id == article_id).order_by(ArticleComment.created_at.desc())
    ).all()
    
    res = []
    for c in comments:
        res.append({
            "id": c.id,
            "content": c.content,
            "created_at": c.created_at.isoformat(),
            "user_id": c.user.id,
            "username": c.user.username,
            "profile_picture": c.user.profile_picture
        })
    return res

@router.post("/magazines/{magazine_id}", response_model=CommentResponse)
def add_magazine_comment(magazine_id: int, request: CommentCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    magazine = db.get(Magazine, magazine_id)
    if not magazine:
        raise HTTPException(status_code=404, detail="Dergi bulunamadı")
        
    comment = MagazineComment(
        magazine_id=magazine_id,
        user_id=current_user.id,
        content=request.content
    )
    db.add(comment)
    db.commit()
    db.refresh(comment)
    
    return {
        "id": comment.id,
        "content": comment.content,
        "created_at": comment.created_at.isoformat(),
        "user_id": current_user.id,
        "username": current_user.username,
        "profile_picture": current_user.profile_picture
    }

@router.get("/magazines/{magazine_id}", response_model=List[CommentResponse])
def get_magazine_comments(magazine_id: int, db: Session = Depends(get_db)):
    comments = db.exec(
        select(MagazineComment).where(MagazineComment.magazine_id == magazine_id).order_by(MagazineComment.created_at.desc())
    ).all()
    
    res = []
    for c in comments:
        res.append({
            "id": c.id,
            "content": c.content,
            "created_at": c.created_at.isoformat(),
            "user_id": c.user.id,
            "username": c.user.username,
            "profile_picture": c.user.profile_picture
        })
    return res
