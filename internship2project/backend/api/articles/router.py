import secrets
import time
from typing import List, Optional
from sqlmodel import Session
from sqlalchemy.exc import IntegrityError
from core.models import SavedArticle

from fastapi import APIRouter, Depends, HTTPException, status, Query, BackgroundTasks
from fastapi.responses import FileResponse
import os
from pathlib import Path
import re

# TTS API hata cooldown — başarısız isteklerin tekrar tekrar atılmasını önler
_tts_error_cache: dict[str, tuple[float, int, str]] = {}  # key -> (timestamp, status_code, detail)
_TTS_COOLDOWN_SECONDS = 60

from core.database import get_db
from core.dependencies import get_current_user, get_optional_user
from api.articles.schemas import ArticleCreate, ArticleUpdate, ArticleDetail, ArticleListItem
from api.articles import service as article_service

from core.models import Category, TranslatedArticle
from sqlmodel import select

def _process_language_translation_and_audio(article_id: int, lang: str):
    """Arka planda tek bir dil için çeviri ve ses üretme işini yapar."""
    import os
    import json
    import time
    from pathlib import Path
    from sqlmodel import Session
    from core.database import engine
    from google import genai
    from google.genai import types
    from api.articles import service as article_service
    
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        return
        
    audio_dir = Path("data/audios")
    audio_dir.mkdir(parents=True, exist_ok=True)
    audio_base = audio_dir / f"article_{article_id}_{lang}"
    
    # Varsa geç
    for ext in [".wav", ".mp3", ".ogg", ".webm"]:
        if audio_base.with_suffix(ext).exists():
            return
            
    with Session(engine) as session:
        article = article_service.get_article_by_id(session, article_id)
        if not article:
            return
            
        text_content = article.content
        title = article.title
        summary = article.summary
        
        # 1. Çeviri (eğer Türkçe/Orijinal değilse)
        if lang.lower() not in ["orijinal", "türkçe", "tr"]:
            try:
                # Önce var mı diye bak
                from core.models import TranslatedArticle
                from sqlmodel import select
                translation = session.exec(
                    select(TranslatedArticle).where(
                        TranslatedArticle.article_id == article_id, 
                        TranslatedArticle.language == lang
                    )
                ).first()
                
                if not translation:
                    client = genai.Client(api_key=api_key)
                    system_instruction = (
                        f"Sen profesyonel bir çevirmensin. Verilen makaleyi HTML etiketlerini ve yapısını kesinlikle "
                        f"bozmadan {lang} diline çevireceksin. Sadece aşağıdaki JSON formatında geçerli bir yanıt dön, markdown kullanma:\n"
                        "{\n"
                        '  "title": "Çevrilmiş Başlık",\n'
                        '  "summary": "Çevrilmiş Özet",\n'
                        '  "content": "Çevrilmiş HTML İçerik"\n'
                        "}"
                    )
                    prompt = f"Başlık: {title}\nÖzet: {summary or ''}\nİçerik:\n{text_content}"
                    max_retries = 5
                    response = None
                    for attempt in range(max_retries):
                        try:
                            response = client.models.generate_content(
                                model='gemini-3-flash-preview',
                                contents=f"{system_instruction}\n\nÇevrilecek Metin:\n{prompt}",
                                config=types.GenerateContentConfig(response_mime_type="application/json")
                            )
                            break
                        except Exception as e:
                            err_msg = str(e)
                            if "429" in err_msg or "RESOURCE_EXHAUSTED" in err_msg or "Quota" in err_msg:
                                if attempt < max_retries - 1:
                                    print(f"Rate limit hit for translation ({lang}), waiting 65s...")
                                    time.sleep(65)
                                    continue
                            raise e
                    
                    if not response:
                        raise Exception("Failed to generate content after retries")
                        
                    text = response.text.strip()
                    if text.startswith("```json"): text = text[7:]
                    if text.startswith("```"): text = text[3:]
                    if text.endswith("```"): text = text[:-3]
                    text = text.strip()
                    
                    parsed = json.loads(text)
                    translation = TranslatedArticle(
                        article_id=article.id,
                        language=lang,
                        title=parsed.get('title', title),
                        summary=parsed.get('summary', summary),
                        content=parsed.get('content', text_content)
                    )
                    session.add(translation)
                    session.commit()
                    
                    text_content = translation.content
                else:
                    text_content = translation.content
            except Exception as e:
                print(f"Background translation failed for {lang}: {e}")
                with open(audio_base.with_suffix(".error"), "w", encoding="utf-8") as f:
                    f.write(f"Translation failed: {str(e)}")
                return # Çeviri başarısızsa sese geçme!
                
        # API limitlerini (15 RPM) zorlamamak adına çeviri ile ses arasına 10 saniye koy
        time.sleep(10)
                
        # 2. Ses Üretimi
        clean_text = re.sub(r'<[^>]+>', '', text_content).strip()
        if not clean_text:
            return
            
        clean_text = clean_text[:2500] 
        
        lang_map = {
            "Orijinal": "Türkçe", "tr": "Türkçe", "Türkçe": "Türkçe",
            "en": "İngilizce", "İngilizce": "İngilizce",
            "de": "Almanca", "Almanca": "Almanca",
            "fr": "Fransızca", "Fransızca": "Fransızca",
            "es": "İspanyolca", "İspanyolca": "İspanyolca",
            "it": "İtalyanca", "İtalyanca": "İtalyanca",
            "ru": "Rusça", "Rusça": "Rusça",
            "ar": "Arapça", "Arapça": "Arapça",
            "ja": "Japonca", "Japonca": "Japonca",
        }
        target_lang = lang_map.get(lang, "Türkçe")
        
        try:
            client = genai.Client(api_key=api_key)
            max_retries = 5
            response = None
            for attempt in range(max_retries):
                try:
                    response = client.models.generate_content(
                        model='gemini-3.1-flash-tts-preview',
                        contents=f"Lütfen şu metni akıcı, doğal ve profesyonel bir ses tonuyla {target_lang} dilinde oku ve okumaktan başka bir cevap verme:\n\n{clean_text}",
                        config=types.GenerateContentConfig(response_modalities=["AUDIO"])
                    )
                    break
                except Exception as e:
                    err_msg = str(e)
                    if "429" in err_msg or "RESOURCE_EXHAUSTED" in err_msg or "Quota" in err_msg:
                        if attempt < max_retries - 1:
                            print(f"Rate limit hit for TTS ({lang}), waiting 65s...")
                            time.sleep(65)
                            continue
                    raise e
                    
            if not response:
                raise Exception("Failed to generate TTS after retries")
            
            audio_bytes = None
            mime_type = "audio/mp3"
            
            if response.candidates and response.candidates[0].content.parts:
                for part in response.candidates[0].content.parts:
                    if part.inline_data:
                        audio_bytes = part.inline_data.data
                        mime_type = part.inline_data.mime_type or mime_type
                        break
                        
            if audio_bytes:
                import base64
                if isinstance(audio_bytes, str):
                    audio_bytes = base64.b64decode(audio_bytes)
                    
                if "pcm" in mime_type.lower():
                    import wave
                    final_file = audio_base.with_suffix(".wav")
                    with wave.open(str(final_file), 'wb') as wav_file:
                        wav_file.setnchannels(1)
                        wav_file.setsampwidth(2)
                        wav_file.setframerate(24000)
                        wav_file.writeframes(audio_bytes)
                else:
                    ext = ".mp3"
                    if "ogg" in mime_type: ext = ".ogg"
                    elif "webm" in mime_type: ext = ".webm"
                    elif "wav" in mime_type: ext = ".wav"
                    final_file = audio_base.with_suffix(ext)
                    with open(final_file, "wb") as f:
                        f.write(audio_bytes)
        except Exception as e:
            with open(audio_base.with_suffix(".error"), "w", encoding="utf-8") as f:
                f.write(str(e))
                
        # API limitlerini (15 RPM) zorlamamak adına diğer dile geçmeden önce 10 saniye koy
        time.sleep(10)

