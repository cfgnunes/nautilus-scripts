#!/usr/bin/env bash
# =============================================================================
# Description: Provide installer functions for Nautilus.
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

    # Step 1: Collect the new shortcuts to be added to the accels file.
    local -A new_by_name=()
    local -A new_by_shortcut=()
    local -a new_lines=()
    local filename=""
    while IFS= read -r -d $'\0' filename; do
        # Read the shortcut declared in the script header.
        local keyboard_shortcut=""
        keyboard_shortcut=$(_get_par_value \
            "$filename" "install_keyboard_shortcut")

        # Scripts without a shortcut are ignored.
        if [[ -n "$keyboard_shortcut" ]]; then
            # The name must match the one shown in Nautilus, so it goes
            # through the same translation (_i18n) used at link creation.
            local name=""
            name=$(_i18n "$(basename -- "$filename")")
            new_by_name["$name"]=1
            new_by_shortcut["$keyboard_shortcut"]=1
            new_lines+=("$keyboard_shortcut $name")
        fi
    done < <(_list_scripts)

    # Step 2: Build the new content in a temporary file first. The new content
    # is the combination of current accels file lines and the new shortcuts to
    # be added, while avoiding conflicts.
    local accels_tmp=""
    accels_tmp=$(mktemp --tmpdir="$TEMP_DIR")
    {
        # Keep existing lines, except those replaced by a new shortcut.
        if [[ -f "$accels_file" ]]; then
            local line=""
            while IFS= read -r line || [[ -n "$line" ]]; do
                # Drop empty lines.
                [[ -z "$line" ]] && continue

                # Split the line at the first space.
                local old_shortcut="${line%% *}"
                local old_name="${line#* }"

                # Skip lines that conflict with a new shortcut.
                if [[ -n "${new_by_name["$old_name"]:-}" ||
                    -n "${new_by_shortcut["$old_shortcut"]:-}" ]]; then
                    continue
                fi
                printf "%s\n" "$line"
            done <"$accels_file"
        fi

        # Step 3: Append the new shortcuts after the preserved ones.
        # The new lines are sorted.
        if ((${#new_lines[@]} > 0)); then
            printf "%s\n" "${new_lines[@]}" | sort -V
        fi
    } | _tee_file "$accels_tmp"

    _replace_file "$accels_tmp" "$accels_file"
}

_install_actions_nautilus() {
    _create_links "$HOME/.local/share/nautilus/scripts"
}
