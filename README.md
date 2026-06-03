[English](README.md) | [Bahasa Indonesia](README.id.md)

# DexForge

**Optimize Android DEX/ART compilations dynamically based on your device hardware.**

![License](https://img.shields.io/badge/License-MIT-blue.svg)
![Android](https://img.shields.io/badge/Android-7.0%2B-green.svg)
![Version](https://img.shields.io/badge/Version-1.3-orange.svg)
![Root](https://img.shields.io/badge/Root-Magisk%20%7C%20KernelSU%20%7C%20APatch-red.svg)

## Overview

DexForge is a root module that dynamically optimizes Android's DEX/ART compilations. It profiles your device memory and Android version to select the best compiler filter, improving system fluidity without overloading lower-tier hardware.

---

## Why Use DexForge?

- **Tailored Performance**: Automatically selects the best compiler filter (`speed`, `speed-profile`, or `quicken`) based on your device's RAM capacity.
- **Safety Guards**: Actively checks battery level and storage space before running to prevent errors.
- **Interactive Cache Reset**: Lets you optionally purge compilation caches before optimization to start fresh.

---

## Requirements

| Requirement | Details |
|-------------|---------|
| Android | 7.0+ (API 24+) |
| Storage | Minimum 512MB free space on `/data` partition |
| Battery | Minimum 15% charge capacity (waived if actively charging) |
| Root | Magisk v20.4+, KernelSU, or APatch |

---

## Installation & Configuration

1. Install the module ZIP via your root manager's **Modules** tab (Magisk, KernelSU, or APatch).
2. Trigger the compilation run from your root manager's **Action** section.
3. **Reboot** your device to fully apply the runtime compilation layout.
4. Check execution logs at: `/data/adb/modules/DexForge/dexforge.log`

---

## Usage

### Interactive Compiler Configuration
When you launch the DexForge action script, you will be prompted via physical buttons:
* Press **Volume UP** to clear compilation caches and perform a clean reforge.
* Press **Volume DOWN** (or wait 10 seconds) to compile existing states incrementally.

### Dry-Run Simulation (Developer CLI)
Audits the module compiler output without performing actual filesystem writes (requires root shell):
```sh
su
/data/adb/modules/DexForge/action.sh --dry-run
```

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
├── customize.sh     # install-time setup and configuration
├── module.prop      # module metadata properties
├── service.sh       # boot service stub
├── uninstall.sh     # resets compile filter caches and removes logs
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

## Developer & License

- **Developer**: [dyokism](https://github.com/dyokism)
- **License**: MIT
