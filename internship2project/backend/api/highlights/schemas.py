from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class HighlightCreate(BaseModel):
    start_index: int
    end_index: int
    text: str

class HighlightResponse(BaseModel):
    model_config = {"from_attributes": True}
    
    id: int
    article_id: int
    user_id: Optional[int] = None
    start_index: int
    end_index: int
    text: str
    created_at: datetime
