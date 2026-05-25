#!/system/bin/sh
# shellcheck disable=SC3043

# redirect stderr for magisk
exec 2>&1

# define log file
LOG_FILE="/data/adb/modules/DexForge/dexforge.log"

# prevent screen sleep
ORIG_TIMEOUT=$(settings get system screen_off_timeout 2>/dev/null | tr -d '\r')
settings put system screen_off_timeout 1800000 2>/dev/null
svc power stayon true 2>/dev/null

cleanup() {
    # restore screen sleep on exit
    if [ -n "$ORIG_TIMEOUT" ] && [ "$ORIG_TIMEOUT" != "null" ]; then
        settings put system screen_off_timeout "$ORIG_TIMEOUT" 2>/dev/null
    fi
    svc power stayon false 2>/dev/null
}
trap cleanup EXIT INT TERM

# log helper
log_echo() {
    echo "$@"
    echo "$@" >> "$LOG_FILE"
}

# initialize log
echo "execution log - $(date)" > "$LOG_FILE"

log_echo "Starting DexForge..."
START_TIME=$(date +%s)

# device profiling
MEM_TOTAL=$(grep MemTotal /proc/meminfo | awk '{print $2}')
FREE_STORAGE_KB=$(df -k /data | awk 'NR==2 {print $4}')
SDK_VERSION=$(getprop ro.build.version.sdk | tr -d '\r')
PROF_COUNT=$(find /data/misc/profiles/cur -name "*.prof" 2>/dev/null | wc -l)

log_echo "Profiling device..."

# battery safety check
batt_level=""
if [ -f /sys/class/power_supply/battery/capacity ]; then
    batt_level=$(cat /sys/class/power_supply/battery/capacity | tr -d '\r')
fi
is_charging=0
if [ -f /sys/class/power_supply/battery/status ]; then
    batt_status=$(cat /sys/class/power_supply/battery/status | tr -d '\r')
    if [ "$batt_status" = "Charging" ] || [ "$batt_status" = "Full" ]; then
        is_charging=1
    fi
fi

if [ -z "$batt_level" ]; then
    batt_level=$(dumpsys battery 2>/dev/null | grep level | awk '{print $2}' | tr -d '\r')
    if dumpsys battery 2>/dev/null | grep -q "powered: true"; then
        is_charging=1
    fi
fi

case "$batt_level" in
    ''|*[!0-9]*) batt_level=100 ;;
esac

if [ "$batt_level" -lt 15 ] && [ "$is_charging" -ne 1 ]; then
    log_echo "ERROR: Battery level is too low ($batt_level%) and not charging. Aborting."
    exit 1
fi

# tier classification
TIER="entry"
if [ "$MEM_TOTAL" -gt 6291456 ]; then
    TIER="flagship"
elif [ "$MEM_TOTAL" -gt 3145728 ]; then
    TIER="mid"
fi

# safety checks
FREE_STORAGE_MB=$((FREE_STORAGE_KB / 1024))
if [ "$FREE_STORAGE_MB" -lt 512 ]; then
    log_echo "WARNING: Free storage is less than 512MB ($FREE_STORAGE_MB MB). Aborting."
    exit 1
fi

if [ "$SDK_VERSION" -lt 24 ]; then
    log_echo "WARNING: Unsupported Android version (SDK $SDK_VERSION). Requires SDK 24+. Aborting."
    exit 1
fi

# volume key cache option
CLEAR_CACHE="false"
choose_cache_option() {
    log_echo " "
    log_echo "=================================================="
    log_echo "Cache Reset"
    log_echo "Clearing cache resets all optimization states."
    log_echo "First compile will take significantly longer!"
    log_echo "--------------------------------------------------"
    log_echo "Vol UP   : Yes (Clear cache)"
    log_echo "Vol DOWN : No (Compile only)"
    log_echo "(Auto-skip to No in 10 seconds)"
    log_echo "=================================================="
    log_echo " "
    
    local delay=10
    local event_file="/data/local/tmp/dexforge_events"
    rm -f "$event_file"
    
    /system/bin/getevent -l > "$event_file" 2>&1 &
    local getevent_pid=$!
    
    local count=0
    local result=""
    while [ $count -lt $delay ]; do
        sleep 1
        if grep -q -i -E '(volumeup|0073)' "$event_file" 2>/dev/null; then
            result="true"
            break
        elif grep -q -i -E '(volumedown|0072)' "$event_file" 2>/dev/null; then
            result="false"
            break
        fi
        count=$((count + 1))
    done
    
    kill $getevent_pid 2>/dev/null
    wait $getevent_pid 2>/dev/null
    rm -f "$event_file"
    
    if [ "$result" = "true" ]; then
        CLEAR_CACHE="true"
        log_echo "Cache clearing: Enabled"
    else
        CLEAR_CACHE="false"
        log_echo "Cache clearing: Disabled"
    fi
}