def process_article_background(article_id: int, target_languages: list):
    """Tüm hedef diller için sırayla arkaplan işlemlerini yürütür."""
    # Orijinal dil (tr) sesini üret
    _process_language_translation_and_audio(article_id, "tr")
    
    # Kullanıcının seçtiği tüm desteklenen dilleri arkaplanda üret
    target_languages = target_languages or []
    for lang in target_languages:
        if lang.lower() not in ["tr", "türkçe", "orijinal"]:
            _process_language_translation_and_audio(article_id, lang)
            
    # Bütün seslerin ve çevirilerin bittiğini işaretle
    from pathlib import Path
    audio_dir = Path("data/audios")
    audio_dir.mkdir(parents=True, exist_ok=True)
    (audio_dir / f"article_{article_id}_done.txt").touch(exist_ok=True)

router = APIRouter(prefix="/articles", tags=["Articles"])

@router.get("/categories")
def get_categories(session: Session = Depends(get_db)):
    categories = session.exec(select(Category)).all()
    return [c.name for c in categories]

@router.get("/public", response_model=List[ArticleListItem])
def list_public(skip: int = 0, limit: int = 20, categories: List[str] = Query(None), session: Session = Depends(get_db)):
    return article_service.get_public_articles(session, skip, limit, categories)

