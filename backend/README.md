## 🛠️ 快速開始 (3 步驟)

### 步驟 1: 安裝依賴
```bash
pip install -r requirements.txt
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
