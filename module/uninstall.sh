#!/system/bin/sh
MODDIR=${0%/*}

# reset optimization state
if command -v cmd >/dev/null 2>&1; then
    cmd package compile --reset -a 2>/dev/null || true
fi

# clean up dexforge log file
rm -f "$MODDIR/dexforge.log"
