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
    # 2. Renaming retained links with numeric prefixes (e.g., "01", "02") to
    #    maintain chronological order.

    local links=()
    readarray -d "" links < <(
        find "$ACCESSED_RECENTLY_DIR" -maxdepth 1 -type l -print0 2>/dev/null |
            sort --zero-terminated --numeric-sort
    )

    # Process the links, keeping only the '$NUM_LINKS_TO_KEEP' most recent.
    local count=1
    local link=""
    for link in "${links[@]}"; do
        if ((count <= NUM_LINKS_TO_KEEP)); then
            # Rename the link with a numeric prefix for ordering.
            mv -f -- "$link" "$ACCESSED_RECENTLY_DIR/$(printf '%02d' "$count") $(basename "$link" | sed --regexp-extended 's|^[0-9]{2} ||')" 2>/dev/null
            ((count++))
        else
            # Remove excess links.
            rm -f -- "$link"
        fi
    done
}

_recent_scripts_add() {
    # This function adds the running script to the history of recently accessed
    # scripts ('$ACCESSED_RECENTLY_DIR').

    local running_script=""
    running_script=$(realpath -e "$0")

    # Create '$ACCESSED_RECENTLY_DIR' if it does not exist.
    if [[ ! -d $ACCESSED_RECENTLY_DIR ]]; then
        mkdir -p "$ACCESSED_RECENTLY_DIR"
    fi

    _directory_push "$ACCESSED_RECENTLY_DIR" || return 1

    # Remove any existing links pointing to the same script.
    find "$ACCESSED_RECENTLY_DIR" -lname "$running_script" \
        -exec rm -f -- "{}" +

    # Create a new symbolic link with a "00" prefix.
    ln -s -- "$running_script" "00 $(basename -- "$running_script")"

    _directory_pop || return 1
}

_recent_scripts_add
_recent_scripts_organize
