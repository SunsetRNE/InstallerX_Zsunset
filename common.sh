#!/system/bin/sh
# ============================================================
# common.sh — InstallerX Zsunset 共享函数库
# 作者: 暮雨连秋冬
# 说明: 被 customize.sh / post-fs-data.sh / service.sh / uninstall.sh 共用
# ============================================================

# ---------- 常量 ----------
PACKAGES="com.miui.packageinstaller com.google.android.packageinstaller com.android.packageinstaller com.android.permissioncontroller com.google.android.permissioncontroller"
FALLBACK_PACKAGES="com.android.permissioncontroller com.google.android.permissioncontroller"

STATE_DIR_BASE="/data/adb/installerx_zsunset"
STATE_FILE="$STATE_DIR_BASE/last_version"
GUARD_FILE="$STATE_DIR_BASE/version_guard"
FORCE_REFRESH_FLAG="/data/local/installerx_zsunset_force_refresh"
UPDATE_DIR="/data/local/installerx_update"

STATUS_OK="InstallerX Zsunset · 暮雨连秋冬 ✅"
STATUS_FAIL="InstallerX Zsunset · 暮雨连秋冬 💢"

# ---------- 多语言函数 ----------
LANG_MODE="en"

normalize_lang_code() {
    local l
    l="$1"
    l="${l%%,*}"
    l="${l%%;*}"
    l="${l%%[_-]*}"
    echo "$l" | tr '[:upper:]' '[:lower:]'
}

get_lang() {
    local l
    l="$(settings get system system_locales 2>/dev/null)"
    [ "$l" = "null" ] && l=""
    [ -z "$l" ] && l="$(settings get global device_locales 2>/dev/null)"
    [ "$l" = "null" ] && l=""
    [ -z "$l" ] && l="$(getprop persist.sys.locale 2>/dev/null)"
    [ -z "$l" ] && l="$(getprop persist.sys.language 2>/dev/null)"
    [ -z "$l" ] && l="$(getprop persist.sys.locale.language 2>/dev/null)"
    [ -z "$l" ] && l="$(getprop ro.product.locale 2>/dev/null)"
    [ -z "$l" ] && l="$(getprop ro.product.locale.language 2>/dev/null)"
    normalize_lang_code "$l"
}

SYS_LANG="$(get_lang)"

case "$SYS_LANG" in
    ru|uk|be|kk) LANG_MODE="ru" ;;
    zh|zh*) LANG_MODE="zh" ;;
    *) LANG_MODE="en" ;;
esac

t() {
    case "$1" in
        checking_support)
            case "$LANG_MODE" in
                ru) echo "Проверка поддержки" ;;
                zh) echo "检查支持情况" ;;
                *) echo "Checking support" ;;
            esac ;;
        root_manager)
            case "$LANG_MODE" in
                ru) echo "Root менеджер" ;;
                zh) echo "Root 管理器" ;;
                *) echo "Root manager" ;;
            esac ;;
        rom_family)
            case "$LANG_MODE" in
                ru) echo "Тип прошивки" ;;
                zh) echo "系统类型" ;;
                *) echo "ROM family" ;;
            esac ;;
        preparing)
            case "$LANG_MODE" in
                ru) echo "Подготовка" ;;
                zh) echo "准备中" ;;
                *) echo "Preparing" ;;
            esac ;;
        uninstall_updates)
            case "$LANG_MODE" in
                ru) echo "Удаление обновлений установщика" ;;
                zh) echo "卸载安装器更新" ;;
                *) echo "Uninstalling installer updates" ;;
            esac ;;
        installer_found)
            case "$LANG_MODE" in
                ru) echo "Найден установщик" ;;
                zh) echo "已找到安装器" ;;
                *) echo "Installer found" ;;
            esac ;;
        base_apk)
            case "$LANG_MODE" in
                ru) echo "Системный APK" ;;
                zh) echo "系统 APK" ;;
                *) echo "ROM base APK" ;;
            esac ;;
        variant)
            case "$LANG_MODE" in
                ru) echo "Выбран вариант" ;;
                zh) echo "已选择版本" ;;
                *) echo "Using variant" ;;
            esac ;;
        existing_module)
            case "$LANG_MODE" in
                ru) echo "Найден установленный модуль InstallerX_Zsunset" ;;
                zh) echo "已找到已安装的 InstallerX_Zsunset 模块" ;;
                *) echo "Found existing InstallerX_Zsunset module" ;;
            esac ;;
        update_not_conflict)
            case "$LANG_MODE" in
                ru) echo "Обновление модуля (не конфликтует)" ;;
                zh) echo "更新模块（无冲突）" ;;
                *) echo "Treating as update, not conflict" ;;
            esac ;;
        replace_target)
            case "$LANG_MODE" in
                ru) echo "Путь замены" ;;
                zh) echo "替换目标路径" ;;
                *) echo "Replace target" ;;
            esac ;;
        done)
            case "$LANG_MODE" in
                ru) echo "Готово" ;;
                zh) echo "完成" ;;
                *) echo "Done" ;;
            esac ;;
        handle_partition)
            case "$LANG_MODE" in
                ru) echo "Обработка раздела" ;;
                zh) echo "处理分区" ;;
                *) echo "Handle partition" ;;
            esac ;;
        module_installed)
            case "$LANG_MODE" in
                ru) echo "Модуль успешно установлен" ;;
                zh) echo "模块安装成功" ;;
                *) echo "Module installed successfully" ;;
            esac ;;
        engine_fix)
            case "$LANG_MODE" in
                ru) echo "Движок: Fix (Magisk replace)" ;;
                zh) echo "引擎：Fix（Magisk 替换）" ;;
                *) echo "Engine: Fix (Magisk replace)" ;;
            esac ;;
        engine_bind)
            case "$LANG_MODE" in
                ru) echo "Движок: Default (bind mount)" ;;
                zh) echo "引擎：Bind（运行时挂载）" ;;
                *) echo "Engine: Bind (runtime mount)" ;;
            esac ;;
        meta_module)
            case "$LANG_MODE" in
                ru) echo "Мета модуль" ;;
                zh) echo "Meta 模块" ;;
                *) echo "Meta module" ;;
            esac ;;
        not_detected)
            case "$LANG_MODE" in
                ru) echo "Не найден" ;;
                zh) echo "未检测到" ;;
                *) echo "Not detected" ;;
            esac ;;
        err_pkg_not_found)
            case "$LANG_MODE" in
                ru) echo "Ошибка: установщик не найден" ;;
                zh) echo "错误：未找到安装器" ;;
                *) echo "Error: Package Installer not found" ;;
            esac ;;
        err_apk_path)
            case "$LANG_MODE" in
                ru) echo "Ошибка: не удалось определить путь APK" ;;
                zh) echo "错误：无法解析 APK 路径" ;;
                *) echo "Error: failed to resolve APK path" ;;
            esac ;;
        err_unknown_variant)
            case "$LANG_MODE" in
                ru) echo "Внутренняя ошибка: неизвестный вариант" ;;
                zh) echo "内部错误：未知变体" ;;
                *) echo "Internal error: unknown variant" ;;
            esac ;;
        select_prompt)
            case "$LANG_MODE" in
                ru) echo "Выберите версию установщика" ;;
                zh) echo "请选择安装器版本" ;;
                *) echo "Please select installer variant" ;;
            esac ;;
        vol_up)
            case "$LANG_MODE" in
                ru) echo "Громкость +" ;;
                zh) echo "音量+" ;;
                *) echo "Volume +" ;;
            esac ;;
        vol_down)
            case "$LANG_MODE" in
                ru) echo "Громкость -" ;;
                zh) echo "音量-" ;;
                *) echo "Volume -" ;;
            esac ;;
        online_version)
            case "$LANG_MODE" in
                ru) echo "Онлайн-версия" ;;
                zh) echo "联网版" ;;
                *) echo "Online version" ;;
            esac ;;
        offline_version)
            case "$LANG_MODE" in
                ru) echo "Офлайн-версия" ;;
                zh) echo "本地版" ;;
                *) echo "Offline version" ;;
            esac ;;
        timeout_hint)
            case "$LANG_MODE" in
                ru) echo "Автовыбор через" ;;
                zh) echo "超时自动选择" ;;
                *) echo "Auto-select after" ;;
            esac ;;
        default_offline)
            case "$LANG_MODE" in
                ru) echo "Офлайн (по умолч.)" ;;
                zh) echo "本地版（默认）" ;;
                *) echo "Offline (default)" ;;
            esac ;;
        vol_up_detected)
            case "$LANG_MODE" in
                ru) echo "Нажата громкость +" ;;
                zh) echo "已按下音量+" ;;
                *) echo "Volume + pressed" ;;
            esac ;;
        vol_down_detected)
            case "$LANG_MODE" in
                ru) echo "Нажата громкость -" ;;
                zh) echo "已按下音量-" ;;
                *) echo "Volume - pressed" ;;
            esac ;;
        timeout_use_default)
            case "$LANG_MODE" in
                ru) echo "Тайм-аут, по умолч." ;;
                zh) echo "超时，使用默认" ;;
                *) echo "Timeout, using default" ;;
            esac ;;
        icon_refresh)
            case "$LANG_MODE" in
                ru) echo "Обновление кэша иконок" ;;
                zh) echo "刷新图标缓存" ;;
                *) echo "Refreshing icon cache" ;;
            esac ;;
        icon_refresh_done)
            case "$LANG_MODE" in
                ru) echo "Кэш иконок обновлен" ;;
                zh) echo "图标缓存已刷新" ;;
                *) echo "Icon cache refreshed" ;;
            esac ;;
        reinstall_detected)
            case "$LANG_MODE" in
                ru) echo "Обнаружена переустановка" ;;
                zh) echo "检测到重复安装" ;;
                *) echo "Reinstall detected" ;;
            esac ;;
        rollback_restored)
            case "$LANG_MODE" in
                ru) echo "Откат предотвращен, восстановлено из" ;;
                zh) echo "防回退已触发，从以下恢复" ;;
                *) echo "Rollback prevented, restored from" ;;
            esac ;;
        quick_update_found)
            case "$LANG_MODE" in
                ru) echo "Найдено быстрое обновление" ;;
                zh) echo "发现快速更新" ;;
                *) echo "Quick update found" ;;
            esac ;;
        key_select_mode)
            case "$LANG_MODE" in
                ru) echo "Режим выбора: кнопки громкости" ;;
                zh) echo "选择模式：音量键" ;;
                *) echo "Selection mode: volume keys" ;;
            esac ;;
        no_keycheck)
            case "$LANG_MODE" in
                ru) echo "keycheck не найден, используем офлайн" ;;
                zh) echo "未找到 keycheck，使用默认本地版" ;;
                *) echo "keycheck not found, using offline default" ;;
            esac ;;
        *) echo "$1" ;;
    esac
}

