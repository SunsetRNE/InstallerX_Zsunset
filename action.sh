#!/system/bin/sh

MODDIR=${0%/*}
PRIMARY_PKG=""
[ -f "$MODDIR/target_pkg" ] && PRIMARY_PKG="$(cat "$MODDIR/target_pkg" 2>/dev/null)"

launch_pkg() {
    local pkg="$1"
    [ -n "$pkg" ] || return 1
    pm list packages 2>/dev/null | grep -q "^package:$pkg$" || return 1

    am start -n "$pkg/com.rosan.installer.ui.activity.SettingsActivity" >/dev/null 2>&1 && return 0
    monkey -p "$pkg" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1 && return 0
    am start -a android.intent.action.MAIN \
        -c android.intent.category.LAUNCHER -p "$pkg" >/dev/null 2>&1 && return 0
    am start -a android.settings.APPLICATION_DETAILS_SETTINGS \
        -d "package:$pkg" >/dev/null 2>&1 && return 0
    return 1
}

launch_pkg "$PRIMARY_PKG" && exit 0

for pkg in com.google.android.packageinstaller com.android.packageinstaller; do
    [ "$pkg" = "$PRIMARY_PKG" ] && continue
    launch_pkg "$pkg" && exit 0
done

exit 1