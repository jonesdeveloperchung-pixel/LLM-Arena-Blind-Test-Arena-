#!/usr/bin/env python3
"""
LLM 基準測試系統 (LLM Benchmarking System)
實作 5 大能力評測
"""
import json
import requests
import yaml
from datetime import datetime
from typing import List, Optional
from pathlib import Path # Import Path for PromptLoader
from prompt_loader import PromptLoader # Import PromptLoader
from standard_loader import StandardLoader # Import StandardLoader
import logging # Import logging
import re # Import re for regex

logger = logging.getLogger(__name__) # Initialize logger

# --- Global Prompt Loader Instance ---
prompt_loader = PromptLoader(prompts_dir=Path(__file__).parent / "benchmark" / "prompts")

# --- Global Standard Loader Instance ---
standard_loader = StandardLoader(standards_dir=Path(__file__).parent / "benchmark" / "standards")

# --- Localized Strings for Benchmarking ---
LOCALIZED_STRINGS = {
    "en": {
        "category_name_reasoning": "Reasoning",
        "category_name_coding": "Coding",
        "category_name_vision": "Vision",
        "category_name_general": "General Language",
        "category_name_embedding": "Embedding",
        "score_simple_reasoning": "Simple scoring based on response length ({length} characters)",
        "score_model_fail": "Model response failed",
        "score_judge_fail": "Judge failed: {error}",
        "ollama_not_enabled": "⚠️  Ollama is not enabled, please edit config/jade_config.yaml",
        "ollama_api_error": "❌ Ollama API Error: {status_code} - {text}",
        "ollama_connection_fail": "Connection failed: {error}",
        "benchmark_test_category": "🧪 Testing {model_name} - {category_name}",
        "benchmark_model_response": "📝 Model response: {response_snippet}...",
        "benchmark_score": "⭐ Score: {score}/5",
        "benchmark_complete_full": "🚀 Starting full benchmark: {model_name}",
        "benchmark_complete": "✅ Test complete! Results saved: {output_file}",
        "benchmark_average_score": "📊 Average score: {avg_score}/5"
    },
    "zh_TW": {
        "category_name_reasoning": "推理能力",
        "category_name_coding": "編碼能力",
        "category_name_vision": "視覺語言",
        "category_name_general": "通用語言",
        "category_name_embedding": "嵌入能力",
        "score_simple_reasoning": "基於回應長度的簡單評分（{length} 字元）",
        "score_model_fail": "模型回應失敗",
        "score_judge_fail": "評審失敗: {error}",
        "ollama_not_enabled": "⚠️  Ollama 未啟用，請編輯 config/jade_config.yaml",
        "ollama_api_error": "❌ Ollama API 錯誤: {status_code} - {text}",
        "ollama_connection_fail": "連接失敗: {error}",
        "benchmark_test_category": "🧪 測試 {model_name} - {category_name}",
        "benchmark_model_response": "📝 模型回應: {response_snippet}...",
        "benchmark_score": "⭐ 評分: {score}/5",
        "benchmark_complete_full": "🚀 開始完整基準測試: {model_name}",
        "benchmark_complete": "✅ 測試完成！結果已儲存: {output_file}",
        "benchmark_average_score": "📊 平均分數: {avg_score}/5"
    }
}

def get_localized_string(key, lang_code: str = "en", **kwargs):
    # Use base language code (e.g., 'zh' from 'zh_TW') for primary lookup, then fallback to 'en'
    lang_key = lang_code.replace('-', '_') # Convert 'zh-TW' to 'zh_TW' for dictionary keys
    
    strings = LOCALIZED_STRINGS.get(lang_key)
    if strings is None:
        # Fallback to base language (e.g., 'zh' if 'zh_TW' not found)
        base_lang = lang_code.split('-')[0]
        strings = LOCALIZED_STRINGS.get(base_lang, LOCALIZED_STRINGS["en"])
    
    return strings.get(key, LOCALIZED_STRINGS["en"].get(key, f"MISSING_STRING({key})")).format(**kwargs)


