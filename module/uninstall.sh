#!/system/bin/sh
# dexforge uninstaller script (posix compliant busybox ash)

MODDIR="${0%/*}"

# clean up log files
rm -f "$MODDIR/dexforge.log"