@router.get("/my", response_model=List[ArticleListItem])
def my_articles(
    current_user = Depends(get_current_user),
    session: Session = Depends(get_db),
):
    return article_service.get_articles_by_author(session, current_user.id, public_only=False)

@router.get("/{article_id}", response_model=ArticleDetail)
def get_article(
    article_id: int,
    share_token: Optional[str] = None,
    lang: Optional[str] = None,
    session: Session = Depends(get_db),
    current_user = Depends(get_optional_user),
):
    article = article_service.get_article_by_id(session, article_id)
    if not article:
        raise HTTPException(status_code=404, detail="Makale bulunamadı")
    if not article.is_public:
        is_author = current_user and current_user.id == article.author_id
        valid_token = share_token and article.share_token == share_token
        if not (is_author or valid_token):
            raise HTTPException(status_code=403, detail="Erişim yetkiniz yok")
            
    if lang and lang.lower() not in ["orijinal", "türkçe", "tr"]:
        from core.models import TranslatedArticle
        from sqlmodel import select
        translation = session.exec(
            select(TranslatedArticle).where(
                TranslatedArticle.article_id == article_id, 
                TranslatedArticle.language == lang
            )
        ).first()
        
        if translation:
            article.title = translation.title
            article.summary = translation.summary
            article.content = translation.content
        else:
            # On-demand çeviri oluştur (sadece seçildiğinde)
            try:
                import os
                import json
                from google import genai
                from google.genai import types
                api_key = os.environ.get("GEMINI_API_KEY")
                if api_key:
                    client = genai.Client(api_key=api_key)
                    system_instruction = (
                        f"Sen profesyonel bir çevirmensin. Verilen makaleyi HTML etiketlerini ve yapısını kesinlikle "
                        f"bozmadan {lang} diline çevireceksin. Sadece aşağıdaki JSON formatında geçerli bir yanıt dön, markdown kullanma:\n"
                        "{\n"
                        '  "title": "Çevrilmiş Başlık",\n'
                        '  "summary": "Çevrilmiş Özet",\n'
                        '  "content": "Çevrilmiş HTML İçerik"\n'
                        "}"
                    )
                    prompt = f"Başlık: {article.title}\nÖzet: {article.summary or ''}\nİçerik:\n{article.content}"
                    response = client.models.generate_content(
                        model='gemini-3-flash-preview',
                        contents=f"{system_instruction}\n\nÇevrilecek Metin:\n{prompt}",
                        config=types.GenerateContentConfig(response_mime_type="application/json")
                    )
                    text = response.text.strip()
                    if text.startswith("```json"):
                        text = text[7:]
                    if text.startswith("```"):
                        text = text[3:]
                    if text.endswith("```"):
                        text = text[:-3]
                    text = text.strip()
                    parsed = json.loads(text)
                    
                    translation = TranslatedArticle(
                        article_id=article.id,
                        language=lang,
                        title=parsed.get('title', article.title),
                        summary=parsed.get('summary', article.summary),
                        content=parsed.get('content', article.content)
                    )
                    session.add(translation)
                    session.commit()
                    
                    article.title = translation.title
                    article.summary = translation.summary
                    article.content = translation.content
            except Exception as e:
                print(f"On-demand translation failed: {e}")

    return article

