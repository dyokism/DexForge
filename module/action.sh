#!/system/bin/sh

# Bind stderr to stdout to prevent root managers from swallowing errors.
exec 2>&1

MODDIR="${0%/*}"
LOG_FILE="$MODDIR/dexforge.log"

CR=$(printf '\r')
GETEVENT_PID=""

TMP_DIR="/data/local/tmp"
[ ! -d "$TMP_DIR" ] && TMP_DIR="/tmp"

USAGE_TOP_FILE="$TMP_DIR/dexforge_usage_top.tmp"
USAGE_NEVER_FILE="$TMP_DIR/dexforge_usage_never.tmp"
USAGE_UNIQUE_FILE="$TMP_DIR/dexforge_usage_unique.tmp"

mkdir -p "${LOG_FILE%/*}" /data/local/tmp 2>/dev/null || true

# Keep screen awake to stop Doze mode from suspending compilation.
ORIG_TIMEOUT=$(settings get system screen_off_timeout 2>/dev/null || true)
ORIG_TIMEOUT="${ORIG_TIMEOUT%"$CR"}"
if [ -n "${ORIG_TIMEOUT:-}" ] && [ "${ORIG_TIMEOUT:-}" != "null" ]; then
    settings put system screen_off_timeout 1800000 2>/dev/null || true
fi
svc power stayon true 2>/dev/null || true

# Cleanup handler for graceful exit on interrupts.
cleanup() {
    local exit_code=$?
    
    if [ -n "${GETEVENT_PID:-}" ]; then
        kill "$GETEVENT_PID" 2>/dev/null || true
        wait "$GETEVENT_PID" 2>/dev/null || true
        GETEVENT_PID=""
    fi

    if [ -n "${ORIG_TIMEOUT:-}" ] && [ "${ORIG_TIMEOUT:-}" != "null" ]; then
        settings put system screen_off_timeout "${ORIG_TIMEOUT:-}" 2>/dev/null || true
    fi
    svc power stayon false 2>/dev/null || true
    
    rm -f "$TMP_DIR"/dexforge_usage_*.tmp
    rm -f "$TMP_DIR"/dexforge_evt.*
    
    if [ "$exit_code" -ne 0 ]; then
        echo "Error: DexForge failed with exit code $exit_code" | tee /dev/kmsg 2>/dev/null || true
    fi
    exit "$exit_code"
}
trap cleanup EXIT INT TERM

log_echo() {
    echo "$@"
    echo "$@" >> "$LOG_FILE"
}

log_printf() {
    # shellcheck disable=SC2059
    printf "$@"
    # shellcheck disable=SC2059
    printf "$@" >> "$LOG_FILE"
}

