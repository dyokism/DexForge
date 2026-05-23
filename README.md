[English](README.md) | [Bahasa Indonesia](README.id.md)

# DexForge

**Reforge your Android Runtime cache with dynamic tier-based ART/Dalvik optimization.**

![License](https://img.shields.io/badge/License-MIT-blue.svg)
![Android](https://img.shields.io/badge/Android-7.0%2B-green.svg)
![Version](https://img.shields.io/badge/Version-1.1-orange.svg)
![Root](https://img.shields.io/badge/Root-Magisk%20%7C%20KernelSU%20%7C%20APatch-red.svg)

## Overview

DexForge is a professional Magisk/KernelSU/APatch module designed to analyze your device resources dynamically and optimize the ART (Android Runtime) and Dalvik cache using high-efficiency, tier-based compilation strategies.

### How It Works

- **Hardware Profiling**: Detects RAM and specs to route the best compilation method for your phone.
- **Screen Stay-Awake**: Keeps your display on automatically during the compilation process.
- **Smart Compiles**: Compiles all apps (speed) on flagships, or user apps only (speed-profile) on mid/entry phones to save space.
- **Centralized Logs**: Saves clean compilation history directly to the module folder.

---

## Why Use DexForge?

If you experience app lag or micro-stutters during everyday use, DexForge helps reforge your runtime cache to deliver:
- **Instant App Launches**: Pre-compiles your apps so they open much faster.
- **Lag-Free Navigation**: Eliminates system UI stutters and frame drops.
- **Better Battery Life**: Reduces active CPU overhead when running apps.
- **Optimized Storage**: Fits the optimization level specifically to your device memory.

---

## Safeguards

- **Anti-Bootloop**: Automatically cancels compilation if free storage is below 512MB.
- **Battery Guard**: Pauses compilation if battery level is below 15% and unplugged from a charger.
- **Optional Cache Reset**: Clear ART cache using volume keys before recompiling.
- **Silent Flash**: Installs instantly without volume key prompts during zip flashing.

---

## Requirements

| Requirement | Details |
|-------------|---------|
| Android | 7.0+ (API 24+) |
| Root | Magisk v20.4+, KernelSU, or APatch |

---

## Installation

1. Download the latest `DexForge-v1.1.zip` release.
2. Open Magisk, KernelSU, or APatch manager.
3. Install the ZIP via the **Modules** tab.
4. **Reboot** your device.

---

## Usage

1. Open your root manager application (Magisk, KernelSU, or APatch).
2. Navigate to the **Modules** section.
3. Tap the **Action** (or "Run") button next to DexForge.
4. Use volume keys to select your cache clearing choice within 10 seconds.
5. Wait for the process to complete (the screen will stay awake automatically).
6. **Reboot** is highly recommended once compilation is complete.

---

## Developer & License

- **Developer**: [dyokism](https://github.com/dyokism)
- **License**: MIT
