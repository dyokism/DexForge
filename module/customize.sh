#!/system/bin/sh
# shellcheck disable=SC2034,SC3043,SC1091

ui_print "- Target Architecture : $ARCH"
ui_print "- Android SDK API Level: $API"

# Android 10 (API 29) is the minimum baseline for modular ART runtime and profiles
if [ "${API:-0}" -lt 29 ]; then
    abort "! Unsupported Android version: API $API detected (Requires Android 10+ / API 29+)."
fi

if [ -f "$MODPATH/util.sh" ]; then
    . "$MODPATH/util.sh"
else
    abort "! Corrupted module package: util.sh is missing."
fi

setup_persistent_storage

set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/dexforge_daemon.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755
set_perm "$MODPATH/util.sh" 0 0 0644

ui_print "- DexForge installation completed."
