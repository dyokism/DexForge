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
  <img src="https://img.shields.io/badge/Version-2.0-ff9f0a?style=for-the-badge&logo=github&logoColor=white" alt="Version">
  <img src="https://img.shields.io/badge/Root-KSU%20%7C%20APatch%20%7C%20Magisk-e65c00?style=for-the-badge&logo=linux&logoColor=white" alt="Root">
  <br>
  <br>
  <a href="README.md">English</a> | <a href="README.id.md">Bahasa Indonesia</a>
</p>

## Overview

DexForge is a cross-platform Android root module designed to dynamically optimize the system's DEX/ART compilations. By profiling the device's RAM tier, SDK level, battery state, and available storage during execution, DexForge automatically assigns the most appropriate compilation filter—ranging from `speed` for flagship devices to `speed-profile` or `quicken` for entry and mid-tier hardware. This hardware-aware profiling ensures that app launch times are minimized and system fluidity is maximized without overloading lower-spec devices.

---

## Why Use DexForge?

- **Tailored Performance**: Automatically selects the best compiler filter (`speed`, `speed-profile`, or `quicken`) based on your device's RAM capacity.
- **Safety Guards**: Actively checks battery level and storage space before running to prevent errors.
- **Interactive Cache Reset**: Lets you optionally purge compilation caches before optimization to start fresh.

---

## How to Use

### 1. Installation & Setup
* Download the latest `DexForge.zip` from [Releases](https://github.com/dyokism/DexForge/releases).
* Install the ZIP file via your root manager's **Modules** tab (Magisk, KernelSU, or APatch).
* **Reboot** your device to fully initialize the background services and core thread watchdog.

### 2. Execution (Action Button)
* Launch the compilation engine by pressing the **Action** button in your root manager's menu.
* **Interactive Cache Prompt**: During start-up, press **Volume UP** to perform a clean reforge (purges existing compiler caches first) or **Volume DOWN** (or wait 10 seconds) to compile existing states incrementally.
* Optimization results and execution events are logged at: `/data/adb/modules/DexForge/dexforge.log`

### 3. Dry-Run Audit Mode (CLI)
* To simulate execution and verify compiler selection without performing physical writes, run the CLI utility in a root shell:
  ```sh
  su
  /data/adb/modules/DexForge/action.sh --dry-run
  ```

---

## Technical Details

### Hardware-Based Classification
* **Flagship Tier (> 6144 MB RAM)**: Assigns the `speed` filter (unconditional AOT machine code compilation) for maximum CPU efficiency.
* **Mid Tier (3072 MB - 6144 MB RAM)**: Assigns the `speed-profile` filter (Profile-Guided Optimization). It acts as a protective wrapper, overriding requests for full `speed` compilation to protect the system from storage exhaustion and virtual memory out-of-memory (OOM) failures. If profile data is insufficient, it safely falls back to `verify` (API >= 31) or `quicken` (API < 31).
* **Entry Tier (<= 3072 MB RAM)**: Assigns the `verify` filter (API >= 31) or `quicken` filter (API < 31) to keep the non-volatile storage footprint minimal and prevent physical RAM pressure.

### System Safety Validation Protocols
* **Storage Failsafe**: Verifies contiguous free space on the `/data` partition using standard POSIX white-space tokenization over `df -k` output. If available storage is under **512MB**, compilation terminates to prevent filesystem corruption and bootloops.
* **Battery Failsafe**: Queries PMIC sysfs metrics `/sys/class/power_supply/battery/` with an automated fallback to the `dumpsys battery` binder service. Execution is blocked if the device is not charging and the capacity is under **15%**.

### Late-Boot Core Regulation (`service.sh`)
* **Core Affinity Pinning**: Spawns an early-boot polling watchdog that hooks onto `sys.boot_completed`. Upon boot completion, it configures system properties (`dalvik.vm.dex2oat-cpu-set=0,1,2,3` and `dalvik.vm.dex2oat-threads=4`) to restrict background compiler operations to logical efficiency cores. This prevents CPU thermal throttling and maintains system responsiveness.

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

## How It Works

```mermaid
flowchart TD
    Start([Start: Flash ZIP Module]) --> Install[1. Extract action.sh & Assets]
    Install --> Setup[2. Register Action in Root Manager]
    Setup --> Trigger[3. Trigger action.sh via Action Button]
    Trigger --> EnvCheck[4. Profile RAM, SDK, Storage & Battery]
    EnvCheck --> Verification{Validate Constraints?}
    
    Verification -- Fail --> Abort[Abort: Safe System Shutdown]
    Verification -- Pass --> VolumePrompt{Volume UP pressed within 10s?}
    
    VolumePrompt -- Yes --> CacheReset[Enable Compiler Cache Reset]
    VolumePrompt -- No / Timeout --> CompileOnly[Disable Cache Reset]
    
    CacheReset --> DeviceTier{Classify RAM Tier?}
    CompileOnly --> DeviceTier
    
    DeviceTier -- Flagship --> Bulk[Run speed bulk compile -a]
    DeviceTier -- Mid / Entry --> Scan[Scan User-Installed Apps -3]
    
    Scan --> ProcessApps[Compile Apps One-by-One with Progress %]
    Bulk --> Output[Generate dexforge.log & Completion Summary]
    ProcessApps --> Output
    
    Output --> Finish([Finish: Reboot Recommended])

    %% Custom Styles and Colors (Ultra-Muted Slate Theme)
    classDef startEnd fill:#1b2c24,stroke:#34d399,stroke-width:1.5px,color:#e6f4ea;
    classDef fail fill:#2c1b1b,stroke:#f87171,stroke-width:1.5px,color:#fce8e6;
    classDef decision fill:#2d2216,stroke:#fbbf24,stroke-width:1.5px,color:#fef3c7;
    classDef process fill:#1e293b,stroke:#475569,stroke-width:1px,color:#f1f5f9;
    
    class Start,Finish startEnd;
    class Abort fail;
    class Verification,VolumePrompt,DeviceTier decision;
    class Install,Setup,Trigger,EnvCheck,CacheReset,CompileOnly,Bulk,Scan,ProcessApps,Output process;
```

---

## Developer, Credits & License

- **Developer**: [dyokism](https://github.com/dyokism)
- **License**: [MIT](LICENSE)
- **Credits & Acknowledgements**:
  - **Android Runtime (ART)** by [Google](https://source.android.com/devices/tech/dalvik)
  - **Root Managers**: [Magisk](https://github.com/topjohnwu/Magisk), [KernelSU](https://github.com/tiann/KernelSU), and [APatch](https://github.com/bmax121/APatch)