get_timestamp_ms() {
    local ts s n ms
    ts=$(date +%s%N 2>/dev/null)
    case "$ts" in
        *[!0-9]*|"")
            s="${ts%%[!0-9]*}"
            [ -z "$s" ] && s=$(date +%s 2>/dev/null)
            [ -z "$s" ] && s=0
            echo "$s 0"
            ;;
        *)
            s=${ts%?????????}
            n=${ts#"$s"}
            ms=${n%??????}
            while [ "${ms#0}" != "$ms" ] && [ -n "${ms#0}" ]; do
                ms=${ms#0}
            done
            [ -z "$ms" ] && ms=0
            echo "$s $ms"
            ;;
    esac
}

calc_duration() {
    local start_s="$1" start_ms="$2" end_s="$3" end_ms="$4"
    local ds dms
    ds=$((end_s - start_s))
    dms=$((end_ms - start_ms))
    if [ "$dms" -lt 0 ]; then
        ds=$((ds - 1))
        dms=$((dms + 1000))
    fi
    [ "$ds" -lt 0 ] && ds=0 && dms=0
    local tenth=$((dms / 100))
    echo "${ds}.${tenth}s"
}

{
    echo "DexForge 3.0"
    echo "Started: $(date)"
    echo ""
} > "$LOG_FILE"

echo "DexForge 3.0"
echo ""

START_TIME=$(date +%s)

DRY_RUN=0
if [ "${1:-}" = "--dry-run" ]; then
    DRY_RUN=1
fi

execute_cmd() {
    if [ "$DRY_RUN" -eq 1 ]; then
        echo "[dry-run] $*" >> "$LOG_FILE"
        return 0
    else
        local ec=0
        "$@" >> "$LOG_FILE" 2>&1 || ec=$?
        return $ec
    fi
}

# Parse dumpsys usagestats output via parameter expansion to avoid subshell overhead.
parse_usagestats() {
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

# Collect and sort telemetry into usage queues.
collect_usage_data() {
    raw_pkgs="${raw_pkgs:-}"
    local top_file="$USAGE_TOP_FILE"
    local never_file="$USAGE_NEVER_FILE"
    local raw_file="$TMP_DIR/dexforge_usage_raw.tmp"
    local sorted_file="$TMP_DIR/dexforge_usage_sorted.tmp"
    local unique_file="$USAGE_UNIQUE_FILE"
    local dump_file="$TMP_DIR/dexforge_usage_dump.tmp"
    
    rm -f "$top_file" "$never_file" "$raw_file" "$sorted_file" "$unique_file" "$dump_file"
    
    dumpsys usagestats > "$dump_file" 2>/dev/null
    if [ ! -s "$dump_file" ]; then
        echo "Notice: dumpsys usagestats returned empty or failed. Falling back to flat-filter." >> "$LOG_FILE"
        rm -f "$dump_file"
        return 1
    fi
    
    parse_usagestats < "$dump_file" > "$raw_file"
    rm -f "$dump_file"
    
    if [ ! -s "$raw_file" ]; then
        echo "Notice: No usage data extracted from dumpsys. Falling back to flat-filter." >> "$LOG_FILE"
        rm -f "$raw_file"
        return 1
    fi
    
    sort -rn "$raw_file" > "$sorted_file"
    
    local seen_pkgs=" "
    local active_pkgs=" "
    local top_count=0
    local cnt pkg

    while read -r cnt pkg _; do
        [ -z "$cnt" ] || [ -z "$pkg" ] && continue
        case "$seen_pkgs" in
            *" $pkg "*) continue ;;
        esac
        seen_pkgs="$seen_pkgs$pkg "
        echo "$cnt $pkg" >> "$unique_file"

        if [ "$cnt" -gt 0 ] 2>/dev/null; then
            active_pkgs="$active_pkgs$pkg "
            if [ "$top_count" -lt 10 ]; then
                echo "$pkg" >> "$top_file"
                top_count=$((top_count + 1))
            fi
        fi
    done < "$sorted_file"
    
    local line
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        pkg="${line#package:}"
        pkg="${pkg%"$CR"}"
        [ -z "$pkg" ] && continue
        
        case "$active_pkgs" in
            *" $pkg "*) ;;
            *) echo "$pkg" >> "$never_file" ;;
        esac
    done <<EOF
$raw_pkgs
EOF
    
    rm -f "$raw_file" "$sorted_file"
    touch "$top_file" "$never_file" "$unique_file"
    return 0
}

# Profile device RAM tier and limits.
mem_total_kb=0
if [ -f /proc/meminfo ]; then
    while IFS=: read -r key val; do
        if [ "$key" = "MemTotal" ]; then
            val="${val#"${val%%[! 	]*}"}"
            mem_total_kb="${val%%[!0-9]*}"
            break
        fi
    done < /proc/meminfo
fi

if [ "$mem_total_kb" -le 0 ]; then
    log_echo "Error: Failed to read MemTotal from /proc/meminfo."
    exit 1
fi

sdk_version=$(getprop ro.build.version.sdk 2>/dev/null || echo "0")
sdk_version=${sdk_version%%[!0-9]*}

if [ "$sdk_version" -eq 0 ]; then
    log_echo "Error: Failed to retrieve Android SDK level."
    exit 1
fi

if [ "$sdk_version" -lt 24 ]; then
    log_echo "Error: Unsupported Android version (SDK $sdk_version). Requires SDK 24+ (Nougat+)."
    exit 1
fi

android_rel=$(getprop ro.build.version.release 2>/dev/null || echo "Unknown")

MIN_FREE_MB=512
free_storage_mb=0

