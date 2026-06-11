#!/system/bin/sh
# dexforge uninstaller script (posix compliant busybox ash)

MODDIR="${0%/*}"

# clean up log and temp files
rm -f "$MODDIR/dexforge.log"
rm -f /data/local/tmp/dexforge_*.tmp
rm -f /data/local/tmp/dexforge_evt.*
