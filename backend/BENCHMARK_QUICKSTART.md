# 🚀 基準測試快速修正指南

## ❌ 問題：評分 0/5

您看到的錯誤是因為：
1. Ollama 未啟用（預設離線）
2. Gemini API Key 未設定

---

## ✅ 解決方案

### 步驟 1: 啟用 Ollama
編輯 `config/jade_config.yaml`：

```yaml
ollama:
  enabled: true  # 改為 true
  url: "http://localhost:11434"
  model: "llama3.2:latest"
```

### 步驟 2: 確認 Ollama 執行中
```bash
# 啟動 Ollama
ollama serve

# 測試連接
curl http://localhost:11434/api/tags
```

### 步驟 3: (選用) 設定 Gemini 評審
```yaml
gemini:
  enabled: true
  api_key: "YOUR_GEMINI_API_KEY"
```

**不設定 Gemini：** 系統會使用簡單評分（基於回應長度）

---

## 🧪 重新測試

```bash
# 測試單一模型
python benchmark.py llama3.2:latest

# 測試推薦模型
python benchmark.py deepseek-r1:32b
python benchmark.py qwen2.5-coder:latest
python benchmark.py llama3.2-vision:latest
```

---

## 📊 預期輸出

### 有 Ollama + 無 Gemini
```
🧪 測試 llama3.2:latest - 推理能力
📝 模型回應: A > C，因為傳遞性...
⭐ 評分: 3/5  # 簡單評分
```

### 有 Ollama + 有 Gemini
```
🧪 測試 llama3.2:latest - 推理能力
📝 模型回應: A > C，因為傳遞性...
⭐ 評分: 4/5  # Gemini 評審
```

---

## 🔧 疑難排解

### Q: Ollama 連接失敗？
```bash
# 檢查 Ollama 狀態
ollama list

# 確認模型已下載
ollama pull llama3.2:latest
```

### Q: 想跳過 Gemini 評審？
不需要設定，系統會自動使用簡單評分。

### Q: 如何批次測試？
```bash
python benchmark_batch.py
```

---

## 📈 推薦測試順序

1. **輕量測試**
   ```bash
   python benchmark.py llama3.2:1b
   ```

2. **標準測試**
   ```bash
   python benchmark.py llama3.2:latest
   ```

3. **完整測試**
   ```bash
   python benchmark_batch.py
   ```

---

**修正後重新執行即可！** 🎉
