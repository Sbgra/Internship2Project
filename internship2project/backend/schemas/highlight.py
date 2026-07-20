from pydantic import BaseModel
from typing import Optional

class HighlightCreate(BaseModel):
    start_index: int
    end_index: int
    text: str

class HighlightResponse(BaseModel):
    id: int
    article_id: int
    user_id: Optional[int] = None
    start_index: int
    end_index: int
    text: str
    created_at: str
