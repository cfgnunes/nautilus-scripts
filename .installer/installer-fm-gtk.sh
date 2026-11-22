#!/usr/bin/env bash
# =============================================================================
# Description: Shared installer functions for GTK-based file managers (Nautilus, Nemo and Caja).
# Sourced by 'install.sh'. Do not run directly.
# =============================================================================

_create_links() {
    local destination_dir=$1

    # Remove symlinks left by a previous install.
    find "$destination_dir" -type l -lname "$INSTALL_DIR/*" -delete 2>/dev/null

    # Remove empty directories left by a previous install.
    find "$destination_dir" -type d -empty -delete 2>/dev/null

    mkdir --parents -- "$destination_dir"
    ln -sf -- "$INSTALL_DIR/.po" "$destination_dir/.po"

    local dir=""
    local name=""
    local relative_path=""

    # Process all files and directories recursively.
    local file_path=""
    while IFS= read -r -d $'\0' file_path; do
        relative_path="${file_path#"$INSTALL_DIR"/}"
        dir=$(dirname -- "$relative_path")
        name=$(basename -- "$file_path")

        # Skip the .po directory (already linked).
        [[ "$relative_path" == ".po" ]] && continue

        # Create translated directory path.
        local translated_dir=""
        translated_dir=$(_i18n_translate_path "$dir")

        # Create destination path.
        local destination_path="$destination_dir"
        if [[ -n "$translated_dir" ]]; then
            destination_path="$destination_dir/$translated_dir"
        fi

        if [[ -d "$file_path" ]]; then
            # Create translated directory.
            mkdir --parents -- "$destination_path/$(_i18n "$name")"
        else
            # Create parent directories and link file.
            mkdir --parents -- "$destination_path"
            ln -sf -- "$file_path" "$destination_path/$(_i18n "$name")"
        fi
    done < <(find -L "$INSTALL_DIR" \
        -mindepth 1 "${IGNORE_FIND_PATHS[@]}" -print0 2>/dev/null)
}

_encode_path_gtk() {
    local string=$1
    local length="${#string}"

    local c=""
    local i=""
    for ((i = 0; i < length; i++)); do
        c="${string:i:1}"
        # shellcheck disable=SC1001
        case "$c" in
        [a-zA-Z0-9\:\'\(\)\.\_\~\-\\]) printf "%s" "$c" ;;
        *) printf "%s" "$c" | hexdump -v -e '/1 "-%02X" ' | sed "s|-|\%|g" ;;
        esac
    done
}

_install_accels_gnome2() {
    local accels_file=$1
    local scripts_installed_dir=$2

    mkdir --parents -- "$(dirname -- "$accels_file")"

    # Create a backup of older custom actions.
    _item_create_backup "$accels_file"
    rm -f -- "$accels_file"

    {
        # Disable the shortcut <Control><Shift>O (OpenAlternate).
        printf "%s\n" '(gtk_accel_path "<Actions>/DirViewActions/OpenAlternate" "")'
        # Disable the shortcut <Control><Shift>O (OpenInNewTab).
        printf "%s\n" '(gtk_accel_path "<Actions>/DirViewActions/OpenInNewTab" "")'

        local filename=""
        while IFS= read -r -d $'\0' filename; do
            local keyboard_shortcut=""
            keyboard_shortcut=$(_get_par_value \
                "$filename" "install_keyboard_shortcut")
            keyboard_shortcut=${keyboard_shortcut//Control/Primary}

            if [[ -n "$keyboard_shortcut" ]]; then
                filename=${filename//\//\\\\s}
                filename=$(_encode_path_gtk "$filename")

                printf "%s\n" '(gtk_accel_path "<Actions>/ScriptsGroup/script_file:\\s\\s'"$filename"'" "'"$keyboard_shortcut"'")'
            fi
        done < <(_list_installed_links "$scripts_installed_dir")

    } | _tee_file "$accels_file"
    _chown_file "$accels_file"
}

_list_installed_links() {
    local dir=$1
    find "$dir" -mindepth 2 -type l -lname "$INSTALL_DIR/*" \
        "${IGNORE_FIND_PATHS[@]}" \
        -print0 2>/dev/null | sort --zero-terminated
}
