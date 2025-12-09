#!/usr/bin/env python3
"""
配置預設 (Config Presets)
Phase 4: 快速配置模式
"""
import yaml
import shutil

PRESETS = {
    'quick': {
        'ollama': {'model': 'llama3.2:1b', 'timeout_seconds': 15},
        'processing': {'max_concurrent_jobs': 1},
        'output': {'thumbnail_max_size': 400}
    },
    'cpu': {
        'ollama': {'model': 'llama3.2:3b', 'timeout_seconds': 30},
        'processing': {'max_concurrent_jobs': 2},
        'output': {'thumbnail_max_size': 800}
    },
    'gpu': {
        'ollama': {'model': 'llama3.2-vision:latest', 'timeout_seconds': 30},
        'processing': {'max_concurrent_jobs': 4},
        'output': {'thumbnail_max_size': 1200}
    }
}

def apply_preset(preset_name):
    """套用預設配置"""
    if preset_name not in PRESETS:
        print(f"❌ 無效預設: {preset_name}")
        print(f"可用預設: {', '.join(PRESETS.keys())}")
        return
    
    config_path = "./config/jade_config.yaml"
    backup_path = "./config/jade_config.yaml.backup"
    
    # 備份
    shutil.copy(config_path, backup_path)
    
    # 載入並更新
    with open(config_path, 'r', encoding='utf-8') as f:
        config = yaml.safe_load(f)
    
    preset = PRESETS[preset_name]
    for section, values in preset.items():
        if section in config:
            config[section].update(values)
    
    with open(config_path, 'w', encoding='utf-8') as f:
        yaml.dump(config, f, allow_unicode=True)
    
    print(f"✅ 已套用 '{preset_name}' 預設")
    print(f"📋 備份: {backup_path}")

if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1:
        apply_preset(sys.argv[1])
    else:
        print("使用方式: python config_presets.py [quick|cpu|gpu]")
