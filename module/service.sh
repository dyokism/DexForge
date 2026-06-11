#!/system/bin/sh
# dexforge late-boot service script (posix compliant busybox ash)

MODDIR="${0%/*}"
CR=$(printf '\r')

# safe boot completion polling (ksu/apatch/magisk compatible)
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
            return 0
        fi
        sleep 2
        elapsed=$((elapsed + 2))
    done
}

resolve_cpu_mask() {
    # resolve lower half of logical cores dynamically
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

# run optimization setup asynchronously to prevent blocking boot
(
    poll_boot_completed

    # set background dexopt compilation filters
    resetprop -n pm.dexopt.bg-dexopt speed-profile 2>/dev/null || setprop pm.dexopt.bg-dexopt speed-profile
    resetprop -n pm.dexopt.shared speed 2>/dev/null || setprop pm.dexopt.shared speed

    # restrict background aot compiler threads dynamically based on topology
    cpu_mask=$(resolve_cpu_mask)
    resetprop -n dalvik.vm.dex2oat-cpu-set "$cpu_mask" 2>/dev/null || setprop dalvik.vm.dex2oat-cpu-set "$cpu_mask"
    resetprop -n dalvik.vm.dex2oat-threads 4 2>/dev/null || setprop dalvik.vm.dex2oat-threads 4
) &
