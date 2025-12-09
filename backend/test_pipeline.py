#!/usr/bin/env python3
"""
管道測試腳本 (Pipeline Test Script)
"""
import os
from pathlib import Path
from PIL import Image

def create_test_image():
    """建立測試圖像"""
    input_dir = Path("./input")
    input_dir.mkdir(exist_ok=True)
    
    # 建立簡單測試圖像
    img = Image.new('RGB', (800, 600), color='blue')
    test_path = input_dir / "test_image.jpg"
    img.save(test_path)
    
    print(f"✅ 已建立測試圖像: {test_path}")
    return test_path

def verify_output():
    """驗證輸出"""
    output_dir = Path("./output/test_image")
    
    checks = {
        'description.zh-TW.md': output_dir / "description.zh-TW.md",
        'metadata.json': output_dir / "metadata.json",
        'thumbnail.jpg': output_dir / "thumbnail.jpg"
    }
    
    print("\n🔍 驗證輸出：")
    all_ok = True
    for name, path in checks.items():
        if path.exists():
            print(f"  ✅ {name}")
        else:
            print(f"  ❌ {name} (缺少)")
            all_ok = False
    
    return all_ok

if __name__ == "__main__":
    print("🧪 Phase 1 管道測試\n")
    
    # 建立測試圖像
    create_test_image()
    
    print("\n▶️  執行管道...")
    print("請執行: python pipeline.py\n")
    
    input("按 Enter 驗證輸出...")
    
    if verify_output():
        print("\n🎉 測試通過！")
    else:
        print("\n❌ 測試失敗，請檢查輸出")
