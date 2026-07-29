from sqlmodel import SQLModel, Field, Relationship
from typing import Optional, List
from datetime import datetime, timezone

class User(SQLModel, table=True):
    __tablename__ = "users"
    id: Optional[int] = Field(default=None, primary_key=True)
    username: str = Field(unique=True, index=True)
    email: str = Field(unique=True, index=True)
    hashed_password: str
    bio: Optional[str] = None
    profile_picture: Optional[str] = None
    profile_color: Optional[str] = None
    emotes: Optional[str] = None
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

    articles: List["Article"] = Relationship(back_populates="author")
    settings: Optional["UserSettings"] = Relationship(back_populates="user")
    communities_created: List["Community"] = Relationship(back_populates="creator")
    magazines: List["Magazine"] = Relationship(back_populates="owner")
    claps: List["Clap"] = Relationship(back_populates="user")
    community_memberships: List["CommunityMember"] = Relationship(back_populates="user")
    saved_articles: List["SavedArticle"] = Relationship(back_populates="user")
    highlights: List["Highlight"] = Relationship(back_populates="user")
    article_comments: List["ArticleComment"] = Relationship(back_populates="user")
    magazine_comments: List["MagazineComment"] = Relationship(back_populates="user")
    forum_topics: List["CommunityForumTopic"] = Relationship(back_populates="author")
    forum_posts: List["CommunityForumPost"] = Relationship(back_populates="author")

class UserSettings(SQLModel, table=True):
    __tablename__ = "user_settings"
    user_id: int = Field(primary_key=True, foreign_key="users.id")
    app_icon: str = Field(default="default")
    
    user: User = Relationship(back_populates="settings")

class Article(SQLModel, table=True):
    __tablename__ = "articles"
    id: Optional[int] = Field(default=None, primary_key=True)
    title: str
    content: str
    summary: Optional[str] = None
    cover_image: Optional[str] = None
    is_public: bool = Field(default=True)
    author_id: int = Field(foreign_key="users.id")
    share_token: Optional[str] = Field(default=None, unique=True, index=True)
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    updated_at: Optional[datetime] = None

    author: User = Relationship(back_populates="articles")
    claps: List["Clap"] = Relationship(back_populates="article")
    stats: Optional["ArticleStats"] = Relationship(back_populates="article")
    magazine_links: List["MagazineArticle"] = Relationship(back_populates="article")
    saves: List["SavedArticle"] = Relationship(back_populates="article")
    highlights: List["Highlight"] = Relationship(back_populates="article")
    categories: List["ArticleCategory"] = Relationship(back_populates="article")
    comments: List["ArticleComment"] = Relationship(back_populates="article")
    translations: List["TranslatedArticle"] = Relationship(back_populates="article")

    @property
    def available_translations(self) -> List[str]:
        return [t.language for t in self.translations] if self.translations else []

class Clap(SQLModel, table=True):
    __tablename__ = "claps"
    id: Optional[int] = Field(default=None, primary_key=True)
    article_id: int = Field(foreign_key="articles.id")
    user_id: Optional[int] = Field(default=None, foreign_key="users.id")
    ip_address: Optional[str] = None
    count: int = Field(default=1)
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

    article: Article = Relationship(back_populates="claps")
    user: Optional[User] = Relationship(back_populates="claps")

class ArticleStats(SQLModel, table=True):
    __tablename__ = "article_stats"
    article_id: int = Field(primary_key=True, foreign_key="articles.id")
    view_count: int = Field(default=0)
    clap_count: int = Field(default=0)

    article: Article = Relationship(back_populates="stats")

class Community(SQLModel, table=True):
    __tablename__ = "communities"
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str
    description: Optional[str] = None
    image: Optional[str] = None
    created_by: int = Field(foreign_key="users.id")
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

    creator: User = Relationship(back_populates="communities_created")
    members: List["CommunityMember"] = Relationship(back_populates="community")
    forum_topics: List["CommunityForumTopic"] = Relationship(back_populates="community")

class CommunityMember(SQLModel, table=True):
    __tablename__ = "community_members"
    id: Optional[int] = Field(default=None, primary_key=True)
    community_id: int = Field(foreign_key="communities.id")
    user_id: int = Field(foreign_key="users.id")
    joined_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

    community: Community = Relationship(back_populates="members")
    user: User = Relationship(back_populates="community_memberships")

