#!/system/bin/sh

# reset optimization state
cmd package compile --reset -a 2>/dev/null

# clean up dexforge log file
rm -f /data/adb/modules/DexForge/dexforge.log
