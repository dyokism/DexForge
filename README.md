[English](README.md) | [Bahasa Indonesia](README.id.md)

# DexForge

A professional Magisk/KernelSU module designed to analyze your device resources dynamically and optimize the ART/Dalvik cache with high-efficiency tier-based compilation strategies.

### How It Works
Android compiles apps using the Android Runtime (ART). Over time, or after software updates, compiled code can lose optimization, resulting in micro-stutters, slower app launches, and increased battery drain.
1. **Resource Profiling**: DexForge checks available RAM, free storage space, and Android SDK version.
2. **Tier-Based Classification**: It classifies the device as Flagship, Mid, or Entry.
3. **Screen Sleep Prevention**: It dynamically overrides screen sleep timeouts (`screen_off_timeout` + `svc power stayon`) so the display stays awake during compilation regardless of the charger state, then restores original settings automatically upon completion or abort.
4. **Smart Optimization Routing**:
   - **Flagship**: Uses bulk compilation (`-a`) to compile all apps, including critical system applications (like Settings, SystemUI) for an ultra-smooth experience.
   - **Mid & Entry**: Uses focused package-by-package compilation (`-3`) targeting user-installed apps to preserve storage, thermals, and battery health.
5. **SELinux Safe Pipe**: Captures standard error and standard output to shell variables first, completely bypassing Android's SELinux write restrictions to `/data/adb/`.

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
