# DexForge

<p align="center">
  <img src="DexForge.webp" alt="DexForge Logo" width="600">
</p>

<p align="center">
  <strong>Adaptive ART compilation and CPU thread tuner for Android.</strong>
</p>

<p align="center">
  <a href="README.md">English</a> | <a href="README.id.md">Bahasa Indonesia</a>
</p>

## Overview

Android defaults to uniform background compilation profiles regardless of device memory limits or actual app usage. DexForge optimizes DEX bytecode execution by selecting compiler filters tailored to device RAM capacity and app launch history. The module also configures compiler thread pools and CPU core masks to prevent background compilation from degrading foreground UI performance.

Detailed architecture and compiler mechanics are documented in [COMPILATION_REFERENCE.md](COMPILATION_REFERENCE.md).

## Features

- Restricts background compiler threads to efficiency cores to maintain UI responsiveness.
- Dynamically assigns compilation filters (`speed`, `speed-profile`, `verify`, `quicken`) based on RAM tier and usage stats.
- Root manager Action button triggers on-demand optimization with single-line progress reporting.
- Interactive volume key prompt allows full cache resets or incremental compiles.
- Pre-flight checks verify battery charge and free storage before initiating compilation.

## Requirements

| Component | Minimum Specification |
| :--- | :--- |
| Android Version | Android 7.0 (API 24) or newer |
| Storage | Minimum 512 MB free space on `/data` partition |
| Battery | Minimum 15% charge (waived while charging) |
| Root Environment | Magisk (v20.4+), KernelSU, or APatch |

## Installation

1. Download the latest `DexForge.zip` from [Releases](https://github.com/dyokism/DexForge/releases).
2. Install the zip package through your root manager's **Modules** tab.
3. Reboot your device to initialize background CPU pinning.

## Configuration

After boot completes, DexForge inspects CPU topology and applies these system properties to isolate compiler workloads:

- **Log file**: `/data/adb/modules/DexForge/dexforge.log`

```properties
pm.dexopt.bg-dexopt=speed-profile
pm.dexopt.shared=speed
dalvik.vm.dex2oat-cpu-set=<efficiency_cores>
dalvik.vm.dex2oat-threads=<thread_count>
dalvik.vm.background-dex2oat-cpu-set=<efficiency_cores>
dalvik.vm.background-dex2oat-threads=<thread_count>
```

## Action button

You can tap the **Action** button next to DexForge in KernelSU, APatch, or compatible Magisk managers at any time:

- **Cache reset menu**: Press **Volume Up** to wipe existing compilation caches and recompile cleanly. Press **Volume Down** (or wait 10 seconds) to proceed with incremental compilation.
- **Dry-run mode**: To preview optimization actions without modifying system state, execute the script with the `--dry-run` flag in a root shell:
  ```bash
  su -c "/data/adb/modules/DexForge/action.sh --dry-run"
  ```
