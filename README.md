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

DexForge is an Android root module that optimizes your phone's apps to make them open faster and run smoother. 

Instead of using the same settings for every phone, DexForge checks your phone's hardware--like your RAM, Android version, battery level, and free storage space. Based on this check, it automatically chooses the best optimization method for your specific device. 

For high-end phones, it focuses on maximum speed. For older or budget phones, it carefully balances speed and storage space so your phone doesn't get overloaded or slow down.

---

## Why Use DexForge?

- **Tailored Performance**: Automatically selects the best compiler filter (`speed`, `speed-profile`, or `verify`/`quicken`) based on your device's RAM capacity and app usage statistics.
- **Safety Guards**: Actively checks battery level and storage space before running to prevent errors.
- **Interactive Cache Reset**: Lets you optionally purge compilation caches before optimization to start fresh.

---

## How to Use

### 1. Installation
* Download the latest `DexForge.zip` from [Releases](https://github.com/dyokism/DexForge/releases).
* Install the ZIP file using your root manager (Magisk, KernelSU, or APatch).
* **Reboot** your phone so the module can start working in the background.

### 2. Running the Optimizer
* Open your root manager and press the **Action** button on the DexForge module.

> [!WARNING]
> If you want to clear the cache, compilation on some (and eventually all) devices will take significantly longer. Do it with your own sense.

* **Cache Menu**: When it starts, it will ask you a question. Press **Volume UP** if you want to clear your old caches first (a clean start). Press **Volume DOWN** (or wait 10 seconds) if you want to keep your old caches and just update them.
* You can read the results later at: `/data/adb/modules/DexForge/dexforge.log`

### 3. Test Mode
* If you want to see what DexForge will do without actually changing anything on your phone, you can run a test. Open a root terminal (like Termux) and type:
  ```sh
  su
  /data/adb/modules/DexForge/action.sh --dry-run
  ```

---

## Technical Details

### Hardware Optimization & App Usage Priority
* **Flagship Phones (More than 6GB RAM)**: Optimizes all apps for maximum `speed`. It processes apps one by one to avoid freezing the phone. If you choose to clear the cache, it checks your app usage and sets rarely used apps to `speed-profile` to save time. If you don't clear the cache, it skips checking app usage to make the process much faster.
* **Mid-Range Phones (3GB to 6GB RAM)**: Checks your app usage to decide the best setup. Your most used apps get the `speed` setting, normal apps get `speed-profile`, and unused apps get `verify` (or `quicken` on older Android versions). This prevents the phone from running out of memory or storage space.
* **Entry-Level Phones (3GB RAM or less)**: Limits optimization to `speed-profile` for your top apps, and `verify` or `quicken` for everything else. This saves your phone's CPU power and storage space.

>*If you have 8GB of RAM, it doesn't mean your phone is actually a "flagship". This is just for better classification :)*

### System Safety Checks
* **Storage Check**: Checks how much free space you have on your phone. If you have less than **512MB** of free space, it stops running. This protects your phone from getting stuck in a bootloop.
* **Battery Check**: Checks your battery level. If your phone is not charging and the battery is under **15%**, it stops running to prevent sudden shutdowns.

### Background Tuning (`service.sh`)
* **CPU Core Control**: After your phone finishes booting, a background script checks your processor. It forces the system's background compiler to only use the small, energy-efficient CPU cores. This prevents your phone from overheating or lagging while you use it.

---

## Requirements

| Requirement | Details |
|-------------|---------|
| Android | 7.0+ (API 24+) |
| Storage | Minimum 512MB free space on `/data` partition |
| Battery | Minimum 15% charge capacity (waived if actively charging) |
| Root | Magisk v20.4+, KernelSU, or APatch |

---

## File Structure

```text
DexForge/
├── META-INF/
│   └── com/
│       └── google/
│           └── android/
│               ├── update-binary
│               └── updater-script
├── action.sh        # core compiler selection and execution engine
├── changelog.md     # changelog tracking module version updates
├── customize.sh     # install-time setup and configuration
├── module.prop      # module metadata properties
├── service.sh       # late boot completion optimizer & thread regulator
├── uninstall.sh     # clean up persistent data on uninstall
└── update.json      # update metadata configuration
```

---


## Developer, Credits & License

- **Developer**: [dyokism](https://github.com/dyokism)
- **License**: [MIT](LICENSE)
- **Credits & Acknowledgements**:
  - **Android Runtime (ART)** by [Google](https://source.android.com/devices/tech/dalvik)
  - **Root Managers**: [Magisk](https://github.com/topjohnwu/Magisk), [KernelSU](https://github.com/tiann/KernelSU), and [APatch](https://github.com/bmax121/APatch)
