#!/usr/bin/env bash

# This script manages an "Accessed recently" directory within the scripts directory.
# It creates symbolic links to maintain a list of the 10 most recently accessed scripts.
# The directory serves as a shortcut to quickly access frequently used scripts.

# -----------------------------------------------------------------------------
# CONSTANTS
# -----------------------------------------------------------------------------

ACCESSED_RECENTLY_DIR="$ROOT_DIR/Accessed recently"
NUM_LINKS_TO_KEEP=10

readonly \
    ACCESSED_RECENTLY_DIR \
    NUM_LINKS_TO_KEEP

# -----------------------------------------------------------------------------
# FUNCTIONS
# -----------------------------------------------------------------------------

_clean_up_accessed_files() {
    # This function Cleans up the '$ACCESSED_RECENTLY_DIR' directory by:
    # - Removing duplicate symbolic links.
    # - Keeping only the '$NUM_LINKS_TO_KEEP' most recently accessed files.
    # - Renaming the links with zero-padded numeric prefixes for easy sorting.

    local file=""
    local files=()
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
                files+=("$file")
            fi
            set -u
        fi
    done < <(find "$ACCESSED_RECENTLY_DIR" -maxdepth 1 -type l -printf '%T@ %p\0' | sort -r -z -n | cut -z -d " " -f2-)

    # Delete all but the most recent '$NUM_LINKS_TO_KEEP' symbolic links.
    for ((i = NUM_LINKS_TO_KEEP; i < ${#files[@]}; i++)); do
        rm -f "${files[$i]}"
    done

    # Rename remaining files with zero-padded numeric prefixes for sorted display.
    local count=1
    for file in "${files[@]}"; do
        mv "$file" "$ACCESSED_RECENTLY_DIR/$(printf '%02d' $count) $(basename "$file" | sed 's/^\([0-9]\{2\} \)*//')"
        ((count++))
    done
}

_link_file_to_accessed() {
    # This function creates a symbolic link to the specified file in the '$ACCESSED_RECENTLY_DIR'
    # directory.
    #
    # Parameters:
    #   - $1 (file): The path to the file that will be linked in the '$ACCESSED_RECENTLY_DIR'
    #     directory.

    local file="$1"

    pushd "$ACCESSED_RECENTLY_DIR" &>/dev/null || return

    # Create a symbolic link to the specified file in the directory.
    ln -s "$file" .

    popd &>/dev/null || return
}

_update_accessed_recently_history() {
    # This function updates the history of recently accessed scripts. It ensures that the script
    # currently being executed is properly tracked and linked within the '$ACCESSED_RECENTLY_DIR'
    # directory.

    local script_name=""
    local script_matches=""
    local match_count=0
    local script_to_link_full_path=""

    # Ensure the '$ACCESSED_RECENTLY_DIR' directory exists, creating it if necessary.
    if [[ ! -d $ACCESSED_RECENTLY_DIR ]]; then
        mkdir -p "$ACCESSED_RECENTLY_DIR"
    fi

    # Identify the script being executed to potentially add it
    # to the '$ACCESSED_RECENTLY_DIR' directory.
    script_name=$(basename -- "$(realpath -e "$0")")
    script_matches=$(find "$ROOT_DIR" -path "$ACCESSED_RECENTLY_DIR" -prune -o -type f -name "$script_name" -print)

    if [ -z "$script_matches" ]; then
        match_count=0
    else
        match_count=$(echo "$script_matches" | wc -l)
    fi

    # If exactly one match is found, store its full path for linking.
    if [[ $match_count == 1 ]]; then
        script_to_link_full_path="$script_matches"
    fi

    # If the script's full path is determined and it exists, link it to the directory.
    if [[ -n $script_to_link_full_path ]] && [[ -f $script_to_link_full_path ]]; then
        _link_file_to_accessed "$script_to_link_full_path"
        _clean_up_accessed_files
    fi
}

_update_accessed_recently_history
