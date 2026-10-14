import asyncio
import websockets
import json
import random
import os
import urllib.request
import urllib.error

# Global durum değişkenleri
active_bots = {}          # { username: asyncio.Task }
bot_usernames = []        # Tüm aktif botların isim listesi (mesajlaşmak için)
password = "test11"
host = "127.0.0.1:8000"
base_url = f"http://{host}"
ws_base_url = f"ws://{host}"
db_path = os.path.join("data", "articles.db")
bot_counter = 0           # Hiç çakışmaması için artan sayaç

async def simulate_bot(username):
    uri = f"{ws_base_url}/ws/chat/{username}"
    try:
        async with websockets.connect(uri) as ws:
            # Gelenleri dinleme
            async def listen():
                try:
                    while True:
                        await ws.recv()
                except:
                    pass
            
            listener = asyncio.create_task(listen())
            
            # Sürekli diğerlerine mesaj atma döngüsü
            target_index = 0
            try:
                while True:
                    # Anlık olarak güncel bot_usernames listesinden sırayla hedef seç
                    current_len = len(bot_usernames)
                    if current_len > 1:
                        target_index = target_index % current_len
                        target = bot_usernames[target_index]
                        target_index += 1
                        
                        if target == username:
                            continue
                            
                        msg_payload = {
                            "type": "message",
                            "receiver_id": target,
                            "message": f"Bu bir test mesajidir. Gonderen: {username} -> Alici: {target}"
                        }
                        await ws.send(json.dumps(msg_payload))
                        
                    # Döngünün kilitlenmemesi için çok çok küçük bir bekleme (0.01 saniye)
                    await asyncio.sleep(0.01)
            except asyncio.CancelledError:
                # Bot kapatılırken (kullanıcı sayısı düşürülürse)
                pass
            finally:
                listener.cancel()
                
    except Exception as e:
        print(f"\033[91m[!] {username} botunda hata: {e}\033[0m")

def register_bot_sync(username, bot_id):
    payload = json.dumps({
        "username": username,
        "email": f"BOT@bot{bot_id}.com",
        "password": password
    }).encode('utf-8')
    
    req = urllib.request.Request(f"{base_url}/auth/register", data=payload, headers={'Content-Type': 'application/json'})
    try:
        with urllib.request.urlopen(req) as response:
            return response.status == 201
    except:
        return False

async def add_bots(count):
    global bot_counter
    print(f"\n[+] {count} yeni bot ekleniyor... (Lütfen bekleyin, API'ye kaydediliyor)")
    
    sem = asyncio.Semaphore(15)  # Eşzamanlı HTTP kayıt limiti (thread pool çökmemesi için)
    
    async def register_and_start(username, bot_id):
        async with sem:
            success = await asyncio.to_thread(register_bot_sync, username, bot_id)
        if success:
            bot_usernames.append(username)
            task = asyncio.create_task(simulate_bot(username))
            active_bots[username] = task

    tasks = []
    for _ in range(count):
        username = f"test_bot_{bot_counter}"
        bot_counter += 1
        tasks.append(register_and_start(username, bot_counter))
        
    await asyncio.gather(*tasks)
    print(f"  > Toplam {len(active_bots)} aktif bot birbiriyle konuşuyor.\n> ", end="", flush=True)

async def remove_bots(count):
    print(f"\n[-] {count} bot sistemden çıkartılıyor...")
    to_remove = []
    
    for _ in range(min(count, len(bot_usernames))):
        username = bot_usernames.pop()
        to_remove.append(username)
        
        # Görevi iptal et (WebSocket kapanır)
        task = active_bots.pop(username)
        task.cancel()
    
    # Bekleyip DB'den sadece çıkanları silebiliriz ama test sonunda topluca silmek daha performanslı.
    print(f"  > Toplam {len(active_bots)} aktif bot kaldı.\n> ", end="", flush=True)

def cleanup_database():
    print("\n[!] Tüm test verileri (Kullanıcılar ve Mesajlar) FastAPI üzerinden kalıcı olarak siliniyor...")
    
    req = urllib.request.Request(f"{base_url}/auth/test-cleanup", method="DELETE")
    req.add_header('secret-key', 'MySuperSecretTestKey')
    
    try:
        with urllib.request.urlopen(req) as response:
            if response.status == 200:
                result = json.loads(response.read().decode('utf-8'))
                print(f"  > {result.get('detail', 'Başarıyla silindi.')}")
            else:
                print(f"  ! Silme işlemi başarısız. HTTP Kodu: {response.status}")
    except urllib.error.HTTPError as e:
        print(f"  ! Temizlik reddedildi veya hata oluştu: {e.read().decode('utf-8')}")
    except Exception as e:
        print(f"  ! Sunucuya bağlanılamadı: {e}")

async def cli_loop():
    print("\n" + "="*50)
    print(" CANLI VE DİNAMİK YÜK TESTİ ")
    print("="*50)
    print("Aşağıdaki komutları çalışırken KESİNTİSİZ olarak yazabilirsiniz:")
    print("  add 10    -> 10 yeni bot ekler")
    print("  remove 5  -> 5 botun bağlantısını keser")
    print("  set 50    -> Aktif bot sayısını tam 50'ye sabitler")
    print("  q         -> Testi bitirir ve veritabanını temizler")
    print("="*50)
    
    # İlk başta 10 tane ile başla
    await add_bots(10)
    
    while True:
        # Arka planda Input bekle
        cmd = await asyncio.to_thread(input, "")
        cmd = cmd.strip().lower()
        
        if cmd == 'q' or cmd == 'quit':
            print("Çıkış yapılıyor...")
            break
            
        parts = cmd.split()
        if len(parts) == 2 and parts[1].isdigit():
            action = parts[0]
            val = int(parts[1])
            
            if action == 'add':
                await add_bots(val)
            elif action == 'remove':
                await remove_bots(val)
            elif action == 'set':
                current = len(active_bots)
                if val > current:
                    await add_bots(val - current)
                elif val < current:
                    await remove_bots(current - val)
                else:
                    print(f"Zaten {current} bot aktif.\n> ", end="", flush=True)
            else:
                print("Hatalı komut. Örnek: 'add 5', 'remove 2', 'set 20', 'q'\n> ", end="", flush=True)
        elif cmd:
            print("Hatalı komut. Örnek: 'add 5', 'remove 2', 'set 20', 'q'\n> ", end="", flush=True)

async def main():
    # Başlamadan önce önceki kalıntıları temizle
    cleanup_database()
    
    try:
        # Etkileşimli CLI (Terminal) döngüsünü başlat
        await cli_loop()
    finally:
        # Q tuşuna basıldığında veya hata olduğunda tüm görevleri durdur
        for task in active_bots.values():
            task.cancel()
            
        # Son büyük temizliği yap
        cleanup_database()
        print(" TEST GÜVENLİ BİR ŞEKİLDE KAPATILDI ")

if __name__ == "__main__":
    # Windows'ta CancelledError kirliliğini gizlemek için küçük ayar
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        pass
