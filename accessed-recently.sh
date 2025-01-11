#!/usr/bin/env bash

# This script manages an "Accessed recently" folder within the "scripts" directory.
# It creates symbolic links to maintain a list of the 10 most recently accessed scripts.
# The folder serves as a shortcut to quickly access frequently used scripts.

ACCESSED_LINKS_PATH="$ROOT_DIR/Accessed recently"
readonly ACCESSED_LINKS_PATH

_clean_up_accessed_files() {
    # This function Cleans up the "Accessed recently" folder by:
    # - Removing duplicate symbolic links.
    # - Keeping only the 10 most recently accessed files.
    # - Renaming the links with zero-padded numeric prefixes for easy sorting.

    local directory="$ACCESSED_LINKS_PATH"
    local num_files_to_keep=10
    local file=""
    declare -A file_map

    # Read all symbolic links in the directory.
    while IFS= read -r -d '' file; do
        local link_target=""
        link_target=$(readlink "$file")
        if [[ -n $link_target ]]; then
            set +u
            if [[ -n ${file_map[$link_target]} ]]; then
                # Remove duplicate symbolic link pointing to the same target.
                rm -f "$file"
            else
                file_map["$link_target"]="$file"
                local files+=("$file")
            fi
            set -u
        fi
    done < <(find "$directory" -maxdepth 1 -type l -printf '%T@ %p\0' | sort -r -z -n | cut -z -d " " -f2-)

    # Delete all but the most recent 'num_files_to_keep' symbolic links.
    for ((i = num_files_to_keep; i < ${#files[@]}; i++)); do
        rm -f "${files[$i]}"
    done

    # Rename remaining files with zero-padded numeric prefixes for sorted display.
    local count=1
    for file in "${files[@]}"; do
        mv "$file" "$directory/$(printf '%02d' $count) $(basename "$file" | sed 's/^\([0-9]\{2\} \)*//')"
        ((count++))
    done
}

_link_file_to_accessed() {
    # This function creates a symbolic link to the specified file in the "Accessed recently" folder.
    #
    # Parameters:
    #   - $1 (file): The path to the file that will be linked in the "Accessed recently" folder.

    local file="$1"

    pushd "$ACCESSED_LINKS_PATH" &>/dev/null || return

    # Create a symbolic link to the specified file in the directory.
    ln -s "$file" .

    popd &>/dev/null || return
}

_update_accessed_recently_history() {
    local script_name=""
    local script_matches=""
    local match_count=0
    local script_to_link_full_path=""

    # Identify the script being executed to potentially add it to the "Accessed recently" folder.
    script_name=$(basename -- "$(realpath -e "$0")")
    script_matches=$(find "$ROOT_DIR" -path "$ACCESSED_LINKS_PATH" -prune -o -type f -name "$script_name" -print)

    if [ -z "$script_matches" ]; then
        match_count=0
    else
        match_count=$(echo "$script_matches" | wc -l)
    fi

    # If exactly one match is found, store its full path for linking.
    if [[ $match_count == 1 ]]; then
        script_to_link_full_path="$script_matches"
    else
        _display_error_box "Can't find [ $script_name ] location to link in accessed"
    fi

    # Ensure the "Accessed recently" directory exists, creating it if necessary.
    if [[ ! -d $ACCESSED_LINKS_PATH ]]; then
        mkdir -p "$ACCESSED_LINKS_PATH"
    fi

    # If the script's full path is determined and it exists, link it to the folder.
    if [[ -n $script_to_link_full_path ]] && [[ -f $script_to_link_full_path ]]; then
        _link_file_to_accessed "$script_to_link_full_path"
        _clean_up_accessed_files
    fi
}

_update_accessed_recently_history
