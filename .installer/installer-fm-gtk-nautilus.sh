#!/usr/bin/env bash

# =============================================================================
# Description: Installer functions for Nautilus.
# Sourced by 'install.sh'. Do not run directly.
# =============================================================================

_close_file_manager_nautilus() {
    # This file manager supports the '-q' option to quit gracefully.
    nautilus -q &>/dev/null
}

_install_accels_nautilus() {
    local accels_file="$HOME/.config/nautilus/scripts-accels"
    mkdir --parents -- "$(dirname -- "$accels_file")"

    # Create a backup of older custom actions.
    _item_create_backup "$accels_file"
    rm -f -- "$accels_file"

    {
        local filename=""
        while IFS= read -r -d $'\0' filename; do
            local keyboard_shortcut=""
            keyboard_shortcut=$(_get_par_value \
                "$filename" "install_keyboard_shortcut")

            if [[ -n "$keyboard_shortcut" ]]; then
                local name=""
                name=$(basename -- "$filename")
                printf "%s\n" "$keyboard_shortcut $(_i18n "$name")"
            fi
        done < <(_list_scripts)

    } | _tee_file "$accels_file"
    _chown_file "$accels_file"
}

_install_actions_nautilus() {
    _create_links "$HOME/.local/share/nautilus/scripts"
}
