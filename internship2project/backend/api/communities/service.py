"""
community_service.py — Topluluk CRUD işlemleri.
Sadece üyeler topluluk oluşturabilir ve katılabilir.
"""
from typing import List, Optional
from sqlmodel import Session, select
from sqlalchemy import func
from sqlalchemy.exc import IntegrityError
from core.models import Community, CommunityMember

def create_community(
    session: Session, name: str, description: Optional[str], image: Optional[str], creator_id: int
) -> dict:
    """Yeni topluluk oluşturur ve kurucuyu otomatik üye yapar."""
    community = Community(name=name, description=description, image=image, created_by=creator_id)
    session.add(community)
    session.commit()
    session.refresh(community)
    
    # Kurucuyu otomatik üye yap
    member = CommunityMember(community_id=community.id, user_id=creator_id)
    session.add(member)
    session.commit()
    
    return get_community_detail(session, community.id, creator_id)

def list_communities(
    session: Session, skip: int = 0, limit: int = 20
) -> List[dict]:
    """Tüm toplulukları listeler, üye sayısı ile birlikte."""
    statement = (
        select(Community, func.count(CommunityMember.id).label("member_count"))
        .outerjoin(CommunityMember, CommunityMember.community_id == Community.id)
        .group_by(Community.id)
        .order_by(Community.created_at.desc())
        .offset(skip)
        .limit(limit)
    )
    results = session.exec(statement).all()
    return [
        {
            **comm.model_dump(),
            "member_count": member_count
        }
        for comm, member_count in results
    ]

def get_community_detail(
    session: Session, community_id: int, user_id: Optional[int] = None
) -> Optional[dict]:
    """Topluluk detayını döndürür. user_id verilirse is_member hesaplanır."""
    statement = (
        select(Community, func.count(CommunityMember.id).label("member_count"))
        .outerjoin(CommunityMember, CommunityMember.community_id == Community.id)
        .where(Community.id == community_id)
        .group_by(Community.id)
    )
    result = session.exec(statement).first()
    if not result:
        return None
    
    comm, member_count = result
    data = {
        **comm.model_dump(),
        "member_count": member_count
    }
    
    # Üyelik durumu kontrolü
    if user_id:
        is_member = session.exec(
            select(CommunityMember).where(
                CommunityMember.community_id == community_id, 
                CommunityMember.user_id == user_id
            )
        ).first() is not None
        data["is_member"] = is_member
    else:
        data["is_member"] = False
        
    return data

def join_community(session: Session, community_id: int, user_id: int) -> bool:
    """Kullanıcıyı topluluğa ekler. Zaten üyeyse False döner."""
    member = CommunityMember(community_id=community_id, user_id=user_id)
    session.add(member)
    try:
        session.commit()
        return True
    except IntegrityError:
        session.rollback()
        return False

def leave_community(session: Session, community_id: int, user_id: int) -> bool:
    """Kullanıcıyı topluluktan çıkarır. Üye değilse False döner."""
    member = session.exec(
        select(CommunityMember).where(
            CommunityMember.community_id == community_id, 
            CommunityMember.user_id == user_id
        )
    ).first()
    
    if not member:
        return False
        
    session.delete(member)
    session.commit()
    return True
