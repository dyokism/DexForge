#!/system/bin/sh

# Requires Nougat ART daemon for speed-profile compilation. Use abort since exit traps the root manager.
if [ -z "$API" ] || [ "$API" -lt 24 ]; then
  abort "[!] Unsupported Android version (API $API). Requires API 24+ (Nougat+)."
fi

ui_print "- Installing DexForge..."
ui_print "- Target Path: $MODPATH"

# Prevent execution denial when running from CLI or service daemon.
set_perm "$MODPATH/action.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755
set_perm "$MODPATH/service.sh" 0 0 0755

ui_print "- Action script registered successfully."
