#!/system/bin/sh
# shellcheck disable=SC2003,SC3043,SC1091

MODDIR="${0%/*}"

if [ -f "$MODDIR/util.sh" ]; then
    . "$MODDIR/util.sh"
fi

timeout=120
elapsed=0
# Polling sys.boot_completed avoids resetprop -w premature wakeups on value 0
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 2
    elapsed=$(expr "$elapsed" + 2)
    if [ "$elapsed" -ge "$timeout" ]; then
        exit 1
    fi
done

total_cpus=8
if [ -r /sys/devices/system/cpu/present ]; then
    IFS= read -r cpu_present < /sys/devices/system/cpu/present
    case "$cpu_present" in
        *-*)
            max_cpu="${cpu_present#*-}"
            max_cpu="${max_cpu%%,*}"
            min_cpu="${cpu_present%%-*}"
            if [ -n "$max_cpu" ] && [ "$max_cpu" -eq "$max_cpu" ] 2>/dev/null; then
                total_cpus=$(expr "$max_cpu" - "$min_cpu" + 1)
            fi
            ;;
    esac
fi

# Lower-half cores target the efficiency cluster, preventing compiler spikes on prime cores
little_count=$(expr "$total_cpus" / 2)
[ "$little_count" -lt 1 ] && little_count=1

case "$little_count" in
    1) cpu_mask="0" ;;
    2) cpu_mask="0,1" ;;
    3) cpu_mask="0,1,2" ;;
    4) cpu_mask="0,1,2,3" ;;
    5) cpu_mask="0,1,2,3,4" ;;
    6) cpu_mask="0,1,2,3,4,5" ;;
    *) cpu_mask="0,1,2,3" ;;
esac

thread_count="$little_count"
[ "$thread_count" -lt 2 ] && thread_count=2

set_prop_safe dalvik.vm.dex2oat-cpu-set "$cpu_mask"
set_prop_safe dalvik.vm.dex2oat-threads "$thread_count"
set_prop_safe dalvik.vm.background-dex2oat-cpu-set "$cpu_mask"
set_prop_safe dalvik.vm.background-dex2oat-threads "$thread_count"
set_prop_safe pm.dexopt.bg-dexopt speed-profile
set_prop_safe pm.dexopt.shared speed

log_info "Initialized (LITTLE cores: $cpu_mask, threads: $thread_count)."

# Spawn detached so late_start boot execution returns immediately
if command -v nohup >/dev/null 2>&1; then
    nohup sh "$MODDIR/dexforge_daemon.sh" >/dev/null 2>&1 &
else
    sh "$MODDIR/dexforge_daemon.sh" >/dev/null 2>&1 &
fi
