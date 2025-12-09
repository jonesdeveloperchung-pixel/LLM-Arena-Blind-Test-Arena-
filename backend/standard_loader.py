import json
from pathlib import Path
from typing import Dict, List, Optional

from models import ScoringStandard # Assuming models.py is in backend/

class StandardLoader:
    def __init__(self, standards_dir: Path = Path(__file__).parent / "benchmark" / "standards"):
        self.standards_dir = standards_dir
        self._standards: Dict[str, Dict[str, ScoringStandard]] = {} # {category: {language: ScoringStandard}}
        self._load_standards()

    def _load_standards(self):
        if not self.standards_dir.exists():
            self.standards_dir.mkdir(parents=True, exist_ok=True)
            return

        for standard_file in self.standards_dir.glob("*.json"):
            try:
                with open(standard_file, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    standard = ScoringStandard(**data)
                    
                    if standard.category not in self._standards:
                        self._standards[standard.category] = {}
                    self._standards[standard.category][standard.language] = standard
            except Exception as e:
                print(f"Error loading standard file {standard_file}: {e}")

    def get_standard(self, category: str, language: str = "en") -> Optional[ScoringStandard]:
        # Try exact match first (e.g., 'zh_TW')
        if category in self._standards and language in self._standards[category]:
            return self._standards[category][language]
        
        # Fallback to base language (e.g., 'zh' if 'zh_TW' not found)
        base_language = language.split('_')[0]
        if category in self._standards and base_language in self._standards[category]:
            return self._standards[category][base_language]
        
        # Fallback to English if no specific or base language standard is found
        if category in self._standards and "en" in self._standards[category]:
            return self._standards[category]["en"]
            
        return None

# Example usage (for testing)
if __name__ == "__main__":
    loader = StandardLoader()
    print("Loaded Standards:")
    for category, langs in loader._standards.items():
        print(f"  Category: {category}")
        for lang, standard in langs.items():
            print(f"    Lang: {lang}, Name: {standard.name}, Metrics: {standard.metrics}")

    reasoning_en = loader.get_standard("reasoning", "en")
    if reasoning_en:
        print(f"\nReasoning EN Standard Metrics: {reasoning_en.metrics}")

    reasoning_zh_tw = loader.get_standard("reasoning", "zh_TW")
    if reasoning_zh_tw:
        print(f"Reasoning ZH_TW Standard Metrics: {reasoning_zh_tw.metrics}")
