#!/usr/bin/env bash
# =============================================================================
# Description: Provide installer functions for KDE (Dolphin and Krusader).
# Sourced by 'install.sh'. Do not run directly.
#
# Files and directories created:
#   ~/.local/share/kio/servicemenus/
#   ~/.local/share/kio/servicemenus/nautilus-scripts-*.desktop
# =============================================================================

_install_actions_dolphin() {
    _install_actions_kio_servicemenus
}

_install_actions_krusader() {
    _install_actions_kio_servicemenus
}

_install_actions_kio_servicemenus() {
    local menu_file=""
    local menus_path="$HOME/.local/share/kio/servicemenus"

    # Create a temporary directory for the new menu files. Write to a temporary
    # directory first, then move the files to the final location.
    local temp_dir=""
    # shellcheck disable=SC2153
    temp_dir=$(mktemp --directory --tmpdir="$TEMP_DIR") || return 1

    # -------------------------------------------------------------------------
    # Create a '.desktop' file for each script.
    # -------------------------------------------------------------------------
    local action_name=""
    local icon=""
    local name=""
    local mime_type=""
    local max_items=""
    local min_items=""
    local script_relative=""
    local submenu=""
    local filename=""
    while IFS= read -r -d '' filename; do
        script_relative=${filename##*scripts/}
        name=${script_relative##*/}
        submenu=${script_relative%%/*}

        mime_type=$(_get_par_value "$filename" "install_mime_type")
        if [[ -z "$mime_type" ]]; then
            mime_type="all/all;"
        fi

        icon=$(_get_par_value "$filename" "install_icon_kde")
        max_items=$(_get_par_value "$filename" "par_max_items" | grep -oE "^[0-9]+" 2>/dev/null)
        min_items=$(_get_par_value "$filename" "par_min_items" | grep -oE "^[0-9]+" 2>/dev/null)

        action_name=$(_sanitize_string <<<"$name")
        menu_file="${action_name}.desktop"
        menu_file="$temp_dir/$APP_NAME-$menu_file"
        {
            printf "%s\n" "[Desktop Entry]"
            printf "%s\n" "Type=Service"
            printf "%s\n" "X-KDE-ServiceTypes=KonqPopupMenu/Plugin"
            if [[ -n "$min_items" ]]; then
                printf "%s\n" "X-KDE-MinNumberOfUrls=$min_items"
            fi
            if [[ -n "$max_items" ]]; then
                printf "%s\n" "X-KDE-MaxNumberOfUrls=$max_items"
            fi
            printf "%s\n" "Actions=$action_name;"
            printf "%s\n" "MimeType=$mime_type"
            printf "%s\n" "Icon=$icon"
            printf "%s\n" "Encoding=UTF-8"
            printf "%s\n" "X-KDE-Submenu=$submenu"
            _i18n_print_desktop_name "X-KDE-Submenu" "$submenu"
            printf "\n"
            printf "%s\n" "[Desktop Action $action_name]"
            printf "%s\n" "Name=$name"
            _i18n_print_desktop_name "Name" "$name"
            printf "%s\n" "Icon=$icon"
            printf "%s\n" "Exec=bash \"$filename\" %F"

        } | _tee_file "$menu_file"
        chmod +x -- "$menu_file"

    done < <(_list_scripts)

    # -------------------------------------------------------------------------
    # Replace the old files only after all new files were created.
    # -------------------------------------------------------------------------
    mkdir --parents -- "$menus_path" || return 1

    # Set the old files date to 1970, to mark them as "old".
    find "$menus_path" -maxdepth 1 -type f -name "$APP_NAME-*.desktop" \
        -exec touch -d '@0' -- {} +

    # Copy the new files (they get the current date). If this fails, or if
    # there are no new files, stop here and keep the old ones.
    cp --force -- "$temp_dir/$APP_NAME-"*.desktop "$menus_path/" || return 1

    # Delete only the files that still have the old date (the stale ones).
    find "$menus_path" -maxdepth 1 -type f -name "$APP_NAME-*.desktop" \
        ! -newermt '@1' -delete
}
