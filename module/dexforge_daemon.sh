#!/system/bin/sh
# shellcheck disable=SC2003,SC2086,SC3043,SC1091

MODDIR="${0%/*}"

if [ -f "$MODDIR/util.sh" ]; then
    . "$MODDIR/util.sh"
fi

setup_persistent_storage
LOGFILE="${LOG_FILE:-/data/adb/modules_config/DexForge/DexForge.log}"
PIDFILE="/data/local/tmp/dexforge_daemon.pid"

# Single-instance lock prevents multiple daemon processes racing on queue and compiler
if [ -f "$PIDFILE" ]; then
    _old_pid=$(cat "$PIDFILE" 2>/dev/null)
    if [ -n "$_old_pid" ] && kill -0 "$_old_pid" 2>/dev/null; then
        if grep -q "dexforge_daemon" /proc/"$_old_pid"/cmdline 2>/dev/null; then
            exit 0
        fi
    fi
fi
echo "$$" > "$PIDFILE"

cleanup_scratch() {
    rm -f /data/local/tmp/dexforge_* 2>/dev/null || true
    rm -f "$MODDIR"/module.prop.tmp.* 2>/dev/null || true
    rm -f "$PIDFILE" 2>/dev/null || true
}
trap cleanup_scratch EXIT INT TERM

rotate_log() {
    [ -f "$LOGFILE" ] || return 0
    _log_size=$(wc -c < "$LOGFILE" 2>/dev/null || echo 0)
    if [ "${_log_size:-0}" -gt 512000 ] 2>/dev/null; then
        mv -f "$LOGFILE" "${LOGFILE}.old" 2>/dev/null || true
    fi
}

get_sdk_version() {
    _sdk="$(getprop ro.build.version.sdk)"
    case "$_sdk" in
        ''|*[!0-9]*) _sdk=34 ;;
    esac
    printf '%s' "$_sdk"
}

# Sysfs direct reads bypass system_server Binder IPC and HAL wakeups
check_charging() {
    _status=""
    for _st in /sys/class/power_supply/battery/status /sys/class/power_supply/*/status; do
        if [ -r "$_st" ]; then
            IFS= read -r _status < "$_st"
            case "$_status" in
                Charging|Full|[cC]harging|[fF]ull) return 0 ;;
            esac
        fi
    done
    return 1
}

get_battery_temp() {
    _temp=0
    for _t_node in /sys/class/power_supply/battery/temp /sys/class/power_supply/*/temp; do
        if [ -r "$_t_node" ]; then
            IFS= read -r _temp < "$_t_node"
            [ -n "$_temp" ] && break
        fi
    done
    # Normalize millidegrees (e.g. 36000) or raw degrees (36) to standard decidegrees (360)
    if [ "${_temp:-0}" -ge 1000 ] 2>/dev/null; then
        _temp=$(expr "$_temp" / 100)
    elif [ "${_temp:-0}" -lt 100 ] && [ "${_temp:-0}" -gt 0 ] 2>/dev/null; then
        _temp=$(expr "$_temp" \* 10)
    fi
    printf '%s' "${_temp:-0}"
}

# 385 decidegrees = 38.5C; threshold chosen to keep battery below chemical aging limit
check_battery_temp_safe() {
    _t=$(get_battery_temp)
    if [ "${_t:-0}" -lt 385 ] 2>/dev/null; then
        return 0
    fi
    return 1
}

get_battery_capacity() {
    _cap=0
    for _c_node in /sys/class/power_supply/battery/capacity /sys/class/power_supply/*/capacity; do
        if [ -r "$_c_node" ]; then
            IFS= read -r _cap < "$_c_node"
            [ -n "$_cap" ] && break
        fi
    done
    printf '%s' "${_cap:-0}"
}

check_battery_capacity() {
    _c=$(get_battery_capacity)
    if [ "${_c:-0}" -ge 50 ] 2>/dev/null; then
        return 0
    fi
    return 1
}

check_screen_off() {
    _found=0
    # Must inspect all readable nodes; some vendors provide a dummy 0 node alongside the active panel
    for bl in /sys/class/leds/lcd-backlight/brightness /sys/class/backlight/*/brightness; do
        [ -r "$bl" ] || continue
        _found=1
        _br=""
        IFS= read -r _br < "$bl"
        if [ -n "$_br" ] && [ "$_br" -gt 0 ] 2>/dev/null; then
            return 1
        fi
    done
    if [ "$_found" -eq 1 ]; then
        return 0
    fi

    # Fallback to framework wakefulness state if sysfs nodes are absent
    _wake="$(dumpsys power 2>/dev/null | grep -m 1 'mWakefulness=' | cut -d= -f2)"
    case "$_wake" in
        Awake*) return 1 ;;
        *) return 0 ;;
    esac
}

