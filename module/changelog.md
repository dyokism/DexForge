# DexForge Changelog

## v2.1
- Add usage-aware compilation via usagestats (Samsung/OEM compatible).
- Resolve CPU affinity dynamically in service.sh.
- Fix package regex dot matching using POSIX helper.
- Support env overrides for CLEAR_CACHE and TEST_TIER.
- Clean up temporary files and remove auto-closing delays.

## v2.0
- Refactored entire codebase for strict POSIX compliance (BusyBox Ash compatibility).
- Implemented robust stat-based `/data` free space validation to prevent `df` parsing errors.
- Enhanced battery checks with PMIC fallback options.
- Added thread-optimized CPU affinity adjustments in `service.sh`.
- Upgraded volume key interception loop with fallback capabilities.
- Added strict dry-run architecture wrapper for simulation.
