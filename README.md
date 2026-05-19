[English](README.md) | [Bahasa Indonesia](README.id.md)

# DexForge

A Magisk/KernelSU module designed to automatically analyze your device and rebuild the ART/Dalvik cache using the most optimal compiler filter.

### How It Works
Android uses the ART (Android Runtime) to compile apps. Over time, or after a system update, this cache can become unoptimized, leading to sluggish performance or battery drain. 
1. DexForge profiles your device's RAM, available storage, and Android version.
2. It classifies your device into a tier (Flagship, Mid, or Entry).
3. Based on the tier and available space, it selects the best `dex2oat` compiler filter (e.g., `speed-profile`, `speed`, `verify`, or `quicken`).
4. It safely recompiles your installed packages to restore optimal performance.

### Safety & Quality Standards
**Why not force 'everything' to 'speed'?** Compiling everything with the `speed` filter consumes massive amounts of storage and takes a very long time. DexForge uses smart profiling to only apply aggressive filters on high-end devices with plenty of storage, while using safer, balanced filters for mid-range and entry-level devices. It also includes built-in safeguards to abort if your free storage is under 512MB.

### Core Features
- **Smart Profiling**: Automatically detects device capabilities (RAM & Storage).
- **Dynamic Filters**: Applies the optimal compilation filter based on the device tier.
- **Safety Guards**: Prevents bootloops or system crashes by checking storage limits and SDK versions.
- **Action Button Ready**: No need to use the terminal; execute the optimization directly from the Magisk/KernelSU app interface.

### Requirements
- Magisk v20.4+ or KernelSU / APatch
- Android 7.0+ (SDK 24+)

### Installation
1. Download the latest DexForge `.zip` release.
2. Open the Magisk / KernelSU / APatch app.
3. Go to the Modules section.
4. Tap **Install from storage** and select the downloaded zip file.
5. Reboot your device.

### How to Use

**01 Open your root manager**
Open the Magisk, KernelSU, or APatch application on your device.

**02 Go to Modules**
Navigate to the modules tab where DexForge is installed.

**03 Tap the Action Button**
Find DexForge and tap the **Action** (or 'Run') button. The script will automatically profile your device and begin the recompilation process.

**04 Wait and Reboot**
Let the process finish. Once it shows the summary, it is highly recommended to reboot your device for the changes to take full effect.

### Disclaimer
This is an experimental tool. While safeguards are in place, modifying system caches can sometimes cause unexpected app behavior. Use responsibly and keep a backup of your important data.
