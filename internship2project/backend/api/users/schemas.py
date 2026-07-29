from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class UserPublic(BaseModel):
    model_config = {"from_attributes": True}
    
    id: int
    username: str
    bio: Optional[str] = None
    profile_picture: Optional[str] = None
    profile_color: Optional[str] = None
    emotes: Optional[str] = None
    created_at: datetime

class UserProfile(BaseModel):
    model_config = {"from_attributes": True}
    
    id: int
    username: str
    email: str
    bio: Optional[str] = None
    profile_picture: Optional[str] = None
    profile_color: Optional[str] = None
    emotes: Optional[str] = None
    created_at: datetime
    article_count: int = 0

class UserUpdateBio(BaseModel):
    bio: Optional[str] = None

class UserUpdateProfile(BaseModel):
    profile_picture: Optional[str] = None
    profile_color: Optional[str] = None
    emotes: Optional[str] = None