DATA_TARGET="/data"
[ ! -d "$DATA_TARGET" ] && DATA_TARGET="/"

if stat_out=$(stat -f -c '%a %S' "$DATA_TARGET" 2>/dev/null); then
    avail_blocks="${stat_out%% *}"
    block_size="${stat_out##* }"
    avail_blocks="${avail_blocks%%[!0-9]*}"
    block_size="${block_size%%[!0-9]*}"
    [ -n "$avail_blocks" ] && [ "$avail_blocks" -gt 0 ] && \
    [ -n "$block_size" ] && [ "$block_size" -gt 0 ] && \
    free_storage_mb=$(( avail_blocks * (block_size / 1024) / 1024 ))
fi

if [ "$free_storage_mb" -eq 0 ]; then
    df_out=$(df -k "$DATA_TARGET" 2>/dev/null || df "$DATA_TARGET" 2>/dev/null)
    last_line=""
    while read -r line; do
        [ -n "$line" ] && last_line="$line"
    done <<EOF
$df_out
EOF
    # shellcheck disable=SC2086
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
fi

if [ "$free_storage_mb" -lt "$MIN_FREE_MB" ]; then
    log_echo "Error: Insufficient storage (${free_storage_mb} MB available, ${MIN_FREE_MB} MB required)."
    exit 1
fi

batt_level=""
is_charging=0

if [ -f /sys/class/power_supply/battery/capacity ]; then
    read -r batt_level < /sys/class/power_supply/battery/capacity 2>/dev/null || true
    batt_level=${batt_level%%[!0-9]*}
fi
if [ -f /sys/class/power_supply/battery/status ]; then
    status_str=""
    read -r status_str < /sys/class/power_supply/battery/status 2>/dev/null || true
    status_str=${status_str%"$CR"}
    if [ "$status_str" = "Charging" ] || [ "$status_str" = "Full" ]; then
        is_charging=1
    fi
fi

if [ -z "$batt_level" ] || [ "$is_charging" -eq 0 ]; then
    batt_dump=$(dumpsys battery 2>/dev/null || true)
    if [ -n "$batt_dump" ]; then
        status_val=""
        while read -r line; do
            case "$line" in
                *level:*)
                    if [ -z "$batt_level" ]; then
                        batt_level="${line##*level: }"
                        batt_level="${batt_level%%[!0-9]*}"
                    fi
                    ;;
                *status:*)
                    status_val="${line##*status: }"
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

[ -z "$batt_level" ] && batt_level=100

if [ "$is_charging" -ne 1 ] && [ "$batt_level" -lt 15 ]; then
    log_echo "Error: Battery level low (${batt_level}%). Connect charger to proceed."
    exit 1
fi

mem_total_mb=$((mem_total_kb / 1024))
tier="entry"
filter="verify"

if [ "$mem_total_mb" -gt 6144 ]; then
    tier="flagship"
    filter="speed"
elif [ "$mem_total_mb" -gt 3072 ]; then
    tier="mid"
    filter="speed-profile"
else
    tier="entry"
    if [ "$sdk_version" -ge 31 ]; then
        filter="verify"
    else
        filter="quicken"
    fi
fi

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

log_echo "Device Profile"
log_echo "  Android        : $android_rel (API $sdk_version)"
log_echo "  Memory         : ${mem_total_mb} MB ($tier tier)"
log_echo "  Storage        : ${free_storage_mb} MB available"
if [ "$is_charging" -eq 1 ]; then
    log_echo "  Battery        : ${batt_level}% (charging)"
else
    log_echo "  Battery        : ${batt_level}%"
fi
log_echo "  Target filter  : $filter"
if [ "$DRY_RUN" -eq 1 ]; then
    log_echo "  Mode           : Dry-Run (simulation)"
fi
log_echo ""

CLEAR_CACHE="${CLEAR_CACHE:-false}"