choose_cache_option

# filter selection
FILTER="verify"
if [ "$TIER" = "flagship" ]; then
    FILTER="speed"
elif [ "$TIER" = "mid" ]; then
    if [ "$CLEAR_CACHE" = "true" ]; then
        FILTER="speed"
    elif [ "$PROF_COUNT" -gt 5 ]; then
        FILTER="speed-profile"
    else
        if [ "$SDK_VERSION" -ge 31 ]; then
            FILTER="verify"
        else
            FILTER="quicken"
        fi
    fi
else
    if [ "$SDK_VERSION" -ge 31 ]; then
        FILTER="verify"
    else
        FILTER="quicken"
    fi
fi

log_echo "Device Tier: $TIER"
log_echo "Selected Compiler Filter: $FILTER"

if ! command -v cmd >/dev/null 2>&1; then
    log_echo "ERROR: 'cmd' tool not found. Cannot recompile packages. Aborting."
    exit 1
fi

PKG_COUNT=0
FAIL_COUNT=0

# package compile execution
if [ "$TIER" = "flagship" ]; then
    log_echo "Compiling all packages (bulk compile)..."
    PKG_COUNT=$(pm list packages | wc -l)
    
    if [ "$CLEAR_CACHE" = "true" ]; then
        reset_out=$(cmd package compile --reset -a 2>&1)
        echo "$reset_out" >> "$LOG_FILE"
    fi
    
    compile_out=$(cmd package compile -m "$FILTER" -a 2>&1)
    compile_status=$?
    echo "$compile_out" >> "$LOG_FILE"
    
    if [ $compile_status -ne 0 ]; then
        log_echo "  ! Bulk compilation failed."
        FAIL_COUNT=$PKG_COUNT
    fi
else
    log_echo "Compiling user-installed packages..."
    USER_PKGS=$(pm list packages -3 | cut -f2 -d":" | tr -d '\r')
    TOTAL_PKGS=$(echo "$USER_PKGS" | grep -c "^")
    CURRENT=1

    for pkg in $USER_PKGS; do
        log_echo "Reforging ($CURRENT/$TOTAL_PKGS): $pkg"
        
        if [ "$CLEAR_CACHE" = "true" ]; then
            reset_out=$(cmd package compile --reset "$pkg" 2>&1)
            echo "$reset_out" >> "$LOG_FILE"
        fi
        
        compile_out=$(cmd package compile -m "$FILTER" "$pkg" 2>&1)
        compile_status=$?
        echo "$compile_out" >> "$LOG_FILE"
        
        if [ $compile_status -ne 0 ]; then
            log_echo "  ! Failed to compile: $pkg"
            FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
        CURRENT=$((CURRENT + 1))
    done
    PKG_COUNT=$TOTAL_PKGS
fi

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
SUCCESS_COUNT=$((PKG_COUNT - FAIL_COUNT))

# completion summary
log_echo "=== SUMMARY ==="
log_echo "Device Tier: $TIER"
log_echo "Filter Used: $FILTER"
log_echo "Clear Cache: $CLEAR_CACHE"
log_echo "Successful: $SUCCESS_COUNT"
log_echo "Failed: $FAIL_COUNT"
log_echo "Elapsed Time: ${ELAPSED}s"
log_echo "Done. Log file saved at $LOG_FILE"

if [ -n "$KSU" ] || [ -n "$APATCH" ]; then
    log_echo " "
    log_echo "=================================================="
    log_echo "Compilation Complete"
    log_echo "A reboot is highly recommended for full effect."
    log_echo "--------------------------------------------------"
    log_echo "Auto-closing in 15 seconds..."
    log_echo "=================================================="
    log_echo " "
    sleep 15
else
    log_echo " "
    log_echo "=================================================="
    log_echo "Compilation Complete"
    log_echo "A reboot is highly recommended for full effect."
    log_echo "=================================================="
    log_echo " "
fi
