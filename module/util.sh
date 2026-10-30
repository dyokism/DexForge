#!/system/bin/sh
# shellcheck disable=SC3043,SC2034

MODDIR="${MODDIR:-${0%/*}}"
MODID="DexForge"

PERSISTENT="/data/adb/modules_config/${MODID}"
LEGACY_PERSISTENT="/data/adb/${MODID}"
STATE_FILE="${PERSISTENT}/boot_state"
LOG_FILE="${PERSISTENT}/${MODID}.log"
LOCK_DIR="${PERSISTENT}/state.lock"
RESETPROP_BIN=""

setup_persistent_storage() {
    [ -n "$MODID" ] || return 1
    if [ ! -d "$PERSISTENT" ]; then
        mkdir -p "$PERSISTENT" 2>/dev/null
        chmod 0700 "$PERSISTENT" 2>/dev/null
    fi
    if [ -d "$LEGACY_PERSISTENT" ] && [ "$LEGACY_PERSISTENT" != "$PERSISTENT" ] && [ "$LEGACY_PERSISTENT" != "/data/adb" ]; then
        cp -af "${LEGACY_PERSISTENT}/." "$PERSISTENT/" 2>/dev/null
        rm -rf "$LEGACY_PERSISTENT" 2>/dev/null
    fi
    if [ -n "$MODDIR" ] && [ -f "$MODDIR/dexforge.log" ]; then
        if [ ! -f "$LOG_FILE" ]; then
            mv -f "$MODDIR/dexforge.log" "$LOG_FILE" 2>/dev/null || cat "$MODDIR/dexforge.log" >> "$LOG_FILE" 2>/dev/null
        else
            cat "$MODDIR/dexforge.log" >> "$LOG_FILE" 2>/dev/null
        fi
        rm -f "$MODDIR"/dexforge.log* 2>/dev/null || true
    fi
}

# Monotonic uptime avoids misleading 1970 timestamps before RTC sync in early boot
get_uptime() {
    if [ -f /proc/uptime ]; then
        local uptime_sec rest
        read -r uptime_sec rest < /proc/uptime 2>/dev/null
        printf '%ss' "${uptime_sec%%.*}"
    else
        date "+%Y-%m-%d %H:%M:%S"
    fi
}

# Dual logging writes to kmsg for dmesg post-crash triage and to disk for manager inspection
log_info() {
    setup_persistent_storage
    local ts
    ts=$(get_uptime)
    local msg="[${ts}][${MODID}][INFO]: $*"
    [ -w /dev/kmsg ] && printf '<6>%s\n' "$msg" > /dev/kmsg 2>/dev/null
    printf '%s\n' "$msg" >> "$LOG_FILE" 2>/dev/null
}

log_warn() {
    setup_persistent_storage
    local ts
    ts=$(get_uptime)
    local msg="[${ts}][${MODID}][WARN]: $*"
    [ -w /dev/kmsg ] && printf '<4>%s\n' "$msg" > /dev/kmsg 2>/dev/null
    printf '%s\n' "$msg" >> "$LOG_FILE" 2>/dev/null
}

log_error() {
    setup_persistent_storage
    local ts
    ts=$(get_uptime)
    local msg="[${ts}][${MODID}][ERROR]: $*"
    [ -w /dev/kmsg ] && printf '<3>%s\n' "$msg" > /dev/kmsg 2>/dev/null
    printf '%s\n' "$msg" >> "$LOG_FILE" 2>/dev/null
}

resolve_resetprop() {
    [ -n "$RESETPROP_BIN" ] && return 0
    if command -v resetprop >/dev/null 2>&1; then
        RESETPROP_BIN="$(command -v resetprop)"
        return 0
    fi
    for p in \
        /data/adb/ksu/bin/resetprop \
        /data/adb/magisk/resetprop \
        /data/adb/ap/bin/resetprop \
        /system/bin/resetprop; do
        if [ -x "$p" ]; then
            RESETPROP_BIN="$p"
            return 0
        fi
    done
    if command -v magisk >/dev/null 2>&1; then
        RESETPROP_BIN="magisk resetprop"
        return 0
    elif command -v ksud >/dev/null 2>&1; then
        RESETPROP_BIN="ksud resetprop"
        return 0
    fi
    return 1
}

# Bypasses init socket IPC via -n to prevent circular deadlocks
set_prop_safe() {
    local prop="$1"
    local val="$2"
    resolve_resetprop || return 1
    $RESETPROP_BIN -n "$prop" "$val"
}

# Atomic rename avoids empty-file reads by manager dashboards polling module.prop
update_description() {
    local new_desc="$1"
    local prop_file="${MODDIR}/module.prop"
    [ -f "$prop_file" ] || return 1
    local tmp_file="${prop_file}.tmp.$$"

    if grep -v '^description=' "$prop_file" > "$tmp_file" 2>/dev/null; then
        printf 'description=%s\n' "$new_desc" >> "$tmp_file"
        chmod 644 "$tmp_file" 2>/dev/null
        chcon --reference="$prop_file" "$tmp_file" 2>/dev/null || true
        mv -f "$tmp_file" "$prop_file" 2>/dev/null && return 0
    fi
    rm -f "$tmp_file" 2>/dev/null
    return 1
}

# mkdir is atomic at the VFS layer, providing mutex when flock is unavailable
acquire_lock() {
    local timeout="${1:-5}"
    local count=0
    setup_persistent_storage
    while ! mkdir "$LOCK_DIR" 2>/dev/null; do
        sleep 1
        count=$((count + 1))
        [ "$count" -ge "$timeout" ] && return 1
    done
    return 0
}

release_lock() {
    rm -rf "$LOCK_DIR" 2>/dev/null
}

write_state() {
    local key="$1"
    local val="$2"
    setup_persistent_storage
    acquire_lock 5 || return 1
    local tmp_file="${STATE_FILE}.tmp.$$"

    if [ -f "$STATE_FILE" ]; then
        grep -v "^${key}=" "$STATE_FILE" > "$tmp_file" 2>/dev/null || true
    fi
    printf '%s=%s\n' "$key" "$val" >> "$tmp_file"
    chmod 0600 "$tmp_file" 2>/dev/null || true
    mv -f "$tmp_file" "$STATE_FILE" 2>/dev/null
    release_lock
    return 0
}

read_state() {
    local key="$1"
    local default_val="${2:-}"
    [ -f "$STATE_FILE" ] || { printf '%s\n' "$default_val"; return 1; }
    local val
    val=$(grep "^${key}=" "$STATE_FILE" 2>/dev/null | head -1 | cut -d= -f2-)
    if [ -n "$val" ]; then
        printf '%s\n' "$val"
        return 0
    fi
    printf '%s\n' "$default_val"
    return 1
}
