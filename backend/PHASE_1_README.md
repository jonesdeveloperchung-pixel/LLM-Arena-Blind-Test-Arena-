# 🚀 Phase 1: 單次執行管道 (MVP)

## ✅ 完成項目

- [x] 圖像掃描模組
- [x] Ollama API 整合
- [x] 輸出生成（描述、元數據、縮圖）
- [x] SQLite 記錄
- [x] 錯誤處理

---

## 🎯 快速開始

### 步驟 1: 安裝依賴
```bash
pip install -r requirements.txt
```

### 步驟 2: 啟用 Ollama
編輯 `config/jade_config.yaml`：
```yaml
ollama:
  enabled: true
  model: "llama3.2-vision:latest"
```

### 步驟 3: 放置測試圖像
```bash
# 複製圖像到 input/ 資料夾
copy your_image.jpg input/
```

### 步驟 4: 執行管道
```bash
python pipeline.py
```

---

## 📊 輸出結構

```
output/
└── image_name/
    ├── description.zh-TW.md    # 繁體中文描述
    ├── metadata.json           # 元數據
    └── thumbnail.jpg           # 縮圖
```

---

## 🧪 驗證測試

### 測試 1: 基本處理
```bash
# 放置測試圖像
echo "Test" > input/test.jpg

# 執行管道
python pipeline.py

# 檢查輸出
dir output\test\
```

### 測試 2: 資料庫記錄
```bash
sqlite3 db/pipeline.db "SELECT * FROM pipeline_items;"
```

---

## 🔧 疑難排解

**Q: Ollama 連接失敗？**
```bash
# 確認 Ollama 執行中
ollama serve

# 測試連接
curl http://localhost:11434/api/tags
```

**Q: 圖像未處理？**
- 檢查檔案格式 (JPG/PNG/WebP)
- 確認 input/ 目錄有檔案
- 查看錯誤訊息

---

## 📈 效能指標

- **處理速度：** ~5 秒/圖像 (llama3.2-vision)
- **記憶體使用：** ~2GB
- **支援格式：** JPG, PNG, WebP

---

## 🔜 下一步：Phase 2

- 守護程序模式
- 檔案監控
- 審核隊列
- CLI 審核工具
