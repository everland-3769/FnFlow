#   FnFlow — Smart Fn Key Mode Switcher for macOS
> Effortlessly switch between Media Keys and Standard F1–F12 Function Keys on macOS, tailored to your active application.

[](README.zh-CN.md)
---

English | [繁體中文](README.zh-TW.md) | [简体中文](README.zh-CN.md)

I am thrilled to introduce **FnFlow**! This is my very first macOS app project.

The inspiration for this app came from **Fluor**, a handy tool that I personally loved and used for years. Unfortunately, Fluor's original development ended around 2021. Although a community version 2.5.1 was released in 2022 for Apple Silicon compatibility, its user interface felt aging and its feature set wasn't quite keeping up with modern macOS standards. While Fluor remained rock-solid in stability, I couldn't find a simple, modern, and powerful alternative online.

So, I decided to build a brand-new Fn key switcher from scratch specifically for modern macOS—complete with a modern SwiftUI design and thoughtful features. I hope FnFlow helps anyone who shares the same workflow needs!

---

## ✨ Key Features

- 🔄 **Automatic F1–F12 Mode Switching**: Seamlessly switches keyboard modes between Media Keys and Standard Function Keys based on your frontmost application.
- 💧 **Modern Liquid Glass UI**: High-quality SwiftUI menu bar interface featuring responsive, high-contrast liquid glass sliders.
- 🎯 **Custom Per-App Rules**: Easily set dedicated rules for individual applications, complete with rule search and active app selection.
- 🔔 **Customizable OSD Notifications**: Get instant feedback when switching apps with floating screen OSD capsules, menu bar indicators, system banners, or audio cues (can also be turned off completely).
- ☁️ **iCloud Sync & JSON Backup**: Automatically sync your custom app rules across your Macs via iCloud, or export/import JSON configuration backups anytime.
- ⚡ **Global Hotkey**: Press `Option + F` anywhere to toggle the global function key mode instantly.
- 🎨 **Tailored Menu Bar Styles**: Choose between Standard Icon (Sun / Fn), Minimal Dot, or Text-Only mode. Dynamic color adaptation automatically matches your macOS system accent color.
- 🚀 **Launch at Login**: Background startup support upon macOS login.

---

## 🛠️ Installation

1. Download the latest `FnFlow.dmg` from the [Releases](../../releases) section.
2. Open the DMG file and drag `FnFlow.app` into your `/Applications` folder.
3. If macOS Gatekeeper prevents opening the app, open Terminal and run:
   ```bash
   xattr -cr /Applications/FnFlow.app
   ```

## 📣 Feedback & Support
FnFlow will be continuously updated and maintained. I hope you enjoy using it! If you encounter any bugs or have ideas for new features, please feel free to open an issue in the issues section.
