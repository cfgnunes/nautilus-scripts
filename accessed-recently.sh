#!/usr/bin/env bash

ACCESSED_LINKS_PATH="$ROOT_DIR/Accessed recently"

_clean_up_accessed_files() {
    local directory="$ACCESSED_LINKS_PATH"
    local num_files_to_keep=10
    declare -A file_map

    while IFS= read -r -d '' file; do
        local link_target
        link_target=$(readlink "$file")
        if [[ -n $link_target ]]; then
            set +u
            if [[ -n ${file_map[$link_target]} ]]; then
                # _display_info_box "Removing duplicate link $file"
                rm -f "$file"
            else
                file_map["$link_target"]="$file"
                local files+=("$file")
            fi
            set -u
        fi
    done < <(find "$directory" -maxdepth 1 -type l -printf '%T@ %p\0' | sort -r -z -n | cut -z -d' ' -f2-)

    # Delete all but the most recent num_files_to_keep files
    for ((i = num_files_to_keep; i < ${#files[@]}; i++)); do
        _display_info_box "Removing ${files[$i]}"
        rm -f "${files[$i]}"
    done

    # Rename files to prepend 0 padded numbers
    local count=1
    for file in "${files[@]}"; do
        mv "$file" "$directory/$(printf '%02d' $count) $(basename "$file" | sed 's/^\([0-9]\{2\} \)*//')"
        ((count++))
    done
}

_link_file_to_accessed() {
    local directory="$ACCESSED_LINKS_PATH"
    local file="$1"

    pushd "$directory" || {
        _display_error_box "${FUNCNAME[0]}: Can't access folder"
        exit
    }

    echo "Into $(pwd)"
    ln -s "$file" .

    popd || _display_error_box "${FUNCNAME[0]}: Can't popd"
    echo "Back to $(pwd)"
    _clean_up_accessed_files
}

SCRIPT_NAME=$(basename -- "$(realpath -e "$0")")
SCRIPT_MATCHES=$(find "$ROOT_DIR" -path "$ACCESSED_LINKS_PATH" -prune -o -type f -name "$SCRIPT_NAME" -print)

if [ -z "$SCRIPT_MATCHES" ]; then
    MATCH_COUNT=0
else
    MATCH_COUNT=$(echo "$SCRIPT_MATCHES" | wc -l)
fi

if [[ $MATCH_COUNT == 1 ]]; then
    SCRIPT_TO_LINK_FULL_PATH="$SCRIPT_MATCHES"
else
    _display_error_box "Can't find [ $SCRIPT_NAME ] location to link in accessed"
fi

if [[ ! -d $ACCESSED_LINKS_PATH ]]; then
    echo "[$ACCESSED_LINKS_PATH] does not exist"
    mkdir -p "$ACCESSED_LINKS_PATH"
fi

if [[ -n $SCRIPT_TO_LINK_FULL_PATH ]] && [[ -f $SCRIPT_TO_LINK_FULL_PATH ]]; then
    _link_file_to_accessed "$SCRIPT_TO_LINK_FULL_PATH"
fi
