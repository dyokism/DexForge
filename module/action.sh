#!/system/bin/sh
# dexforge optimization action script (posix compliant busybox ash)
# prioritizes execution stability, strict posix compliance, and advanced art/dex logic.

# redirect stderr to stdout for shell terminal visibility under managers
exec 2>&1

MODDIR="${0%/*}"
LOG_FILE="$MODDIR/dexforge.log"

# create log directory if missing
mkdir -p "${LOG_FILE%/*}" 2>/dev/null || true

# prevent screen sleep during optimization
ORIG_TIMEOUT=$(settings get system screen_off_timeout 2>/dev/null | tr -d '\r' || true)
if [ -n "${ORIG_TIMEOUT:-}" ] && [ "${ORIG_TIMEOUT:-}" != "null" ]; then
    settings put system screen_off_timeout 1800000 2>/dev/null || true
fi
svc power stayon true 2>/dev/null || true

# execution cleanup handler
cleanup() {
    local exit_code=$?
    # restore original screen timeout settings
    if [ -n "${ORIG_TIMEOUT:-}" ] && [ "${ORIG_TIMEOUT:-}" != "null" ]; then
        settings put system screen_off_timeout "${ORIG_TIMEOUT:-}" 2>/dev/null || true
    fi
    svc power stayon false 2>/dev/null || true
    
    if [ "$exit_code" -ne 0 ]; then
        echo "FATAL: DexForge optimization failed with exit code $exit_code" | tee /dev/kmsg || true
    fi
    exit "$exit_code"
}
trap cleanup EXIT INT TERM

# logging helper function
log_echo() {
    echo "$@"
    echo "$@" >> "$LOG_FILE"
}

# initialize log file
{
    echo ""
    echo "=========================================="
    echo "DexForge Run - $(date)"
    echo "=========================================="
} >> "$LOG_FILE"

log_echo "Starting DexForge optimization engine..."
START_TIME=$(date +%s)

# cli argument parsing
DRY_RUN=0
if [ "${1:-}" = "--dry-run" ]; then
    DRY_RUN=1
    log_echo "Running in Dry-Run simulation mode."
fi

# command execution wrapper (direct invocation without eval to prevent injection)
execute_cmd() {
    if [ "$DRY_RUN" -eq 1 ]; then
        log_echo "[DRY-RUN] Would execute: $@"
        return 0
    else
        log_echo "[EXECUTE] Running: $@"
        local ec=0
        "$@" || ec=$?
        if [ "$ec" -ne 0 ]; then
            log_echo "[ERROR] Command failed with exit code $ec: $@"
            return $ec
        fi
        return 0
    fi
}

# 1. device hardware profiling (pure posix without grep/awk/tr subshells)
log_echo "Profiling system hardware limits..."

mem_total_kb=0
if [ -f /proc/meminfo ]; then
    while IFS=: read -r key val; do
        if [ "$key" = "MemTotal" ]; then
            # split using positional parameters to strip leading spaces and trailing unit
            set -- $val
            mem_total_kb=$1
            break
        fi
    done < /proc/meminfo
fi

if [ "$mem_total_kb" -le 0 ]; then
    log_echo "ERROR: Failed to read system MemTotal from /proc/meminfo. Aborting."
    exit 1
fi

# retrieve sdk version safely and strip non-digit characters
sdk_version=$(getprop ro.build.version.sdk 2>/dev/null || echo "0")
sdk_version=${sdk_version%%[!0-9]*}

if [ "$sdk_version" -eq 0 ]; then
    log_echo "ERROR: Failed to retrieve Android SDK level. Aborting."
    exit 1
fi

if [ "$sdk_version" -lt 24 ]; then
    log_echo "ERROR: Unsupported Android version (SDK $sdk_version). Requires SDK 24+ (Nougat+). Aborting."
    exit 1
fi

# 2. system safety protocols and failsafes
log_echo "Enforcing pre-flight safety validations..."

# a. storage space verification on /data partition (direct df parsing without gnu stat)
df_out=$(df -k /data 2>/dev/null || df /data 2>/dev/null)
last_line=""
while read -r line; do
    [ -n "$line" ] && last_line="$line"
done <<EOF
$df_out
EOF

