#!/system/bin/sh

[ -f "$MODPATH/common.sh" ] && . "$MODPATH/common.sh"

detect_rom_family() {
    mi_os="$(getprop ro.mi.os.version.name)"
    miui_ui="$(getprop ro.miui.ui.version.name)"
    xiaomi_props="$(getprop ro.miui.ui.version.code) $(getprop ro.miui.region) $(getprop ro.mi.os.version.code)"
    build_id="$(getprop ro.build.version.incremental)"
    display_id="$(getprop ro.build.display.id)"
    oppo_rom="$(getprop ro.build.version.opporom)"
    oplus_ver="$(getprop ro.vendor.oplus.os.version)"
    oplus_rom="$(getprop ro.build.version.oplusrom)"
    realme_ui="$(getprop ro.build.version.realmeui)"
    oneui_ver="$(getprop ro.build.version.oneui)"
    brand="$(getprop ro.product.brand)"
    manufacturer="$(getprop ro.product.manufacturer)"
    fingerprint="$(getprop ro.system.build.fingerprint) $(getprop ro.build.fingerprint)"

    if [ -n "$mi_os" ] || echo "$build_id $display_id $xiaomi_props $fingerprint" | grep -qiE 'hyperos'; then
        ROM_FAMILY="hyperos"
    elif [ -n "$miui_ui" ] || echo "$build_id $display_id $xiaomi_props $fingerprint" | grep -qiE 'miui'; then
        ROM_FAMILY="miui"
    elif [ -n "$realme_ui" ] || echo "$brand $manufacturer $fingerprint" | grep -qiE 'realme'; then
        ROM_FAMILY="realmeui"
    elif [ -n "$oppo_rom" ] || [ -n "$oplus_ver" ] || [ -n "$oplus_rom" ] || \
         echo "$brand $manufacturer $fingerprint" | grep -qiE 'oppo|oplus|coloros'; then
        ROM_FAMILY="coloros"
    elif [ -n "$oneui_ver" ] || echo "$brand $manufacturer $fingerprint" | grep -qiE 'oneui|samsung'; then
        ROM_FAMILY="oneui"
    else
        ROM_FAMILY="aosp"
    fi

    case "$ROM_FAMILY" in
        hyperos) ui_print "- $(t rom_family): HyperOS" ;;
        miui) ui_print "- $(t rom_family): MIUI" ;;
        realmeui) ui_print "- $(t rom_family): RealmeUI" ;;
        coloros) ui_print "- $(t rom_family): ColorOS" ;;
        oneui) ui_print "- $(t rom_family): OneUI" ;;
        aosp) ui_print "- $(t rom_family): AOSP" ;;
    esac
}

detect_root_manager() {
    if [ -d /data/adb/ap ] || [ -d /data/adb/apatch ] || command -v apd >/dev/null 2>&1; then
        ROOT_MGR="APatch"
    elif [ -d /data/adb/ksu ] || command -v ksud >/dev/null 2>&1 || [ -n "$KSU" ]; then
        ROOT_MGR="KernelSU"
    else
        ROOT_MGR="Magisk"
    fi
    ui_print "- $(t root_manager): $ROOT_MGR"
}

