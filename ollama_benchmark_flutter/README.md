# Ollama Benchmark & Pipeline Flutter UI

This is a unified Flutter application that combines the **Benchmark Suite** and **Pipeline UI** into a single, user-friendly desktop application.

## 🚀 Features

- **Unified Dashboard**: Switch between Benchmark and Pipeline views seamlessly.
- **Benchmark Suite**: 
  - Run LLM capability tests (Reasoning, Coding, Vision, etc.).
  - Visualize results with Radar Charts.
  - Simulated test runner for UI demonstration.
- **Pipeline UI**:
  - Monitor image processing status (Pending, Approved, Rejected).
  - View system health and statistics.
  - Manage the review queue.
  - Configure system settings (Ollama URL, Gemini Fallback).
- **Telemetry**: Built-in tracking for debugging and usage analysis (logs to console in debug mode).

## 🛠️ Prerequisites

- **Flutter SDK**: [Install Flutter](https://flutter.dev/docs/get-started/install)
- **Ollama**: Ensure Ollama is running locally (`ollama serve`).

## 🏃‍♂️ How to Run

1.  **Install Dependencies**:
    ```bash
    flutter pub get
    ```

2.  **Run the App**:
    ```bash
    flutter run -d windows
    # or macos, linux
    ```

## 🧩 Project Structure

- `lib/main.dart`: Entry point and Main Navigation.
- `lib/core/telemetry.dart`: Telemetry service.
- `lib/features/benchmark`: UI for LLM benchmarking.
- `lib/features/pipeline`: UI for image processing pipeline.

## 🎨 Design Principles

- **User-Friendly**: Simple navigation, clear visual feedback.
- **Safe Defaults**: Pre-configured for local Ollama (`http://localhost:11434`) and Traditional Chinese (zh-TW).
- **Telemetry**: Tracks navigation and key actions for debugging.