# Cancels native BackgroundDexoptJob to prevent mInstallLock contention and Binder buffer exhaustion
deconflict_native_jobs() {
    _sdk=$(get_sdk_version)
    if [ "$_sdk" -ge 34 ] 2>/dev/null; then
        cmd package bg-dexopt-job --cancel 2>/dev/null | cat >/dev/null 2>&1 || true
    else
        cmd jobscheduler cancel android 800 2>/dev/null | cat >/dev/null 2>&1 || true
        cmd package bg-dexopt-job --cancel 2>/dev/null | cat >/dev/null 2>&1 || true
    fi
}

# Requires 1024MB on /data to prevent ENOSPC during temporary .vdex/.art artifact generation
check_disk_space() {
    _df_line="$(df -k /data 2>/dev/null | tail -n 1)"
    set -- $_df_line
    _avail="$4"
    if [ -n "$_avail" ] && [ "$_avail" -ge 1048576 ] 2>/dev/null; then
        return 0
    fi
    if [ -n "$_avail" ] && [ "$_avail" -lt 1048576 ] 2>/dev/null; then
        return 1
    fi
    return 0
}

count_file_lines() {
    _file="$1"
    _cnt=0
    [ -f "$_file" ] || { printf '0'; return; }
    while IFS= read -r _l || [ -n "$_l" ]; do
        [ -n "$_l" ] && _cnt=$(expr "$_cnt" + 1)
    done < "$_file"
    printf '%s' "$_cnt"
}

# Single-transaction bytecode dump parsed in pure Ash to prioritize user-installed apps
scan_unoptimized_packages() {
    _dexopt_file="/data/local/tmp/dexforge_dexopt.tmp"
    _user_queue="/data/local/tmp/dexforge_user_queue.tmp"
    _sys_queue="/data/local/tmp/dexforge_sys_queue.tmp"
    _final_queue="/data/local/tmp/dexforge_queue.tmp"
    _failed_file="/data/local/tmp/dexforge_failed.tmp"
    _compiled_file="/data/local/tmp/dexforge_compiled.tmp"

    dumpsys package dexopt 2>/dev/null | cat > "$_dexopt_file"
    # Space-padded string allows zero-fork case pattern matching: *" $pkg "*
    _user_pkgs=" $(pm list packages -3 2>/dev/null | sed 's/^package://' | tr '\n' ' ') "

    : > "$_user_queue"
    : > "$_sys_queue"

    _curr_pkg=""
    while IFS= read -r _line || [ -n "$_line" ]; do
        _trimmed="${_line#"${_line%%[! ]*}"}"
        case "$_trimmed" in
            "["*.*"]")
                _tmp_pkg="${_trimmed#\[}"
                _curr_pkg="${_tmp_pkg%%\]*}"
                ;;
            *"[status="*)
                if [ -n "$_curr_pkg" ]; then
                    _tmp_status="${_trimmed#*\[status=}"
                    _filter="${_tmp_status%%\]*}"
                    case "$_filter" in
                        speed|speed-profile|everything)
                            _curr_pkg=""
                            ;;
                        *)
                            # Skip packages already compiled or blacklisted this session to guarantee queue progression
                            if [ -f "$_compiled_file" ] && grep -Fxq "$_curr_pkg" "$_compiled_file" 2>/dev/null; then
                                _curr_pkg=""
                                continue
                            fi
                            if [ -f "$_failed_file" ] && grep -Fxq "$_curr_pkg" "$_failed_file" 2>/dev/null; then
                                _curr_pkg=""
                                continue
                            fi
                            case "$_user_pkgs" in
                                *" $_curr_pkg "*)
                                    printf '%s\n' "$_curr_pkg" >> "$_user_queue"
                                    ;;
                                *)
                                    printf '%s\n' "$_curr_pkg" >> "$_sys_queue"
                                    ;;
                            esac
                            _curr_pkg=""
                            ;;
                    esac
                fi
                ;;
        esac
    done < "$_dexopt_file"

    cat "$_user_queue" "$_sys_queue" > "$_final_queue" 2>/dev/null || true
    rm -f "$_dexopt_file" "$_user_queue" "$_sys_queue" 2>/dev/null || true
}

