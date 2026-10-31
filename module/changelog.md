## [v3.0.1] - 2026-10-31

### Added
- Multi-tier CPU topology resolver in `service.sh` querying hardware DVFS `related_cpus` -> `cpu_capacity` -> legacy cluster fallback, accurately isolating the true LITTLE efficiency cluster across DynamIQ, asymmetric ARM layouts (e.g. Snapdragon 8 Gen 2/3), and All-Big architectures (e.g. Dimensity 9300/9400, Snapdragon 8 Elite).
- Direct `/proc/[0-9]*/comm` task scanning during watchdog abort to reliably signal `dex2oat`, `dex2oat64`, and `dex2oat32` workers, immune to Android 15/16 `art_exec` `--process-name-suffix` argv[0] mutations.
- Universal OEM charging detection supporting Pixel Adaptive Charging (80% limit), Samsung Protect Battery (80%/85%), and Asus ROG Bypass Charging when plugged into AC/USB.
- Maximum-luminance backlight aggregation with Always-On Display (AOD / Doze) framework fallback, enabling overnight compilation while preventing false wake triggers on multi-display foldables.

### Fixed
- Fixed naive 4-core assumption in `service.sh` that caused performance cores to be included in dex2oat CPU sets on modern asymmetric SoCs.
- Fixed watchdog cancellation missing `dex2oat64` under Toybox `killall` on 64-bit Android 14+ runtimes.

Note: Starting from version 2.1 and under, please download directly from [GitHub releases](https://github.com/dyokism/DexForge/releases) because of update.json issues. Sorry for the inconvenience :)