@router.post("", response_model=ArticleDetail, status_code=status.HTTP_201_CREATED)
def create_article(
    data: ArticleCreate,
    background_tasks: BackgroundTasks,
    current_user = Depends(get_current_user),
    session: Session = Depends(get_db),
):
    article = article_service.create_article(
        session, data.title, data.content, data.summary, data.cover_image, data.is_public, current_user.id, data.categories, data.target_languages
    )
    
    # Arkaplan işlemine makaleyi ve seçilen dilleri gönder
    background_tasks.add_task(process_article_background, article.id, data.target_languages or [])
    
    return article

@router.put("/{article_id}", response_model=ArticleDetail)
def update_article(
    article_id: int,
    data: ArticleUpdate,
    current_user = Depends(get_current_user),
    session: Session = Depends(get_db),
):
    updated = article_service.update_article(
        session, article_id, current_user.id, data.model_dump(exclude_unset=True)
    )
    if not updated:
        raise HTTPException(status_code=404, detail="Makale bulunamadı veya yetkiniz yok")
    return updated

@router.delete("/{article_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_article(
    article_id: int,
    current_user = Depends(get_current_user),
    session: Session = Depends(get_db),
):
    if not article_service.delete_article(session, article_id, current_user.id):
        raise HTTPException(status_code=404, detail="Makale bulunamadı veya yetkiniz yok")

@router.post("/{article_id}/share")
def generate_share_token(
    article_id: int,
    current_user = Depends(get_current_user),
    session: Session = Depends(get_db),
):
    """Makale için paylaşım bağlantısı token'ı üretir (Sadece yazar)."""
    article = article_service.get_article_by_id(session, article_id)
    if not article or article.author_id != current_user.id:
        raise HTTPException(status_code=404, detail="Makale bulunamadı veya yetkiniz yok")
    
    token = secrets.token_urlsafe(16)
    article.share_token = token
    session.add(article)
    session.commit()
    return {"share_token": token}

@router.post("/{article_id}/offline")
def save_offline(
    article_id: int,
    current_user = Depends(get_current_user),
    session: Session = Depends(get_db),
):
    """Makaleyi çevrimdışı okumak için kaydeder (Sadece üyeler)."""
    article = article_service.get_article_by_id(session, article_id)
    if not article:
        raise HTTPException(status_code=404, detail="Makale bulunamadı")
    try:
        saved = SavedArticle(user_id=current_user.id, article_id=article_id)
        session.add(saved)
        session.commit()
    except IntegrityError:
        session.rollback() # Zaten kaydedilmiş
    return {"status": "ok", "message": "Makale çevrimdışı okuma için kaydedildi"}