CATEGORIES = {
    'reasoning': {},
    'coding': {},
    'vision': {},
    'general': {}, # Mapped from 'language' in frontend
    'embedding': {}
}

def call_ollama(model: str, prompt: str, config: dict, language: str = "en") -> str:
    """呼叫 Ollama 模型"""
    if not config['ollama']['enabled']:
        print(get_localized_string("ollama_not_enabled", language))
        return get_localized_string("ollama_not_enabled", language)
    
    try:
        response = requests.post(
            f"{config['ollama']['url']}/api/generate",
            json={"model": model, "prompt": prompt, "stream": False},
            timeout=config['ollama']['timeout_seconds']
        )
        if response.status_code == 200:
            return response.json().get('response', '')
        print(get_localized_string("ollama_api_error", language, status_code=response.status_code, text=response.text[:50]))
        return get_localized_string("ollama_api_error", language, status_code=response.status_code, text=response.text[:50])
    except Exception as e:
        return get_localized_string("ollama_connection_fail", language, error=e)

def _call_ollama_judge(model_output: str, category: str, config: dict, language: str = "en") -> dict:
    """使用 Ollama 作為評審 (Helper function for Ollama judging)"""
    standard = standard_loader.get_standard(category, language)
    if not standard:
        raise ValueError(f"Scoring standard not found for category '{category}' and language '{language}'")

    ollama_judge_model = config['ollama_judge']['model']
    judge_prompt_template = standard.ollama_judge_prompt_template or standard.judge_prompt_template
    judge_prompt = judge_prompt_template.replace("{model_output_placeholder}", model_output)

    try:
        response_text = call_ollama(ollama_judge_model, judge_prompt, config, language)
        
        # Extract JSON from markdown code block if present
        json_match = re.search(r'```json\s*(.*?)\s*```', response_text, re.DOTALL)
        if json_match:
            json_str = json_match.group(1)
        else:
            json_str = response_text # Assume it's raw JSON if no markdown block
            
        parsed_response = json.loads(json_str)
        
        main_score = parsed_response.get('score', 0)
        reasoning = parsed_response.get('reasoning', response_text[:200])
        breakdown_from_judge = parsed_response.get('breakdown', {})
        
        breakdown_scores = {}
        for metric in standard.metrics:
            breakdown_scores[metric] = breakdown_from_judge.get(metric, main_score)
        
        return {
            'score': float(main_score),
            'reasoning': reasoning,
            'breakdown': {m: float(breakdown_scores.get(m, 0)) for m in standard.metrics}
        }
    except json.JSONDecodeError as e:
        logger.error(f"Ollama Judge response not valid JSON: {response_text[:200]} Error: {e}")
        return {'score': 0, 'reasoning': get_localized_string("score_judge_fail", language, error=f"JSON parsing error: {e}"), 'breakdown': {m: 0 for m in standard.metrics}}
    except Exception as e:
        logger.error(f"Error during Ollama judging: {e}")
        return {'score': 0, 'reasoning': get_localized_string("score_judge_fail", language, error=e), 'breakdown': {m: 0 for m in standard.metrics}}

