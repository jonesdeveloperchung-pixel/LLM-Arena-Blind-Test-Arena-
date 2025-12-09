#!/usr/bin/env python3
"""
備援機制 (Fallback System)
Phase 3: 錯誤處理與重試
"""
import time
import requests

def call_ollama_with_retry(url, model, prompt, max_retries=3, timeout=30):
    """帶重試的 Ollama 呼叫"""
    for attempt in range(max_retries):
        try:
            response = requests.post(
                f"{url}/api/generate",
                json={"model": model, "prompt": prompt, "stream": False},
                timeout=timeout
            )
            if response.status_code == 200:
                return response.json().get('response', ''), 'Ollama'
        except Exception as e:
            print(f"⚠️  Ollama 嘗試 {attempt+1}/{max_retries} 失敗: {e}")
            if attempt < max_retries - 1:
                time.sleep(2 ** attempt)  # 指數退避
    return None, None

def call_gemini_fallback(api_key, prompt):
    """Gemini 備援"""
    if not api_key:
        return None, None
    
    try:
        import google.generativeai as genai
        genai.configure(api_key=api_key)
        model = genai.GenerativeModel('gemini-2.0-flash-exp')
        response = model.generate_content(prompt)
        return response.text, 'Gemini'
    except Exception as e:
        print(f"❌ Gemini 備援失敗: {e}")
        return None, None

def process_with_fallback(config, prompt):
    """帶備援的處理"""
    # 嘗試 Ollama
    if config['ollama']['enabled']:
        result, source = call_ollama_with_retry(
            config['ollama']['url'],
            config['ollama']['model'],
            prompt,
            config['ollama']['retry_attempts'],
            config['ollama']['timeout_seconds']
        )
        if result:
            return result, source
    
    # 備援至 Gemini
    if config['gemini']['enabled'] and config['gemini']['fallback_on_ollama_failure']:
        print("🔄 切換至 Gemini 備援...")
        result, source = call_gemini_fallback(config['gemini']['api_key'], prompt)
        if result:
            return result, source
    
    return "處理失敗：所有服務不可用", "Failed"
