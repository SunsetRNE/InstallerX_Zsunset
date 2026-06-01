#!/system/bin/sh
# ============================================================
# post-fs-data.sh — InstallerX Zsunset 早期启动脚本
# 作者: 暮雨连秋冬
# 功能: 快速更新检测 + 防回退守卫 + bind mount
# ============================================================

MODDIR=${0%/*}

# 加载共享库
[ -f "$MODDIR/common.sh" ] && . "$MODDIR/common.sh"

# 读取状态
ENGINE="$(cat "$MODDIR/engine" 2>/dev/null)"
PKG="$(cat "$MODDIR/target_pkg" 2>/dev/null)"
TARGET_FILE="$(cat "$MODDIR/target_apk" 2>/dev/null)"

# ============================================================
# ★ 快速更新检测：检查 /data/local/installerx_update/
# ============================================================
check_quick_update "$MODDIR"
HAS_UPDATE=$?  # 1=执行了更新

# ============================================================
# ★ 防回退守卫
# ============================================================
anti_rollback_guard "$MODDIR"

# ============================================================
# 如果 need_remount 标记存在，或引擎是 bind，执行挂载
# ============================================================
NEED_REMOUNT=0
[ -f "$MODDIR/need_remount" ] && NEED_REMOUNT=1

if [ "$NEED_REMOUNT" = "1" ] || [ "$ENGINE" = "bind" ] || [ "$HAS_UPDATE" = "1" ]; then
    ensure_bind_mount "$MODDIR" "$TARGET_FILE" "$PKG"
    rc=$?
    [ $rc -eq 0 ] && rm -f "$MODDIR/need_remount" >/dev/null 2>&1
fi

# ============================================================
# ★ 图标修复第二阶段
# ============================================================
[ -f "$FORCE_REFRESH_FLAG" ] && force_refresh_package_icon "$PKG" 2

exit 0