@router.get("/{article_id}/audio")
def get_audio_stream(
    article_id: int,
    lang: str = Query("tr"),
    token: Optional[str] = None,
    current_user = Depends(get_optional_user),
    session: Session = Depends(get_db),
):
    """Makaleyi sesli dinleme özelliği (Sadece yerel cache)."""
    article = article_service.get_article_by_id(session, article_id)
    if not article:
        raise HTTPException(status_code=404, detail="Makale bulunamadı")

    # Eğer makale public değilse, giriş yapılmış olmasını iste
    if not article.is_public:
        if not current_user and not token:
            raise HTTPException(status_code=401, detail="Yetkiniz yok")
        if token and not current_user:
            from api.auth.service import decode_token
            payload = decode_token(token)
            if not payload:
                raise HTTPException(status_code=401, detail="Geçersiz token")

    # Çeviri var mı kontrol et, yoksa orijinalini kullan
    from core.models import TranslatedArticle
    from sqlmodel import select
    
    text_content = article.content
    if lang != "tr":
        translation = session.exec(
            select(TranslatedArticle).where(
                TranslatedArticle.article_id == article_id, 
                TranslatedArticle.language == lang
            )
        ).first()
        if translation:
            text_content = translation.content

    clean_text = re.sub(r'<[^>]+>', '', text_content)
    clean_text = clean_text.strip()
    if not clean_text:
        raise HTTPException(status_code=400, detail="Makale içeriği boş")
        
    # Gemini TTS API'sinin aşırı uzun metinlerde 400 Bad Request dönmesini engellemek için metni sınırla
    clean_text = clean_text[:2500] 

    lang_map = {
        "Orijinal": "Türkçe",
        "tr": "Türkçe",
        "Türkçe": "Türkçe",
        "en": "İngilizce",
        "İngilizce": "İngilizce",
        "de": "Almanca",
        "Almanca": "Almanca",
        "fr": "Fransızca",
        "Fransızca": "Fransızca",
        "es": "İspanyolca",
        "İspanyolca": "İspanyolca",
        "it": "İtalyanca",
        "İtalyanca": "İtalyanca",
        "ru": "Rusça",
        "Rusça": "Rusça",
        "ar": "Arapça",
        "Arapça": "Arapça",
        "ja": "Japonca",
        "Japonca": "Japonca",
    }
    target_lang = lang_map.get(lang, "Türkçe")

    audio_dir = Path("data/audios")
    audio_dir.mkdir(parents=True, exist_ok=True)
    audio_base = audio_dir / f"article_{article_id}_{lang}"
    
    # Mevcut dosyaları kontrol et
    for ext in [".wav", ".mp3", ".ogg", ".webm"]:
        if audio_base.with_suffix(ext).exists():
            media_type = f"audio/{ext[1:]}"
            if ext == ".mp3": media_type = "audio/mpeg"
            return FileResponse(audio_base.with_suffix(ext), media_type=media_type)
    
    # Cooldown kontrolü — son hata çok yakın zamandaysa tekrar API'ye istek atma
    cache_key = f"{article_id}_{lang}"
    if cache_key in _tts_error_cache:
        cached_time, cached_status, cached_detail = _tts_error_cache[cache_key]
        if time.time() - cached_time < _TTS_COOLDOWN_SECONDS:
            remaining = int(_TTS_COOLDOWN_SECONDS - (time.time() - cached_time))
            raise HTTPException(
                status_code=cached_status,
                detail=f"{cached_detail} (Lütfen {remaining} saniye sonra tekrar deneyin.)"
            )
        else:
            del _tts_error_cache[cache_key]

    # Dosya yoksa üret
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        raise HTTPException(status_code=503, detail="Gemini API yapılandırılmamış.")
        
    from google import genai
    from google.genai import types
    client = genai.Client(api_key=api_key)
    
    try:
        response = client.models.generate_content(
            model='gemini-2.5-flash-preview-tts',
            contents=f"Lütfen şu metni akıcı, doğal ve profesyonel bir ses tonuyla {target_lang} dilinde oku ve okumaktan başka bir cevap verme:\n\n{clean_text}",
            config=types.GenerateContentConfig(response_modalities=["AUDIO"])
        )
        
        audio_bytes = None
        mime_type = "audio/mp3"
        
        if response.candidates and response.candidates[0].content.parts:
            for part in response.candidates[0].content.parts:
                if part.inline_data:
                    audio_bytes = part.inline_data.data
                    mime_type = part.inline_data.mime_type or mime_type
                    break
                    
        if audio_bytes:
            import base64
            if isinstance(audio_bytes, str):
                audio_bytes = base64.b64decode(audio_bytes)
                
            if "pcm" in mime_type.lower():
                import wave
                final_file = audio_base.with_suffix(".wav")
                with wave.open(str(final_file), 'wb') as wav_file:
                    wav_file.setnchannels(1)
                    wav_file.setsampwidth(2)
                    wav_file.setframerate(24000)
                    wav_file.writeframes(audio_bytes)
                return FileResponse(final_file, media_type="audio/wav")
            else:
                ext = ".mp3"
                if "ogg" in mime_type: ext = ".ogg"
                elif "webm" in mime_type: ext = ".webm"
                elif "wav" in mime_type: ext = ".wav"
                
                final_file = audio_base.with_suffix(ext)
                with open(final_file, "wb") as f:
                    f.write(audio_bytes)
                
                resp_media_type = mime_type if mime_type else "audio/mpeg"
                return FileResponse(final_file, media_type=resp_media_type)
        else:
            raise Exception(f"Gemini yanıtında ses verisi bulunamadı. Dönen veri: {response}")
            
    except Exception as e:
        err_msg = str(e)
        with open(audio_dir / "last_audio_error.txt", "w", encoding="utf-8") as f:
            import traceback
            f.write(traceback.format_exc())
            
        status_code = 500
        detail = f"Ses oluşturulamadı (Gemini API Hatası): {err_msg}"
        
        try:
            from google.genai.errors import APIError
            if isinstance(e, APIError):
                if getattr(e, "code", None) == 429 or getattr(e, "status", None) == "RESOURCE_EXHAUSTED":
                    status_code = 429
                    detail = "Gemini API limitine takıldınız (Dakikada en fazla 3 istek). Lütfen biraz bekleyip tekrar deneyin."
                elif getattr(e, "code", None) and e.code >= 400:
                    status_code = e.code if isinstance(e.code, int) else 500
                    detail = f"Gemini API Hatası: {getattr(e, 'message', str(e))}"
        except ImportError:
            pass

        if status_code == 500 and ("429" in err_msg or "RESOURCE_EXHAUSTED" in err_msg):
            status_code = 429
            detail = "Gemini API limitine takıldınız. Lütfen biraz bekleyip tekrar deneyin."
        
        # Hatayı cache'le — tekrar tekrar API'ye istek atılmasını önle
        _tts_error_cache[cache_key] = (time.time(), status_code, detail)
            
        raise HTTPException(status_code=status_code, detail=detail)

