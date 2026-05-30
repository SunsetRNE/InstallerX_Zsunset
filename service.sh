#!/system/bin/sh

MODDIR="${0%/*}"

[ -f "$MODDIR/common.sh" ] && . "$MODDIR/common.sh"

mkdir -p "$STATE_DIR_BASE" >/dev/null 2>&1

APK_SRC="$MODDIR/apk/installer.apk"
ENGINE="$(cat "$MODDIR/engine" 2>/dev/null)"
PKG="$(cat "$MODDIR/target_pkg" 2>/dev/null)"
TARGET_FILE="$(cat "$MODDIR/target_apk" 2>/dev/null)"

i=0
while [ "$(getprop sys.boot_completed)" != "1" ] && [ $i -lt 180 ]; do
    sleep 1
    i=$((i+1))
done

prepare_nsenter
BOOT_OK=0
ACTIVE_PATH=""
[ -n "$PKG" ] && ACTIVE_PATH="$(get_first_apk_path "$PKG")"

if [ -z "$PKG" ] || [ -z "$ACTIVE_PATH" ]; then
    if [ -f "$TARGET_FILE" ]; then
        ACTIVE_PATH="$TARGET_FILE"
    fi
fi

if [ -n "$ACTIVE_PATH" ] && [ -f "$ACTIVE_PATH" ]; then
    CUR_SRC="$(mount_src_for_target "$ACTIVE_PATH")"

    if [ "$ENGINE" = "bind" ] || [ -f "$MODDIR/rollback_flag" ]; then
        if [ "$CUR_SRC" != "$APK_SRC" ]; then
            ensure_bind_mount "$MODDIR" "$TARGET_FILE" "$PKG"
            CUR_SRC="$(mount_src_for_target "$ACTIVE_PATH")"
            if [ "$CUR_SRC" = "$APK_SRC" ]; then
                BOOT_OK=0
            else
                BOOT_OK=1
            fi
        fi
        rm -f "$MODDIR/rollback_flag" >/dev/null 2>&1
    elif [ "$ENGINE" = "fix" ]; then
        if [ -f "$ACTIVE_PATH" ]; then
            BOOT_OK=0
        else
            BOOT_OK=1
        fi
    fi
else
    BOOT_OK=1
fi

VER="$(grep -m1 '^version=' "$MODDIR/module.prop" 2>/dev/null | cut -d= -f2-)"
[ -z "$VER" ] && VER="unknown"
LAST=""
[ -f "$STATE_FILE" ] && LAST="$(cat "$STATE_FILE" 2>/dev/null)"

if [ "$VER" != "$LAST" ]; then
    cleanup_installer_caches
    echo "$VER" > "$STATE_FILE"
fi

for pkg in $PACKAGES; do
    am force-stop "$pkg" >/dev/null 2>&1
done

force_refresh_package_icon "$PKG" 3

capture_common_snapshot
if [ "$BOOT_OK" -eq 0 ]; then
    set_module_desc "$STATUS_OK"
else
    set_module_desc "$STATUS_FAIL"
fi

exit 0