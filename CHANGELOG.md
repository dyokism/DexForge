# Changelog

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
