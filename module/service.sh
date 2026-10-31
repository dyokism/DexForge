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

# Resolve efficiency cluster deterministically across GKI 4.19-6.6 and diverse SoCs
_raw_cpus=""

# Priority 1: Hardware DVFS domain for CPU0 (immune to DynamIQ 0-7 package_cpus_list)
if [ -r "/sys/devices/system/cpu/cpufreq/policy0/related_cpus" ]; then
    read -r _raw_cpus < "/sys/devices/system/cpu/cpufreq/policy0/related_cpus"
elif [ -r "/sys/devices/system/cpu/cpu0/cpufreq/related_cpus" ]; then
    read -r _raw_cpus < "/sys/devices/system/cpu/cpu0/cpufreq/related_cpus"
elif [ -r "/sys/devices/system/cpu/cpu0/cpufreq/affected_cpus" ]; then
    read -r _raw_cpus < "/sys/devices/system/cpu/cpu0/cpufreq/affected_cpus"
fi

# Priority 2: Minimum cpu_capacity tier scan (fallback if cpufreq sysfs is hidden)
if [ -z "$_raw_cpus" ] && [ -r "/sys/devices/system/cpu/cpu0/cpu_capacity" ]; then
    _min_cap=999999
    for _cap_file in /sys/devices/system/cpu/cpu[0-9]*/cpu_capacity; do
        [ -r "$_cap_file" ] || continue
        read -r _cap < "$_cap_file"
        case "$_cap" in
            ''|*[!0-9]*) continue ;;
        esac
        if [ "$_cap" -lt "$_min_cap" ] 2>/dev/null; then
            _min_cap="$_cap"
        fi
    done
    for _cpu_dir in /sys/devices/system/cpu/cpu[0-9]*; do
        [ -r "$_cpu_dir/cpu_capacity" ] || continue
        read -r _cap < "$_cpu_dir/cpu_capacity"
        if [ "$_cap" = "$_min_cap" ]; then
            _cid="${_cpu_dir##*cpu}"
            _raw_cpus="${_raw_cpus:+$_raw_cpus }$_cid"
        fi
    done
fi

# Priority 3: Topology cluster_cpus_list or core_siblings_list (legacy kernel fallback)
if [ -z "$_raw_cpus" ]; then
    if [ -r "/sys/devices/system/cpu/cpu0/topology/cluster_cpus_list" ]; then
        read -r _raw_cpus < "/sys/devices/system/cpu/cpu0/topology/cluster_cpus_list"
    elif [ -r "/sys/devices/system/cpu/cpu0/topology/core_siblings_list" ]; then
        read -r _raw_cpus < "/sys/devices/system/cpu/cpu0/topology/core_siblings_list"
    fi
fi

# Normalize syntax ("0-2", "0 1 2", "0,1,2", "0-2,4") into space-separated integers
_expanded=""
_old_ifs="$IFS"
IFS=', '
for _token in $_raw_cpus; do
    case "$_token" in
        *-*)
            _start="${_token%-*}"
            _end="${_token#*-}"
            _curr="$_start"
            while [ "$_curr" -le "$_end" ] 2>/dev/null; do
                _expanded="${_expanded:+$_expanded }$_curr"
                _curr=$(expr "$_curr" + 1)
            done
            ;;
        [0-9]*)
            _expanded="${_expanded:+$_expanded }$_token"
            ;;
    esac
done
IFS="$_old_ifs"

# Guard: If fallback returned full-chip (8+ cores) from DynamIQ core_siblings_list, clamp to 0-3
_count=0
for _c in $_expanded; do
    _count=$(expr "$_count" + 1)
done
if [ "$_count" -ge 8 ] || [ -z "$_expanded" ]; then
    _expanded="0 1 2 3"
    _count=4
fi

# Build comma-separated mask and thread count
cpu_mask=""
for _c in $_expanded; do
    cpu_mask="${cpu_mask:+$cpu_mask,}$_c"
done

thread_count="$_count"
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
