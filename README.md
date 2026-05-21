[English](README.md) | [Bahasa Indonesia](README.id.md)

# DexForge

A professional Magisk/KernelSU module designed to analyze your device resources dynamically and optimize the ART/Dalvik cache with high-efficiency tier-based compilation strategies.

### How It Works
DexForge dynamically optimizes your Android Runtime (ART) cache:
1. **Profiling**: Reads RAM, free storage, and SDK version to classify your device (Flagship, Mid, or Entry).
2. **Stay-Awake**: Overrides `screen_off_timeout` to keep the display on during execution, restoring it automatically on exit.
3. **Smart Routing**: Compiles all packages (`-a`) on flagships for absolute smoothness, or user-installed packages (`-3`) on mid/entry tiers to preserve storage and thermals.
4. **Subshell Capture**: Captures compile logs via standard shell variables before writing to `/data/adb/` to avoid sub-process permission blockages.


### Safety & Quality Standards
- **Low Storage Protection**: Compilation aborts instantly if free storage is below 512MB to prevent bootloops.
- **Battery Threshold**: Compilation is blocked if the battery level is below 15% and not connected to a charger.
- **Robust Cache Reset**: Interactive volume key option to reset target packages' cache before recompiling, detailing compile-time implications.
- **Magisk Silent Install**: Seamless automated installations with an on-demand volume key interface at runtime via the Action Button.

### Requirements
- Magisk v20.4+ or KernelSU / APatch
- Android 7.0+ (SDK 24+)

### Installation
1. Download the latest `DexForge-v1.1.zip` release.
2. Open the Magisk, KernelSU, or APatch manager app.
3. Go to the Modules section.
4. Tap **Install from storage** and select the downloaded zip file.
5. Reboot your device.

### How to Use
1. Open your root manager application.
2. Navigate to the modules section.
3. Tap the **Action** (or "Run") button next to DexForge.
4. Use volume keys to select your cache clearing choice within 10 seconds.
5. Wait for the process to complete (the screen will stay awake automatically). A reboot is highly recommended once compilation is complete.

### Disclaimer
This is an advanced optimization tool. While robust safeguards are implemented, modifying runtime caches involves system-level operations. Use responsibly.
