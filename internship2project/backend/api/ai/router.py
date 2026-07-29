import os
import json
from google import genai
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from core.dependencies import get_current_user

router = APIRouter(prefix="/ai", tags=["AI"])

# Debug: API key durumu
_key = os.environ.get("GEMINI_API_KEY")
print(f"[AI Router] GEMINI_API_KEY loaded: {'YES (' + _key[:8] + '...)' if _key else 'NO'}")

class AIGenerateRequest(BaseModel):
    prompt: str
    language: str = "Türkçe"

class AIGenerateResponse(BaseModel):
    title: str
    content: str
    summary: str

class AIHelpRequest(BaseModel):
    context: str
    prompt: str

@router.post("/generate-article", response_model=AIGenerateResponse)
def generate_article(request: AIGenerateRequest, current_user = Depends(get_current_user)):
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        raise HTTPException(status_code=503, detail="Gemini API is not configured (GEMINI_API_KEY).")
        
    client = genai.Client(api_key=api_key)
    
    system_instruction = (
        f"Sen profesyonel bir makale yazarısın. Kullanıcının verdiği konuya veya duruma göre {request.language} dilinde bir makale yazacaksın. "
        "Çıktıyı tam olarak şu formatta bir JSON olarak vermelisin:\n"
        "{\n"
        '  "title": "Makalenin Başlığı",\n'
        '  "summary": "Makalenin 1-2 cümlelik kısa özeti",\n'
        '  "content": "Makalenin HTML formatında (<p>, <strong>, vb.) yazılmış detaylı içeriği"\n'
        "}\n"
        "Sadece geçerli bir JSON döndür, markdown işaretleri kullanma."
    )
    
    try:
        response = client.models.generate_content(
            model='gemini-3.5-flash',
            contents=f"{system_instruction}\n\nKullanıcı Promptu:\n{request.prompt}"
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
        return AIGenerateResponse(**parsed)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI generation failed: {str(e)}")

@router.post("/help-write")
def help_write(request: AIHelpRequest, current_user = Depends(get_current_user)):
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        raise HTTPException(status_code=503, detail="Gemini API is not configured.")
        
    client = genai.Client(api_key=api_key)
    
    prompt = (
        "Şu ana kadar yazılmış olan makale metni (bağlam):\n"
        f"\"{request.context}\"\n\n"
        "Kullanıcının isteği/sorusu:\n"
        f"\"{request.prompt}\"\n\n"
        "Lütfen kullanıcıya yazısına devam etmesi veya ilham alması için faydalı, kısa ve öz bir öneri/metin sağla. HTML veya Markdown kullanabilirsin."
    )
    
    try:
        response = client.models.generate_content(
            model='gemini-3.5-flash',
            contents=prompt
        )
        return {"suggestion": response.text.strip()}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI help failed: {str(e)}")

from typing import List

class ChatMessage(BaseModel):
    role: str
    content: str

class AIChatRequest(BaseModel):
    context: str
    messages: List[ChatMessage]

@router.post("/chat")
def chat(request: AIChatRequest, current_user = Depends(get_current_user)):
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        raise HTTPException(status_code=503, detail="Gemini API is not configured.")
        
    client = genai.Client(api_key=api_key)
    
    formatted_messages = []
    for msg in request.messages:
        role = "user" if msg.role == "user" else "model"
        # google-genai expects parts to be a list of Part dicts or objects
        formatted_messages.append({"role": role, "parts": [{"text": msg.content}]})
        
    system_instruction = (
        "Sen makale yazımında kullanıcıya yardımcı olan bir yapay zeka asistanısın. "
        "Kullanıcının mevcut makale metni şudur (bunu okuyarak bağlamı anla):\n"
        f"\"{request.context}\"\n\n"
        "Kullanıcıya bu bağlamda yardımcı ol. Yanıtlarını doğrudan kullanıcıya ver (HTML desteklenir, makaleye eklenecekse paragraf vb kullan)."
    )
    
    try:
        from google.genai import types
        response = client.models.generate_content(
            model='gemini-3.5-flash',
            contents=formatted_messages,
            config=types.GenerateContentConfig(
                system_instruction=system_instruction
            )
        )
        return {"reply": response.text.strip()}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI chat failed: {str(e)}")

