## 3.0
- Installer hardening: unified Magisk, KernelSU, and APatch update-binary stub with robust API detection fallback and root manager inspection.
- Lineless UI overhaul: eliminated ASCII borders across customize.sh and action.sh in favor of whitespace grouping and indented key-values.
- Single-line progress logging: package compilation now reports zero-padded indices, aligned filters, and subsecond timing on a single line.
- Zero-fork Ash architecture: eliminated pipe forks and subshells in CPU topology parsing, telemetry matching, and progress logging.
- Android 14+ ART compliance: added mainline module background dex2oat affinity property setters and app-profile reset integration.
- Telemetry streaming: stream dumpsys usagestats directly to avoid buffer overflows and flash wear.

Note: Starting from version 2.1 and under, please download directly from [GitHub releases](https://github.com/dyokism/DexForge/releases) because of update.json issues. Sorry for the inconvenience :)
