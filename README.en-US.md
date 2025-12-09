# 🎉 LLM Arena Blind Test Arena - Project Completed!

> **User-Friendly LLM Benchmarking and Image Processing Automation System**
> Traditional Chinese First | Safe Defaults | Minimal Setup Steps

---

## 📋 Project Overview

This project provides a complete solution for LLM Arena Blind Test Arena, including:

### 🎯 Core Features
- **LLM Capability Assessment** - 5 major dimensions (Reasoning, Coding, Vision-Language, General Language, Embedding)
- **Image Processing Pipeline** - Automated description generation, object detection, review workflow
- **Multi-Model Support** - Ollama local models + Gemini cloud fallback (with retry logic)
- **Review System** - Human review queue, approve/reject workflow
- **Model Management** - One-click pull, delete Ollama models
- **Data Analysis** - Historical trends, report export, side-by-side model comparison
- **Telemetry Dashboard** - Real-time monitoring of application status
- **Auto-Update Mechanism** - Checks for and prompts application updates
- **Blind Test Arena** - Conduct A/B blind tests for models

### ✨ Design Highlights
- ✅ **Traditional Chinese First** - UI, documentation, error messages fully localized in Traditional Chinese
- ✅ **Safe Defaults** - Ollama offline, SQLite local, no cloud services required
- ✅ **3-Minute Setup** - One-click initialization, minimal configuration steps
- ✅ **User-Friendly** - Clear feedback, intuitive interface, detailed documentation
- ✅ **Flutter Desktop Application** - Integrates all features into a single desktop UI

---

## 🏗️ Project Architecture

```
📦 Benchmarking_Ollama_Models
├── 📱 llm_arena_blind_test_arena/        # Integrated Desktop Application (Flutter UI)
└── 🔧 backend/                         # Backend Processing System (Python FastAPI)
```

**Detailed Architecture:** See [PROJECT_STRUCTURE.md](./PROJECT_STRUCTURE.md)

---

## ⚡ Quick Start (3 Steps)

### Step 1: Clone the Project
```bash
git clone [PROJECT_REPOSITORY_URL]
cd Benchmarking_Ollama_Models/
```

### Step 2: One-Click Backend Setup and Launch

1.  **Activate Python Virtual Environment** (if not already):
    ```bash
    cd backend
    python -m venv .venv312
    # Windows
    .\.venv312\Scripts\activate.bat
    # Linux/macOS
    source ./.venv312/bin/activate
    ```
2.  **Install Backend Dependencies and Initialize Database**:
    ```bash
    pip install -r requirements.txt
    python init_db.py
    ```
3.  **Launch FastAPI Backend Service**:
    ```bash
    python api_server.py
    ```

### Step 3: Launch Flutter Desktop Application

1.  **Install Flutter Dependencies**:
    ```bash
    cd ../llm_arena_blind_test_arena
    flutter pub get
    ```
2.  **Launch Flutter UI**:
    ```bash
    flutter run -d windows # Or macos, linux, chrome, edge
    ```

**Done!** 🎉

**Detailed Guide:** See [QUICK_START.zh-TW.md](./QUICK_START.zh-TW.md)

---

## 📚 Documentation Navigation

### 🎯 For Users
| Document | Purpose |
|------|------|
| [QUICK_START.zh-TW.md](./QUICK_START.zh-TW.md) | Quick Start Guide |

### 👨‍💻 For Developers
| Document | Purpose |
|------|------|
| [backend/README.md](./backend/README.md) | Backend Development Guide |

### 🔬 For Researchers
| Document | Purpose |
|------|------|
| (No public documents available for researchers currently) | (Please refer to the codebase for research) |

---

## 🛠️ Development Phase Progress - **Project Completed!**

| Phase | Status | Feature Overview |
|-------|------|------------------|
| **Phase 0** | ✅ Completed | Project Initialization, Basic Configuration, and Database Architecture |
| **Phase 1** | ✅ Completed | Backend Image Processing Pipeline MVP |
| **Phase 2** | ✅ Completed | Interactive UI MVP (Integrated Dashboard, Basic Settings, Daemon Control) |
| **Phase 3** | ✅ Completed | Model Management, Ollama/Gemini Fallback & Retry Mechanism, Human Review |
| **Phase 4** | ✅ Completed | Benchmark History Analysis, Report Export, Custom Datasets, Side-by-Side Model Comparison |
| **Phase 5** | ✅ Completed | Telemetry Dashboard, Packaging & Distribution, Auto-Update Check, Blind Test System |

---

## 🔧 Technology Stack

### Backend (Python FastAPI)
- **Language:** Python 3.12+
- **Framework:** FastAPI
- **Server:** Uvicorn
- **Database:** SQLite 3 (Persistent Data)
- **Dependency Management:** pip (requirements.txt)
- **Packaging:** PyInstaller (for distribution)

### Frontend (Flutter)
- **Framework:** Flutter 3.x
- **Language:** Dart 3.x
- **State Management:** Riverpod
- **Charts:** `fl_chart`
- **File Operations:** `file_saver`, `file_picker`
- **API Communication:** `http`

---

## 🔐 Configuration Instructions

### Safe Defaults
- Ollama: Offline (manual activation required)
- Gemini: Offline (manual activation and API Key required)
- Language: Traditional Chinese (zh-TW)
- Database: SQLite local
- Auto-Approval: 0.85 threshold (conservative strategy)
- Input Directory: `input/` (relative path from project root)

**Full Configuration Details:** See [backend/README.md](./backend/README.md)

---

## 🆘 Troubleshooting

**Q: FastAPI or Flutter fails to start?**
A: Please check if your virtual environment is activated, all dependencies are installed, and both backend and frontend have been restarted to load the latest changes.

**Full Troubleshooting:** See [QUICK_START.zh-TW.md](./QUICK_START.zh-TW.md#疑難排解)

---

## 🤝 Contribution Guide

All contributions are welcome! Please follow this process:
1.  **Familiarize yourself with the project:** (Please refer to the codebase for research).
2.  **Set up the environment:** Follow [QUICK_START.zh-TW.md](./QUICK_START.zh-TW.md) to set up your development environment.
3.  **Follow best practices:** Refer to existing code styles and maintain clear commit messages.
4.  **Submit changes:** Submit Pull Requests to the `develop` branch.

---

## 📄 License

This project is licensed under the MIT License.

---

## 🌟 Acknowledgements

Thanks to all contributors for their support and dedication to this project!

---

**Last Updated:** Project Completed!
**Maintainer:** Jones Chung
**Contact:** jones.developer.chung@gmail.com
