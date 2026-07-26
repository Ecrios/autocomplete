# 🚀 Text Autocomplete Script (AHK v2)
<img width="397" height="159" alt="image" src="https://github.com/user-attachments/assets/16a159f5-f901-4d9a-8fe7-28c8956af2bc" />

[Читать на русском](README.ru.md) | **English**

$\color{red}{\text{This program was created entirely using AI (Gemini 3.5 Flash, Gemini 3.1 Pro Preview, Gemini 3.6 Flash).}}$

An intelligent text autocompletion script written in **AutoHotkey v2**. It mimics mobile keyboard suggestions, offering word completions, next-word predictions (bigrams), and full phrase suggestions. 
Words and phrases are stored in an automatically generated `dictionary.txt` file located in the script's directory.

![AHK v2](https://img.shields.io/badge/AutoHotkey-v2.0+-green.svg)
![Platform](https://img.shields.io/badge/Platform-Windows-blue.svg)
![License](https://img.shields.io/badge/License-MIT-brightgreen.svg)

---

## ⚡ Available Script Versions

This repository contains **two versions** of the script. You can choose the one that best fits your needs:

| Feature | Version 1 (Secure) | Version 2 (Lightweight) |
| :--- | :---: | :---: |
| **Password Field Detection** |  Yes (Auto) | ❌ No |
| **Privacy Protection** | High (prevents logging secrets) | Manual (via `F12`) |
| **Execution Speed** | Standard | ⚡ Maximum |
| **File I/O Method** | File Rewrite | Optimized (`FileOpen`) |

### Key Differences

1. **Version 1 (Secure / Password Protection):**
   * Includes built-in `IsPasswordField()` detection.
   * **How it works:** Queries Windows API and browser window titles. If you type in a password input field or login form, text capturing is **automatically disabled** to prevent saving sensitive data into `dictionary.txt`.
   * **Best for:** Everyday use on personal/work PCs.

2. **Version 2 (Lightweight / Performance-Focused):**
   * Password detection is completely removed.
   * **How it works:** Doesn't spend system resources checking window controls on every keypress, ensuring maximum responsiveness. Uses optimized file streaming (`FileOpen`) for saving dictionary updates.
   * **Best for:** Fast typing, low-end PCs, or if you prefer manually pausing the script with `F12` when entering sensitive data.

---

## ✨ Features

- **🧠 Self-Learning Dictionary:** Automatically remembers frequent words, word pairs (bigrams), and full sentences.
- **💡 Compact Overlay:** Displays up to 6 suggestions (4 words + 2 phrases) in a non-intrusive bottom-right popup.
- **🔒 Privacy Protection:** *(Version 1 only)* Auto-detects password fields in Windows and web browsers.
- **🔤 Smart Case Adaptation:** Adjusts inserted text casing (UPPERCASE, TitleCase, lowercase) based on your input.
- **🗑️ Quick Suggestion Removal:** Easily delete erroneous words or phrases directly from the overlay.
- **⚙️ Auto-Space Toggle:** Enable/disable automatic space insertion via the System Tray menu.

---

## ⌨️ Hotkeys & Controls

| Key / Shortcut | Action |
| :--- | :--- |
| `1` – `6` | Insert the corresponding suggestion |
| `Enter` | Insert the 1st suggestion (when overlay is active) |
| `Shift` + `1` – `6` | **Delete** the chosen suggestion from the dictionary |
| `Shift` + `Delete` | **Delete** the 1st suggestion from the dictionary |
| `F12` | **Pause / Resume** the script |

---

## 📥 Installation & Usage

### Prerequisites
1. Download and install **[AutoHotkey v2.0](https://www.autohotkey.com/)** or newer.

### Getting Started
1. Download the repository files.
2. Choose your preferred script version.
3. Place the script in a directory with write permissions (where `dictionary.txt` will be created).
4. Run the chosen `.ahk` file by double-clicking it.

---

## 📁 Dictionary File Structure (`dictionary.txt`)

The script automatically manages `dictionary.txt` in the following format:
- **Single words:** `word: frequency`
- **Word transitions (bigrams):** `word1>word2: frequency`
- **Phrases:** `PHRASE>full sentence text: frequency`

---

## ⚙️ Tray Settings

Right-click the script icon in the **System Tray** to:
- Toggle **"Авто-пробел после автозавершения"** (Auto-space after completion).
- Pause or Exit the script.

---

## 📄 License

This project is released under the [MIT License](LICENSE).