# parse columns using positional parameter tokenization
set -- $last_line
free_kb=0
if [ $# -ge 4 ]; then
    free_kb=$4
elif [ $# -ge 3 ]; then
    free_kb=$3
fi
free_kb=${free_kb%%[!0-9]*}
[ -z "$free_kb" ] && free_kb=0

free_storage_mb=$((free_kb / 1024))

if [ "$free_storage_mb" -lt 512 ]; then
    log_echo "ERROR: Insufficient storage. Only ${free_storage_mb}MB available on /data."
    log_echo "A minimum of 512MB contiguous space is required to compile AOT artifacts safely."
    exit 1
else
    log_echo " -> Storage Failsafe: Passed (${free_storage_mb}MB available)."
fi

# b. battery capacity and status verification
batt_level=""
is_charging=0

# extract battery parameters using posix read (avoids cat subshell)
if [ -f /sys/class/power_supply/battery/capacity ]; then
    read -r batt_level < /sys/class/power_supply/battery/capacity 2>/dev/null || true
    batt_level=${batt_level%%[!0-9]*}
fi
if [ -f /sys/class/power_supply/battery/status ]; then
    status_str=""
    read -r status_str < /sys/class/power_supply/battery/status 2>/dev/null || true
    status_str=${status_str%%[$'\r']*}
    if [ "$status_str" = "Charging" ] || [ "$status_str" = "Full" ]; then
        is_charging=1
    fi
fi

# fallback to dumpsys battery service if sysfs is restricted by selinux
if [ -z "$batt_level" ] || [ "$is_charging" -eq 0 ]; then
    batt_dump=$(dumpsys battery 2>/dev/null || true)
    if [ -n "$batt_dump" ]; then
        [ -z "$batt_level" ] && batt_level=$(echo "$batt_dump" | awk '/level:/ {print $2}')
        status_val=$(echo "$batt_dump" | awk '/status:/ {print $2}')
        if [ "$status_val" = "2" ] || [ "$status_val" = "5" ]; then
            is_charging=1
        fi
    fi
fi

# final backup assumptions
[ -z "$batt_level" ] && batt_level=100

if [ "$is_charging" -ne 1 ] && [ "$batt_level" -lt 15 ]; then
    log_echo "ERROR: Battery capacity is too low ($batt_level%) and device is not charging."
    log_echo "Halted to prevent unexpected power loss and compilation corruption."
    exit 1
else
    log_echo " -> Battery Failsafe: Passed (Capacity: ${batt_level}%, Charging: ${is_charging})."
fi

# 3. interactive volume key selection for cache reset
CLEAR_CACHE="false"

choose_cache_option() {
    log_echo " "
    log_echo "=================================================="
    log_echo "Interactive Cache Reset Option"
    log_echo "Clearing cache resets all optimization states."
    log_echo "First compilation run will take significantly longer."
    log_echo "--------------------------------------------------"
    log_echo "Vol UP   : Yes (Clear Cache & Compile)"
    log_echo "Vol DOWN : No  (Incremental Compile Only)"
    log_echo "(Timeout in 10 seconds: Default to No)"
    log_echo "=================================================="
    log_echo " "

    local delay=10
    local getevent_cmd
    getevent_cmd=$(command -v getevent 2>/dev/null)
    
    if [ -z "$getevent_cmd" ]; then
        log_echo "WARNING: getevent not found. Skipping cache check."
        CLEAR_CACHE="false"
        return
    fi

    local event_file
    event_file=$(mktemp /data/local/tmp/dexforge_evt.XXXXXX)

    # spawn getevent process in background
    $getevent_cmd -l > "$event_file" 2>&1 &
    local getevent_pid=$!
    
    # wait for the device driver listener registration (crucial 0.5s warmup delay)
    sleep 0.5

    local elapsed=0
    local selection=""
    
    while [ "$elapsed" -lt "$delay" ]; do
        if grep -q -i -E '(volumeup|0073)' "$event_file" 2>/dev/null; then
            selection="true"
            break
        elif grep -q -i -E '(volumedown|0072)' "$event_file" 2>/dev/null; then
            selection="false"
            break
        fi
        sleep 1
        elapsed=$((elapsed + 1))
    done

    kill "$getevent_pid" 2>/dev/null
    wait "$getevent_pid" 2>/dev/null
    rm -f "$event_file"

    # fallback to keycheck binary if getevent was unresolved
    if [ -z "$selection" ]; then
        local keycheck_bin=""
        if [ -f "$MODDIR/keycheck" ]; then
            keycheck_bin="$MODDIR/keycheck"
        elif [ -f "$MODDIR/tools/keycheck" ]; then
            keycheck_bin="$MODDIR/tools/keycheck"
        fi

        if [ -n "$keycheck_bin" ] && [ -x "$keycheck_bin" ]; then
            log_echo "Swapping to keycheck fallback..."
            local key_code=0
            # capture real user input with 5 second timeout (timeout 0 removed)
            timeout 5 "$keycheck_bin" || key_code=$?
            if [ "$key_code" -eq 42 ]; then
                selection="true"
            elif [ "$key_code" -eq 41 ]; then
                selection="false"
            fi
        fi
    fi

    if [ "$selection" = "true" ]; then
        CLEAR_CACHE="true"
        log_echo "Cache clearing option: Selected Yes."
    else
        CLEAR_CACHE="false"
        log_echo "Cache clearing option: Selected No."
    fi
}

[ "$DRY_RUN" -eq 0 ] && choose_cache_option

# 4. device classification and compilation filter selection
# MemTotal in MB
mem_total_mb=$((mem_total_kb / 1024))
tier="entry"
filter="verify"

if [ "$mem_total_mb" -gt 6144 ]; then
    tier="flagship"
    filter="speed"
elif [ "$mem_total_mb" -gt 3072 ]; then
    tier="mid"
    filter="speed-profile"
    
    # if incrementing existing compilation and profile data is insufficient,
    # downgrade to verify/quicken to prevent cpu execution waste
    if [ "$CLEAR_CACHE" = "false" ]; then
        prof_count=0
        if [ -d "/data/misc/profiles/cur/0" ]; then
            prof_count=$(find /data/misc/profiles/cur/0 -maxdepth 3 -name "*.prof" 2>/dev/null | wc -l)
        fi
        if [ "$prof_count" -le 5 ]; then
            if [ "$sdk_version" -ge 31 ]; then
                filter="verify"
            else
                filter="quicken"
            fi
        fi
    fi
else
    tier="entry"
    if [ "$sdk_version" -ge 31 ]; then
        filter="verify"
    else
        filter="quicken"
    fi
fi

log_echo "Device Classification: $tier Tier (RAM: ${mem_total_mb}MB)"
log_echo "Selected Compilation Filter: $filter"

if ! command -v cmd >/dev/null 2>&1; then
    log_echo "ERROR: Package manager compilation tool 'cmd' is missing. Aborting."
    exit 1
fi

# 5. compilation process implementation
success_count=0
fail_count=0
total_pkgs=0

if [ "$tier" = "flagship" ]; then
    log_echo "Applying global optimization pass for flagship tier..."
    
    # estimate app count for logging
    total_pkgs=$(pm list packages 2>/dev/null | wc -l)
    
    if [ "$CLEAR_CACHE" = "true" ]; then
        execute_cmd cmd package compile --reset -a
    fi
    
    local compile_status=0
    execute_cmd cmd package compile -m "$filter" -a || compile_status=$?
    
    if [ "$compile_status" -ne 0 ]; then
        log_echo "WARNING: Bulk compilation returned exit status $compile_status."
        fail_count=$total_pkgs
    else
        success_count=$total_pkgs
    fi
else
    log_echo "Applying targeted user-installed application optimizations..."
    
    # read user packages list
    raw_pkgs=$(pm list packages -3 2>/dev/null)
    
    # calculate user packages count using pure redirection loop
    while IFS= read -r line; do
        [ -n "$line" ] && total_pkgs=$((total_pkgs + 1))
    done <<EOF
$raw_pkgs
EOF

    if [ "$total_pkgs" -eq 0 ]; then
        log_echo "No user-installed packages found to compile."
    else
        current=1
        while IFS= read -r line; do
            [ -z "$line" ] && continue
            pkg="${line#package:}"
            pkg="${pkg%%[$'\r']*}"
            [ -z "$pkg" ] && continue

            percent=$(( (current * 100) / total_pkgs ))
            log_echo "[$percent%] Optimizing ($current/$total_pkgs): $pkg"

            if [ "$CLEAR_CACHE" = "true" ]; then
                execute_cmd cmd package compile --reset "$pkg"
            fi

            pkg_start=$(date +%s)
            
            # execute compilation and capture exit status
            local compile_status=0
            execute_cmd cmd package compile -m "$filter" "$pkg" || compile_status=$?
            
            pkg_end=$(date +%s)

            if [ "$compile_status" -ne 0 ] && [ "$DRY_RUN" -eq 0 ]; then
                log_echo "  ! Failed compilation for package: $pkg"
                fail_count=$((fail_count + 1))
            else
                if [ "$DRY_RUN" -eq 1 ]; then
                    log_echo "  [DRY-RUN] Simulated compile success."
                else
                    log_echo "  OK. Done in $((pkg_end - pkg_start))s"
                fi
                success_count=$((success_count + 1))
            fi
            
            current=$((current + 1))
        done <<EOF
$raw_pkgs
EOF
    fi
fi

# 6. optimization summary generation
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

log_echo ""
log_echo "=== OPTIMIZATION SUMMARY ==="
log_echo "Device Tier      : $tier"
log_echo "Selected Filter  : $filter"
log_echo "Cache Cleaned    : $CLEAR_CACHE"
log_echo "Succeeded Apps   : $success_count"
log_echo "Failed Apps      : $fail_count"
log_echo "Elapsed Duration : ${ELAPSED}s"
log_echo "============================"
log_echo "Log file saved at: $LOG_FILE"
log_echo ""

# manager-specific completion announcements
is_ksu_or_apatch=0
[ "${KSU:-}" = "true" ] && is_ksu_or_apatch=1
[ "${APATCH:-}" = "true" ] && is_ksu_or_apatch=1
[ -f /data/adb/ap/package_config ] && is_ksu_or_apatch=1

if [ "$is_ksu_or_apatch" -eq 1 ]; then
    log_echo "=================================================="
    log_echo "Optimization Complete."
    log_echo "Please reboot your device to apply system layers."
    log_echo "Auto-closing in 15 seconds..."
    log_echo "=================================================="
    sleep 15
else
    log_echo "=================================================="
    log_echo "Optimization Complete."
    log_echo "Please reboot your device to apply system layers."
    log_echo "=================================================="
fi
