from pydantic import BaseModel, Field
from typing import Optional
from schemas.user import UserPublic


class ArticleCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    content: str = Field(..., min_length=1)
    summary: Optional[str] = Field(None, max_length=500)
    is_public: bool = True


class ArticleUpdate(BaseModel):
    title: Optional[str] = Field(None, max_length=200)
    content: Optional[str] = None
    summary: Optional[str] = Field(None, max_length=500)
    is_public: Optional[bool] = None


class ArticleListItem(BaseModel):
    id: int
    title: str
    summary: Optional[str] = None
    is_public: bool
    author_id: int
    author: UserPublic
    created_at: str


class ArticleDetail(ArticleListItem):
    content: str
    updated_at: Optional[str] = None