choose_cache_option() {
    log_echo "Cache Reset"
    log_echo "  Vol Up   : Reset cache and recompile"
    log_echo "  Vol Down : Incremental compile only (default in 10s)"

    local delay=10
    local getevent_cmd
    getevent_cmd=$(command -v getevent 2>/dev/null)
    
    if [ -z "$getevent_cmd" ]; then
        CLEAR_CACHE="false"
        log_echo "  Selected : No (getevent unavailable)"
        log_echo ""
        return
    fi

    local event_file
    event_file=$(mktemp "$TMP_DIR/dexforge_evt.XXXXXX")

    $getevent_cmd -l > "$event_file" 2>&1 &
    GETEVENT_PID=$!
    
    sleep 0.5

    local elapsed=0
    local selection=""
    
    while [ "$elapsed" -lt "$delay" ]; do
        if [ -s "$event_file" ]; then
            if grep -q -i -E '(volumeup|0073)' "$event_file" 2>/dev/null; then
                selection="true"
                break
            elif grep -q -i -E '(volumedown|0072)' "$event_file" 2>/dev/null; then
                selection="false"
                break
            fi
        fi
        sleep 1
        elapsed=$((elapsed + 1))
    done

    kill "$GETEVENT_PID" 2>/dev/null || true
    wait "$GETEVENT_PID" 2>/dev/null || true
    GETEVENT_PID=""
    rm -f "$event_file"

    if [ -z "$selection" ]; then
        local keycheck_bin=""
        if [ -f "$MODDIR/keycheck" ]; then
            keycheck_bin="$MODDIR/keycheck"
        elif [ -f "$MODDIR/tools/keycheck" ]; then
            keycheck_bin="$MODDIR/tools/keycheck"
        fi

        if [ -n "$keycheck_bin" ] && [ -x "$keycheck_bin" ]; then
            local key_code=0
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
        log_echo "  Selected : Yes (reset cache)"
    else
        CLEAR_CACHE="false"
        log_echo "  Selected : No (incremental)"
    fi
    log_echo ""
}

if [ "$DRY_RUN" -eq 0 ]; then
    choose_cache_option
else
    log_echo "Cache Reset"
    log_echo "  Skipped in dry-run mode."
    log_echo ""
fi

# If incrementing existing compilation and profile data is insufficient on mid-tier,
# downgrade to verify/quicken to prevent CPU execution waste.
if [ "$tier" = "mid" ] && [ "$CLEAR_CACHE" = "false" ]; then
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
        echo "Notice: Insufficient profiles ($prof_count). Adjusted filter to $filter." >> "$LOG_FILE"
    fi
fi

USE_USAGE_AWARE="false"
if [ "$tier" = "flagship" ] && [ "$CLEAR_CACHE" = "false" ]; then
    :
else
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
    log_echo "Error: Package manager tool 'cmd' is missing."
    exit 1
fi

success_count=0
fail_count=0
total_pkgs=0

if [ "$tier" = "flagship" ]; then
    [ -z "${raw_pkgs:-}" ] && raw_pkgs=$(pm list packages 2>/dev/null)
else
    [ -z "${raw_pkgs:-}" ] && raw_pkgs=$(pm list packages -3 2>/dev/null)
fi

while IFS= read -r line; do
    [ -z "$line" ] && continue
    pkg="${line#package:}"
    pkg="${pkg%"$CR"}"
    [ -z "$pkg" ] && continue
    total_pkgs=$((total_pkgs + 1))
done <<EOF
$raw_pkgs
EOF

log_echo "Compiling Packages"
if [ "$total_pkgs" -eq 0 ]; then
    log_echo "  No packages found to compile."
