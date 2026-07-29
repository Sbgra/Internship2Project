from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from api.users.schemas import UserPublic

class ArticleCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    content: str = Field(..., min_length=1)
    summary: Optional[str] = Field(None, max_length=500)
    cover_image: Optional[str] = None
    is_public: bool = True
    categories: Optional[List[str]] = None
    target_languages: Optional[List[str]] = None

class ArticleUpdate(BaseModel):
    title: Optional[str] = Field(None, max_length=200)
    content: Optional[str] = None
    summary: Optional[str] = Field(None, max_length=500)
    cover_image: Optional[str] = None
    is_public: Optional[bool] = None
    categories: Optional[List[str]] = None

class ArticleListItem(BaseModel):
    model_config = {"from_attributes": True}
    
    id: int
    title: str
    summary: Optional[str] = None
    cover_image: Optional[str] = None
    is_public: bool
    author_id: int
    author: UserPublic
    created_at: datetime

class ArticleDetail(ArticleListItem):
    content: str
    updated_at: Optional[datetime] = None
    available_translations: Optional[List[str]] = None