detect_meta_module() {
    HAS_META_MODULE=0
    META_MODULE_NAME=""
    local root mod id name desc modbase hay
    local exact_hits='^(meta[._-]?module|metamodule|mountify|magicmount|magic_mount|hybrid[._ -]?mount|overlayfs)$'
    local fuzzy_hits='meta[ -]?module|metamodule|mountify|magic mount|hybrid[ -]?mount|overlayfs|magic[ -]?overlay'

    for root in /data/adb/modules_update /data/adb/modules; do
        [ -d "$root" ] || continue
        for mod in "$root"/*; do
            [ -d "$mod" ] || continue
            [ "$mod" = "$MODPATH" ] && continue
            [ -f "$mod/disable" ] && continue
            [ -f "$mod/remove" ] && continue
            [ -f "$mod/module.prop" ] || continue

            id="$(grep -m1 '^id=' "$mod/module.prop" 2>/dev/null | cut -d= -f2-)"
            [ "$id" = 'InstallerX_Zsunset' ] && continue
            [ "$id" = 'InstallerX_Revived' ] && continue
            echo "$id" | grep -qi 'installerx' && continue

            name="$(grep -m1 '^name=' "$mod/module.prop" 2>/dev/null | cut -d= -f2-)"
            desc="$(grep -m1 '^description=' "$mod/module.prop" 2>/dev/null | cut -d= -f2-)"
            modbase="$(basename "$mod")"

            if echo "$id" | tr '[:upper:]' '[:lower:]' | grep -qE "$exact_hits" || \
               echo "$modbase" | tr '[:upper:]' '[:lower:]' | grep -qE "$exact_hits"; then
                HAS_META_MODULE=1
                META_MODULE_NAME="${name:-$modbase}"
                return 0
            fi

            hay="$name $desc"
            if echo "$hay" | tr '[:upper:]' '[:lower:]' | grep -qE "$fuzzy_hits"; then
                HAS_META_MODULE=1
                META_MODULE_NAME="${name:-$modbase}"
                return 0
            fi
        done
    done
}

choose_engine() {
    if [ "${HAS_META_MODULE:-0}" = "1" ]; then
        echo "fix"
    elif [ "$ROOT_MGR" = "KernelSU" ] || [ "$ROOT_MGR" = "APatch" ]; then
        echo "bind"
    else
        echo "fix"
    fi
}

select_variant_by_key() {
    local MODDIR="$1"
    local KEYCHECK
    KEYCHECK="$(get_keycheck_path "$MODDIR")"

    ui_print ""
    ui_print "  ==============================="
    ui_print "  $(t select_prompt)"
    ui_print "  [$(t vol_up)]  $(t online_version)"
    ui_print "  [$(t vol_down)] $(t offline_version)"
    ui_print "  $(t timeout_hint) 5s -> $(t default_offline)"
    ui_print "  ==============================="
    ui_print ""

    local SELECTED_MODE="offline"  # 默认

    if [ -n "$KEYCHECK" ] && [ -f "$KEYCHECK" ]; then
        ui_print "- $(t key_select_mode): keycheck"
        local i=0
        while [ $i -lt 50 ]; do  # 5秒超时
            local key
            key="$("$KEYCHECK" 2>/dev/null; echo $?)"
            case "$key" in
                42)  # VOLUME_UP
                    SELECTED_MODE="online"
                    ui_print "  → $(t vol_up_detected): $(t online_version)"
                    break
                    ;;
                41)  # VOLUME_DOWN
                    SELECTED_MODE="offline"
                    ui_print "  → $(t vol_down_detected): $(t offline_version)"
                    break
                    ;;
            esac
            sleep 0.1
            i=$((i+1))
        done
        [ $i -ge 50 ] && ui_print "  → $(t timeout_use_default): $(t offline_version)"
    else
        ui_print "- $(t no_keycheck)"
    fi

    local PKG
    PKG="$(detect_installed_pkg)"
    [ -z "$PKG" ] && abort "- $(t err_pkg_not_found)"

    local VARIANT
    VARIANT="$(detect_variant "$PKG")"
    [ -z "$VARIANT" ] && abort "- $(t err_unknown_variant)"

    local APK_NAME
    APK_NAME="$(match_apk_name "$VARIANT" "$SELECTED_MODE")"

    ui_print "- $(t installer_found): $PKG"
    ui_print "- $(t variant): $VARIANT ($SELECTED_MODE)"
    ui_print "- APK: $APK_NAME"

    echo "$PKG" > "$MODPATH/target_pkg" 2>/dev/null
    echo "$VARIANT" > "$MODPATH/variant" 2>/dev/null
    echo "$SELECTED_MODE" > "$MODPATH/mode" 2>/dev/null
    echo "$APK_NAME" > "$MODPATH/apk_name" 2>/dev/null
}

reinstall_fix() {
    local MODPATH="$1"
    local is_reinstall=0
    local OLD_MODPATH=""

    for base in /data/adb/modules_update /data/adb/modules; do
        [ -d "$base" ] || continue
        for d in "$base"/*; do
            [ -d "$d" ] || continue
            [ -f "$d/module.prop" ] || continue
            if grep -q '^id=InstallerX_Zsunset$' "$d/module.prop" 2>/dev/null; then
                [ "$d" = "$MODPATH" ] && continue
                is_reinstall=1
                OLD_MODPATH="$d"
                break 2
            fi
        done
    done

    if [ "$is_reinstall" = "1" ] && [ -n "$OLD_MODPATH" ]; then
        ui_print "- $(t reinstall_detected): $(basename "$OLD_MODPATH")"

        mkdir -p "$MODPATH/apk" >/dev/null 2>&1
        for f in target_pkg target_apk variant mode engine apk_name; do
            [ -f "$OLD_MODPATH/$f" ] && cp -f "$OLD_MODPATH/$f" "$MODPATH/$f" 2>/dev/null
        done
        echo "$OLD_MODPATH" > "$MODPATH/prev_module_path" 2>/dev/null

        echo "1" > "$FORCE_REFRESH_FLAG" 2>/dev/null
    fi
}

setup_engine() {
    local MODPATH="$1"
    local variant partition replace_folder

    variant="$(cat "$MODPATH/variant" 2>/dev/null)"
    partition="$(cat "$MODPATH/target_partition" 2>/dev/null)"
    replace_folder="$(cat "$MODPATH/target_folder" 2>/dev/null)"
    local engine
    engine="$(choose_engine)"

    echo "$engine" > "$MODPATH/engine" 2>/dev/null

    if [ "$engine" = "fix" ]; then
        ui_print "- $(t engine_fix)"
        local mod_apk_dir="$MODPATH${partition}/priv-app/ModPackageInstaller"
        mkdir -p "$mod_apk_dir"
        rm -f "$mod_apk_dir"/*.apk >/dev/null 2>&1

        local apk_name
        apk_name="$(cat "$MODPATH/apk_name" 2>/dev/null)"
        [ -z "$apk_name" ] && apk_name="AndroidPackageInstaller.apk"
        cp -f "$MODPATH/files/$apk_name" "$mod_apk_dir/" >/dev/null 2>&1

        local target_file
        target_file="$(cat "$MODPATH/target_apk" 2>/dev/null)"
        if [ -n "$target_file" ]; then
            local alias_dir="$MODPATH$(dirname "$target_file")"
            mkdir -p "$alias_dir"
            cp -f "$MODPATH/files/$apk_name" "$alias_dir/" >/dev/null 2>&1
        fi

        [ -z "$replace_folder" ] && replace_folder="/system/priv-app"
        mkdir -p "$MODPATH$replace_folder"
        touch "$MODPATH$replace_folder/.replace"

        set_perm_recursive "$mod_apk_dir" 0 0 0755 0644
    else
        ui_print "- $(t engine_bind)"
        local target_file
        target_file="$(cat "$MODPATH/target_apk" 2>/dev/null)"
        local apk_name
        apk_name="$(cat "$MODPATH/apk_name" 2>/dev/null)"
        [ -z "$apk_name" ] && apk_name="AndroidPackageInstaller.apk"

        if [ -n "$target_file" ]; then
            local target_dir="$MODPATH$(dirname "$target_file")"
            local target_name="$(basename "$target_file")"
            mkdir -p "$target_dir"
            rm -f "$target_dir"/*.apk >/dev/null 2>&1
            cp -f "$MODPATH/files/$apk_name" "$target_dir/$target_name" >/dev/null 2>&1
            set_perm_recursive "$target_dir" 0 0 0755 0644
        fi
    fi
}

save_state() {
    local MODPATH="$1"
    local pkg target variant engine folder partition apk_name

    pkg="$(cat "$MODPATH/target_pkg" 2>/dev/null)"
    target="$(cat "$MODPATH/target_apk" 2>/dev/null)"
    variant="$(cat "$MODPATH/variant" 2>/dev/null)"
    engine="$(cat "$MODPATH/engine" 2>/dev/null)"
    apk_name="$(cat "$MODPATH/apk_name" 2>/dev/null)"

    if [ -z "$target" ] && [ -n "$pkg" ]; then
        target="$(get_first_apk_path "$pkg")"
    fi

    [ -z "$target" ] && return 1

    folder="$(dirname "$target")"
    partition="$(partition_for_apk_path "$target")"
    replace_folder="$(normalize_module_path "$folder")"

    mkdir -p "$MODPATH/apk" >/dev/null 2>&1

    echo "$pkg" > "$MODPATH/target_pkg"
    echo "$target" > "$MODPATH/target_apk"
    echo "$variant" > "$MODPATH/variant"
    echo "$engine" > "$MODPATH/engine"
    echo "$folder" > "$MODPATH/target_folder"
    echo "$partition" > "$MODPATH/target_partition"
    echo "$apk_name" > "$MODPATH/apk_name"

    [ -n "$apk_name" ] && [ -f "$MODPATH/files/$apk_name" ] && \
        cp -f "$MODPATH/files/$apk_name" "$MODPATH/apk/installer.apk"

    set_perm "$MODPATH/apk/installer.apk" 0 0 0644
    set_perm "$MODPATH/target_pkg" 0 0 0644
    set_perm "$MODPATH/target_apk" 0 0 0644
    set_perm "$MODPATH/variant" 0 0 0644
    set_perm "$MODPATH/engine" 0 0 0644
    set_perm "$MODPATH/mode" 0 0 0644
}

uninstall_updates() {
    ui_print "- $(t uninstall_updates)..."
    for pkg in $PACKAGES; do
        pm uninstall-system-updates "$pkg" >/dev/null 2>&1
    done
}

clean_files() {
    rm -rf "$MODPATH/files" 2>/dev/null
    rm -rf "$MODPATH/bin" 2>/dev/null
    cleanup_installer_caches
}

mods_center() {
    ui_print ""
    ui_print "==============================="
    ui_print "  InstallerX Zsunset"
    ui_print "  暮雨连秋冬重构版"
    ui_print "==============================="
}

check_support() {
    android_ver=$(getprop ro.build.version.release)
    sdk=$(getprop ro.build.version.sdk)
    ui_print "- $(t checking_support)... (Android $android_ver / API $sdk)"
    if [ "$sdk" -lt 26 ]; then
        abort "- Android 8 (API 26) or higher is required"
    fi
}

run_install() {
    mods_center
    check_support
    detect_root_manager
    detect_meta_module
    detect_rom_family

    reinstall_fix "$MODPATH"

    select_variant_by_key "$MODPATH"

    uninstall_updates

    local pkg
    pkg="$(cat "$MODPATH/target_pkg" 2>/dev/null)"
    if [ -n "$pkg" ]; then
        local target
        target="$(get_first_apk_path "$pkg")"
        [ -n "$target" ] && echo "$target" > "$MODPATH/target_apk" 2>/dev/null
    fi
    save_state "$MODPATH"

    setup_engine "$MODPATH"

    local partition
    partition="$(cat "$MODPATH/target_partition" 2>/dev/null)"
    [ -z "$partition" ] && partition="/system"
    write_whitelist_xml "$partition" "$MODPATH"

    force_refresh_package_icon "$pkg" 1

    clean_files

    set_install_status "$STATUS_OK"
    ui_print "- $(t module_installed)"
}

run_install