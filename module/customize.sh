#!/system/bin/sh

MODDIR="${MODPATH:-${0%/*}}"
: "$MODDIR"

API="${API:-0}"
[ "$API" -eq 0 ] && API=$(getprop ro.build.version.sdk 2>/dev/null)
API="${API:-0}"

if [ "$API" -lt 24 ]; then
  abort "[!] Unsupported Android version (API $API). Requires API 24+ (Nougat+)."
fi

# Detect root manager
if [ "${APATCH:-}" = "true" ]; then
  if [ -n "${APATCH_VER:-}" ]; then
    ROOT_MGR="APatch ($APATCH_VER)"
  else
    ROOT_MGR="APatch"
  fi
elif [ "${KSU:-}" = "true" ]; then
  if [ -n "${KSU_VER:-}" ]; then
    ROOT_MGR="KernelSU ($KSU_VER)"
  else
    ROOT_MGR="KernelSU"
  fi
elif [ -n "${MAGISK_VER:-}" ]; then
  ROOT_MGR="Magisk ($MAGISK_VER)"
else
  ROOT_MGR="Unknown / Generic"
fi

ANDROID_REL=$(getprop ro.build.version.release 2>/dev/null || echo "Unknown")

CPU_CORES=""
if [ -r /sys/devices/system/cpu/present ]; then
  read -r cpu_range < /sys/devices/system/cpu/present
  case "$cpu_range" in *-*)
    max_cpus=${cpu_range#*-}
    max_cpus=${max_cpus%%[!0-9]*}
    [ -n "$max_cpus" ] && CPU_CORES=$((max_cpus + 1))
    ;;
  esac
fi
if [ -z "$CPU_CORES" ]; then
  CPU_CORES=$(grep -c '^processor' /proc/cpuinfo 2>/dev/null || echo "Unknown")
fi

ui_print " "
ui_print "DexForge 3.0"
ui_print " "
ui_print "Environment"
ui_print "  Android   : $ANDROID_REL (API $API)"
ui_print "  Manager   : $ROOT_MGR"
ui_print "  Processor : $CPU_CORES cores"
ui_print " "
ui_print "Installing"
ui_print "  Target    : $MODPATH"

# Upgrade cache cleanup: remove stale temporary files and logs from prior installations
rm -f /data/local/tmp/dexforge_* 2>/dev/null
rm -f "$MODPATH/dexforge.log" 2>/dev/null

# Enforce execution permissions
set_perm "$MODPATH/action.sh" 0 0 0755
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755

ui_print " "
ui_print "Setup complete. Reboot required."
ui_print " "
