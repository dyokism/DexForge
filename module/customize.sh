#!/system/bin/sh
# dexforge installer script (posix compliant busybox ash)

# prevent exit calls as it is sourced
# verify installation environment
if [ -z "$API" ] || [ "$API" -lt 24 ]; then
  abort "[!] Unsupported Android version (API $API). Requires API 24+ (Nougat+)."
fi

ui_print "- Installing DexForge..."
ui_print "- Target Path: $MODPATH"

# rebuild custom partition layout symlinks for ksu/apatch compatibility
for partition in product vendor system_ext odm; do
  if [ -d "$MODPATH/system/$partition" ] && [ -L "/system/$partition" ]; then
    ln -sf "./system/$partition" "$MODPATH/$partition"
  fi
done

# set permissions for module scripts
set_perm "$MODPATH/action.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755
set_perm "$MODPATH/service.sh" 0 0 0755

ui_print "- Action script registered successfully."
