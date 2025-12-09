#!/usr/bin/env python3
"""
一鍵設定腳本 (One-Click Setup Script)
用途：自動完成 Phase 0 所有初始化步驟
"""
import os
import sys
import subprocess
from pathlib import Path

def print_header(text):
    """列印標題"""
    print(f"\n{'='*60}")
    print(f"  {text}")
    print(f"{'='*60}\n")

def check_python_version():
    """檢查 Python 版本"""
    if sys.version_info < (3, 8):
        print("❌ 需要 Python 3.8 或更高版本")
        return False
    print(f"✅ Python 版本: {sys.version.split()[0]}")
    return True

def install_dependencies():
    """安裝依賴"""
    print("📦 安裝 Python 依賴...")
    try:
        subprocess.run([sys.executable, "-m", "pip", "install", "-r", "requirements.txt"], 
                      check=True, capture_output=True)
        print("✅ 依賴安裝成功")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ 依賴安裝失敗: {e}")
        return False

def validate_config():
    """驗證配置"""
    print("🔍 驗證配置檔案...")
    try:
        result = subprocess.run([sys.executable, "validate_config.py"], 
                              capture_output=True, text=True)
        print(result.stdout)
        return result.returncode == 0
    except Exception as e:
        print(f"❌ 配置驗證失敗: {e}")
        return False

def init_database():
    """初始化資料庫"""
    print("🗄️  初始化資料庫...")
    try:
        result = subprocess.run([sys.executable, "init_db.py"], 
                              capture_output=True, text=True, input="y\n")
        print(result.stdout)
        return "初始化成功" in result.stdout or "已存在" in result.stdout
    except Exception as e:
        print(f"❌ 資料庫初始化失敗: {e}")
        return False

def verify_structure():
    """驗證目錄結構"""
    print("📁 驗證目錄結構...")
    required_dirs = ['input', 'output', 'templates', 'db', 'logs', 'temp', 'tests', 'config']
    all_exist = True
    
    for dir_name in required_dirs:
        if Path(dir_name).exists():
            print(f"  ✅ {dir_name}/")
        else:
            print(f"  ❌ {dir_name}/ (缺少)")
            all_exist = False
    
    return all_exist

def print_next_steps():
    """列印下一步指示"""
    print_header("🎉 設定完成！")
    print("✅ Phase 0 初始化成功完成\n")
    print("📋 下一步操作：\n")
    print("1. 放置測試圖像到 input/ 資料夾")
    print("2. (選用) 啟動 Ollama 服務：ollama serve")
    print("3. (選用) 編輯配置：config/jade_config.yaml")
    print("4. 啟動 UI：cd ../ollama-benchmark-pipeline-ui && npm run dev\n")
    print("📚 查看文件：")
    print("  - README.md (後端指南)")
    print("  - ../QUICK_START.zh-TW.md (快速開始)")
    print("  - PHASE_0_CHECKLIST.md (檢查清單)\n")

def main():
    """主函式"""
    print_header("🚀 Ollama 基準測試管道 - 自動設定")
    
    # 檢查 Python 版本
    if not check_python_version():
        sys.exit(1)
    
    # 安裝依賴
    if not install_dependencies():
        print("\n⚠️  依賴安裝失敗，但可以繼續...")
    
    # 驗證配置
    if not validate_config():
        print("\n❌ 配置驗證失敗，請檢查 config/jade_config.yaml")
        sys.exit(1)
    
    # 初始化資料庫
    if not init_database():
        print("\n❌ 資料庫初始化失敗")
        sys.exit(1)
    
    # 驗證目錄結構
    if not verify_structure():
        print("\n⚠️  部分目錄缺少，但核心功能可用")
    
    # 列印下一步
    print_next_steps()

if __name__ == "__main__":
    main()