else
    top_pkgs=" "
    never_pkgs=" "
    if [ "$USE_USAGE_AWARE" = "true" ]; then
        if [ -f "$USAGE_TOP_FILE" ]; then
            while IFS= read -r p; do
                p="${p%"$CR"}"
                [ -n "$p" ] && top_pkgs="${top_pkgs}${p} "
            done < "$USAGE_TOP_FILE"
        fi
        if [ -f "$USAGE_NEVER_FILE" ]; then
            while IFS= read -r p; do
                p="${p%"$CR"}"
                [ -n "$p" ] && never_pkgs="${never_pkgs}${p} "
            done < "$USAGE_NEVER_FILE"
        fi
    fi

    verify_quicken="verify"
    [ "$sdk_version" -lt 31 ] && verify_quicken="quicken"

    pkg_width=3
    [ "${#total_pkgs}" -gt "$pkg_width" ] && pkg_width="${#total_pkgs}"

    current=1
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        pkg="${line#package:}"
        pkg="${pkg%"$CR"}"
        [ -z "$pkg" ] && continue

        pkg_filter="$filter"
        pkg_bucket="normal"
        if [ "$USE_USAGE_AWARE" = "true" ]; then
            case "$top_pkgs" in
                *" $pkg "*) pkg_bucket="top" ;;
                *)
                    case "$never_pkgs" in
                        *" $pkg "*) pkg_bucket="never" ;;
                        *) pkg_bucket="normal" ;;
                    esac
                    ;;
            esac

            case "$tier" in
                entry)
                    case "$pkg_bucket" in
                        top) pkg_filter="speed-profile" ;;
                        *) pkg_filter="$verify_quicken" ;;
                    esac
                    ;;
                mid)
                    case "$pkg_bucket" in
                        top) pkg_filter="speed" ;;
                        normal) pkg_filter="speed-profile" ;;
                        never) pkg_filter="$verify_quicken" ;;
                    esac
                    ;;
                flagship)
                    case "$pkg_bucket" in
                        top|normal) pkg_filter="speed" ;;
                        never) pkg_filter="speed-profile" ;;
                    esac
                    ;;
            esac
        fi

        if [ "$CLEAR_CACHE" = "true" ]; then
            if [ "$sdk_version" -ge 34 ]; then
                execute_cmd pm art clear-app-profiles "$pkg"
            else
                execute_cmd cmd package compile --reset "$pkg"
            fi
        fi

        pkg_ts_start=$(get_timestamp_ms)
        start_s="${pkg_ts_start% *}"
        start_ms="${pkg_ts_start#* }"
        compile_status=0
        if [ "$DRY_RUN" -eq 1 ]; then
            execute_cmd cmd package compile -m "$pkg_filter" "$pkg"
        else
            execute_cmd cmd package compile -m "$pkg_filter" "$pkg" || compile_status=$?
        fi
        pkg_ts_end=$(get_timestamp_ms)
        end_s="${pkg_ts_end% *}"
        end_ms="${pkg_ts_end#* }"

        dur_str=$(calc_duration "$start_s" "$start_ms" "$end_s" "$end_ms")

        if [ "$compile_status" -ne 0 ] && [ "$DRY_RUN" -eq 0 ]; then
            log_printf '  [%0*d/%0*d] %-36s  failed (exit %d, %s)\n' \
                "$pkg_width" "$current" "$pkg_width" "$total_pkgs" "$pkg" "$compile_status" "$dur_str"
            fail_count=$((fail_count + 1))
        else
            if [ "$DRY_RUN" -eq 1 ]; then
                log_printf '  [%0*d/%0*d] %-36s  %-13s  (dry-run)\n' \
                    "$pkg_width" "$current" "$pkg_width" "$total_pkgs" "$pkg" "$pkg_filter"
            else
                log_printf '  [%0*d/%0*d] %-36s  %-13s  %s\n' \
                    "$pkg_width" "$current" "$pkg_width" "$total_pkgs" "$pkg" "$pkg_filter" "$dur_str"
            fi
            success_count=$((success_count + 1))
        fi

        current=$((current + 1))
    done <<EOF
$raw_pkgs
EOF
fi

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
[ "$ELAPSED" -lt 0 ] && ELAPSED=0

if [ "$ELAPSED" -ge 60 ]; then
    mins=$((ELAPSED / 60))
    secs=$((ELAPSED % 60))
    duration_str="${mins}m ${secs}s"
else
    duration_str="${ELAPSED}s"
fi

log_echo ""
log_echo "Summary"
log_echo "  Device tier    : $tier"
log_echo "  Default filter : $filter"
log_echo "  Cache cleared  : $CLEAR_CACHE"
log_echo "  Usage aware    : $USE_USAGE_AWARE"
log_echo "  Packages total : $total_pkgs"
log_echo "  Compiled       : $success_count"
log_echo "  Failed         : $fail_count"
log_echo "  Duration       : $duration_str"
log_echo "  Log saved to   : $LOG_FILE"
log_echo ""
log_echo "Reboot recommended to complete optimization."
