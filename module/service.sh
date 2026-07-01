#!/system/bin/sh

MODDIR="${0%/*}"
CR=$(printf '\r')

# Wait for boot completion to prevent init deadlocks.
poll_boot_completed() {
    local timeout=480
    local elapsed=0
    local boot_comp
    until
        boot_comp=$(getprop sys.boot_completed 2>/dev/null || resetprop sys.boot_completed 2>/dev/null)
        boot_comp=${boot_comp%%$CR*}
        [ "$boot_comp" = "1" ]
    do
        if [ "$elapsed" -ge "$timeout" ]; then
            echo "DexForge: boot_completed wait timed out after ${timeout}s, proceeding anyway" > /dev/kmsg 2>/dev/null || true
            return 0
        fi
        sleep 2
        elapsed=$((elapsed + 2))
    done
}

# Dynamically find lower-half cores to avoid pinning compilation to prime cores on "All-Big-Core" SoCs.
resolve_cpu_mask() {
    local cpu_range max_cpus half i mask
    if [ -r /sys/devices/system/cpu/present ]; then
        read -r cpu_range < /sys/devices/system/cpu/present
        case "$cpu_range" in *-*)
            max_cpus=${cpu_range#*-}; max_cpus=${max_cpus%%[!0-9]*}
            if [ -n "$max_cpus" ] && [ "$max_cpus" -gt 0 ]; then
                half=$(( (max_cpus + 1) / 2 )); mask=""; i=0
                while [ "$i" -lt "$half" ]; do mask="${mask}${i},"; i=$((i + 1)); done
                echo "${mask%,}"; return 0
            fi;;
        esac
    fi
    echo "0,1,2,3"
}

# Run ART property overrides in background to avoid blocking late_start.
(
    poll_boot_completed

    resetprop -n pm.dexopt.bg-dexopt speed-profile 2>/dev/null || setprop pm.dexopt.bg-dexopt speed-profile
    resetprop -n pm.dexopt.shared speed 2>/dev/null || setprop pm.dexopt.shared speed

    cpu_mask=$(resolve_cpu_mask)
    thread_count=$(echo "$cpu_mask" | tr ',' '\n' | wc -l)
    [ "$thread_count" -lt 2 ] && thread_count=2
    resetprop -n dalvik.vm.dex2oat-cpu-set "$cpu_mask" 2>/dev/null || setprop dalvik.vm.dex2oat-cpu-set "$cpu_mask"
    resetprop -n dalvik.vm.dex2oat-threads "$thread_count" 2>/dev/null || setprop dalvik.vm.dex2oat-threads "$thread_count"
) &
