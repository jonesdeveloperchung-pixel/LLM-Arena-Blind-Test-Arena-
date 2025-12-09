#!/usr/bin/env python3
"""
配置驗證工具 (Configuration Validator)
用途：驗證 jade_config.yaml 的正確性
"""
import yaml
from pathlib import Path
from typing import Dict, List, Tuple

def validate_config(config_path: str = "./config/jade_config.yaml") -> Tuple[bool, List[str]]:
    """驗證配置檔案"""
    errors = []
    
    if not Path(config_path).exists():
        return False, [f"❌ 配置檔案不存在: {config_path}"]
    
    try:
        with open(config_path, 'r', encoding='utf-8') as f:
            config = yaml.safe_load(f)
    except Exception as e:
        return False, [f"❌ YAML 解析失敗: {e}"]
    
    # 必要欄位檢查
    required_sections = ['system', 'paths', 'database', 'ollama', 'processing', 'output']
    for section in required_sections:
        if section not in config:
            errors.append(f"❌ 缺少必要區段: {section}")
    
    # 路徑驗證
    if 'paths' in config:
        for key, path in config['paths'].items():
            if key != 'database':
                Path(path).mkdir(parents=True, exist_ok=True)
    
    # 語言驗證
    if config.get('system', {}).get('language') not in ['zh-TW', 'en', 'zh-CN']:
        errors.append("⚠️  不支援的語言設定")
    
    # 資料庫類型驗證
    if config.get('database', {}).get('type') != 'sqlite':
        errors.append("⚠️  目前僅支援 SQLite")
    
    if errors:
        return False, errors
    
    return True, ["✅ 配置驗證通過"]

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="驗證配置檔案")
    parser.add_argument("--config-path", type=str, default="./config/jade_config.yaml",
                        help="要驗證的配置檔案路徑")
    args = parser.parse_args()

    is_valid, messages = validate_config(args.config_path)
    for msg in messages:
        print(msg)
    exit(0 if is_valid else 1)
