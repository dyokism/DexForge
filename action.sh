#!/system/bin/sh
# dexforge action script

# redirect stderr for magisk ui
exec 2>&1

echo "[DexForge] Starting DexForge..."
START_TIME=$(date +%s)

# 1. device profiling
MEM_TOTAL=$(grep MemTotal /proc/meminfo | awk '{print $2}')
FREE_STORAGE_KB=$(df -k /data | awk 'NR==2 {print $4}')
SDK_VERSION=$(getprop ro.build.version.sdk)
PROF_COUNT=$(find /data/misc/profiles/cur -name "*.prof" 2>/dev/null | wc -l)

echo "[DexForge] Profiling device..."

# 2. tier classification
TIER="entry"
if [ "$MEM_TOTAL" -gt 6291456 ]; then
    TIER="flagship"
elif [ "$MEM_TOTAL" -gt 3145728 ]; then
    TIER="mid"
fi

# 3. safety guards
FREE_STORAGE_MB=$((FREE_STORAGE_KB / 1024))
if [ "$FREE_STORAGE_MB" -lt 512 ]; then
    echo "[DexForge] WARNING: Free storage is less than 512MB ($FREE_STORAGE_MB MB). Aborting."
    exit 1
fi

if [ "$SDK_VERSION" -lt 24 ]; then
    echo "[DexForge] WARNING: Unsupported Android version (SDK $SDK_VERSION). Requires SDK 24+. Aborting."
    exit 1
fi

# 4. filter selection
FILTER="verify"
if [ "$PROF_COUNT" -gt 5 ] && [ "$TIER" != "entry" ]; then
    FILTER="speed-profile"
elif [ "$TIER" = "flagship" ] && [ "$FREE_STORAGE_MB" -gt 3072 ]; then
    FILTER="speed"
elif [ "$TIER" = "mid" ] || [ "$TIER" = "entry" ]; then
    if [ "$SDK_VERSION" -ge 31 ]; then
        FILTER="verify"
    else
        FILTER="quicken"
    fi
fi

echo "[DexForge] Device Tier: $TIER"
echo "[DexForge] Selected Compiler Filter: $FILTER"

# 5. recompile
if ! command -v cmd >/dev/null 2>&1; then
    echo "[DexForge] ERROR: 'cmd' tool not found. Cannot recompile packages. Aborting."
    exit 1
fi

PKG_COUNT=0
FAIL_COUNT=0
if [ "$TIER" = "flagship" ]; then
    echo "[DexForge] Compiling all packages (this may take a while)..."
    PKG_COUNT=$(pm list packages | wc -l)
    if ! cmd package compile -m "$FILTER" -a; then
        echo "[DexForge] ERROR: Bulk compilation failed."
        FAIL_COUNT=$PKG_COUNT
    fi
else
    echo "[DexForge] Compiling user-installed packages only..."
    USER_PKGS=$(pm list packages -3 | cut -f2 -d":")
    TOTAL_PKGS=$(echo "$USER_PKGS" | grep -c "^")
    CURRENT=1
    
    for pkg in $USER_PKGS; do
        echo "[DexForge] - Compiling ($CURRENT/$TOTAL_PKGS): $pkg"
        if ! cmd package compile -m "$FILTER" "$pkg" >/dev/null 2>&1; then
            echo "[DexForge]   ! Failed to compile: $pkg"
            FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
        CURRENT=$((CURRENT + 1))
    done
    PKG_COUNT=$TOTAL_PKGS
fi

# 6. summary
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
SUCCESS_COUNT=$((PKG_COUNT - FAIL_COUNT))

echo "[DexForge] === SUMMARY ==="
echo "[DexForge] Device Tier: $TIER"
echo "[DexForge] Filter Used: $FILTER"
echo "[DexForge] Successful: $SUCCESS_COUNT"
echo "[DexForge] Failed: $FAIL_COUNT"
echo "[DexForge] Elapsed Time: ${ELAPSED}s"
echo "[DexForge] Done. A reboot is recommended for full effect."

# ksu/apatch auto-close workaround
if [ "$KSU" = "true" ] || [ "$APATCH" = "true" ]; then
    echo "[DexForge] KSU/APatch detected. Dialog closing in 5s..."
    sleep 5
fi
