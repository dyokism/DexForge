# DexForge

<p align="center">
  <img src="DexForge.webp" alt="DexForge Logo" width="600">
</p>

<p align="center">
  <strong>Autonomous DEX and ART compilation engine dynamically tuned to your device hardware.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/License-MIT-d35400?style=for-the-badge" alt="License">
  <img src="https://img.shields.io/badge/Android-10.0%2B-ff7300?style=for-the-badge&logo=android&logoColor=white" alt="Android">
  <img src="https://img.shields.io/badge/Version-3.0.0-ff9f0a?style=for-the-badge&logo=github&logoColor=white" alt="Version">
  <img src="https://img.shields.io/badge/Root-KSU%20%7C%20APatch%20%7C%20Magisk-e65c00?style=for-the-badge&logo=linux&logoColor=white" alt="Root">
</p>

## Overview

DexForge is a root module that optimizes your apps in the background by compiling DEX and ART bytecode during verified idle charging windows.

DexForge started because manual compilation scripts made phones burn up and required constantly pressing buttons or volume keys just to get through a run. This rewrite is what it always should have been: silent, completely automatic, and intelligent. You flash it once and forget about it.


## Why Use DexForge?

- **Fully autonomous**: Runs quietly in the background while your phone is plugged in with the screen off. No buttons, no interactive prompts, and no manual babysitting.
- **Hardware-aware CPU pinning**: Binds compiler worker threads strictly to energy-efficient LITTLE CPU cores, preventing overheating and eliminating UI frame drops.
- **Micro-batching with instant yield**: Compiles 2 to 3 apps per idle cycle and aborts within milliseconds if you wake your screen or unplug the charger.
- **Zero OAT corruption risk**: Relies on Android's native atomic file staging. Stopping compilation mid-flight removes temporary files cleanly, leaving existing app caches untouched.
- **Live status dashboard**: Displays real-time compiler state, battery capacity, and temperature directly on your module card in KernelSU, APatch, or Magisk.


## How to Use

### 1. Installation
* Download `DexForge.zip` from [Releases](https://github.com/dyokism/DexForge/releases).
* Flash the archive using your root manager (KernelSU, APatch, or Magisk).
* **Reboot** your device so the background service can initialize.

### 2. Automatic Background Optimization
Once rebooted, DexForge takes over automatically. You do not need to press any action buttons or keep apps open in the foreground.

Whenever your device meets these conditions:
1. **Charging** (AC, USB, or Wireless)
2. **Battery >= 50%**
3. **Screen off for at least 2 minutes**
4. **Battery temperature under 38.5°C**

DexForge begins compiling your unoptimized apps in small batches, prioritizing your user-installed apps first. If you pick up your phone or turn on the screen, DexForge yields immediately.

### 3. Monitoring Status and Logs
* **Live status**: Check the DexForge module description inside KernelSU, APatch, or Magisk. It dynamically updates with live state (e.g. `[Active • Compiling com.example.app (3/15) • 32.5°C]`).
* **Live log streaming**:
  ```sh
  su -c tail -f /data/adb/modules_config/DexForge/DexForge.log
  ```
* **Kernel ring buffer**:
  ```sh
  su -c dmesg | grep DexForge
  ```


## Technical Details

### Background Tuning and LITTLE-Core Pinning (`service.sh`)
* **CPU core control**: Isolates the efficiency cluster via `/sys/devices/system/cpu/present` and configures `dalvik.vm.dex2oat-cpu-set`, `dalvik.vm.dex2oat-threads`, and background cgroup profiles (`-r bg-dexopt -p PRIORITY_BACKGROUND`). This ensures compiler workers never starve foreground UI threads or touch prime cores.
* **Native job deconfliction**: Cancels competing native Android bg-dexopt tasks (Job 27873780 on Android 14+ and Job 800 on Android 10 to 13) to avoid Binder transaction exhaustion (`0x80000002`) and install lock contention.

### System Safety Checks
* **Zero-IPC sysfs gatekeeper**: Bypasses heavy `system_server` IPC by reading kernel virtual files directly (`/sys/class/power_supply/battery/*` and `/sys/class/backlight/*`).
* **Storage failsafe**: Verifies at least **1024MB** of free space on `/data` before starting compilation to prevent low storage bootloops.
* **Thermal ceiling**: Pauses compilation if battery temperature exceeds **38.5°C**, and kills active workers immediately if temperature reaches **39.0°C**.


## Requirements

| Requirement | Details |
|-------------|---------|
| Android | 10.0+ (API 29 to API 36+) |
| Storage | Minimum 1024MB free space on `/data` partition |
| Condition | Charging + Battery >= 50% + Screen off >= 2m |
| Root | KernelSU v0.6.0+, APatch v0.10.0+, or Magisk v26.0+ |


## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
