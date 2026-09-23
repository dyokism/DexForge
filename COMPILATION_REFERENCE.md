# DexForge Compilation Reference

Technical reference for the Android Runtime (ART) compilation pipeline, compiler filter selection, and CPU topology tuning.

## Android runtime compilation subsystem

Android 7.0 (API 24) introduced a hybrid execution model combining an interpreter, a Just-in-Time (JIT) compiler with code profiling, and an Ahead-of-Time (AOT) compiler driven by the `dex2oat` binary.

When an application runs, the JIT compiler identifies hot methods and writes execution profiles to `/data/misc/profiles/cur/0/<package>/primary.prof`. During idle maintenance windows, the system daemon merges these profiles and recompiles frequently executed methods into native machine code.

## Compiler filter hierarchy

The `pm` service and `dex2oat` binary support several compilation filters that balance execution latency against compilation duration and storage overhead.

| Filter | Internal Strategy | Storage Cost | Compilation Time |
| :--- | :--- | :--- | :--- |
| `verify` | Validates DEX bytecode without compiling native code. | Baseline | Minimal (<1s) |
| `quicken` | Bytecode verification plus basic DEX optimizations (Android 7 to 10). | Low | Fast |
| `speed-profile` | Compiles native code only for methods recorded in runtime profiles. | Moderate | Moderate |
| `speed` | Full AOT compilation of all classes and methods in the APK. | High | Slow |

### Profile-guided execution via `speed-profile`

The `speed-profile` filter optimizes code based on recorded application execution patterns. It avoids compiling unused features, debug handlers, and cold initialization paths, which reduces RAM footprint and keeps oat file sizes small compared to whole-program `speed` compilation.

## Hardware profiling and memory tiers

DexForge interrogates `/proc/meminfo` to calculate total physical memory and assigns the system to a performance tier.

| Tier | Total RAM | Default Filter | App Target Scope |
| :--- | :--- | :--- | :--- |
| **Flagship** | > 6144 MB (>6 GB) | `speed` | System and user applications |
| **Mid-range** | 3072 MB to 6144 MB (3 to 6 GB) | `speed-profile` | User applications |
| **Entry-level** | <= 3072 MB (<=3 GB) | `verify` or `quicken` | User applications |

On mid-range devices without sufficient runtime profiles (5 or fewer recorded profiles), DexForge automatically downgrades from `speed-profile` to `verify` (or `quicken` on Android versions below 12) to avoid compiling cold code without execution data.

## Telemetry-guided usage categorization

When optimizing packages, DexForge queries `dumpsys usagestats` to evaluate real-world application launch counts:

1. **Top-Use Packages**: The top 10 most frequently launched user applications receive prioritized promotion (such as `speed` on mid-tier, or `speed-profile` on entry-tier).
2. **Normal Packages**: Actively used applications receive the tier default compilation filter.
3. **Never-Used Packages**: Applications with zero launch history receive minimal compilation (`verify` or `quicken`) to conserve device flash storage and battery power.

## CPU core masking and thread allocation

Heterogeneous CPU clusters (big.LITTLE, DynamIQ) combine high-performance cores with energy-efficient cores. Without thread constraints, background compilation can saturate performance cores, generating excess heat and causing frame drops in active apps.

### Background tuning via `service.sh`

DexForge waits for `sys.boot_completed=1` and dynamically inspects `/sys/devices/system/cpu/present` to detect the core layout. It isolates compilation to the lower half of available cores:

```properties
dalvik.vm.dex2oat-cpu-set=<lower_half_cores>
dalvik.vm.dex2oat-threads=<core_count>
dalvik.vm.background-dex2oat-cpu-set=<lower_half_cores>
dalvik.vm.background-dex2oat-threads=<core_count>
```

This restriction prevents `dex2oat` from monopolizing primary CPU cores when background optimization runs in Android 14 and newer builds.

## Pre-flight failsafes

DexForge performs verification checks before initiating compilation tasks:

1. **Storage reserve check**: Verifies that `/data` has at least 512 MB of free storage. Writing AOT oat or vdex artifacts to a full storage partition triggers `ENOSPC` errors that can disrupt system services.
2. **Battery charge check**: Requires a minimum 15% battery level or an active power connection. This avoids sudden power loss during profile updates, which could corrupt oat files.
