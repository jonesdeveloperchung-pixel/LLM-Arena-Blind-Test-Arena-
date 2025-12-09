# 圖像描述 (Image Description)

**檔案名稱：** {{filename}}  
**處理時間：** {{timestamp}}  
**來源模型：** {{source}}  
**信心分數：** {{confidence}}

---

## 📝 自動生成描述

{{description}}

---

## 🔍 偵測物件

{{#each objects}}
- **{{label}}** (信心度: {{confidence}})
  - 位置: [{{box_2d}}]
{{/each}}

---

## 📊 元數據

- **尺寸：** {{width}} × {{height}}
- **相機型號：** {{camera_model}}
- **ISO：** {{iso}}

---

*此描述由 Ollama 基準測試管道自動生成*
