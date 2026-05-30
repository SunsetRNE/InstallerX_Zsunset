#!/system/bin/sh

MODDIR=${0%/*}

[ -f "$MODDIR/common.sh" ] && . "$MODDIR/common.sh"

ENGINE="$(cat "$MODDIR/engine" 2>/dev/null)"
PKG="$(cat "$MODDIR/target_pkg" 2>/dev/null)"
TARGET_FILE="$(cat "$MODDIR/target_apk" 2>/dev/null)"

check_quick_update "$MODDIR"
HAS_UPDATE=$?  # 1=执行了更新

anti_rollback_guard "$MODDIR"

NEED_REMOUNT=0
[ -f "$MODDIR/need_remount" ] && NEED_REMOUNT=1

if [ "$NEED_REMOUNT" = "1" ] || [ "$ENGINE" = "bind" ] || [ "$HAS_UPDATE" = "1" ]; then
    ensure_bind_mount "$MODDIR" "$TARGET_FILE" "$PKG"
    rm -f "$MODDIR/need_remount" >/dev/null 2>&1
fi

[ -f "$FORCE_REFRESH_FLAG" ] && force_refresh_package_icon "$PKG" 2

exit 0