#!/system/bin/sh
# dexforge optimization action script (posix compliant busybox ash)
# prioritizes execution stability, strict posix compliance, and advanced art/dex logic.

# redirect stderr to stdout for shell terminal visibility under managers
exec 2>&1

MODDIR="${0%/*}"
LOG_FILE="$MODDIR/dexforge.log"

CR=$(printf '\r')

USAGE_TOP_FILE="/data/local/tmp/dexforge_usage_top.tmp"
USAGE_NEVER_FILE="/data/local/tmp/dexforge_usage_never.tmp"
USAGE_UNIQUE_FILE="/data/local/tmp/dexforge_usage_unique.tmp"

# create log directory if missing
mkdir -p "${LOG_FILE%/*}" 2>/dev/null || true

# prevent screen sleep during optimization
ORIG_TIMEOUT=$(settings get system screen_off_timeout 2>/dev/null || true)
ORIG_TIMEOUT="${ORIG_TIMEOUT%%$CR*}"
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
    
    # remove usage stats and event temp files
    rm -f /data/local/tmp/dexforge_usage_*.tmp
    rm -f /data/local/tmp/dexforge_evt.*
    
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

parse_usagestats() {
    # parse usagestats output line by line
    local cur_pkg=""
    local line
    local trimmed
    
    while IFS= read -r line; do
        trimmed="${line#"${line%%[! ]*}"}"
        
        if [ "$trimmed" != "${trimmed#package=}" ]; then
            cur_pkg="${trimmed#package=}"
            cur_pkg="${cur_pkg%%[!a-zA-Z0-9._-]*}"
            
            if [ "$trimmed" != "${trimmed#*aunchCount=}" ]; then
                local count="${trimmed#*aunchCount=}"
                count="${count%%[!0-9]*}"
                if [ -n "$cur_pkg" ] && [ -n "$count" ]; then
                    echo "$count $cur_pkg"
                    cur_pkg=""
                fi
            elif [ "$trimmed" != "${trimmed#*lC=}" ]; then
                local count="${trimmed#*lC=}"
                count="${count%%[!0-9]*}"
                if [ -n "$cur_pkg" ] && [ -n "$count" ]; then
                    echo "$count $cur_pkg"
                    cur_pkg=""
                fi
            elif [ "$trimmed" != "${trimmed#*lc=}" ]; then
                local count="${trimmed#*lc=}"
                count="${count%%[!0-9]*}"
                if [ -n "$cur_pkg" ] && [ -n "$count" ]; then
                    echo "$count $cur_pkg"
                    cur_pkg=""
                fi
            elif [ "$trimmed" != "${trimmed#*LC=}" ]; then
                local count="${trimmed#*LC=}"
                count="${count%%[!0-9]*}"
                if [ -n "$cur_pkg" ] && [ -n "$count" ]; then
                    echo "$count $cur_pkg"
                    cur_pkg=""
                fi
            fi
        elif [ "$trimmed" != "${trimmed#*:}" ] && [ "$trimmed" != "${trimmed#*times}" ]; then
            local pkg="${trimmed%%:*}"
            pkg="${pkg%%[!a-zA-Z0-9._-]*}"
            local rest="${trimmed#*:}"
            if [ "$rest" != "${rest#*times}" ]; then
                local count="${rest%times*}"
                count="${count#"${count%%[! ]*}"}"
                count="${count%%[!0-9]*}"
                if [ -n "$pkg" ] && [ -n "$count" ]; then
                    echo "$count $pkg"
                fi
            fi
        elif [ -n "$cur_pkg" ]; then
            if [ "$trimmed" != "${trimmed#*aunchCount=}" ]; then
                local count="${trimmed#*aunchCount=}"
                count="${count%%[!0-9]*}"
                echo "$count $cur_pkg"
                cur_pkg=""
            elif [ "$trimmed" != "${trimmed#*lC=}" ]; then
                local count="${trimmed#*lC=}"
                count="${count%%[!0-9]*}"
                echo "$count $cur_pkg"
                cur_pkg=""
            elif [ "$trimmed" != "${trimmed#*lc=}" ]; then
                local count="${trimmed#*lc=}"
                count="${count%%[!0-9]*}"
                echo "$count $cur_pkg"
                cur_pkg=""
            elif [ "$trimmed" != "${trimmed#*LC=}" ]; then
                local count="${trimmed#*LC=}"
                count="${count%%[!0-9]*}"
                echo "$count $cur_pkg"
                cur_pkg=""
            elif [ "$trimmed" = "packages" ] || [ "$trimmed" = "events" ]; then
                cur_pkg=""
            fi
        fi
    done
}