@router.get("/{article_id}/audio-status")
def get_audio_status(
    article_id: int,
    session: Session = Depends(get_db),
):
    """Hangi dillerin ses dosyasının hazır olduğunu döner."""
    article = article_service.get_article_by_id(session, article_id)
    if not article:
        raise HTTPException(status_code=404, detail="Makale bulunamadı")
        
    audio_dir = Path("data/audios")
    status_dict = {}
    
    def check_status(lang: str):
        has_file = False
        for ext in [".wav", ".mp3", ".ogg", ".webm"]:
            if (audio_dir / f"article_{article_id}_{lang}{ext}").exists():
                has_file = True
                break
                
        if has_file:
            status_dict[lang] = "ready"
        elif (audio_dir / f"article_{article_id}_{lang}.error").exists():
            try:
                with open(audio_dir / f"article_{article_id}_{lang}.error", "r", encoding="utf-8") as f:
                    err_msg = f.read().strip()
                status_dict[lang] = f"error: {err_msg}"
            except Exception:
                status_dict[lang] = "error: unknown error"
        else:
            status_dict[lang] = "processing"

    # tr (Orijinal) kontrol et
    check_status("tr")
        
    # Çevirileri kontrol et
    from core.models import TranslatedArticle
    from sqlmodel import select
    translations = session.exec(
        select(TranslatedArticle).where(TranslatedArticle.article_id == article_id)
    ).all()
    
    for t in translations:
        check_status(t.language)
        
    is_done_file_exists = (audio_dir / f"article_{article_id}_done.txt").exists()
    
    # Geriye dönük uyumluluk veya takılı kalmaları önlemek için: makale 1 saatten eskiyse her halükarda hazır kabul et.
    import datetime
    is_old = False
    if article.created_at:
        now = datetime.datetime.now(datetime.timezone.utc)
        created_at_dt = article.created_at
        if created_at_dt.tzinfo is None:
            created_at_dt = created_at_dt.replace(tzinfo=datetime.timezone.utc)
        diff = (now - created_at_dt).total_seconds()
        if diff > 3600:
            is_old = True
            
    status_dict["all_ready"] = is_done_file_exists or is_old
            
    return status_dict

