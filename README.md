# FnFlow 

> A lightweight macOS menu bar utility that automatically toggles F1–F12 keys between Media Keys and Standard Function Keys based on the active application.

![macOS 14.0+](https://img.shields.io/badge/macOS-14.0%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)
![License MIT](https://img.shields.io/badge/License-MIT-green)

## ✨ Features

- 🔄 **Automatic Switching**: Seamlessly toggles Function Key behavior based on the frontmost app.
- 🎛️ **App-Specific Rules**: Easily bind custom behavior to individual apps or follow global preferences.
- 🎨 **Modern macOS Menu Bar UI**: Sleek Liquid Glass design with quick mode controls directly in the menu bar.
- 🚀 **Launch at Login**: Native ServiceManagement background startup support.

## 💻 Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon (M1/M2/M3/M4) or Intel Mac

## 📦 Installation

1. Download the latest `FnFlow.dmg` from the [Releases](../../releases) section.
2. Drag `FnFlow.app` into your `Applications` folder.
3. Launch `FnFlow` from your Applications folder.

> **Note for Non-Code-Signed Builds**:
> If macOS Gatekeeper blocks opening the app, run the following command in Terminal:
> ```bash
> xattr -cr /Applications/FnFlow.app
> ```

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.
