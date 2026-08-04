# DexForge

<p align="center">
  <img src="DexForge.webp" alt="DexForge Logo" width="600">
</p>

<p align="center">
  <strong>Optimize Android DEX/ART compilations dynamically based on your device hardware.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/License-MIT-d35400?style=for-the-badge" alt="License">
  <img src="https://img.shields.io/badge/Android-7.0%2B-ff7300?style=for-the-badge&logo=android&logoColor=white" alt="Android">
  <img src="https://img.shields.io/badge/Version-2.2-ff9f0a?style=for-the-badge&logo=github&logoColor=white" alt="Version">
  <img src="https://img.shields.io/badge/Root-KSU%20%7C%20APatch%20%7C%20Magisk-e65c00?style=for-the-badge&logo=linux&logoColor=white" alt="Root">
  <br>
  <br>
  <a href="README.md">English</a> | <a href="README.id.md">Bahasa Indonesia</a>
</p>

## Overview

DexForge is a root module that optimizes your apps by picking the best DEX compiler filter for your specific hardware.


## Why Use DexForge?

- **Tailored performance**: Automatically selects the best compiler filter (`speed`, `speed-profile`, or `verify`/`quicken`) based on your device's RAM and app usage stats.
- **Safety guards**: Checks battery level and storage space before running to prevent errors.
- **Interactive cache reset**: Lets you optionally purge compilation caches before optimization to start fresh.


## How to Use

### 1. Installation
* Download the latest `DexForge.zip` from [Releases](https://github.com/dyokism/DexForge/releases).
* Flash it using your root manager (Magisk, KernelSU, or APatch).
* **Reboot** so the module can start working in the background.

### 2. Running the Optimizer
* Open your root manager and press the **Action** button on the DexForge module.

> [!WARNING]
> If you clear the cache, compilation on some (and eventually all) devices will take significantly longer. Do it at your own discretion.

* **Cache Menu**: When it starts, it asks you a question. Press **Volume UP** to clear your old caches first (clean start). Press **Volume DOWN** (or wait 10 seconds) to keep your old caches and just update them.
* You can read the results later at: `/data/adb/modules/DexForge/dexforge.log`

### 3. Test Mode
* Want to see what DexForge will do without actually changing anything? Open a root terminal (like Termux) and type:
  ```sh
  su
  /data/adb/modules/DexForge/action.sh --dry-run
  ```


## Technical Details

### Hardware Optimization & App Usage Priority
* **Flagship phones (6GB+ RAM)**: Optimizes all apps for maximum `speed`. Processes apps one by one to avoid freezing the phone. If you clear the cache, it checks your app usage and sets rarely used apps to `speed-profile` to save time. If you don't clear cache, it skips usage checks to speed things up.
* **Mid-range phones (3GB to 6GB RAM)**: Checks your app usage to pick the best setup. Most used apps get `speed`, normal apps get `speed-profile`, and unused apps get `verify` (or `quicken` on older Android). This prevents the phone from running out of memory or storage.
* **Entry-level phones (3GB RAM or less)**: Limits optimization to `speed-profile` for your top apps, and `verify` or `quicken` for everything else. Saves CPU power and storage space.

>*If you have 8GB of RAM, it doesn't mean your phone is actually a "flagship". This is just for better classification :)*

### System Safety Checks
* **Storage check**: If you have less than **512MB** free space, it stops running. This protects your phone from getting stuck in a bootloop.
* **Battery check**: If your phone is not charging and the battery is under **15%**, it stops running to prevent sudden shutdowns.

### Background Tuning (`service.sh`)
* **CPU core control**: After your phone finishes booting, a background script forces the system's background compiler to only use the small, energy-efficient CPU cores. This prevents overheating or lag while you use your phone.


## Requirements

| Requirement | Details |
|-------------|---------|
| Android | 7.0+ (API 24+) |
| Storage | Minimum 512MB free space on `/data` partition |
| Battery | Minimum 15% charge (waived if charging) |
| Root | Magisk v20.4+, KernelSU, or APatch |


## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
