#!/system/bin/sh
# shellcheck disable=SC3043

MODDIR="${0%/*}"
PERSISTENT="/data/adb/modules_config/DexForge"

rm -rf "$PERSISTENT" 2>/dev/null || true
rm -f "$MODDIR"/module.prop.tmp.* 2>/dev/null || true
