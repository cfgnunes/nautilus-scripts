#!/usr/bin/env bash

# This script manages an "Accessed recently" directory within the scripts'
# directory. It creates symbolic links to maintain a list of the 10 most
# recently accessed scripts. The directory serves as a shortcut to quickly
# access frequently used scripts.

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

_recent_scripts_organize() {
    # This function organizes the directory containing recently accessed
    # scripts ('$ACCESSED_RECENTLY_DIR'). This function manages symbolic links
    # in the directory by:
    # 1. Keeping only the '$NUM_LINKS_TO_KEEP' most recently accessed scripts.
    # 2. Renaming retained links with numeric prefixes (e.g., "01", "02") for
    #    easy sorting.

    local files=""
    files=$(find "$ACCESSED_RECENTLY_DIR" -maxdepth 1 -type l -print0 |
        sort --zero-terminated --numeric-sort | tr "\0" "$FIELD_SEPARATOR")

    # Process the files, keeping only the '$NUM_LINKS_TO_KEEP' most recent.
    local count=1
    local file=""
    for file in $files; do
        if ((count <= NUM_LINKS_TO_KEEP)); then
            # Rename the link with a numeric prefix for ordering.
            mv -f -- "$file" "$ACCESSED_RECENTLY_DIR/$(printf '%02d' "$count") $(basename "$file" | sed 's|^\([0-9]\{2\} \)*||')" 2>/dev/null
            ((count++))
        else
            # Remove excess links.
            rm -f -- "$file"
        fi
    done
}

_recent_scripts_add() {
    # This function adds a script to the history of recently accessed scripts
    # ('$ACCESSED_RECENTLY_DIR').
    #
    # Parameters:
    #   - $1 (file): The full path to the script to be linked.

    local file="$1"

    _directory_push "$ACCESSED_RECENTLY_DIR" || return 1

    # Remove any existing links pointing to the same script.
    find "$ACCESSED_RECENTLY_DIR" -lname "$file" -exec rm -f -- "{}" +

    # Create a new symbolic link with a "00" prefix.
    ln -s -- "$file" "00 $(basename -- "$file")"

    _directory_pop || return 1
}

_recent_scripts_update() {
    # This function updates the history of recently accessed scripts, ensuring
    # the current script is tracked. It ensures the current script is properly
    # linked within the '$ACCESSED_RECENTLY_DIR'.

    local match_count=0
    local script_matches=""
    local script_name=""
    local script_to_link=""

    # Ensure the '$ACCESSED_RECENTLY_DIR' directory exists,
    # creating it if necessary.
    if [[ ! -d $ACCESSED_RECENTLY_DIR ]]; then
        mkdir -p "$ACCESSED_RECENTLY_DIR"
    fi

    # Identify the script being executed to potentially add it to the
    # '$ACCESSED_RECENTLY_DIR' directory.
    script_name=$(basename -- "$(realpath -e "$0")")
    script_matches=$(find "$ROOT_DIR" -path "$ACCESSED_RECENTLY_DIR" \
        -prune -o -type f -name "$script_name" -print)

    if [[ -z "$script_matches" ]]; then
        match_count=0
    else
        match_count=$(echo "$script_matches" | wc -l)
    fi

    # If exactly one match is found, store its full path for linking.
    if ((match_count == 1)); then
        script_to_link="$script_matches"
    fi

    # If the script's full path is determined and it exists,
    # link it to the directory.
    if [[ -n "$script_to_link" ]] && [[ -e "$script_to_link" ]]; then
        _recent_scripts_add "$script_to_link"
        _recent_scripts_organize
    fi
}

_recent_scripts_update