@router.post("/{article_id}/translate")
def translate_article(
    article_id: int,
    target_lang: str = Query(..., description="Target language code (e.g., 'en', 'de')"),
    current_user = Depends(get_current_user),
    session: Session = Depends(get_db),
):
    """Makaleyi Gemini API ile çevirir (Sadece yazar). HTML yapısı korunur."""
    article = article_service.get_article_by_id(session, article_id)
    if not article or article.author_id != current_user.id:
        raise HTTPException(status_code=404, detail="Makale bulunamadı veya yetkiniz yok")
        
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        raise HTTPException(status_code=503, detail="Gemini API is not configured.")
        
    from google import genai
    client = genai.Client(api_key=api_key)
    
    system_instruction = (
        f"Aşağıdaki makale içeriğini {target_lang} diline çevir. "
        "DİKKAT: İçerikteki tüm HTML etiketlerini, css stillerini, class'ları ve yapıyı kesinlikle olduğu gibi korumalı, "
        "sadece metinleri çevirmelisin."
    )
    
    try:
        # Translate title
        title_resp = client.models.generate_content(
            model='gemini-3-flash-preview',
            contents=f"Şu başlığı {target_lang} diline çevir: {article.title}"
        )
        translated_title = title_resp.text.strip()
        
        # Translate summary
        translated_summary = None
        if article.summary:
            sum_resp = client.models.generate_content(
                model='gemini-3-flash-preview',
                contents=f"Şu özeti {target_lang} diline çevir: {article.summary}"
            )
            translated_summary = sum_resp.text.strip()
            
        # Translate content
        cont_resp = client.models.generate_content(
            model='gemini-3-flash-preview',
            contents=f"{system_instruction}\n\nİçerik:\n{article.content}"
        )
        translated_content = cont_resp.text.strip()
        
        # Save to DB
        from core.models import TranslatedArticle
        # Check if already translated
        from sqlmodel import select
        existing = session.exec(
            select(TranslatedArticle).where(
                TranslatedArticle.article_id == article_id,
                TranslatedArticle.language == target_lang
            )
        ).first()
        
        if existing:
            existing.title = translated_title
            existing.content = translated_content
            existing.summary = translated_summary
            session.add(existing)
        else:
            new_translation = TranslatedArticle(
                article_id=article_id,
                language=target_lang,
                title=translated_title,
                content=translated_content,
                summary=translated_summary
            )
            session.add(new_translation)
            
        session.commit()
        return {"status": "ok", "message": f"Successfully translated to {target_lang}"}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Translation failed: {str(e)}")

from pydantic import BaseModel
class CommentCreate(BaseModel):
    content: str

@router.post("/{article_id}/comments")
def add_comment(
    article_id: int,
    data: CommentCreate,
    current_user = Depends(get_current_user),
    session: Session = Depends(get_db),
):
    article = article_service.get_article_by_id(session, article_id)
    if not article:
        raise HTTPException(status_code=404, detail="Makale bulunamadı")
        
    from core.models import ArticleComment
    from api.articles.service import sanitize_html
    
    sanitized_content = sanitize_html(data.content)
    comment = ArticleComment(
        article_id=article_id,
        user_id=current_user.id,
        content=sanitized_content
    )
    session.add(comment)
    session.commit()
    return {"status": "ok", "message": "Comment added"}

@router.get("/{article_id}/comments")
def get_comments(
    article_id: int,
    session: Session = Depends(get_db),
):
    from core.models import ArticleComment
    from sqlmodel import select
    from sqlalchemy.orm import joinedload
    
    statement = (
        select(ArticleComment)
        .where(ArticleComment.article_id == article_id)
        .options(joinedload(ArticleComment.user))
        .order_by(ArticleComment.created_at.desc())
    )
    comments = session.exec(statement).all()
    result = []
    for c in comments:
        result.append({
            "id": c.id,
            "content": c.content,
            "created_at": c.created_at,
            "user": {
                "id": c.user.id,
                "username": c.user.username,
                "profile_picture": c.user.profile_picture
            }
        })
    return result