# Micro-batches limit thermal exposure; parallel watchdog yields within 1.5s on screen-on
compile_micro_batch() {
    _queue_file="/data/local/tmp/dexforge_queue.tmp"
    _failed_file="/data/local/tmp/dexforge_failed.tmp"
    _compiled_file="/data/local/tmp/dexforge_compiled.tmp"
    [ -f "$_queue_file" ] || return 0

    _total_unopt=$(count_file_lines "$_queue_file")
    if [ "$_total_unopt" -eq 0 ]; then
        _cap=$(get_battery_capacity)
        update_description "[Complete • All packages optimized (speed-profile) • Bat: ${_cap}%]"
        return 0
    fi

    _sdk=$(get_sdk_version)
    _batch_limit=3
    _batch_count=0
    _interrupted=0
    _batch_summary=""

    while IFS= read -r pkg || [ -n "$pkg" ]; do
        [ -n "$pkg" ] || continue
        [ "$_batch_count" -ge "$_batch_limit" ] && break

        if ! check_charging || ! check_battery_capacity || ! check_battery_temp_safe || ! check_screen_off; then
            _interrupted=1
            break
        fi

        if ! check_disk_space; then
            _interrupted=1
            log_warn "Disk space safeguard: free space < 1024MB on /data."
            break
        fi

        _t=$(get_battery_temp)
        _t_int=$(expr "${_t:-0}" / 10)
        _t_dec=$(expr "${_t:-0}" % 10)
        _t_c="${_t_int}.${_t_dec}"

        _pkg_num=$(expr "$_batch_count" + 1)
        update_description "[Active • Compiling $pkg ($_pkg_num/$_total_unopt) • ${_t_c}°C]"

        # Direct stdout to /dev/null to prevent raw 'Success' log spam; stderr piped safely through cat
        if [ "$_sdk" -ge 34 ] 2>/dev/null; then
            cmd package compile -m speed-profile -r bg-dexopt -p PRIORITY_BACKGROUND "$pkg" >/dev/null 2>&1 &
            compile_pid=$!
        else
            cmd package compile -m speed-profile -r bg-dexopt "$pkg" >/dev/null 2>&1 &
            compile_pid=$!
        fi

        _watchdog_abort=0
        while kill -0 "$compile_pid" 2>/dev/null; do
            sleep 1.5

            if ! check_screen_off || ! check_charging; then
                _watchdog_abort=1
                break
            fi

            _cur_temp=$(get_battery_temp)
            if [ "${_cur_temp:-0}" -ge 390 ] 2>/dev/null; then
                _watchdog_abort=1
                break
            fi
        done

        if [ "$_watchdog_abort" -eq 1 ]; then
            # SIGTERM to dex2oat triggers artd/installd unlinking of .tmp files with zero oat corruption
            killall -TERM dex2oat 2>/dev/null || true
            kill -TERM "$compile_pid" 2>/dev/null || true
            wait "$compile_pid" 2>/dev/null || true
            deconflict_native_jobs
            _interrupted=1
            update_description "[Paused • Interrupted by user wake / thermals]"
            log_info "Micro-batch paused (screen active or temperature ceiling reached)."
            break
        else
            wait "$compile_pid" 2>/dev/null || true
            _compile_rc=$?
            if [ "$_compile_rc" -eq 0 ]; then
                printf '%s\n' "$pkg" >> "$_compiled_file"
                if [ -z "$_batch_summary" ]; then
                    _batch_summary="$pkg"
                else
                    _batch_summary="${_batch_summary}, $pkg"
                fi
            else
                printf '%s\n' "$pkg" >> "$_failed_file"
                log_warn "Compilation failed for $pkg (code: $_compile_rc)."
            fi
            _batch_count=$(expr "$_batch_count" + 1)
        fi
    done < "$_queue_file"

    rm -f "$_queue_file" 2>/dev/null || true

    if [ "$_interrupted" -eq 1 ]; then
        return 1
    fi

    _remaining=$(expr "$_total_unopt" - "$_batch_count")
    [ "$_remaining" -lt 0 ] && _remaining=0
    log_info "Batch completed: ${_batch_count} apps compiled (${_batch_summary}). ${_remaining} remaining."
    update_description "[Idle • Batch finished (${_batch_count} compiled) • Cooling down]"
    return 0
}

idle_seconds=0
while true; do
    rotate_log

    _screen_off=0
    _charging=0
    _cap_ok=0
    _temp_ok=0

    check_screen_off && _screen_off=1
    check_charging && _charging=1
    check_battery_capacity && _cap_ok=1
    check_battery_temp_safe && _temp_ok=1

    if [ "$_screen_off" -eq 1 ] && [ "$_charging" -eq 1 ] && [ "$_cap_ok" -eq 1 ] && [ "$_temp_ok" -eq 1 ]; then
        idle_seconds=$(expr "$idle_seconds" + 5)
        _cap=$(get_battery_capacity)

        # 120s deep idle window ensures device is not in transient screen off/on usage
        if [ "$idle_seconds" -lt 120 ]; then
            update_description "[Idle • Settle: ${idle_seconds}s/120s • Bat: ${_cap}%]"
            sleep 5
            continue
        fi

        if ! check_disk_space; then
            update_description "[Paused • Low storage (<1024MB free) • Bat: ${_cap}%]"
            sleep 30
            continue
        fi

        deconflict_native_jobs
        scan_unoptimized_packages

        if compile_micro_batch; then
            idle_seconds=60
            sleep 15
        else
            idle_seconds=0
            sleep 5
        fi
    else
        idle_seconds=0
        _cap=$(get_battery_capacity)
        if [ "$_screen_off" -eq 0 ]; then
            update_description "[Paused • Screen active • Bat: ${_cap}%]"
        elif [ "$_charging" -eq 0 ]; then
            update_description "[Paused • Discharging • Bat: ${_cap}%]"
        elif [ "$_cap_ok" -eq 0 ]; then
            update_description "[Paused • Battery low (<50%) • Bat: ${_cap}%]"
        else
            update_description "[Paused • High battery temp • Bat: ${_cap}%]"
        fi
        sleep 5
    fi
done
