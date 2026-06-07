#!/system/bin/sh
# dexforge late-boot service script (posix compliant busybox ash)

MODDIR="${0%/*}"

# safe boot completion polling (ksu/apatch/magisk compatible)
poll_boot_completed() {
    local timeout=480
    local elapsed=0
    until [ "$(getprop sys.boot_completed)" = "1" ] || [ "$(resetprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; do
        if [ "$elapsed" -ge "$timeout" ]; then
            return 0
        fi
        sleep 2
        elapsed=$((elapsed + 2))
    done
}

# run optimization setup asynchronously to prevent blocking boot
(
    poll_boot_completed

    # set background dexopt compilation filters
    resetprop -n pm.dexopt.bg-dexopt speed-profile 2>/dev/null || setprop pm.dexopt.bg-dexopt speed-profile
    resetprop -n pm.dexopt.shared speed 2>/dev/null || setprop pm.dexopt.shared speed

    # restrict background aot compiler threads to low-power cores (e.g., cores 0-3)
    # warning: hardcoded assumption that cores 0-3 are efficiency/little cores
    # on some modern soc topologies (e.g., snapdragon prime-first layouts),
    # this affinity mask may need layout-specific tuning.
    resetprop -n dalvik.vm.dex2oat-cpu-set 0,1,2,3 2>/dev/null || setprop dalvik.vm.dex2oat-cpu-set 0,1,2,3
    resetprop -n dalvik.vm.dex2oat-threads 4 2>/dev/null || setprop dalvik.vm.dex2oat-threads 4
) &
