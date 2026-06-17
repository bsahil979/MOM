# MoM Generator - Technical & Development Report

A cross-platform mobile and desktop application developed in Flutter and Dart to capture, transcribe, and structure meeting discussions into professional **Minutes of Meeting (MoM)** documents using artificial intelligence.

---

## 1. Project Overview

The **MoM Generator** app streamlines the post-meeting documentation process. Instead of manually writing minutes, attendees can record live discussions or upload audio files. The app transcribes the audio and uses Google Gemini to generate structured executive summaries, extract participants, flag key decisions, and compile action items with assignees and due dates.

---

## 2. Core Features

### 🎙️ Live Recording & Dictation
- Captures microphone audio streams natively.
- Performs real-time speech-to-text dictation on-screen.
- Visualizes audio input with a dynamic, amplitude-reactive waveform canvas.
- Saves audio locally in `.m4a` format.

### 📁 Pre-Recorded Audio File Upload
- Integrates native file picker supporting `.mp3`, `.wav`, `.m4a`, `.mp4`, and `.aac` audio files.
- Batch transcribes audio files using Gemini 1.5 Flash multimodal capabilities or external backend endpoints.

### 📝 Interactive MoM Editor & Review Screen
- Review raw transcripts before generating structured MoM documents.
- Displays structured MoM components (Summary, Participants, Decisions, and Action Items) in a sleek interface.
- Provides complete inline editing of generated summaries, items, assignees, and dates.

### 🎨 Material 3 Obsidian/Alabaster Themes
- **Dark Mode (Obsidian & Chalk)**: Designed with a pure black background (`#000000`), dark charcoal cards (`#121212`), and subtle industrial borders (`#262626`).
- **Light Mode (Alabaster & Charcoal)**: Sleek slate grey background (`#F2F2F7`) paired with solid white cards and black typography.
- Uses premium typography from Google Fonts: **Outfit** for titles/headers and **Inter** for readable body text.

### 📋 Sharing & Exporting
- Copies generated markdown summaries directly to the system clipboard.
- Exports meetings as formatted Markdown files.
- Launches system sharing protocols (email client drafts, etc.) via `url_launcher`.

---

## 3. Technology Stack & Packages

| Category | Technology / Library | Description |
| :--- | :--- | :--- |
| **Framework** | **Flutter (Dart)** | Core UI framework for native cross-platform deployment. |
| **State Management** | **Provider** | Manages application state, theme states, settings, and audio recording variables. |
| **AI Integration** | **google_generative_ai** | Official Google SDK for Gemini integration. |
| **Speech-to-Text** | **speech_to_text** | On-device native speech recognition engine. |
| **Audio Capture** | **record** | Native microphone recording and file compression. |
| **File Picker** | **file_picker** | Picks audio files from local mobile/computer storage. |
| **Local Storage** | **shared_preferences** | Persists local settings (API keys, theme modes, backend URLs) and meeting lists. |
| **Paths & Directories** | **path_provider** | Resolves local device document paths for audio recording storage. |
| **Permissions** | **permission_handler** | Requests and handles runtime hardware permissions (microphone). |
| **Design** | **google_fonts** | Dynamically loads custom, premium typography. |

---

## 4. Architecture & Integration Modes

The app implements a flexible architecture allowing users to select three distinct integration modes in **Settings**:

### A. Direct Gemini API Mode
- Integrates the **`gemini-1.5-flash`** model directly in the app.
- For MoM generation, uses `GenerationConfig(responseMimeType: 'application/json')` to enforce structured JSON output matching the Dart models.
- For file uploads, utilizes `DataPart` to upload local binary bytes of picked audio files directly to Gemini for transcription.

### B. Custom Team Backend Mode
- Routes requests to a dedicated team API server (configured via base URL).
- Calls `POST /transcribe` (multipart upload) to transcribe audio files.
- Calls `POST /generate-mom` (JSON payload containing transcript text) to format and structure the minutes.

### C. Simulation / Demo Mode
- Allows testing the full capabilities of the user interface offline.
- Features pre-seeded meeting templates (Project Aurora, Sprint Planning, etc.) and simulates transcriptions with realistic loading phases.

---

## 5. Development Metrics

- **Total Hours Worked**: `25 Hours`
- **Key Refactoring & Debugging Completed**:
  - Resolved `Unsupported operation: Cannot remove from a fixed-length list` error on the audio waveform visualizer by switching to growable lists.
  - Fixed a `RenderFlex` horizontal layout overflow in the Help Dialog title by wrapping it in an `Expanded` widget.
  - Migrated `file_picker` to version 11.0.0+ static methods (`FilePicker.pickFiles`).
  - Added support for mobile and desktop responsive views.
