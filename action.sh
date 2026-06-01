#!/system/bin/sh
# ============================================================
# action.sh — InstallerX Zsunset 快捷启动
# 作者: 暮雨连秋冬
# 功能: 启动当前安装的安装器应用
# ============================================================

MODDIR=${0%/*}
PRIMARY_PKG=""
[ -f "$MODDIR/target_pkg" ] && PRIMARY_PKG="$(cat "$MODDIR/target_pkg" 2>/dev/null)"

# 启动函数：多方式尝试
launch_pkg() {
    local pkg="$1"
    [ -n "$pkg" ] || return 1
    pm list packages 2>/dev/null | grep -q "^package:$pkg$" || return 1

    # 1. 直接启动 InstallerX 的 SettingsActivity
    am start -n "$pkg/com.rosan.installer.ui.activity.SettingsActivity" >/dev/null 2>&1 && return 0
    # 2. Monkey 启动
    monkey -p "$pkg" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1 && return 0
    # 3. 标准 MAIN 启动
    am start -a android.intent.action.MAIN \
        -c android.intent.category.LAUNCHER -p "$pkg" >/dev/null 2>&1 && return 0
    # 4. 保底：应用详情页
    am start -a android.settings.APPLICATION_DETAILS_SETTINGS \
        -d "package:$pkg" >/dev/null 2>&1 && return 0
    return 1
}

# 优先启动主安装器
launch_pkg "$PRIMARY_PKG" && exit 0

# 降级尝试其他安装器包
for pkg in com.miui.packageinstaller com.google.android.packageinstaller com.android.packageinstaller \
           com.google.android.permissioncontroller com.android.permissioncontroller; do
    [ "$pkg" = "$PRIMARY_PKG" ] && continue
    launch_pkg "$pkg" && exit 0
done

exit 1
