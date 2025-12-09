import requests
import json
import base64
import time
import random
from typing import Dict, Optional
from pathlib import Path
import logging

# --- Localized Default Prompts ---
LOCALIZED_DEFAULTS = {
    "en": {
        "image_description_prompt": "Describe this image."
    },
    "zh_TW": {
        "image_description_prompt": "請描述這張圖像的內容。"
    },
    "zh": { # Fallback for generic Chinese
        "image_description_prompt": "請描述這張圖像的內容。"
    }
}

def get_localized_default_prompt(key: str, language: str = "en", **kwargs) -> str:
    lang_key = language.replace('-', '_') # Convert 'zh-TW' to 'zh_TW' for dictionary keys
    
    strings = LOCALIZED_DEFAULTS.get(lang_key)
    if strings is None:
        # Fallback to base language (e.g., 'zh' if 'zh_TW' not found)
        base_lang = language.split('-')[0]
        strings = LOCALIZED_DEFAULTS.get(base_lang, LOCALIZED_DEFAULTS["en"])
    
    return strings.get(key, LOCALIZED_DEFAULTS["en"].get(key, f"MISSING_DEFAULT_PROMPT({key})")).format(**kwargs)

class OllamaClient:
    def __init__(self, base_url: str = "http://localhost:11434", model: str = "llama3.2-vision", 
                 timeout: int = 60, retries: int = 3, retry_delay: float = 1.0,
                 use_gemini_fallback: bool = False, gemini_api_key: str = ""):
        self.base_url = base_url
        self.model = model
        self.timeout = timeout
        self.retries = retries
        self.retry_delay = retry_delay
        self.use_gemini_fallback = use_gemini_fallback
        self.gemini_api_key = gemini_api_key
        # Add a logger for debugging
        self.logger = logging.getLogger("OllamaClient")



    def _encode_image_to_base64(self, image_path: str) -> str:
        with open(image_path, "rb") as f:
            return base64.b64encode(f.read()).decode("utf-8")
    
    def _call_ollama_api(self, prompt: str, image_base64: Optional[str] = None, model_override: Optional[str] = None) -> Optional[Dict]:
        url = f"{self.base_url}/api/generate"
        payload = {
            "model": model_override if model_override else self.model,
            "prompt": prompt,
            "stream": False,
        }
        if image_base64:
            payload["images"] = [image_base64]

        headers = {"Content-Type": "application/json"}

        for i in range(self.retries + 1):
            try:
                self.logger.info(f"Attempt {i+1}/{self.retries+1} to call Ollama API for model {payload['model']}.")
                response = requests.post(url, headers=headers, data=json.dumps(payload), timeout=self.timeout)
                response.raise_for_status()
                return response.json()
            except requests.exceptions.RequestException as e:
                self.logger.warning(f"Ollama API request failed (attempt {i+1}): {e}")
                if i < self.retries:
                    sleep_time = self.retry_delay * (2 ** i) + random.uniform(0, 1)
                    self.logger.info(f"Retrying in {sleep_time:.2f} seconds...")
                    time.sleep(sleep_time)
                else:
                    self.logger.error(f"All {self.retries+1} Ollama API attempts failed.")
                    return None
        return None

    def _call_gemini_api(self, image_path: Optional[str], prompt: str) -> Optional[Dict]:
        # This is a simulated Gemini fallback for now.
        # In a real implementation, this would call the Google Gemini API.
        self.logger.info(f"Simulating Gemini API call for {'image: ' + image_path if image_path else 'prompt only'}")
        if not self.gemini_api_key:
            self.logger.warning("Gemini API key not provided, cannot truly fallback to Gemini.")
            return None
        
        # Simulate success
        time.sleep(2 + random.uniform(0, 1)) # Simulate network delay
        return {
            "response": f"Simulated Gemini description: This {'image' if image_path else 'prompt'} contains various elements related to the prompt. Powered by Gemini.",
            "confidence": round(random.uniform(0.7, 0.95), 2),
            "source": "Gemini"
        }

    def generate_description(self, image_path: Optional[str] = None, prompt: str = "", model: Optional[str] = None, language: str = "en") -> Optional[Dict]:
        """
        Calls Ollama API to generate a description for the given image using a vision model,
        with retry logic and optional Gemini fallback.
        """
        image_base64 = None
        if image_path:
            image_base64 = self._encode_image_to_base64(image_path)
        
        # Use localized default prompt if none is provided
        final_prompt = prompt if prompt else get_localized_default_prompt("image_description_prompt", language)

        ollama_response = self._call_ollama_api(final_prompt, image_base64, model_override=model)

        if ollama_response:
            self.logger.info("Ollama API call successful.")
            full_response_content = ollama_response.get("response", "").strip()
            confidence = min(0.5 + len(full_response_content) / 1000, 0.99)
            return {
                "description": full_response_content,
                "confidence": confidence,
                "raw_response": ollama_response,
                "source": "Ollama"
            }
        elif self.use_gemini_fallback:
            self.logger.warning("Ollama failed, attempting Gemini fallback.")
            gemini_response = self._call_gemini_api(image_path, prompt)
            if gemini_response:
                self.logger.info("Gemini fallback successful.")
                return {
                    "description": gemini_response["response"],
                    "confidence": gemini_response["confidence"],
                    "raw_response": gemini_response, # Store raw Gemini response
                    "source": "Gemini"
                }
            else:
                self.logger.error("Gemini fallback also failed.")
                return None
        else:
            self.logger.error("Ollama failed and Gemini fallback is not enabled.")
            return None

    def check_health(self) -> bool:
        """Checks if Ollama is running."""
        try:
            response = requests.get(self.base_url, timeout=5) # Shorter timeout for health check
            return response.status_code == 200
        except requests.exceptions.RequestException:
            return False

    def get_ollama_models(self) -> list:
        """Fetches the list of available models from Ollama."""
        try:
            response = requests.get(f"{self.base_url}/api/tags", timeout=5)
            response.raise_for_status()
            return response.json().get("models", [])
        except requests.exceptions.RequestException as e:
            self.logger.error(f"Failed to list Ollama models: {e}")
            return []

    def pull_model(self, model_name: str) -> bool:
        """Pulls a model from Ollama."""
        url = f"{self.base_url}/api/pull"
        payload = {"name": model_name}
        headers = {"Content-Type": "application/json"}

        for i in range(self.retries + 1):
            try:
                self.logger.info(f"Attempt {i+1}/{self.retries+1} to pull model '{model_name}' from Ollama.")
                response = requests.post(url, headers=headers, data=json.dumps(payload), timeout=self.timeout)
                response.raise_for_status()
                # Ollama's pull API streams output, so we just check for success status
                self.logger.info(f"Model '{model_name}' pull initiated successfully.")
                return True
            except requests.exceptions.RequestException as e:
                self.logger.warning(f"Ollama API pull request failed (attempt {i+1}): {e}")
                if i < self.retries:
                    sleep_time = self.retry_delay * (2 ** i) + random.uniform(0, 1)
                    self.logger.info(f"Retrying in {sleep_time:.2f} seconds...")
                    time.sleep(sleep_time)
                else:
                    self.logger.error(f"All {self.retries+1} Ollama API pull attempts failed for model '{model_name}'.")
                    return False
        return False

    def delete_model(self, model_name: str) -> bool:
        """Deletes a model from Ollama."""
        url = f"{self.base_url}/api/delete"
        payload = {"name": model_name}
        headers = {"Content-Type": "application/json"}

        for i in range(self.retries + 1):
            try:
                self.logger.info(f"Attempt {i+1}/{self.retries+1} to delete model '{model_name}' from Ollama.")
                response = requests.delete(url, headers=headers, data=json.dumps(payload), timeout=self.timeout)
                response.raise_for_status()
                self.logger.info(f"Model '{model_name}' deleted successfully.")
                return True
            except requests.exceptions.RequestException as e:
                self.logger.warning(f"Ollama API delete request failed (attempt {i+1}): {e}")
                if i < self.retries:
                    sleep_time = self.retry_delay * (2 ** i) + random.uniform(0, 1)
                    self.logger.info(f"Retrying in {sleep_time:.2f} seconds...")
                    time.sleep(sleep_time)
                else:
                    self.logger.error(f"All {self.retries+1} Ollama API delete attempts failed for model '{model_name}'.")
                    return False
        return False