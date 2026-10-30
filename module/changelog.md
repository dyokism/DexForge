## [v3.0.0] - 2026-10-30

> [!NOTE]
> This is my last update, at least for now. I did not want to abandon this project because of my own laziness, so I rebuilt it into what it always should have been. I hope everyone still using DexForge enjoys this major update. :)

### Added
- Autonomous background optimization engine (`dexforge_daemon.sh`) executing during deep idle charging.
- Zero-IPC Linux sysfs hardware gatekeepers monitoring charging state, battery capacity, temperature, and display backlight.
- Single-pass zero-fork `dumpsys package dexopt` parser prioritizing third-party user applications.
- Micro-batch compilation orchestrator processing 2 to 3 packages per idle cycle.
- Active 1.5-second watchdog with instant screen-wake and thermal abort via `killall -TERM dex2oat`.
- Shared utility core (`util.sh`) with monotonic early-boot clock and kernel logging to `/dev/kmsg`.
- Session compile cache (`dexforge_compiled.tmp`) and failure blacklist (`dexforge_failed.tmp`) preventing infinite queue loops.
- Persistent state directory standardized under `/data/adb/modules_config/DexForge/`.
- Dynamic atomic `module.prop` description updating for live status badge feedback in root managers.

### Changed
- Pinned `dex2oat` worker threads strictly to energy-efficient LITTLE cores (`dalvik.vm.dex2oat-cpu-set`).
- Enforced background priority cgroups (`-r bg-dexopt -p PRIORITY_BACKGROUND`).
- Raised minimum supported Android version to Android 10 (API 29).
- Cleaned installation flow in `customize.sh` with architecture detection and permission normalization.
- Consolidated project documentation into single English `README.md`.

### Removed
- Removed interactive `action.sh` volume-key interface and manual terminal menus.
- Removed obsolete Dalvik and legacy Nougat and Oreo compatibility workarounds.
- Removed Indonesian documentation translation (`README.id.md`).

## 2.2
- Fixed a bug where battery charging check could be skipped silently.
- Added a safety guard for package list in usage data collection.
- Boot timeout now writes a message to kernel log for easier debugging.
- Compiler thread count is now based on your actual CPU cores instead of always using 4.

Note: Starting from version 2.1 and under, please download directly from [GitHub releases](https://github.com/dyokism/DexForge/releases) because of update.json issues. Sorry for the inconvenience :)