get_usage_count() {
    # lookup package launch count safely without subshells or grep regex metacharacter issues
    local target="$1"
    local file="$2"
    local line cnt pkg
    if [ -f "$file" ]; then
        while read -r line; do
            [ -z "$line" ] && continue
            set -- $line
            cnt="$1"
            pkg="$2"
            if [ "$pkg" = "$target" ]; then
                echo "$cnt"
                return 0
            fi
        done < "$file"
    fi
    return 1
}

get_usage_bucket() {
    # check package bucket in temp files
    local pkg="$1"
    if grep -qxF "$pkg" "$USAGE_TOP_FILE" 2>/dev/null; then
        echo "top"
    elif grep -qxF "$pkg" "$USAGE_NEVER_FILE" 2>/dev/null; then
        echo "never"
    else
        echo "normal"
    fi
}

resolve_filter() {
    # resolve compilation filter based on tier and bucket
    # dependency: reads global sdk_version variable
    local target_tier="$1"
    local bucket="$2"
    local verify_quicken="verify"
    
    if [ "$sdk_version" -lt 31 ]; then
        verify_quicken="quicken"
    fi
    
    case "$target_tier" in
        entry)
            case "$bucket" in
                top) echo "speed-profile" ;;
                *) echo "$verify_quicken" ;;
            esac
            ;;
        mid)
            case "$bucket" in
                top) echo "speed" ;;
                normal) echo "speed-profile" ;;
                never) echo "$verify_quicken" ;;
            esac
            ;;
        flagship)
            case "$bucket" in
                top|normal) echo "speed" ;;
                never) echo "speed-profile" ;;
            esac
            ;;
    esac
}

collect_usage_data() {
    # run dumpsys usagestats and parse it
    local dump
    dump=$(dumpsys usagestats 2>/dev/null)
    if [ -z "$dump" ]; then
        log_echo "WARNING: dumpsys usagestats returned empty or failed. Falling back to flat-filter."
        return 1
    fi
    
    local top_file="$USAGE_TOP_FILE"
    local never_file="$USAGE_NEVER_FILE"
    local raw_file="/data/local/tmp/dexforge_usage_raw.tmp"
    local sorted_file="/data/local/tmp/dexforge_usage_sorted.tmp"
    local unique_file="$USAGE_UNIQUE_FILE"
    
    rm -f "$top_file" "$never_file" "$raw_file" "$sorted_file" "$unique_file"
    
    echo "$dump" | parse_usagestats > "$raw_file"
    
    if [ ! -s "$raw_file" ]; then
        log_echo "WARNING: No usage data extracted from dumpsys. Falling back to flat-filter."
        rm -f "$raw_file"
        return 1
    fi
    
    sort -rn "$raw_file" > "$sorted_file"
    
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        set -- $line
        local cnt="$1"
        local pkg="$2"
        [ -z "$pkg" ] && continue
        if ! get_usage_count "$pkg" "$unique_file" >/dev/null; then
            echo "$cnt $pkg" >> "$unique_file"
        fi
    done < "$sorted_file"
    
    grep -v "^0 " "$unique_file" | head -n 10 | cut -d' ' -f2 > "$top_file"
    
    # dependency: reads global raw_pkgs variable
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        local pkg="${line#package:}"
        pkg="${pkg%%$CR*}"
        [ -z "$pkg" ] && continue
        
        local cnt
        cnt=$(get_usage_count "$pkg" "$unique_file" || echo "0")
        if [ -z "$cnt" ] || [ "$cnt" -eq 0 ]; then
            echo "$pkg" >> "$never_file"
        fi
    done <<EOF
$raw_pkgs
EOF
    
    rm -f "$raw_file" "$sorted_file"
    touch "$top_file" "$never_file"
    return 0
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
    status_str=${status_str%%$CR*}
    if [ "$status_str" = "Charging" ] || [ "$status_str" = "Full" ]; then
        is_charging=1
    fi
fi

# fallback to dumpsys battery service if sysfs is restricted by selinux
if [ -z "$batt_level" ] || [ "$is_charging" -eq 0 ]; then
    batt_dump=$(dumpsys battery 2>/dev/null || true)
    if [ -n "$batt_dump" ]; then
        while read -r line; do
            case "$line" in
                *level:*)
                    if [ -z "$batt_level" ]; then
                        batt_level="${line##*level: }"
                        batt_level="${batt_level%%$CR*}"
                        batt_level="${batt_level%%[!0-9]*}"
                    fi
                    ;;
                *status:*)
                    status_val="${line##*status: }"
                    status_val="${status_val%%$CR*}"
                    status_val="${status_val%%[!0-9]*}"
                    ;;
            esac
        done <<EOF
$batt_dump
EOF
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
CLEAR_CACHE="${CLEAR_CACHE:-false}"

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