class Magazine(SQLModel, table=True):
    __tablename__ = "magazines"
    id: Optional[int] = Field(default=None, primary_key=True)
    title: str
    description: Optional[str] = None
    image: Optional[str] = None
    owner_id: int = Field(foreign_key="users.id")
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

    owner: User = Relationship(back_populates="magazines")
    articles: List["MagazineArticle"] = Relationship(back_populates="magazine")
    comments: List["MagazineComment"] = Relationship(back_populates="magazine")

class MagazineArticle(SQLModel, table=True):
    __tablename__ = "magazine_articles"
    id: Optional[int] = Field(default=None, primary_key=True)
    magazine_id: int = Field(foreign_key="magazines.id")
    article_id: int = Field(foreign_key="articles.id")
    added_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

    magazine: Magazine = Relationship(back_populates="articles")
    article: Article = Relationship(back_populates="magazine_links")

class SavedArticle(SQLModel, table=True):
    __tablename__ = "saved_articles"
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="users.id")
    article_id: int = Field(foreign_key="articles.id")
    saved_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

    user: User = Relationship(back_populates="saved_articles")
    article: Article = Relationship(back_populates="saves")

class Highlight(SQLModel, table=True):
    __tablename__ = "highlights"
    id: Optional[int] = Field(default=None, primary_key=True)
    article_id: int = Field(foreign_key="articles.id")
    user_id: Optional[int] = Field(default=None, foreign_key="users.id")
    ip_address: Optional[str] = None
    start_index: int
    end_index: int
    text: str
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

    article: Article = Relationship(back_populates="highlights")
    user: Optional[User] = Relationship(back_populates="highlights")

class Category(SQLModel, table=True):
    __tablename__ = "categories"
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str = Field(unique=True, index=True)

    article_links: List["ArticleCategory"] = Relationship(back_populates="category")

class ArticleCategory(SQLModel, table=True):
    __tablename__ = "article_categories"
    id: Optional[int] = Field(default=None, primary_key=True)
    article_id: int = Field(foreign_key="articles.id")
    category_id: int = Field(foreign_key="categories.id")

    article: Article = Relationship(back_populates="categories")
    category: Category = Relationship(back_populates="article_links")

class ArticleComment(SQLModel, table=True):
    __tablename__ = "article_comments"
    id: Optional[int] = Field(default=None, primary_key=True)
    article_id: int = Field(foreign_key="articles.id")
    user_id: int = Field(foreign_key="users.id")
    content: str
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

    article: Article = Relationship(back_populates="comments")
    user: User = Relationship(back_populates="article_comments")

class MagazineComment(SQLModel, table=True):
    __tablename__ = "magazine_comments"
    id: Optional[int] = Field(default=None, primary_key=True)
    magazine_id: int = Field(foreign_key="magazines.id")
    user_id: int = Field(foreign_key="users.id")
    content: str
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

    magazine: Magazine = Relationship(back_populates="comments")
    user: User = Relationship(back_populates="magazine_comments")

class CommunityForumTopic(SQLModel, table=True):
    __tablename__ = "community_forum_topics"
    id: Optional[int] = Field(default=None, primary_key=True)
    community_id: int = Field(foreign_key="communities.id")
    author_id: int = Field(foreign_key="users.id")
    title: str
    content: str
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

    community: Community = Relationship(back_populates="forum_topics")
    author: User = Relationship(back_populates="forum_topics")
    posts: List["CommunityForumPost"] = Relationship(back_populates="topic")

class CommunityForumPost(SQLModel, table=True):
    __tablename__ = "community_forum_posts"
    id: Optional[int] = Field(default=None, primary_key=True)
    topic_id: int = Field(foreign_key="community_forum_topics.id")
    author_id: int = Field(foreign_key="users.id")
    parent_id: Optional[int] = Field(default=None, foreign_key="community_forum_posts.id")
    content: str
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

    topic: CommunityForumTopic = Relationship(back_populates="posts")
    author: User = Relationship(back_populates="forum_posts")
    
    parent: Optional["CommunityForumPost"] = Relationship(
        back_populates="replies",
        sa_relationship_kwargs=dict(remote_side="CommunityForumPost.id")
    )
    replies: List["CommunityForumPost"] = Relationship(back_populates="parent")

class TranslatedArticle(SQLModel, table=True):
    __tablename__ = "translated_articles"
    id: Optional[int] = Field(default=None, primary_key=True)
    article_id: int = Field(foreign_key="articles.id")
    language: str = Field(index=True)
    title: str
    content: str
    summary: Optional[str] = None
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

    article: Article = Relationship(back_populates="translations")
