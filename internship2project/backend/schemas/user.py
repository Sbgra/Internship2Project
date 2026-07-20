from pydantic import BaseModel, EmailStr, Field
from typing import Optional


class UserCreate(BaseModel):
    username: str = Field(..., min_length=3, max_length=50)
    email: EmailStr
    password: str = Field(..., min_length=6)


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserPublic(BaseModel):
    id: int
    username: str
    bio: Optional[str] = None
    profile_picture: Optional[str] = None
    profile_color: Optional[str] = None
    emotes: Optional[str] = None
    created_at: str


class UserProfile(BaseModel):
    id: int
    username: str
    email: str
    bio: Optional[str] = None
    profile_picture: Optional[str] = None
    profile_color: Optional[str] = None
    emotes: Optional[str] = None
    created_at: str
    article_count: int = 0


class UserUpdateBio(BaseModel):
    bio: Optional[str] = Field(None, max_length=500)

class UserUpdateProfile(BaseModel):
    profile_picture: Optional[str] = None
    profile_color: Optional[str] = None
    emotes: Optional[str] = None


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserPublic
