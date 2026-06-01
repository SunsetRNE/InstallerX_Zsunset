#!/system/bin/sh

MODID="installerx_zsunset"
STATE_DIR="/data/adb/$MODID"
PACKAGES="com.miui.packageinstaller com.google.android.packageinstaller com.android.packageinstaller com.android.permissioncontroller com.google.android.permissioncontroller"

TARGETS_TMP="/dev/tmp/installerx_targets.$$"
[ -d /dev/tmp ] || TARGETS_TMP="/data/local/tmp/installerx_targets.$$"

cleanup() { rm -f "$TARGETS_TMP" >/dev/null 2>&1; }
trap cleanup EXIT
mkdir -p "$(dirname "$TARGETS_TMP")" >/dev/null 2>&1
: > "$TARGETS_TMP"

find_modpath() {
    if [ -n "$MODPATH" ] && [ -d "$MODPATH" ]; then
        echo "$MODPATH"
        return 0
    fi
    for base in /data/adb/modules_update /data/adb/modules; do
        [ -d "$base" ] || continue
        for d in "$base"/*; do
            [ -d "$d" ] || continue
            if [ -f "$d/module.prop" ] && grep -q '^id=InstallerX_Zsunset$' "$d/module.prop" 2>/dev/null; then
                echo "$d"
                return 0
            fi
        done
    done
    return 1
}

MODPATH="$(find_modpath 2>/dev/null)"
APK_SRC=""
SAVED_TARGET=""
SAVED_PKG=""
SAVED_DIR=""
ENGINE=""

if [ -n "$MODPATH" ] && [ -d "$MODPATH" ]; then
    APK_SRC="$MODPATH/apk/installer.apk"
    SAVED_TARGET="$(cat "$MODPATH/target_apk" 2>/dev/null)"
    SAVED_PKG="$(cat "$MODPATH/target_pkg" 2>/dev/null)"
    SAVED_DIR="$(cat "$MODPATH/target_folder" 2>/dev/null)"
    ENGINE="$(cat "$MODPATH/engine" 2>/dev/null)"
fi

SELF_NS="$(readlink /proc/self/ns/mnt 2>/dev/null)"
INIT_NS="$(readlink /proc/1/ns/mnt 2>/dev/null)"
RUN_CMD=""
if [ -n "$SELF_NS" ] && [ -n "$INIT_NS" ] && [ "$SELF_NS" != "$INIT_NS" ]; then
    if command -v nsenter >/dev/null 2>&1; then
        RUN_CMD="nsenter -t 1 -m --"
    elif command -v toybox >/dev/null 2>&1; then
        toybox nsenter -t 1 -m -- true >/dev/null 2>&1 && RUN_CMD="toybox nsenter -t 1 -m --"
    fi
fi
run_cmd() {
    if [ -n "$RUN_CMD" ]; then $RUN_CMD "$@"; else "$@"; fi
}

append_target() {
    local target="$1"
    [ -n "$target" ] || return 0
    case "$target" in *.apk|*/base.apk) echo "$target" >> "$TARGETS_TMP" ;; esac
}
append_targets_for_pkg() {
    local pkg="$1"
    pm path "$pkg" 2>/dev/null | sed 's/^package://' | while IFS= read -r p; do
        [ -n "$p" ] || continue
        case "$p" in *.apk|*/base.apk) echo "$p" ;; esac
    done >> "$TARGETS_TMP"
}

cleanup_installer_caches() {
    for d in /data/resource-cache /data/system/package_cache; do
        [ -d "$d" ] || continue
        find "$d" -maxdepth 4 \( \
            -iname '*packageinstaller*' \
            -o -iname '*googlepackageinstaller*' \
            -o -iname '*miuipackageinstaller*' \
            -o -iname '*androidpackageinstaller*' \
            -o -iname '*installerx*' \
            -o -iname '*zsunset*' \
        \) -exec rm -rf {} + 2>/dev/null
    done
}

append_target "$SAVED_TARGET"
[ -n "$SAVED_DIR" ] && echo "$SAVED_DIR" >> "$TARGETS_TMP"
[ -n "$SAVED_PKG" ] && append_targets_for_pkg "$SAVED_PKG"
for pkg in $PACKAGES; do append_targets_for_pkg "$pkg"; done
sort -u "$TARGETS_TMP" -o "$TARGETS_TMP" 2>/dev/null || true

unmount_target() {
    local target="$1"
    [ -n "$target" ] || return 0
    run_cmd sh -c "awk '\$2==\"$target\"{found=1} END{exit !found}' /proc/self/mounts" >/dev/null 2>&1 || return 0
    run_cmd umount "$target" >/dev/null 2>&1 && return 0
    sleep 1
    run_cmd umount "$target" >/dev/null 2>&1 && return 0
    run_cmd umount -l "$target" >/dev/null 2>&1 && return 0
    return 1
}

for pkg in $PACKAGES; do
    am force-stop "$pkg" >/dev/null 2>&1
    cmd activity force-stop-package "$pkg" >/dev/null 2>&1
    pm uninstall-system-updates "$pkg" >/dev/null 2>&1
    cmd package compile --reset "$pkg" >/dev/null 2>&1
done

if [ "$ENGINE" = "bind" ] && [ -f "$TARGETS_TMP" ]; then
    while IFS= read -r target; do
        [ -n "$target" ] || continue
        unmount_target "$target"
    done < "$TARGETS_TMP"
fi

cleanup_installer_caches >/dev/null 2>&1
rm -rf "$STATE_DIR" >/dev/null 2>&1

rm -rf /data/local/installerx_update >/dev/null 2>&1
rm -f /data/local/installerx_zsunset_force_refresh >/dev/null 2>&1

am broadcast -a android.intent.action.PACKAGE_REMOVED \
    -d "package:com.android.packageinstaller" >/dev/null 2>&1 || true
am broadcast -a android.intent.action.PACKAGE_REMOVED \
    -d "package:com.google.android.packageinstaller" >/dev/null 2>&1 || true

for base in /data/adb/modules_update /data/adb/modules; do
    [ -d "$base" ] || continue
    for d in "$base"/*; do
        [ -d "$d" ] || continue
        [ -f "$d/module.prop" ] || continue
        grep -q '^id=InstallerX_Zsunset$' "$d/module.prop" 2>/dev/null || continue
        rm -f \
            "$d/target_apk" \
            "$d/target_pkg" \
            "$d/variant" \
            "$d/engine" \
            "$d/target_folder" \
            "$d/target_partition" \
            "$d/apk_name" \
            "$d/mode" \
            "$d/apk/installer.apk" \
            "$d/apk/installer.apk.bak" \
            "$d/apk/installer.apk.md5" \
            "$d/meta_module_name" \
            "$d/last_mount_src" \
            "$d/update_timestamp" \
            "$d/need_remount" \
            "$d/rollback_flag" \
            "$d/prev_module_path" \
            >/dev/null 2>&1
        rm -rf "$d/apk" >/dev/null 2>&1
    done
done

exit 0