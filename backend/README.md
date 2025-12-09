# 🚀 Ollama 基準測試管道 - 後端系統

## 📋 Phase 0: 專案架構與安全預設值

### ✅ 已完成項目

- [x] 目錄結構建立 (`input/`, `output/`, `templates/`, `db/`, `logs/`)
- [x] 安全預設配置檔案 (`jade_config.yaml`)
- [x] 資料庫 Schema 設計 (`schema.sql`)
- [x] 資料庫初始化腳本 (`init_db.py`)
- [x] 配置驗證工具 (`validate_config.py`)
- [x] 繁體中文描述模板

---

## 🛠️ 快速開始 (3 步驟)

### 步驟 1: 安裝依賴
```bash
pip install pyyaml
```

### 步驟 2: 初始化資料庫
```bash
cd backend
python init_db.py
```

### 步驟 3: 驗證配置
```bash
python validate_config.py
```

---

## 📁 目錄結構

```
backend/
├── config/
│   └── jade_config.yaml      # 主配置檔案（繁體中文註解）
├── db/
│   ├── schema.sql            # 資料庫結構定義
│   └── pipeline.db           # SQLite 資料庫（執行後生成）
├── input/                    # 輸入資料夾（放置待處理圖像）
├── output/                   # 輸出資料夾（處理完成的結果）
│   └── _failed/              # 失敗項目隔離區
├── templates/
│   └── description.zh-TW.md  # 繁體中文描述模板
├── logs/                     # 系統日誌
├── temp/                     # 暫存檔案
├── tests/                    # 測試腳本
├── init_db.py                # 資料庫初始化
├── validate_config.py        # 配置驗證工具
└── README.md                 # 本文件
```

---

## ⚙️ 配置說明

### 安全預設值
- ✅ **語言：** 繁體中文 (zh-TW)
- ✅ **資料庫：** SQLite 本地儲存
- ✅ **Ollama：** 預設離線（需手動啟用）
- ✅ **Gemini：** 預設關閉（需手動設定 API Key）

### 修改配置
編輯 `config/jade_config.yaml`：

```yaml
ollama:
  enabled: true  # 啟用 Ollama
  url: "http://localhost:11434"
  model: "llama3.2-vision"

gemini:
  enabled: true  # 啟用 Gemini 備援
  api_key: "YOUR_API_KEY_HERE"
```

---

## 🧪 驗證檢查清單

### Phase 0 驗收標準
- [ ] 配置檔案驗證通過 (`validate_config.py`)
- [ ] 資料庫初始化成功 (`init_db.py`)
- [ ] 所有目錄正確建立
- [ ] 模板檔案可正常載入
- [ ] 無權限錯誤

### 測試指令
```bash
# 驗證配置
python validate_config.py

# 檢查資料庫
sqlite3 db/pipeline.db ".tables"

# 檢查目錄
dir input output templates db logs
```

---

## 🔄 下一步：Phase 1

Phase 1 將實作：
- 單次執行管道 (MVP)
- 圖像掃描與處理
- BLIP + Ollama 整合
- 輸出生成（描述、元數據、縮圖）

---

## 📞 疑難排解

### 問題：資料庫初始化失敗
**解決方案：** 確認 `db/` 目錄存在且有寫入權限

### 問題：配置驗證失敗
**解決方案：** 檢查 YAML 語法，確保縮排正確

### 問題：找不到模板
**解決方案：** 確認 `templates/` 目錄存在且包含 `description.zh-TW.md`

---

## 📄 授權

本專案遵循 MIT 授權條款
