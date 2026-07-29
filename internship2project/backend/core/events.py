from sqlalchemy import event
from core.models import Article
from datetime import datetime, timezone

# SQLAlchemy olay dinleyicileri (Event Listeners) kullanarak SQLModel objelerini izliyoruz.
# Bu yapı, veritabanına sorgu gitmeden veya gittikten sonra otomatik işlemler yapmamızı sağlar.

@event.listens_for(Article, 'before_update')
def receive_before_update(mapper, connection, target):
    """
    Article güncellenmeden hemen önce updated_at alanını otomatik olarak şimdiki zamana ayarlar.
    """
    target.updated_at = datetime.now(timezone.utc)