# ---------- 快照占位函数（保留扩展点） ----------
ts_now() { :; }
capture_runtime_snapshot() { :; }
capture_common_snapshot() { :; }
capture_install_snapshot() { :; }

# ---------- 模块描述设置 ----------
set_desc_for_dir() {
    local d="$1"
    local desc="$2"
    [ -d "$d" ] || return 0
    [ -f "$d/module.prop" ] || return 0
    sed -i "s|^description=.*|description=$desc|" "$d/module.prop" 2>/dev/null
}

set_install_status() {
    local desc="$1"
    set_desc_for_dir "$MODPATH" "$desc"
    local root mod
    for root in /data/adb/modules_update /data/adb/modules; do
        [ -d "$root" ] || continue
        for mod in "$root"/*; do
            [ -d "$mod" ] || continue
            [ -f "$mod/module.prop" ] || continue
            if grep -q '^id=InstallerX_Zsunset$' "$mod/module.prop" 2>/dev/null; then
                set_desc_for_dir "$mod" "$desc"
            fi
        done
    done
}

set_module_desc() {
    local desc="$1"
    [ -f "$MODDIR/module.prop" ] || return 0
    sed -i "s|^description=.*|description=$desc|" "$MODDIR/module.prop" 2>/dev/null
}

# ---------- nsenter 跨命名空间挂载工具 ----------
prepare_nsenter() {
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
}

run_cmd() {
    if [ -n "$RUN_CMD" ]; then
        $RUN_CMD "$@"
    else
        "$@"
    fi
}

# ---------- 挂载工具函数 ----------
get_first_apk_path() {
    local pkg="$1"
    local paths path
    paths="$(pm path "$pkg" 2>/dev/null | sed 's/^package://')"
    path="$(echo "$paths" | grep -m1 '/base\.apk$')"
    [ -z "$path" ] && path="$(echo "$paths" | head -n1)"
    [ -n "$path" ] && echo "$path"
}

resolve_target() {
    local MODDIR="$1"
    local PKG="${2:-}"
    local TARGET_FILE="${3:-}"
    local resolved=""

    if [ -n "$TARGET_FILE" ] && [ -e "$TARGET_FILE" ]; then
        resolved="$TARGET_FILE"
    fi

    if [ -z "$resolved" ] && [ -n "$PKG" ]; then
        resolved="$(get_first_apk_path "$PKG")"
    fi

    if [ -z "$resolved" ]; then
        for pkg in $PACKAGES; do
            resolved="$(get_first_apk_path "$pkg")"
            [ -n "$resolved" ] && PKG="$pkg" && break
        done
    fi

    [ -n "$resolved" ] && echo "$resolved"
}

mount_escape_path() {
    # /proc/self/mounts escapes spaces as \040 and backslashes as \134.
    printf '%s' "$1" | sed 's/\\/\\134/g; s/ /\\040/g; s/\t/\\011/g'
}

mount_src_for_target() {
    local target="$1"
    local escaped
    escaped="$(mount_escape_path "$target")"
    run_cmd sh -c "awk -v t=\"$escaped\" '\$2==t{print \$1; exit}' /proc/self/mounts" 2>/dev/null
}

do_umount_if_needed() {
    local target="$1"
    local escaped
    [ -n "$target" ] || return 1
    escaped="$(mount_escape_path "$target")"
    run_cmd sh -c "awk -v t=\"$escaped\" '\$2==t{found=1} END{exit !found}' /proc/self/mounts" >/dev/null 2>&1 || return 0
    run_cmd umount "$target" >/dev/null 2>&1 && return 0
    sleep 1
    run_cmd umount "$target" >/dev/null 2>&1 && return 0
    run_cmd umount -l "$target" >/dev/null 2>&1
}

do_bind_mount() {
    local src="$1"
    local dst="$2"
    run_cmd mount -o bind "$src" "$dst" >/dev/null 2>&1; local RC=$?
    if [ $RC -ne 0 ]; then
        run_cmd mount --bind "$src" "$dst" >/dev/null 2>&1; RC=$?
    fi
    return $RC
}

# ---------- 缓存清理（增强版） ----------
cleanup_installer_caches() {
    for d in /data/resource-cache /data/system/package_cache \
            /data/dalvik-cache/arm /data/dalvik-cache/arm64; do
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

# ---------- 分区推断 ----------
partition_for_apk_path() {
    local p="$1"
    case "$p" in
        *"/product/"*|/product/*|*"/system/product/"*) echo "/system/product" ;;
        *"/system_ext/"*|/system_ext/*|*"/system/system_ext/"*) echo "/system/system_ext" ;;
        *"/vendor/"*|/vendor/*|*"/system/vendor/"*) echo "/system/vendor" ;;
        *) echo "/system" ;;
    esac
}

normalize_module_path() {
    local p="$1"
    case "$p" in
        /system/*) echo "$p" ;;
        /product/*) echo "/system$p" ;;
        /system_ext/*) echo "/system$p" ;;
        /vendor/*) echo "/system$p" ;;
        *) echo "$p" ;;
    esac
}

# ---------- 权限白名单 ----------
write_whitelist_xml() {
    local partition="$1"
    local MODPATH="$2"
    local xml_path="$MODPATH${partition}/etc/permissions/privapp_whitelist_muyu_installerx.xml"
    mkdir -p "$(dirname "$xml_path")"
    cat > "$xml_path" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<permissions>
    <privapp-permissions package="com.miui.packageinstaller">
        <permission name="android.permission.REAL_GET_TASKS"/>
        <permission name="android.permission.READ_INSTALL_SESSIONS"/>
        <permission name="android.permission.RECEIVE_BOOT_COMPLETED"/>
        <permission name="android.permission.USE_RESERVED_DISK"/>
        <permission name="android.permission.INSTALL_PACKAGES"/>
        <permission name="android.permission.PACKAGE_USAGE_STATS"/>
        <permission name="android.permission.WRITE_SECURE_SETTINGS"/>
        <permission name="android.permission.MANAGE_USERS"/>
        <permission name="android.permission.ACCESS_MTP"/>
        <permission name="android.permission.CLEAR_APP_CACHE"/>
        <permission name="android.permission.UPDATE_APP_OPS_STATS"/>
        <permission name="android.permission.DELETE_PACKAGES"/>
        <permission name="android.permission.QUERY_ALL_PACKAGES"/>
        <permission name="android.permission.SUBSTITUTE_NOTIFICATION_APP_NAME"/>
    </privapp-permissions>
    <privapp-permissions package="com.google.android.packageinstaller">
        <permission name="android.permission.REAL_GET_TASKS"/>
        <permission name="android.permission.READ_INSTALL_SESSIONS"/>
        <permission name="android.permission.RECEIVE_BOOT_COMPLETED"/>
        <permission name="android.permission.USE_RESERVED_DISK"/>
        <permission name="android.permission.INSTALL_PACKAGES"/>
        <permission name="android.permission.PACKAGE_USAGE_STATS"/>
        <permission name="android.permission.WRITE_SECURE_SETTINGS"/>
        <permission name="android.permission.MANAGE_USERS"/>
        <permission name="android.permission.ACCESS_MTP"/>
        <permission name="android.permission.CLEAR_APP_CACHE"/>
        <permission name="android.permission.UPDATE_APP_OPS_STATS"/>
        <permission name="android.permission.DELETE_PACKAGES"/>
        <permission name="android.permission.QUERY_ALL_PACKAGES"/>
        <permission name="android.permission.SUBSTITUTE_NOTIFICATION_APP_NAME"/>
    </privapp-permissions>
    <privapp-permissions package="com.android.packageinstaller">
        <permission name="android.permission.REAL_GET_TASKS"/>
        <permission name="android.permission.READ_INSTALL_SESSIONS"/>
        <permission name="android.permission.RECEIVE_BOOT_COMPLETED"/>
        <permission name="android.permission.USE_RESERVED_DISK"/>
        <permission name="android.permission.INSTALL_PACKAGES"/>
        <permission name="android.permission.PACKAGE_USAGE_STATS"/>
        <permission name="android.permission.WRITE_SECURE_SETTINGS"/>
        <permission name="android.permission.MANAGE_USERS"/>
        <permission name="android.permission.ACCESS_MTP"/>
        <permission name="android.permission.CLEAR_APP_CACHE"/>
        <permission name="android.permission.UPDATE_APP_OPS_STATS"/>
        <permission name="android.permission.DELETE_PACKAGES"/>
        <permission name="android.permission.QUERY_ALL_PACKAGES"/>
        <permission name="android.permission.SUBSTITUTE_NOTIFICATION_APP_NAME"/>
    </privapp-permissions>
    <privapp-permissions package="com.android.permissioncontroller">
        <permission name="android.permission.REAL_GET_TASKS"/>
        <permission name="android.permission.READ_INSTALL_SESSIONS"/>
        <permission name="android.permission.RECEIVE_BOOT_COMPLETED"/>
        <permission name="android.permission.USE_RESERVED_DISK"/>
        <permission name="android.permission.INSTALL_PACKAGES"/>
        <permission name="android.permission.PACKAGE_USAGE_STATS"/>
        <permission name="android.permission.WRITE_SECURE_SETTINGS"/>
        <permission name="android.permission.MANAGE_USERS"/>
        <permission name="android.permission.ACCESS_MTP"/>
        <permission name="android.permission.CLEAR_APP_CACHE"/>
        <permission name="android.permission.UPDATE_APP_OPS_STATS"/>
        <permission name="android.permission.DELETE_PACKAGES"/>
        <permission name="android.permission.QUERY_ALL_PACKAGES"/>
        <permission name="android.permission.SUBSTITUTE_NOTIFICATION_APP_NAME"/>
    </privapp-permissions>
    <privapp-permissions package="com.google.android.permissioncontroller">
        <permission name="android.permission.REAL_GET_TASKS"/>
        <permission name="android.permission.READ_INSTALL_SESSIONS"/>
        <permission name="android.permission.RECEIVE_BOOT_COMPLETED"/>
        <permission name="android.permission.USE_RESERVED_DISK"/>
        <permission name="android.permission.INSTALL_PACKAGES"/>
        <permission name="android.permission.PACKAGE_USAGE_STATS"/>
        <permission name="android.permission.WRITE_SECURE_SETTINGS"/>
        <permission name="android.permission.MANAGE_USERS"/>
        <permission name="android.permission.ACCESS_MTP"/>
        <permission name="android.permission.CLEAR_APP_CACHE"/>
        <permission name="android.permission.UPDATE_APP_OPS_STATS"/>
        <permission name="android.permission.DELETE_PACKAGES"/>
        <permission name="android.permission.QUERY_ALL_PACKAGES"/>
        <permission name="android.permission.SUBSTITUTE_NOTIFICATION_APP_NAME"/>
    </privapp-permissions>
</permissions>
XML
    set_perm "$xml_path" 0 0 0644
}

# ============================================================
# ★ 新增函数：获取 keycheck 路径
# ============================================================
get_keycheck_path() {
    # 优先使用模块自带的
    local MODDIR="${1:-}"
    [ -n "$MODDIR" ] && [ -f "$MODDIR/bin/keycheck" ] && {
        echo "$MODDIR/bin/keycheck"
        return 0
    }
    # 扫描已安装模块
    for base in /data/adb/modules /data/adb/modules_update; do
        [ -d "$base" ] || continue
        local found
        found="$(find "$base" -name "keycheck" -type f 2>/dev/null | head -1)"
        [ -n "$found" ] && { echo "$found"; return 0; }
    done
    return 1
}

# ============================================================
# ★ 新增函数：检测当前系统安装器包名
# ============================================================
detect_installed_pkg() {
    for pkg in $PACKAGES; do
        if pm list packages 2>/dev/null | grep -q "^package:$pkg$"; then
            echo "$pkg"
            return 0
        fi
    done
    for pkg in $FALLBACK_PACKAGES; do
        if pm list packages 2>/dev/null | grep -q "^package:$pkg$"; then
            echo "$pkg"
            return 0
        fi
    done
    pm list packages -s 2>/dev/null | sed 's/^package://' | grep -iE 'packageinstaller|permissioncontroller' | head -n 1
}

# ============================================================
# ★ 新增函数：检测系统安装器所属变体
# ============================================================
detect_variant() {
    local pkg="$1"
    case "$pkg" in
        com.google.android.packageinstaller|com.google.android.permissioncontroller) echo "GooglePackageInstaller" ;;
        com.miui.packageinstaller) echo "MiuiPackageInstaller" ;;
        com.android.packageinstaller|com.android.permissioncontroller) echo "AndroidPackageInstaller" ;;
        *)
            # 上下文推断
            local path
            path="$(get_first_apk_path "$pkg" 2>/dev/null)"
            local hay="$pkg $path"
            if echo "$hay" | grep -qiE 'google|pixel|gms'; then echo "GooglePackageInstaller"
            elif echo "$hay" | grep -qiE 'miui|hyperos'; then echo "MiuiPackageInstaller"
            else echo "AndroidPackageInstaller"
            fi
            ;;
    esac
}

# ============================================================
# ★ 新增函数：匹配 APK 文件名
# ============================================================
match_apk_name() {
    local variant="$1"
    local mode="$2"  # online / offline
    case "$variant" in
        GooglePackageInstaller)
            [ "$mode" = "online" ] && echo "GooglePackageInstaller_online.apk" || echo "GooglePackageInstaller.apk"
            ;;
        AndroidPackageInstaller)
            [ "$mode" = "online" ] && echo "AndroidPackageInstaller_online.apk" || echo "AndroidPackageInstaller.apk"
            ;;
        MiuiPackageInstaller)
            [ "$mode" = "online" ] && echo "AndroidPackageInstaller_online.apk" || echo "AndroidPackageInstaller.apk"
            ;;
        *) echo "AndroidPackageInstaller.apk" ;;
    esac
}

get_apk_source() {
    local MODPATH="$1"
    local apk_name="$2"
    [ -n "$apk_name" ] || return 1
    if [ -f "$MODPATH/files/$apk_name" ]; then
        echo "$MODPATH/files/$apk_name"
        return 0
    fi
    # MIUI/HyperOS may still use the AOSP package-name compatible build.
    if echo "$apk_name" | grep -q '^MiuiPackageInstaller'; then
        local fallback
        fallback="$(echo "$apk_name" | sed 's/^MiuiPackageInstaller/AndroidPackageInstaller/')"
        [ -f "$MODPATH/files/$fallback" ] && { echo "$MODPATH/files/$fallback"; return 0; }
    fi
    return 1
}

# ============================================================
# ★ 新增函数：三阶段图标修复
# ============================================================
force_refresh_package_icon() {
    local pkg="$1"
    local phase="$2"  # 1=install, 2=post-fs-data, 3=service
    [ -z "$pkg" ] && return 0

    # Phase 1 / Phase 3 才输出信息
    [ "$phase" != "2" ] && ui_print "- $(t icon_refresh) (phase $phase): $pkg"

    # ---- 停止包进程 ----
    am force-stop "$pkg" >/dev/null 2>&1
    cmd activity force-stop-package "$pkg" >/dev/null 2>&1

    # ---- 清除缓存目录 ----
    for d in /data/resource-cache /data/system/package_cache; do
        [ -d "$d" ] || continue
        find "$d" -maxdepth 4 \( \
            -iname "*packageinstaller*" \
            -o -iname "*googlepackageinstaller*" \
            -o -iname "*miuipackageinstaller*" \
            -o -iname "*androidpackageinstaller*" \
            -o -iname "*installerx*" \
            -o -iname "*zsunset*" \
        \) -exec rm -rf {} + 2>/dev/null
    done

    # ---- 清除 oat 目录 ----
    local apk_path
    apk_path="$(get_first_apk_path "$pkg" 2>/dev/null)"
    if [ -n "$apk_path" ]; then
        local apk_dir
        apk_dir="$(dirname "$apk_path")"
        rm -rf "$apk_dir/oat" >/dev/null 2>&1
        rm -rf "$apk_dir/lib" >/dev/null 2>&1
    fi

    # ---- 重置编译状态 ----
    cmd package compile --reset "$pkg" >/dev/null 2>&1

    # ---- Phase 3 特有：触发广播 ----
    if [ "$phase" = "3" ]; then
        cmd package resolve-linkage "$pkg" >/dev/null 2>&1 || true
        am broadcast -a android.intent.action.PACKAGE_CHANGED \
            --include-stopped-packages \
            -d "package:$pkg" >/dev/null 2>&1 || true
        # 通知 Launcher 刷新
        for launcher in com.android.launcher3 com.google.android.apps.nexuslauncher \
                        com.miui.home com.oneplus.launcher com.android.launcher; do
            am force-stop "$launcher" >/dev/null 2>&1 || true
        done
        # 清除强制刷新标记
        rm -f "$FORCE_REFRESH_FLAG" >/dev/null 2>&1
    fi

    # Phase 2 特有：清除快速更新标记
    [ "$phase" = "2" ] && rm -f "$FORCE_REFRESH_FLAG" >/dev/null 2>&1

    [ "$phase" != "2" ] && ui_print "- $(t icon_refresh_done): $pkg"
}

# ============================================================
# ★ 新增函数：统一 bind mount（融合快速更新 + 防回退）
# ============================================================
ensure_bind_mount() {
    local MODDIR="$1"
    local APK_SRC="$MODDIR/apk/installer.apk"
    local TARGET_FILE="${2:-}"
    local PKG="${3:-}"

    [ ! -f "$APK_SRC" ] && return 1

    # 如果目标未指定，尝试读取状态文件或降级检测
    if [ -z "$TARGET_FILE" ] || [ ! -f "$TARGET_FILE" ]; then
        [ -f "$MODDIR/target_apk" ] && TARGET_FILE="$(cat "$MODDIR/target_apk" 2>/dev/null)"
    fi
    if [ -z "$PKG" ]; then
        [ -f "$MODDIR/target_pkg" ] && PKG="$(cat "$MODDIR/target_pkg" 2>/dev/null)"
    fi

    # 降级检测目标
    if [ -z "$TARGET_FILE" ] || [ ! -f "$TARGET_FILE" ]; then
        [ -n "$PKG" ] && TARGET_FILE="$(get_first_apk_path "$PKG")"
    fi
    if [ -z "$TARGET_FILE" ] || [ ! -f "$TARGET_FILE" ]; then
        for pkg in $PACKAGES; do
            TARGET_FILE="$(get_first_apk_path "$pkg")"
            [ -n "$TARGET_FILE" ] && PKG="$pkg" && break
        done
    fi
    [ -z "$TARGET_FILE" ] && return 1

    prepare_nsenter

    # 卸载旧 mount
    local cur_src
    cur_src="$(mount_src_for_target "$TARGET_FILE")"
    if [ -n "$cur_src" ] && [ "$cur_src" != "$APK_SRC" ]; then
        do_umount_if_needed "$TARGET_FILE"
    elif [ "$cur_src" = "$APK_SRC" ]; then
        return 0  # 已经是我们挂载的
    fi

    # 等待目标就绪
    local i=0
    while [ ! -e "$TARGET_FILE" ] && [ $i -lt 60 ]; do
        sleep 0.2
        TARGET_FILE="$(resolve_target "$MODDIR" "$PKG" "$TARGET_FILE")"
        i=$((i+1))
    done
    [ ! -e "$TARGET_FILE" ] && return 1

    # 执行 bind mount
    do_bind_mount "$APK_SRC" "$TARGET_FILE"
    local rc=$?

    # 保存状态
    echo "$TARGET_FILE" > "$MODDIR/target_apk" 2>/dev/null
    echo "$PKG" > "$MODDIR/target_pkg" 2>/dev/null
    echo "$APK_SRC" > "$MODDIR/last_mount_src" 2>/dev/null

    return $rc
}

# ============================================================
# ★ 新增函数：快速更新检测
# ============================================================
check_quick_update() {
    local MODDIR="$1"
    local update_dir="$UPDATE_DIR"
    local update_apk=""

    [ -d "$update_dir" ] || return 0

    # 按优先级查找
    for name in "installer.apk" "GooglePackageInstaller.apk" \
                "AndroidPackageInstaller.apk" "update.apk"; do
        if [ -f "$update_dir/$name" ]; then
            update_apk="$update_dir/$name"
            break
        fi
    done
    [ -z "$update_apk" ] && return 0

    # 验证 ZIP 魔数
    local magic
    magic="$(head -c 4 "$update_apk" 2>/dev/null | od -A n -t x1 | tr -d ' \n')"
    [ "$magic" != "504b0304" ] && return 0  # 不是 ZIP

    # 计算校验和
    local new_md5=""
    new_md5="$(md5sum "$update_apk" 2>/dev/null | cut -d' ' -f1)"
    local old_md5=""
    [ -f "$MODDIR/apk/installer.apk" ] && \
        old_md5="$(md5sum "$MODDIR/apk/installer.apk" 2>/dev/null | cut -d' ' -f1)"

    [ "$new_md5" = "$old_md5" ] && {
        rm -f "$update_apk" 2>/dev/null
        return 0
    }

    # 执行更新
    mkdir -p "$MODDIR/apk" >/dev/null 2>&1

    # 备份旧 APK
    [ -f "$MODDIR/apk/installer.apk" ] && \
        cp -f "$MODDIR/apk/installer.apk" "$MODDIR/apk/installer.apk.bak" 2>/dev/null

    # 复制新 APK
    cp -f "$update_apk" "$MODDIR/apk/installer.apk" 2>/dev/null
    chmod 0644 "$MODDIR/apk/installer.apk"

    # 复制配套状态（如果有）
    for f in variant target_pkg target_apk mode; do
        [ -f "$update_dir/$f" ] && cp -f "$update_dir/$f" "$MODDIR/$f" 2>/dev/null
    done

    # 记录更新时间
    echo "$(date +%s)" > "$MODDIR/update_timestamp" 2>/dev/null
    echo "$new_md5" > "$MODDIR/apk/installer.apk.md5" 2>/dev/null

    # 归档更新文件
    mkdir -p "$update_dir/backup" 2>/dev/null
    mv -f "$update_apk" "$update_dir/backup/installer_$(date +%Y%m%d_%H%M%S).apk" 2>/dev/null

    echo "1" > "$MODDIR/need_remount" 2>/dev/null
    return 1  # 表示执行了更新
}

# ============================================================
# ★ 新增函数：防回退守卫
# ============================================================
anti_rollback_guard() {
    local MODDIR="$1"
    mkdir -p "$STATE_DIR_BASE" >/dev/null 2>&1

    local module_apk="$MODDIR/apk/installer.apk"
    [ ! -f "$module_apk" ] && return 0

    local module_md5=""
    module_md5="$(md5sum "$module_apk" 2>/dev/null | cut -d' ' -f1)"
    local deployed_md5=""
    [ -f "$GUARD_FILE" ] && deployed_md5="$(cat "$GUARD_FILE" 2>/dev/null)"

    local target_file=""
    [ -f "$MODDIR/target_apk" ] && target_file="$(cat "$MODDIR/target_apk" 2>/dev/null)"

    # 如果快速更新已执行，直接更新守卫
    if [ -f "$MODDIR/need_remount" ]; then
        echo "$module_md5" > "$GUARD_FILE" 2>/dev/null
        return 0
    fi

    # 版本不一致 + 守卫有记录 → 可能回退
    if [ -n "$deployed_md5" ] && [ -n "$module_md5" ] && \
       [ "$deployed_md5" != "$module_md5" ] && [ -f "$target_file" ]; then

        local cur_src
        prepare_nsenter
        cur_src="$(mount_src_for_target "$target_file")"

        if [ "$cur_src" != "$module_apk" ]; then
            # 检测到回退！
            echo "rollback_detected" > "$MODDIR/rollback_flag" 2>/dev/null

            # 从备份恢复
            if [ -f "$MODDIR/apk/installer.apk.bak" ]; then
                local bak_md5
                bak_md5="$(md5sum "$MODDIR/apk/installer.apk.bak" 2>/dev/null | cut -d' ' -f1)"
                if [ "$bak_md5" = "$deployed_md5" ]; then
                    cp -f "$MODDIR/apk/installer.apk.bak" "$MODDIR/apk/installer.apk"
                fi
            fi
            echo "1" > "$MODDIR/need_remount" 2>/dev/null
        fi
    fi

    # 更新守卫
    [ -n "$module_md5" ] && echo "$module_md5" > "$GUARD_FILE" 2>/dev/null
}