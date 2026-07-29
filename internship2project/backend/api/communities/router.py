"""
communities.py — Topluluk endpoint'leri.
Listeleme herkese açık, oluşturma/katılma/ayrılma sadece üyelere.
"""
from typing import List, Optional
from sqlmodel import Session

from fastapi import APIRouter, Depends, HTTPException, status

from core.database import get_db
from core.dependencies import get_current_user, get_optional_user
from api.communities.schemas import CommunityCreate, CommunityListItem, CommunityResponse
from api.communities import service as community_service

router = APIRouter(prefix="/communities", tags=["Communities"])

@router.get(
    "",
    response_model=List[CommunityListItem],
    summary="Toplulukları listele",
    description="Herkes erişebilir — tüm toplulukları üye sayıları ile listeler.",
)
def list_communities(
    skip: int = 0,
    limit: int = 20,
    session: Session = Depends(get_db),
):
    """Tüm toplulukları listeler."""
    return community_service.list_communities(session, skip, limit)

@router.post(
    "",
    response_model=CommunityResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Topluluk oluştur",
    description="Sadece üyeler — yeni topluluk oluşturur ve kurucuyu otomatik üye yapar.",
)
def create_community(
    data: CommunityCreate,
    current_user = Depends(get_current_user),
    session: Session = Depends(get_db),
):
    """Yeni topluluk oluşturur."""
    return community_service.create_community(
        session, data.name, data.description, data.image, current_user.id
    )

@router.get(
    "/{community_id}",
    response_model=CommunityResponse,
    summary="Topluluk detayı",
    description="Herkes erişebilir — topluluk bilgilerini ve üyelik durumunu döndürür.",
)
def get_community(
    *,
    session: Session = Depends(get_db),
    current_user = Depends(get_optional_user),
    community_id: int,
):
    """Topluluk detayını döndürür."""
    user_id = current_user.id if current_user else None
    community = community_service.get_community_detail(session, community_id, user_id)
    if not community:
        raise HTTPException(status_code=404, detail="Topluluk bulunamadı")
    return community

@router.post(
    "/{community_id}/join",
    summary="Topluluğa katıl",
    description="Sadece üyeler — topluluğa katılır.",
)
def join_community(
    community_id: int,
    current_user = Depends(get_current_user),
    session: Session = Depends(get_db),
):
    """Kullanıcıyı topluluğa ekler."""
    community = community_service.get_community_detail(session, community_id)
    if not community:
        raise HTTPException(status_code=404, detail="Topluluk bulunamadı")
    if not community_service.join_community(session, community_id, current_user.id):
        raise HTTPException(status_code=400, detail="Zaten bu topluluğun üyesisiniz")
    return {"status": "ok", "message": "Topluluğa katıldınız"}

@router.delete(
    "/{community_id}/leave",
    summary="Topluluktan ayrıl",
    description="Sadece üyeler — topluluktan ayrılır.",
)
def leave_community(
    community_id: int,
    current_user = Depends(get_current_user),
    session: Session = Depends(get_db),
):
    """Kullanıcıyı topluluktan çıkarır."""
    if not community_service.leave_community(session, community_id, current_user.id):
        raise HTTPException(status_code=400, detail="Bu topluluğun üyesi değilsiniz")
    return {"status": "ok", "message": "Topluluktan ayrıldınız"}

from pydantic import BaseModel
class TopicCreate(BaseModel):
    title: str
    content: str

class PostCreate(BaseModel):
    content: str
    parent_id: Optional[int] = None

@router.post("/{community_id}/forum")
def create_topic(
    community_id: int,
    data: TopicCreate,
    current_user = Depends(get_current_user),
    session: Session = Depends(get_db)
):
    from core.models import CommunityForumTopic
    from api.articles.service import sanitize_html
    
    topic = CommunityForumTopic(
        community_id=community_id,
        author_id=current_user.id,
        title=data.title,
        content=sanitize_html(data.content)
    )
    session.add(topic)
    session.commit()
    return {"status": "ok", "message": "Topic created", "topic_id": topic.id}

@router.get("/{community_id}/forum")
def get_topics(
    community_id: int,
    session: Session = Depends(get_db)
):
    from core.models import CommunityForumTopic
    from sqlmodel import select
    from sqlalchemy.orm import joinedload
    
    statement = (
        select(CommunityForumTopic)
        .where(CommunityForumTopic.community_id == community_id)
        .options(joinedload(CommunityForumTopic.author))
        .order_by(CommunityForumTopic.created_at.desc())
    )
    topics = session.exec(statement).all()
    result = []
    for t in topics:
        result.append({
            "id": t.id,
            "title": t.title,
            "created_at": t.created_at,
            "author": {
                "id": t.author.id,
                "username": t.author.username,
                "profile_picture": t.author.profile_picture
            }
        })
    return result

@router.post("/forum/{topic_id}/posts")
def create_post(
    topic_id: int,
    data: PostCreate,
    current_user = Depends(get_current_user),
    session: Session = Depends(get_db)
):
    from core.models import CommunityForumPost, CommunityForumTopic
    from api.articles.service import sanitize_html
    
    topic = session.get(CommunityForumTopic, topic_id)
    if not topic:
        raise HTTPException(status_code=404, detail="Topic not found")
        
    post = CommunityForumPost(
        topic_id=topic_id,
        author_id=current_user.id,
        parent_id=data.parent_id,
        content=sanitize_html(data.content)
    )
    session.add(post)
    session.commit()
    return {"status": "ok", "message": "Post created"}

@router.get("/forum/{topic_id}")
def get_topic_details(
    topic_id: int,
    session: Session = Depends(get_db)
):
    from core.models import CommunityForumTopic, CommunityForumPost
    from sqlmodel import select
    from sqlalchemy.orm import joinedload
    
    topic = session.get(CommunityForumTopic, topic_id)
    if not topic:
        raise HTTPException(status_code=404, detail="Topic not found")
        
    statement = (
        select(CommunityForumPost)
        .where(CommunityForumPost.topic_id == topic_id)
        .options(joinedload(CommunityForumPost.author))
        .order_by(CommunityForumPost.created_at.asc())
    )
    posts = session.exec(statement).all()
    
    return {
        "id": topic.id,
        "title": topic.title,
        "content": topic.content,
        "created_at": topic.created_at,
        "posts": [
            {
                "id": p.id,
                "content": p.content,
                "created_at": p.created_at,
                "author": {
                    "id": p.author.id,
                    "username": p.author.username,
                    "profile_picture": p.author.profile_picture
                },
                "parent_id": p.parent_id
            } for p in posts
        ]
    }