# allow testing override for tier classification
if [ -n "${TEST_TIER:-}" ]; then
    tier="$TEST_TIER"
    if [ "$tier" = "flagship" ]; then
        filter="speed"
    elif [ "$tier" = "mid" ]; then
        filter="speed-profile"
    elif [ "$tier" = "entry" ]; then
        if [ "$sdk_version" -ge 31 ]; then
            filter="verify"
        else
            filter="quicken"
        fi
    fi
fi

log_echo "Device Classification: $tier Tier (RAM: ${mem_total_mb}MB)"
log_echo "Selected Compilation Filter: $filter"

# retrieve package list and run usagestats parsing once
USE_USAGE_AWARE="false"
if [ "$tier" = "flagship" ] && [ "$CLEAR_CACHE" = "false" ]; then
    # skip usagestats parsing for flagship without clear cache
    :
else
    # query package list for never-used list generation
    list_cmd="pm list packages -3"
    if [ "$tier" = "flagship" ]; then
        list_cmd="pm list packages"
    fi
    raw_pkgs=$($list_cmd 2>/dev/null)
    
    if collect_usage_data; then
        USE_USAGE_AWARE="true"
    fi
fi

if ! command -v cmd >/dev/null 2>&1; then
    log_echo "ERROR: Package manager compilation tool 'cmd' is missing. Aborting."
    exit 1
fi

# 5. compilation process implementation
success_count=0
fail_count=0
total_pkgs=0

# read package list and set target text
if [ "$tier" = "flagship" ]; then
    log_echo "Applying global system and user application optimizations..."
    [ -z "${raw_pkgs:-}" ] && raw_pkgs=$(pm list packages 2>/dev/null)
else
    log_echo "Applying targeted user-installed application optimizations..."
    [ -z "${raw_pkgs:-}" ] && raw_pkgs=$(pm list packages -3 2>/dev/null)
fi

# calculate packages count using pure redirection loop
while IFS= read -r line; do
    [ -n "$line" ] && total_pkgs=$((total_pkgs + 1))
done <<EOF
$raw_pkgs
EOF

if [ "$total_pkgs" -eq 0 ]; then
    log_echo "No packages found to compile."
else
    current=1
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        pkg="${line#package:}"
        pkg="${pkg%%$CR*}"
        [ -z "$pkg" ] && continue

        # resolve filter per-package
        pkg_filter="$filter"
        pkg_bucket="normal"
        if [ "$USE_USAGE_AWARE" = "true" ]; then
            pkg_bucket=$(get_usage_bucket "$pkg")
            pkg_filter=$(resolve_filter "$tier" "$pkg_bucket")
        fi

        percent=$(( (current * 100) / total_pkgs ))
        if [ "$USE_USAGE_AWARE" = "true" ]; then
            bucket_tag="NORMAL"
            if [ "$pkg_bucket" = "top" ]; then
                bucket_tag="TOP-USE"
            elif [ "$pkg_bucket" = "never" ]; then
                bucket_tag="NEVER"
            fi
            log_echo "[$percent%] Optimizing ($current/$total_pkgs): $pkg [$bucket_tag]"
            
            if [ "$DRY_RUN" -eq 1 ]; then
                cnt=$(get_usage_count "$pkg" "$USAGE_UNIQUE_FILE" || echo "0")
                spacing=" "
                if [ "$pkg_bucket" = "never" ]; then
                    spacing="   "
                elif [ "$pkg_bucket" = "normal" ]; then
                    spacing="  "
                fi
                log_echo "[DRY-RUN][$bucket_tag]$spacing$pkg → $pkg_filter (launched $cnt times)"
            fi
        else
            log_echo "[$percent%] Optimizing ($current/$total_pkgs): $pkg"
        fi

        if [ "$CLEAR_CACHE" = "true" ]; then
            execute_cmd cmd package compile --reset "$pkg"
        fi

        pkg_start=$(date +%s)
        
        # execute compilation and capture exit status
        compile_status=0
        execute_cmd cmd package compile -m "$pkg_filter" "$pkg" || compile_status=$?
        
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

# 6. optimization summary generation
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

log_echo ""
log_echo "=== OPTIMIZATION SUMMARY ==="
log_echo "Device Tier      : $tier"
log_echo "Selected Filter  : $filter"
log_echo "Cache Cleaned    : $CLEAR_CACHE"
log_echo "Usage-Aware Mode : $USE_USAGE_AWARE"
log_echo "Succeeded Apps   : $success_count"
log_echo "Failed Apps      : $fail_count"
log_echo "Elapsed Duration : ${ELAPSED}s"
log_echo "============================"
log_echo "Log file saved at: $LOG_FILE"
log_echo ""

log_echo "=================================================="
log_echo "Optimization Complete."
log_echo "Please reboot your device to apply system layers."
log_echo "=================================================="
