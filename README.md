# 🎉 LLM Arena 盲測競技場 - 專案已完成!

> **使用者友善的 LLM 基準測試與圖像處理自動化系統**  
> 繁體中文優先 | 安全預設值 | 最小化設定步驟

---

## 📋 專案概覽

本專案提供完整的 LLM Arena 盲測競技場 解決方案，包含：

### 🎯 核心功能
- **LLM 能力評測** - 5 大維度評測（推理、編碼、視覺語言、通用語言、嵌入）
- **圖像處理管道** - 自動描述生成、物件偵測、審核工作流程
- **多模型支援** - Ollama 本地模型 + Gemini 雲端備援 (含重試邏輯)
- **審核系統** - 人工審核隊列、批准/拒絕工作流程
- **模型管理** - 一鍵拉取、刪除 Ollama 模型
- **數據分析** - 歷史趨勢圖、報告匯出、模型側邊比較
- **遙測儀表板** - 即時監控應用程式運行狀態
- **自動更新機制** - 檢查並提示應用程式更新
- **盲測競技場** - 進行模型 A/B 盲測比較

### ✨ 設計特色
- ✅ **繁體中文優先** - UI、文件、錯誤訊息全面中文化
- ✅ **安全預設值** - Ollama 離線、SQLite 本地、無需雲端服務
- ✅ **3 分鐘設定** - 一鍵初始化、最小化配置步驟
- ✅ **使用者友善** - 清晰回饋、直觀介面、詳細文件
- ✅ **Flutter 桌面應用程式** - 整合所有功能於單一桌面 UI

---

## 🏗️ 專案架構

```
📦 Benchmarking_Ollama_Models
├── 📱 llm_arena_blind_test_arena/        # 整合桌面應用程式 (Flutter UI)
└── 🔧 backend/                         # 後端處理系統 (Python FastAPI)
```

**詳細架構：** 查看 [PROJECT_STRUCTURE.md](./PROJECT_STRUCTURE.md)

---

## ⚡ 快速開始（3 步驟）

### 步驟 1: 克隆專案
```bash
git clone [專案儲存庫 URL]
cd Benchmarking_Ollama_Models/
```

### 步驟 2: 一鍵設定與啟動後端

1.  **啟用 Python 虛擬環境** (若尚未):
    ```bash
    cd backend
    python -m venv .venv312
    # Windows
    .\.venv312\Scripts\activate.bat
    # Linux/macOS
    source ./.venv312/bin/activate
    ```
2.  **安裝後端依賴並初始化資料庫**:
    ```bash
    pip install -r requirements.txt
    python init_db.py
    ```
3.  **啟動 FastAPI 後端服務**:
    ```bash
    python api_server.py
    ```

### 步驟 3: 啟動 Flutter 桌面應用程式

1.  **安裝 Flutter 依賴**:
    ```bash
    cd ../llm_arena_blind_test_arena
    flutter pub get
    ```
2.  **啟動 Flutter UI**:
    ```bash
    flutter run -d windows # 或 macos, linux, chrome, edge
    ```

**完成！** 🎉 

**詳細指南：** 查看 [QUICK_START.zh-TW.md](./QUICK_START.zh-TW.md)

---

## 📚 文件導覽

### 🎯 給使用者
| 文件 | 用途 |
|------|------|
| [QUICK_START.zh-TW.md](./QUICK_START.zh-TW.md) | 快速上手指南 |

### 👨‍💻 給開發者
| 文件 | 用途 |
|------|------|
| [backend/README.md](./backend/README.md) | 後端開發指南 |

### 🔬 給研究者
| 文件 | 用途 |
|------|------|
| (目前沒有專為研究者提供的公開文件) | (請參考程式碼庫進行研究) |

---

## 📸 螢幕截圖

| 螢幕截圖 1 | 螢幕截圖 2 | 螢幕截圖 3 |
|---|---|---|
| ![螢幕截圖 1](https://github.com/jonesdeveloperchung-pixel/LLM-Arena-Blind-Test-Arena-/blob/main/screens/screenshot-1.png) | ![螢幕截圖 2](https://github.com/jonesdeveloperchung-pixel/LLM-Arena-Blind-Test-Arena-/blob/main/screens/screenshot-2.png) | ![螢幕截圖 3](https://github.com/jonesdeveloperchung-pixel/LLM-Arena-Blind-Test-Arena-/blob/main/screens/screenshot-3.png) |

---

## 🛠️ 開發階段進度 - **專案已完成!**

| Phase | 狀態 | 功能概覽 |
|-------|------|----------|
| **Phase 0** | ✅ 完成 | 專案初始化、基礎配置與資料庫架構 |
| **Phase 1** | ✅ 完成 | 後端圖像處理管道 MVP |
| **Phase 2** | ✅ 完成 | 互動式 UI MVP (整合儀表板、基本設定、守護進程控制) |
| **Phase 3** | ✅ 完成 | 模型管理、Ollama/Gemini 備援與重試機制、人工審核 |
| **Phase 4** | ✅ 完成 | 基準測試歷史分析、報告匯出、自定義數據集、模型側邊比較 |
| **Phase 5** | ✅ 完成 | 遙測儀表板、打包發佈文件、自動更新檢查、盲測系統 |

---

## 🔧 技術棧

### 後端 (Python FastAPI)
- **語言：** Python 3.12+
- **框架：** FastAPI
- **伺服器：** Uvicorn
- **資料庫：** SQLite 3 (持久化數據)
- **依賴管理：** pip (requirements.txt)
- **打包：** PyInstaller (用於發佈)

### 前端 (Flutter)
- **框架：** Flutter 3.x
- **語言：** Dart 3.x
- **狀態管理：** Riverpod
- **圖表：** `fl_chart`
- **文件操作：** `file_saver`, `file_picker`
- **API 通訊：** `http`

---

## 🔐 配置說明

### 安全預設值
- Ollama: 離線 (需手動啟用)
- Gemini: 離線 (需手動啟用並提供 API Key)
- 語言: 繁體中文 (zh-TW)
- 資料庫: SQLite 本地
- 自動批准: 0.85 閾值 (保守策略)
- 輸入目錄: `input/` (專案根目錄下的相對路徑)

**完整配置說明：** 查看 [backend/README.md](./backend/README.md)

---

## 🆘 疑難排解

**Q: FastAPI 或 Flutter 啟動失敗？**  
A: 請檢查您的虛擬環境是否已激活，所有依賴是否已安裝，且後端與前端是否已重啟以載入最新變更。

**完整疑難排解：** 查看 [QUICK_START.zh-TW.md](./QUICK_START.zh-TW.md#疑難排解)

---

## 🤝 貢獻指南

歡迎所有貢獻！請遵循以下流程：
1.  **熟悉專案：** (請參考程式碼庫進行研究)。
2.  **環境設定：** 依照 [QUICK_START.zh-TW.md](./QUICK_START.zh-TW.md) 設置開發環境。
3.  **遵循規範：** 參考現有程式碼風格，保持提交訊息清晰。
4.  **提交變更：** 提交 Pull Request 至 `develop` 分支。

---

## 📄 授權

本專案遵循 MIT 授權條款

---

## 🌟 致謝

感謝所有貢獻者對本專案的支持與付出！

---

**最後更新：** 專案已完成！
**維護者：** Jones Chung
**聯絡方式：** jones.developer.chung@gmail.com
