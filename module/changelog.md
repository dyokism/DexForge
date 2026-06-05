# Changelog

## v1.4
- Switched hardcoded paths to dynamic `MODDIR` resolution in all scripts.
- Enforced strict execution (`set -eu`), variable fallbacks, and command guards.
- Standardized KernelSU/APatch boolean checks and eliminated BusyBox ash UUOC pipelines.
- Removed non-standard properties from `module.prop` and passed all validation/shellcheck audits.

## v1.3
- **Instant Dry-Run**: Moved dry-run check to initialization to avoid 10-second cache reset prompt blockages.
- **Robust Storage & Battery Checks**: Resolved `df` line-wrapping using end-relative columns and stabilized `dumpsys` battery regex parsing.
- **Dynamic & Secure Paths**: Switched to dynamic `getevent` discovery and secured temporary input log files using `mktemp`.
- **Reliable Stats & Package Loops**: Solved flagship failure stats and utilized a subshell-free here-document loop to support packages with spaces.
- **Full State Reset on Uninstall**: Enhanced `uninstall.sh` to trigger system-wide compilation resets on module removal.
- **Optimized Shell Commands**: Consolidated MemTotal extraction into a single-process `awk` lookup to reduce process forks.

## v1.2
- **Robust Environment Validation**: Added defensive regex-based numeric checks for total RAM and Android SDK levels to prevent shell crashes.
- **Improved Storage & Battery Resilience**: Integrated fallback defaults for `df` storage queries and `dumpsys` battery values under custom or restrictive environments.
- **Enhanced Log Management**: Implemented `mkdir -p` check for the log directory and switched log initiation to append (`>>`) with clear execution separators to preserve history.
- **Smart I/O Scheduling**: Restricted prof file searching via lazy evaluation, executing filesystem scans only on the mid-tier where profile compilations are actually used.
- **APatch Compatibility**: Added robust secondary APatch detection by querying `/data/adb/ap/package_config`.
- **Developer Dry-Run**: Introduced a `--dry-run` argument allowing developers to test the compilation filter map without physical filesystem writes.
- **Precise Progress & Timing**: Added dynamic compilation percentages and individual per-package elapsed compilation timers.
- **Input Warmup Guard**: Added a brief `sleep 0.5` delay during input polling startup to allow device driver registration and eliminate missing volume keystrokes.
- **Empty List Protection**: Hardened the package query pipeline using line counting filters to prevent statistical errors if zero packages are installed.
- **Service & Uninstall Stubs**: Created a compatibility `service.sh` stub and an `uninstall.sh` cleanup script to delete module logs on removal.

## v1.1
- **Tier-Based Optimization**: Implemented dynamic compiler filter assignment based on hardware RAM (Flagship, Mid, Entry).
- **Flagship Path**: Uses bulk compilation (`-a`) for comprehensive system-wide speedups.
- **Mid & Entry Path**: Focuses on user-installed apps (`-3`) to preserve storage and thermals.
- **Robust Screen Stay-Awake**: Temporary screen sleep timeout overrides (30 mins) with clean trap-restoration on completion or abort.
- **Subshell Output Capture**: Captures command output to local shell variables first to reliably handle Magisk module log path write permissions.
- **Improved Input Compatibility**: Broadened `getevent` checking to support hex keycodes (`0073`/`0072`) alongside standard volume key labels.
- **Defensible Mid-Tier Routing**: Conservative compilation defaults (`verify`/`quicken`) for standard runs, reserving intensive optimization for manual cache resets.
- **Magisk Update Checks**: Added automated update checking configuration using Magisk/KernelSU specifications.

## v1.0
- Initial stable release.
- Automated ART/Dalvik cache optimization.
- Smart device profiling and dynamic filter selection.
