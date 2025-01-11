#!/usr/bin/env bash

# This script manages an "Accessed recently" folder within the "scripts" directory.
# It creates symbolic links to maintain a list of the 10 most recently accessed scripts.
# The folder serves as a shortcut to quickly access frequently used scripts.

ACCESSED_LINKS_PATH="$ROOT_DIR/Accessed recently"

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

    local directory="$ACCESSED_LINKS_PATH"
    local file="$1"

    pushd "$directory" &>/dev/null || true

    # Create a symbolic link to the specified file in the directory.
    ln -s "$file" .

    popd &>/dev/null || true
    _clean_up_accessed_files
}

# Identify the script being executed to potentially add it to the "Accessed recently" folder.
SCRIPT_NAME=$(basename -- "$(realpath -e "$0")")
SCRIPT_MATCHES=$(find "$ROOT_DIR" -path "$ACCESSED_LINKS_PATH" -prune -o -type f -name "$SCRIPT_NAME" -print)

if [ -z "$SCRIPT_MATCHES" ]; then
    MATCH_COUNT=0
else
    MATCH_COUNT=$(echo "$SCRIPT_MATCHES" | wc -l)
fi

# If exactly one match is found, store its full path for linking.
if [[ $MATCH_COUNT == 1 ]]; then
    SCRIPT_TO_LINK_FULL_PATH="$SCRIPT_MATCHES"
else
    _display_error_box "Can't find [ $SCRIPT_NAME ] location to link in accessed"
fi

# Ensure the "Accessed recently" directory exists, creating it if necessary.
if [[ ! -d $ACCESSED_LINKS_PATH ]]; then
    mkdir -p "$ACCESSED_LINKS_PATH"
fi

# If the script's full path is determined and it exists, link it to the folder.
if [[ -n $SCRIPT_TO_LINK_FULL_PATH ]] && [[ -f $SCRIPT_TO_LINK_FULL_PATH ]]; then
    _link_file_to_accessed "$SCRIPT_TO_LINK_FULL_PATH"
fi
