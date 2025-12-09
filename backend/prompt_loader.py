import json
from pathlib import Path
from typing import Dict, List, Optional

from models import BenchmarkPrompt # Assuming models.py is in backend/ 

class PromptLoader:
    def __init__(self, prompts_dir: Path = Path(__file__).parent / "benchmark" / "prompts"):
        self.prompts_dir = prompts_dir
        self._prompts: Dict[str, Dict[str, BenchmarkPrompt]] = {} # {category: {language: BenchmarkPrompt}}
        self._load_prompts()

    def _load_prompts(self):
        if not self.prompts_dir.exists():
            self.prompts_dir.mkdir(parents=True, exist_ok=True)
            return

        for prompt_file in self.prompts_dir.glob("*.json"):
            try:
                with open(prompt_file, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    prompt = BenchmarkPrompt(**data)
                    
                    if prompt.category not in self._prompts:
                        self._prompts[prompt.category] = {}
                    self._prompts[prompt.category][prompt.language] = prompt
            except Exception as e:
                print(f"Error loading prompt file {prompt_file}: {e}")

    def get_prompt(self, category: str, language: str = "en") -> Optional[BenchmarkPrompt]:
        # Try exact match first (e.g., 'zh_TW')
        if category in self._prompts and language in self._prompts[category]:
            return self._prompts[category][language]
        
        # Fallback to base language (e.g., 'zh' if 'zh_TW' not found)
        base_language = language.split('_')[0]
        if category in self._prompts and base_language in self._prompts[category]:
            return self._prompts[category][base_language]
        
        # Fallback to English if no specific or base language prompt is found
        if category in self._prompts and "en" in self._prompts[category]:
            return self._prompts[category]["en"]
            
        return None

# Example usage (for testing)
if __name__ == "__main__":
    loader = PromptLoader()
    print("Loaded Prompts:")
    for category, langs in loader._prompts.items():
        print(f"  Category: {category}")
        for lang, prompt in langs.items():
            print(f"    Lang: {lang}, Name: {prompt.name}, Text: {prompt.text[:50]}...")

    reasoning_en = loader.get_prompt("reasoning", "en")
    if reasoning_en:
        print(f"\nReasoning EN Prompt: {reasoning_en.text}")

    reasoning_zh_tw = loader.get_prompt("reasoning", "zh_TW")
    if reasoning_zh_tw:
        print(f"Reasoning ZH_TW Prompt: {reasoning_zh_tw.text}")

    coding_en = loader.get_prompt("coding", "en")
    if coding_en:
        print(f"Coding EN Prompt: {coding_en.text}")
    else:
        print("\nCoding EN Prompt not found, falling back to English (default).")
        # Example of how to handle if a prompt isn't specifically defined but falls back
        # The loader itself handles the fallback logic.
