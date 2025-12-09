#!/usr/bin/env python3
"""
批次基準測試 (Batch Benchmarking)
測試多個模型並生成比較報告
"""
import json
from benchmark import run_full_benchmark
from datetime import datetime

# 從 my_ollama_llms.txt 推薦的模型
RECOMMENDED_MODELS = {
    'reasoning': 'deepseek-r1:32b',
    'coding': 'qwen2.5-coder:latest',
    'vision': 'llama3.2-vision:latest',
    'general': 'llama3.2:latest',
    'embedding': 'nomic-embed-text:v1.5'
}

def run_batch_benchmark():
    """批次測試推薦模型"""
    print("🚀 批次基準測試開始\n")
    
    all_results = {}
    
    for category, model in RECOMMENDED_MODELS.items():
        print(f"\n{'='*60}")
        print(f"測試類別: {category} | 模型: {model}")
        print('='*60)
        
        try:
            results = run_full_benchmark(model)
            all_results[model] = results
        except Exception as e:
            print(f"❌ 測試失敗: {e}")
    
    # 生成比較報告
    report_file = f"./output/benchmark_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
    with open(report_file, 'w', encoding='utf-8') as f:
        json.dump(all_results, f, ensure_ascii=False, indent=2)
    
    print(f"\n✅ 批次測試完成！報告: {report_file}")

if __name__ == "__main__":
    run_batch_benchmark()
