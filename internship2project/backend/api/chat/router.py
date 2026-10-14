from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends
from typing import Dict, List
import json
from sqlmodel import Session, select, or_, and_
from core.database import get_db, engine
from core.models import ChatMessage
from datetime import datetime, timezone
import asyncio

router = APIRouter(tags=["Chat"])

message_queue = asyncio.Queue()

async def background_db_writer():
    """Arka planda kuyruktaki tüm mesajları saniyede bir topluca veritabanına yazar."""
    while True:
        try:
            # 1. Bekleyen ilk mesajı al
            msg = await message_queue.get()
            msgs = [msg]
            
            # 2. Varsa diğer mesajları da beklemeden topla (max 5000)
            while not message_queue.empty() and len(msgs) < 5000:
                msgs.append(message_queue.get_nowait())
                
            # 3. Topluca yaz
            def save_to_db(messages):
                try:
                    from sqlalchemy import insert
                    from core.models import ChatMessage
                    with engine.begin() as conn:
                        conn.execute(insert(ChatMessage), messages)
                except Exception as e:
                    print(f"Toplu yazma hatası: {e}")
                    
            await asyncio.to_thread(save_to_db, msgs)
            
            # 4. Kuyruk görevlerini bitir
            for _ in msgs:
                message_queue.task_done()
                
            # Eğer kuyrukta hala mesaj varsa beklememek için sleep koymuyoruz,
            # zaten await message_queue.get() kuyruk boşsa kendi kendine uyutur.
                
        except Exception as e:
            print(f"Yazıcı döngü hatası: {e}")
            await asyncio.sleep(0.5)

class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, WebSocket] = {}
        self.writer_started = False

    async def connect(self, websocket: WebSocket, client_id: str):
        await websocket.accept()
        self.active_connections[client_id] = websocket
        
        # Sadece ilk bağlantıda arka plan görevini başlat
        if not self.writer_started:
            self.writer_started = True
            asyncio.create_task(background_db_writer())

    def disconnect(self, client_id: str):
        if client_id in self.active_connections:
            del self.active_connections[client_id]

    async def send_personal_message(self, message: str, receiver_id: str):
        if receiver_id in self.active_connections:
            websocket = self.active_connections[receiver_id]
            try:
                await websocket.send_text(message)
            except:
                self.disconnect(receiver_id)

manager = ConnectionManager()

@router.get("/api/chat/key/{user1}/{user2}")
def get_chat_encryption_key(user1: str, user2: str):
    """
    İki kullanıcı arasındaki sohbet için deterministik ve güvenli bir 32-byte şifreleme anahtarı üretir.
    Kullanıcı sıralaması alfabetik yapılarak her iki tarafın da aynı anahtarı alması sağlanır.
    """
    import hmac
    import hashlib
    import base64
    from api.auth.service import SECRET_KEY

    users = sorted([user1.strip().lower(), user2.strip().lower()])
    salt = f"chat_room_{users[0]}_{users[1]}".encode('utf-8')
    key_bytes = hmac.new(SECRET_KEY.encode('utf-8'), salt, hashlib.sha256).digest()
    key_base64 = base64.b64encode(key_bytes).decode('utf-8')
    return {
        "key": key_base64,
        "algorithm": "ChaCha20-Poly1305"
    }

@router.get("/api/chat/history/{user1}/{user2}")
def get_chat_history(user1: str, user2: str, limit: int = 10, offset: int = 0, db: Session = Depends(get_db)):
    statement = select(ChatMessage).where(
        or_(
            and_(ChatMessage.sender_id == user1, ChatMessage.receiver_id == user2),
            and_(ChatMessage.sender_id == user2, ChatMessage.receiver_id == user1)
        )
    ).order_by(ChatMessage.created_at.desc()).offset(offset).limit(limit)
    
    messages = db.exec(statement).all()
    return messages[::-1]

@router.websocket("/ws/chat/{client_id}")
async def websocket_endpoint(websocket: WebSocket, client_id: str):
    await manager.connect(websocket, client_id)
    try:
        while True:
            data = await websocket.receive_text()
            
            try:
                message_data = json.loads(data)
                
                if not isinstance(message_data, dict):
                    continue
                    
                message_type = message_data.get("type", "message")
                receiver_id = message_data.get("receiver_id")
                
                if not receiver_id:
                    continue
                    
                if message_type == "typing":
                    typing_payload = json.dumps({
                        "type": "typing",
                        "sender_id": client_id,
                        "is_typing": message_data.get("is_typing", False)
                    })
                    asyncio.create_task(manager.send_personal_message(typing_payload, receiver_id))
                    continue

                message_text = message_data.get("message")
                if message_text and isinstance(message_text, str) and message_text.strip():
                    # Tarihi yerel değişkende tut ki DB oturumu kapanınca uçmasın
                    current_time = datetime.now(timezone.utc)
                    db_message = {
                        "sender_id": client_id,
                        "receiver_id": receiver_id,
                        "content": message_text,
                        "created_at": current_time
                    }
                    
                    # Doğrudan kuyruğa at (Event loop asla bloke olmaz)
                    await message_queue.put(db_message)
                    
                    formatted_message = json.dumps({
                        "type": "message",
                        "sender_id": client_id, 
                        "message": message_text,
                        "created_at": current_time.isoformat()
                    })
                    # Gönderim işlemini beklemeyerek (fire-and-forget) darboğazı önlüyoruz
                    asyncio.create_task(manager.send_personal_message(formatted_message, receiver_id))
                    
            except json.JSONDecodeError:
                error_msg = json.dumps({"error": "Lütfen mesajı doğru JSON formatında gönderin."})
                await websocket.send_text(error_msg)
            except Exception as e:
                print(f"WebSocket veri işleme hatası: {e}")
                
    except WebSocketDisconnect:
        manager.disconnect(client_id)
