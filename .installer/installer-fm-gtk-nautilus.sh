#!/usr/bin/env bash

# =============================================================================
# Description: Installer functions for Nautilus.
# Sourced by 'install.sh'. Do not run directly.
#
# Files and directories created:
#   ~/.local/share/nautilus/scripts/
#   ~/.config/nautilus/scripts-accels
# =============================================================================

_close_file_manager_nautilus() {
    nautilus -q &>/dev/null
}

_install_accels_nautilus() {
    local accels_file="$HOME/.config/nautilus/scripts-accels"

    mkdir --parents -- "$(dirname -- "$accels_file")"

    # Write to a temporary file first, then replace the destination.
    local accels_tmp=""
    accels_tmp=$(mktemp --tmpdir="$TEMP_DIR")

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

    } | _tee_file "$accels_tmp"

    _replace_file "$accels_tmp" "$accels_file"
}

_install_actions_nautilus() {
    _create_links "$HOME/.local/share/nautilus/scripts"
}
