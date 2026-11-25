#!/usr/bin/env bash

# =============================================================================
# Description: Installer functions for PCManFM and PCManFM-Qt.
# Sourced by 'install.sh'. Do not run directly.
#
# Files and directories created:
#   ~/.local/share/file-manager/actions/nautilus-scripts-main.desktop
#   ~/.local/share/file-manager/actions/nautilus-scripts-<category>.desktop
#   ~/.local/share/file-manager/actions/nautilus-scripts-<script>.desktop
# =============================================================================

_close_file_manager_pcmanfm() {
    local file_manager=$1

    # NOTE: PCManFM does not reload automatically after quitting.
    # We need to capture its current launch command to restart it.
    local session_cmd=""

    # Reload the file manager in background to restore desktop session.
    if [[ -n "${XDG_CURRENT_DESKTOP:-}" ]]; then
        # Only restart if running under LXDE or LXQT.
        if [[ "${XDG_CURRENT_DESKTOP,,}" == *"lxde"* ||
            "${XDG_CURRENT_DESKTOP,,}" == *"lxqt"* ]]; then
            session_cmd=$(pgrep -a "$file_manager" |
                grep -o -P -m1 "[0-9]+\s*\K.*")
            # Kill all existing PCManFM processes.
            killall "$file_manager" &>/dev/null
            if [[ -n "$session_cmd" ]]; then
                # Split the list into an array.
                local -a session_args=()
                IFS=" " read -r -a session_args <<<"$session_cmd"

                nohup "${session_args[@]}" &>/dev/null &
            else
                # Fallback: start PCManFM with default settings.
                nohup "$file_manager" --desktop &>/dev/null &
            fi
        fi
    fi
}

_install_actions_pcmanfm() {
    local menu_file=""
    local menus_path="$HOME/.local/share/file-manager/actions"

    # Create a temporary directory for the new menu files. Write to a temporary
    # directory first, then move the files to the final location.
    local temp_dir=""
    # shellcheck disable=SC2153
    temp_dir=$(mktemp --directory --tmpdir="$TEMP_DIR") || return 1

    # FIXME: PCManFM is missing names of nested action menus.
    # See: https://github.com/lxde/pcmanfm/issues/40
    # See: https://github.com/lxde/libfm/issues/129

    # -------------------------------------------------------------------------
    # Create the 'scripts.desktop' for the categories (main menu).
    # -------------------------------------------------------------------------
    local msg_scripts=""
    msg_scripts=$(_i18n 'Scripts')
    menu_file="$temp_dir/$APP_NAME-main.desktop"
    {
        printf "%s\n" "[Desktop Entry]"
        printf "%s\n" "Type=Menu"
        printf "%s\n" "Name=$msg_scripts"
        _i18n_print_desktop_name "Name" "$msg_scripts"
        printf "%s\n" "Icon=inode-directory"
        printf "%s" "ItemsList="
        find -L "$INSTALL_DIR" -mindepth 1 -maxdepth 1 -type d \
            "${IGNORE_FIND_PATHS[@]}" \
            -printf "$APP_NAME-%f\0" 2>/dev/null |
            sort --zero-terminated | tr "\0" ";" | _sanitize_string
        printf "\n"

    } | _tee_file "$menu_file"
    chmod +x -- "$menu_file"

    # -------------------------------------------------------------------------
    # Create a '.desktop' file for each sub-category (sub-menus).
    # -------------------------------------------------------------------------
    local dir_items=""
    local name=""
    local filename=""
    while IFS= read -r -d $'\0' filename; do
        name=${filename##*/}
        dir_items=$(find -L "$filename" -mindepth 1 -maxdepth 1 \
            "${IGNORE_FIND_PATHS[@]}" \
            -printf "$APP_NAME-%f\0" 2>/dev/null |
            sort --zero-terminated | tr "\0" ";" | _sanitize_string)
        if [[ -z "$dir_items" ]]; then
            continue
        fi

        menu_file=$(_sanitize_string <<<"$name")
        menu_file="${menu_file}.desktop"
        menu_file="$temp_dir/$APP_NAME-$menu_file"
        {
            printf "%s\n" "[Desktop Entry]"
            printf "%s\n" "Type=Menu"
            printf "%s\n" "Name=$name"
            _i18n_print_desktop_name "Name" "$name"
            printf "%s\n" "Icon=inode-directory"
            printf "%s\n" "ItemsList=$dir_items"

        } | _tee_file "$menu_file"
        chmod +x -- "$menu_file"

    done < <(find -L "$INSTALL_DIR" -mindepth 1 -type d \
        "${IGNORE_FIND_PATHS[@]}" \
        -print0 2>/dev/null | sort --zero-terminated)

    # -------------------------------------------------------------------------
    # Create a '.desktop' file for each script.
    # -------------------------------------------------------------------------
    local action_name=""
    while IFS= read -r -d $'\0' filename; do
        name=${filename##*/}

        action_name=$(_sanitize_string <<<"$name")
        menu_file="${action_name}.desktop"
        menu_file="$temp_dir/$APP_NAME-$menu_file"
        {
            printf "%s\n" "[Desktop Entry]"
            printf "%s\n" "Type=Action"
            printf "%s\n" "Name=$name"
            _i18n_print_desktop_name "Name" "$name"
            printf "%s\n" "Profiles=$action_name"
            printf "\n"
            printf "%s\n" "[X-Action-Profile $action_name]"
            printf "%s\n" "Exec=bash \"$filename\" %F"

        } | _tee_file "$menu_file"
        chmod +x -- "$menu_file"

    done < <(_list_scripts)

    # -------------------------------------------------------------------------
    # Replace the old files only after all new files were created.
    # -------------------------------------------------------------------------
    rm -f -- "$menus_path/$APP_NAME-"*.desktop
    mkdir --parents -- "$menus_path"
    cp --force -- "$temp_dir/$APP_NAME-"*.desktop "$menus_path/"
}
