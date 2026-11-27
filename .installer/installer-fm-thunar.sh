#!/usr/bin/env bash
# =============================================================================
# Description: Provide installer functions for Thunar.
# Sourced by 'install.sh'. Do not run directly.
#
# Files and directories created:
#   ~/.config/Thunar/uca.xml
#   ~/.config/Thunar/accels.scm
# =============================================================================

_close_file_manager_thunar() {
    thunar -q &>/dev/null
}

_install_accels_thunar() {
    local accels_file="$HOME/.config/Thunar/accels.scm"

    mkdir --parents -- "$(dirname -- "$accels_file")"

    # Write to a temporary file first, then replace the destination.
    local accels_tmp=""
    accels_tmp=$(mktemp --tmpdir="$TEMP_DIR")

    {
        # Default Thunar shortcuts.
        printf "%s\n" '(gtk_accel_path "<Actions>/ThunarActions/uca-action-1-1" "")'
        printf "%s\n" '(gtk_accel_path "<Actions>/ThunarActions/uca-action-2-2" "")'
        printf "%s\n" '(gtk_accel_path "<Actions>/ThunarActions/uca-action-3-3" "<Primary><Shift>f")'
        printf "%s\n" '(gtk_accel_path "<Actions>/ThunarActions/uca-action-4-4" "")'
        # Disable the shortcut <Control><Shift>O (open-in-new-window).
        printf "%s\n" '(gtk_accel_path "<Actions>/ThunarActionManager/open-in-new-window" "")'
        # Disable the shortcut <Control>E (view-side-pane-tree).
        printf "%s\n" '(gtk_accel_path "<Actions>/ThunarWindow/view-side-pane-tree" "")'

        local filename=""
        while IFS= read -r -d '' filename; do
            local keyboard_shortcut=""
            keyboard_shortcut=$(_get_par_value \
                "$filename" "install_keyboard_shortcut")
            keyboard_shortcut=${keyboard_shortcut//Control/Primary}

            if [[ -n "$keyboard_shortcut" ]]; then
                local msg_scripts=""
                msg_scripts=$(_i18n 'Scripts')
                local name=""
                local submenu=""
                local unique_id=""
                name=$(basename -- "$filename")
                submenu=$(dirname -- "$filename")
                submenu="$msg_scripts/${submenu##*scripts/}"
                unique_id=$(md5sum <<<"$submenu$name" 2>/dev/null |
                    sed "s|[^0-9]*||g" | cut -c 1-8)

                printf "%s\n" '(gtk_accel_path "<Actions>/ThunarActions/uca-action-'"$unique_id"'" "'"$keyboard_shortcut"'")'
            fi
        done < <(_list_scripts)

    } | _tee_file "$accels_tmp"

    _replace_file "$accels_tmp" "$accels_file"
}

_install_actions_thunar() {
    local menu_file=""
    local menus_path="$HOME/.config/Thunar"
    mkdir --parents -- "$menus_path"
    menu_file="$menus_path/uca.xml"

    if [[ -f "$menu_file" ]]; then
        # Create a backup of older custom actions.
        _item_create_backup "$menu_file"
    else
        # Create the file "~/.config/Thunar/uca.xml" (if not exists).
        {
            printf "%s\n" "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
            printf "%s\n" "<actions>"
            printf "%s\n" "</actions>"
        } | _tee_file "$menu_file"
    fi

    # Restore a previously created backup of custom actions, if available,
    # before updating the file with new custom actions.
    if [[ -f "$menu_file.bak" ]]; then
        cp --force -- "$menu_file.bak" "$menu_file"
    fi

    # -------------------------------------------------------------------------
    # Update the file "~/.config/Thunar/uca.xml".
    # -------------------------------------------------------------------------
    sed -i "/<\/actions>/d" -- "$menu_file"
    {
        local filename=""
        local name=""
        local submenu=""
        local unique_id=""
        local msg_scripts=""
        msg_scripts=$(_i18n 'Scripts')

        while IFS= read -r -d '' filename; do
            name=$(basename -- "$filename")
            submenu=$(dirname -- "$filename")
            submenu="$msg_scripts/${submenu##*scripts/}"

            printf "%s\n" "<action>"
            printf "\t%s\n" "<icon></icon>"
            printf "\t%s\n" "<name>$(_xml_escape "$(_i18n "$name")")</name>"
            printf "\t%s\n" "<submenu>$(_xml_escape "$(_i18n_translate_path "$submenu")")</submenu>"

            # Generate a unique id.
            unique_id=$(md5sum <<<"$submenu$name" 2>/dev/null |
                sed "s|[^0-9]*||g" | cut -c 1-8)
            printf "\t%s\n" "<unique-id>$unique_id</unique-id>"

            printf "\t%s\n" "<command>$(_xml_escape "bash \"$filename\" %F")</command>"
            printf "\t%s\n" "<description></description>"
            printf "\t%s\n" "<range></range>"
            printf "\t%s\n" "<patterns>*</patterns>"
            printf "\t%s\n" "<directories/>"
            printf "\t%s\n" "<audio-files/>"
            printf "\t%s\n" "<image-files/>"
            printf "\t%s\n" "<text-files/>"
            printf "\t%s\n" "<video-files/>"
            printf "\t%s\n" "<other-files/>"
            printf "%s\n" "</action>"
        done < <(_list_scripts)

        printf "%s\n" "</actions>"

    } | _tee_file_append "$menu_file"
}

# Escape the XML special characters in a string.
_xml_escape() {
    local text=$1

    text=${text//&/"&amp;"}
    text=${text//</"&lt;"}
    text=${text//>/"&gt;"}
    text=${text//\"/"&quot;"}
    printf "%s" "$text"
}