def call_llm_judge(model_output: str, category: str, config: dict, language: str = "en") -> dict:
    """使用 LLM 作為評審 (Generic LLM judging function)"""
    
    standard = standard_loader.get_standard(category, language)
    if not standard:
        raise ValueError(f"Scoring standard not found for category '{category}' and language '{language}'")

    category_name = get_localized_string(f"category_name_{category}", language)
    
    gemini_key = config['gemini'].get('api_key')
    gemini_enabled = config['gemini'].get('enabled', False)
    ollama_judge_enabled = config['ollama_judge'].get('enabled', False)

    if gemini_enabled and gemini_key:
        try:
            import google.generativeai as genai
            genai.configure(api_key=gemini_key)
            judge = genai.GenerativeModel('gemini-2.0-flash-exp') # Use configured Gemini model if available from standard
            
            judge_prompt = standard.judge_prompt_template.replace("{model_output_placeholder}", model_output)
            
            response = judge.generate_content(judge_prompt)
            text = response.text
            
            main_score = 0
            breakdown_scores = {}
            
            try:
                parsed_response = json.loads(text)
                main_score = parsed_response.get('score', 0)
                reasoning = parsed_response.get('reasoning', text[:200])
                breakdown_from_judge = parsed_response.get('breakdown', {})
                
                for metric in standard.metrics:
                    breakdown_scores[metric] = breakdown_from_judge.get(metric, main_score)
                
            except json.JSONDecodeError:
                logger.warning(f"Gemini Judge response not valid JSON: {text[:200]}")
                import re
                match = re.search(r'"score"\s*:\s*(\d)', text)
                main_score = int(match.group(1)) if match else 3
                reasoning = text[:200]
                for metric in standard.metrics:
                    breakdown_scores[metric] = main_score
            
            return {
                'score': float(main_score),
                'reasoning': reasoning,
                'breakdown': {m: float(breakdown_scores.get(m, 0)) for m in standard.metrics}
            }
        except Exception as e:
            logger.error(f"Error during Gemini judging: {e}")
            return {'score': 0, 'reasoning': get_localized_string("score_judge_fail", language, error=e), 'breakdown': {m: 0 for m in standard.metrics}}
    elif ollama_judge_enabled:
        return _call_ollama_judge(model_output, category, config, language)
    else:
        # Final fallback to simple scoring
        if "錯誤" in model_output or "失敗" in model_output or "未啟用" in model_output:
            return {'score': 0, 'reasoning': get_localized_string("score_model_fail", language), 'breakdown': {}}
        
        score = 3 if len(model_output) > 50 else 2
        return {
            'score': score,
            'reasoning': get_localized_string("score_simple_reasoning", language, length=len(model_output)),
            'breakdown': {m: score for m in standard.metrics}
        }

def run_benchmark(model_name: str, category: str, config: dict, language: str = "en") -> dict:
    """執行單項基準測試"""
    
    category_name_display = get_localized_string(f"category_name_{category}", language)
    print(get_localized_string("benchmark_test_category", language, model_name=model_name, category_name=category_name_display))
    
    # 呼叫模型
    prompt_obj = prompt_loader.get_prompt(category, language)
    if not prompt_obj:
        raise ValueError(f"Prompt not found for category '{category}' and language '{language}'")
    prompt = prompt_obj.text
    model_output = call_ollama(model_name, prompt, config, language)
    
    print(get_localized_string("benchmark_model_response", language, response_snippet=model_output[:100]))
    
    # LLM 評分
    result = call_llm_judge(model_output, category, config, language)
    
    print(get_localized_string("benchmark_score", language, score=result['score']))
    
    return {
        'model': model_name,
        'category': category,
        'prompt': prompt,
        'output': model_output,
        'score': result['score'],
        'reasoning': result['reasoning'],
        'breakdown': result.get('breakdown', {}),
        'timestamp': datetime.now().isoformat()
    }

def run_full_benchmark(model_name: str, language: str = "en") -> List[dict]:
    """執行完整基準測試"""
    with open("./config/jade_config.yaml", 'r', encoding='utf-8') as f:
        config = yaml.safe_load(f)
    
    print(get_localized_string("benchmark_complete_full", language, model_name=model_name))
    
    results = []
    for category in CATEGORIES.keys():
        result = run_benchmark(model_name, category, config, language)
        results.append(result)
    
    # 儲存結果
    output_file = f"./output/benchmark_{model_name.replace(':', '_')}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(results, f, ensure_ascii=False, indent=2)
    
    print(get_localized_string("benchmark_complete", language, output_file=output_file))
    
    # 顯示摘要
    avg_score = sum(r['score'] for r in results) / len(results)
    print(get_localized_string("benchmark_average_score", language, avg_score=f"{avg_score:.1f}"))
    
    return results

if __name__ == "__main__":
    import sys
    model = sys.argv[1] if len(sys.argv) > 1 else "llama3.2:latest"
    lang = sys.argv[2] if len(sys.argv) > 2 else "en"
    run_full_benchmark(model, lang)
