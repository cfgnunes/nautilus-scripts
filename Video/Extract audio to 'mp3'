#!/usr/bin/env bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
# shellcheck source=/dev/null
source "${SCRIPT_DIR/%scripts\/*/scripts}/_common_functions"

# Initial checks
_check_dependencies ffmpeg || exit 1
INPUT_FILES=$(_get_files "$*" "f" "1" "" "video") || exit 1
OUTPUT_DIR=$(_get_output_dir) || exit 1

_main_task() {
    local FILE=$1
    local OUTPUT_DIR=$2
    local OUTPUT_FILE
    local STD_OUTPUT
    local EXIT_CODE

    OUTPUT_FILE="$OUTPUT_DIR/$(_get_filename_without_extension "$FILE").mp3"
    STD_OUTPUT=$(ffmpeg -threads 4 -y -i "$FILE" -vn -c:a libmp3lame -b:a 192k -ar 44100 -ac 2 "$OUTPUT_FILE" 2>&1)
    EXIT_CODE=$?
    _log_error_result "$FILE" "$STD_OUTPUT" "$OUTPUT_DIR" "$EXIT_CODE" "$OUTPUT_FILE"
}

_run_parallel_tasks "$INPUT_FILES"
_display_result_tasks "$OUTPUT_DIR"
