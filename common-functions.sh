#!/usr/bin/env bash

# This file contains common functions that will be imported by the scripts.

set -u

# Define only 'New line' as default field separator:
# used in 'for' commands to iterate over files.
_DEFAULT_IFS=$'\n'
IFS=$_DEFAULT_IFS

# Parameters
_PREFIX_ERROR_LOG_FILE="Errors"
_PREFIX_OUTPUT_DIR="Output"

# Create temp directories for use in scripts
_TEMP_DIR=$(mktemp --directory --suffix="-script")
_TEMP_DIR_LOG=$(mktemp --directory --tmpdir="$_TEMP_DIR" --suffix="-log")
TEMP_DIR_TASK=$(mktemp --directory --tmpdir="$_TEMP_DIR" --suffix="-task")

# A temporary FIFO to use in the "wait_box"
_TEMP_FIFO="$_TEMP_DIR/fifo"

# Remove the temp directory in unexpected exit
_trap_handler() {
    rm -rf "$_TEMP_DIR"
    echo "End of the script."
}
trap _trap_handler EXIT

_check_dependencies() {
    local DEPENDENCIES=$*
    local COMMAND=""
    local MESSAGE=""
    local PACKAGE_NAME=""

    # Add basic commands to check
    DEPENDENCIES="grep file xargs(findutils) pstree(psmisc) cmp(diffutils) $DEPENDENCIES"

    # Check all commands in the list 'DEPENDENCIES'
    IFS=" "
    for ITEM in $DEPENDENCIES; do
        # Item syntax: command(package), example: photorec(testdisk)
        COMMAND=${ITEM%%(*}

        # Check if has the command in the shell
        if hash "$COMMAND" &>/dev/null; then
            continue
        fi

        PACKAGE_NAME=$(echo "$ITEM" | grep --only-matching -P "\(+\K[^)]+")
        if [[ -n "$PACKAGE_NAME" ]]; then
            MESSAGE="The '$COMMAND' was not found (from package '$PACKAGE_NAME'). Would you like to install it?"
        else
            MESSAGE="The '$COMMAND' was not found. Would you like to install it?"
            PACKAGE_NAME=$COMMAND
        fi

        # Ask the user to install the package
        if _display_question_box "$MESSAGE"; then
            _install_package "$PACKAGE_NAME" "$COMMAND"
            continue
        fi

        _exit_error
    done
    IFS=$_DEFAULT_IFS
}

_check_result() {
    local EXIT_CODE=$1
    local STD_OUTPUT=$2
    local INPUT_FILE=$3
    local OUTPUT_FILE=$4

    # Check the 'EXIT_CODE' and log the error
    if ((EXIT_CODE != 0)); then
        _log_error "Exit code error." "$INPUT_FILE" "$STD_OUTPUT"
        return 1
    fi

    # Check if there is the word "Error" in stdout
    if ! echo "$INPUT_FILE" | grep --quiet --ignore-case "[^\w]error"; then
        if echo "$STD_OUTPUT" | grep --quiet --ignore-case "[^\w]error"; then
            _log_error "Word 'error' found in the standard output." "$INPUT_FILE" "$STD_OUTPUT"
            return 1
        fi
    fi

    # Check if output file exists
    if [[ -n "$OUTPUT_FILE" ]] && ! [[ -e "$OUTPUT_FILE" ]]; then
        _log_error "The output file does not exist." "$INPUT_FILE" "$STD_OUTPUT"
        return 1
    fi

    return 0
}

_display_info_box() {
    local MESSAGE=$1

    if env | grep --quiet "^TERM"; then
        echo "$MESSAGE"
    elif hash notify-send 2>/dev/null; then
        notify-send "$MESSAGE" &
    elif hash zenity &>/dev/null; then
        zenity --title "$(_get_script_name)" --info --width=300 --text "$MESSAGE"
    fi
}

_display_error_box() {
    local MESSAGE=$1

    if env | grep --quiet "^TERM"; then
        echo >&2 "$MESSAGE"
    elif hash notify-send 2>/dev/null; then
        notify-send -i error "$MESSAGE" &
    elif hash zenity &>/dev/null; then
        zenity --title "$(_get_script_name)" --error --width=300 --text "$MESSAGE"
    fi
}

_display_question_box() {
    local MESSAGE=$1
    local RESPONSE=""

    if env | grep --quiet "^TERM"; then
        read -r -p "$MESSAGE [Y/n] " RESPONSE
        [[ ${RESPONSE,,} == *"n"* ]] && return 1
    elif hash zenity &>/dev/null; then
        zenity --question --width=300 --text="$MESSAGE" || return 1
    fi
    return 0
}

_display_text_box() {
    local MESSAGE=$1
    _close_wait_box

    if [[ -z "$MESSAGE" ]]; then
        MESSAGE="(Empty result)"
    fi

    if env | grep --quiet "^TERM"; then
        echo "$MESSAGE"
    elif hash zenity &>/dev/null; then
        echo "$MESSAGE" | zenity \
            --text-info \
            --no-wrap \
            --height=400 \
            --width=750 \
            --title "$(_get_script_name)" &
    fi
}

_display_password_box() {
    local PASSWORD=""

    # Ask the user a password.
    if env | grep --quiet "^TERM"; then
        echo -n "Type your password: " >&2
        read -r PASSWORD
    elif hash zenity &>/dev/null; then
        PASSWORD=$(zenity \
            --password \
            --title="$(_get_script_name)" 2>/dev/null) || return 1
    fi

    # Check if the password is not empty
    if [[ -z "$PASSWORD" ]]; then
        _display_error_box "Error: you must define a password!"
        _exit_error
    fi

    echo "$PASSWORD"
}

_display_result_box() {
    local OUTPUT_DIR=$1
    local ERROR_LOG_FILE="$OUTPUT_DIR/$_PREFIX_ERROR_LOG_FILE.log"
    _close_wait_box

    # If the file already exists, add a suffix
    ERROR_LOG_FILE=$(_get_filename_suffix "$ERROR_LOG_FILE")

    # Compile log errors in a single file
    if ls "$_TEMP_DIR_LOG/"* &>/dev/null; then
        cat "$_TEMP_DIR_LOG/"* >"$ERROR_LOG_FILE"
    fi

    # Check if there was some error
    if [[ -f "$ERROR_LOG_FILE" ]]; then
        _display_error_box "Error: task finished with errors! See the '$ERROR_LOG_FILE' for details."
        _exit_error
    fi

    # If OUTPUT_DIR parameter is defined
    if [[ -n "$OUTPUT_DIR" ]]; then
        # Try to remove the output directory (if it is empty)
        rmdir "$OUTPUT_DIR" &>/dev/null

        # Check if output directory still exists
        if [[ -d "$OUTPUT_DIR" ]]; then
            _display_info_box "Task finished! The output files are in '$OUTPUT_DIR'."
        else
            _display_info_box "Task finished, but there are no output files!"
        fi
    else
        _display_info_box "Task finished!"
    fi
}

_display_wait_box() {
    _display_wait_box_message "Running the task. Please, wait..."
}

_display_wait_box_message() {
    local MESSAGE=$1

    if env | grep --quiet "^TERM"; then
        echo "$MESSAGE"
    elif hash zenity &>/dev/null; then
        rm -f "$_TEMP_FIFO"
        mkfifo "$_TEMP_FIFO"
        # shellcheck disable=SC2002
        cat "$_TEMP_FIFO" | (
            zenity \
                --title="$(_get_script_name)" \
                --width=400 \
                --progress \
                --pulsate \
                --auto-close \
                --text="$MESSAGE" ||
                (echo >"$_TEMP_FIFO" && _kill_tasks)
        ) &
    fi
}

_close_wait_box() {
    # Close the zenity progress by FIFO
    if [[ -p "$_TEMP_FIFO" ]]; then
        echo >"$_TEMP_FIFO"
    fi
}

_exit_error() {
    _close_wait_box
    # See the: https://www.baeldung.com/linux/safely-exit-scripts
    kill -SIGINT $$
}

_has_string_in_list() {
    local STRING=$1
    local LIST=$2

    IFS=", "
    for ITEM in $LIST; do
        if [[ "$STRING" == *"$ITEM"* ]]; then
            IFS=$_DEFAULT_IFS
            return 0
        fi
    done
    IFS=$_DEFAULT_IFS

    return 1
}

_install_package() {
    local PACKAGE_NAME=$1
    local COMMAND=$2

    _display_wait_box_message "Installing the package '$PACKAGE_NAME'. Please, wait..."

    # Install the package
    if hash pkexec &>/dev/null; then
        if hash apt-get &>/dev/null; then
            pkexec bash -c "apt-get update; apt-get -y install $PACKAGE_NAME &>/dev/null"
        elif hash pacman &>/dev/null; then
            pkexec bash -c "pacman -Syy; pacman --noconfirm -S $PACKAGE_NAME &>/dev/null"
        elif hash dnf &>/dev/null; then
            pkexec bash -c "dnf check-update; dnf -y install $PACKAGE_NAME &>/dev/null"
        elif hash yum &>/dev/null; then
            pkexec bash -c "yum check-update; yum -y install $PACKAGE_NAME &>/dev/null"
        else
            _display_error_box "Error: could not find a package manager!"
            _exit_error
        fi
    else
        _display_error_box "Error: could not run the installer as administrator!"
        _exit_error
    fi

    _close_wait_box

    # Check if the package was installed
    if ! hash "$COMMAND" &>/dev/null; then
        _display_error_box "Error: could not install the package '$PACKAGE_NAME'!"
        _exit_error
    fi

    _display_info_box "The package '$PACKAGE_NAME' has been successfully installed!"
}

_kill_tasks() {
    local CHILD_PIDS=""
    local SCRIPT_PID=""

    echo "Aborting the tasks..."

    # Get the process ID (PID) of the current script
    SCRIPT_PID=$$
    CHILD_PIDS=$(pstree -p "$SCRIPT_PID" | grep --only-matching -P "\(+\K[^)]+")

    # Use xargs and kill to send the SIGTERM signal to all child processes
    echo -n "$CHILD_PIDS" | xargs kill &>/dev/null
}

_get_filename_extension() {
    local FILENAME=$1
    echo "$FILENAME" | grep --only-matching --perl-regexp "(\.tar)?\.[^./]*$"
}

_get_filename_without_extension() {
    local FILENAME=$1
    echo "$FILENAME" | sed -r "s|(\.tar)?\.[^./]*$||"
}

_get_filename_suffix() {
    local FILENAME=$1
    local FILENAME_RESULT=$FILENAME
    local FILENAME_BASE=""
    local FILENAME_EXTENSION=""

    FILENAME_BASE=$(_get_filename_without_extension "$FILENAME")
    FILENAME_EXTENSION=$(_get_filename_extension "$FILENAME")

    # Avoid overwrite a file. If there is a file with the same name,
    # try to add a suffix, as 'file (1)', 'file (2)', ...
    local SUFFIX=0
    while [[ -e "$FILENAME_RESULT" ]]; do
        SUFFIX=$((SUFFIX + 1))
        FILENAME_RESULT="$FILENAME_BASE ($SUFFIX)$FILENAME_EXTENSION"
    done

    echo "$FILENAME_RESULT"
}

_get_files() {
    local INPUT_FILES=$1
    local PARAMETERS=$2
    local FILE_ENCODING=""
    local FILE_EXTENSION=""
    local FILE_MIME=""
    local INPUT_FILE=""
    local INPUT_FILES_EXPAND=""
    local OUTPUT_FILES=""
    local PAR_ENCODING=""
    local PAR_EXTENSION=""
    local PAR_MAX_FILES=0
    local PAR_MIME=""
    local PAR_MIN_FILES=0
    local PAR_RETURN_PWD=""
    local PAR_SKIP_ENCODING=""
    local PAR_SKIP_EXTENSION=""
    local PAR_SKIP_MIME=""
    local VALID_FILES_COUNT=0

    # Valid values for the parameter key "type":
    #   "all": Filter files and directories.
    #   "file": Filter files (default).
    #   "directory": Filter directories.
    #   "file_recursive": Filter files recursively.

    # Read values from the parameters
    PAR_ENCODING=$(_get_parameter_value "$PARAMETERS" "encoding")
    PAR_EXTENSION=$(_get_parameter_value "$PARAMETERS" "extension")
    PAR_MAX_FILES=$(_get_parameter_value "$PARAMETERS" "max_files")
    PAR_MIME=$(_get_parameter_value "$PARAMETERS" "mime")
    PAR_MIN_FILES=$(_get_parameter_value "$PARAMETERS" "min_files")
    PAR_RETURN_PWD=$(_get_parameter_value "$PARAMETERS" "get_pwd_if_no_selection")
    PAR_SKIP_ENCODING=$(_get_parameter_value "$PARAMETERS" "skip_encoding")
    PAR_SKIP_EXTENSION=$(_get_parameter_value "$PARAMETERS" "skip_extension")
    PAR_SKIP_MIME=$(_get_parameter_value "$PARAMETERS" "skip_mime")
    PAR_TYPE=$(_get_parameter_value "$PARAMETERS" "type")

    # Check if there are input files
    if [[ -z "$INPUT_FILES" ]]; then
        # Return the current working directory if there are no
        # files selected (parameter 'get_pwd_if_no_selection=true').
        if [[ "$PAR_RETURN_PWD" == "true" ]]; then
            echo "$PWD"
            return 0
        fi
        _display_error_box "Error: there are no input files!"
        _exit_error
    fi

    # Default value for the parameter "type"
    if [[ -z "$PAR_TYPE" ]]; then
        PAR_TYPE="file"
    fi

    # Process the parameter "type":
    # expand files in directories recursively.
    case "$PAR_TYPE" in
    "all" | "file" | "directory")
        :
        ;;
    "all_recursive")
        for INPUT_FILE in $INPUT_FILES; do
            if [[ -n "$INPUT_FILES_EXPAND" ]]; then
                INPUT_FILES_EXPAND+=$_DEFAULT_IFS
            fi
            INPUT_FILES_EXPAND+=$(find -L "$INPUT_FILE" ! -path "*.git/*" 2>/dev/null)
        done
        INPUT_FILES=$INPUT_FILES_EXPAND
        ;;
    "file_recursive")
        for INPUT_FILE in $INPUT_FILES; do
            if [[ -n "$INPUT_FILES_EXPAND" ]]; then
                INPUT_FILES_EXPAND+=$_DEFAULT_IFS
            fi
            INPUT_FILES_EXPAND+=$(find -L "$INPUT_FILE" -type f ! -path "*.git/*" 2>/dev/null)
        done
        INPUT_FILES=$INPUT_FILES_EXPAND
        ;;
    *)
        _display_error_box "Error: invalid value for the parameter 'type' in the function '_get_files'."
        _exit_error
        ;;
    esac

    # Select only valid files
    for INPUT_FILE in $INPUT_FILES; do

        # Validation for files
        if [[ -f "$INPUT_FILE" ]]; then

            FILE_EXTENSION=$(_get_filename_extension "$INPUT_FILE")
            FILE_EXTENSION=${FILE_EXTENSION,,} # Lowercase file extension
            FILE_MIME=$(file --brief --mime-type "$INPUT_FILE")
            FILE_ENCODING=$(file --brief --mime-encoding "$INPUT_FILE")

            if [[ -n "$PAR_SKIP_EXTENSION" ]]; then
                _has_string_in_list "$FILE_EXTENSION" "$PAR_SKIP_EXTENSION" && continue
            fi

            if [[ -n "$PAR_SKIP_ENCODING" ]]; then
                _has_string_in_list "$FILE_ENCODING" "$PAR_SKIP_ENCODING" && continue
            fi

            if [[ -n "$PAR_SKIP_MIME" ]]; then
                _has_string_in_list "$FILE_MIME" "$PAR_SKIP_MIME" && continue
            fi

            if [[ -n "$PAR_EXTENSION" ]]; then
                _has_string_in_list "$FILE_EXTENSION" "$PAR_EXTENSION" || continue
            fi

            if [[ -n "$PAR_ENCODING" ]]; then
                _has_string_in_list "$FILE_ENCODING" "$PAR_ENCODING" || continue
            fi

            if [[ -n "$PAR_MIME" ]]; then
                _has_string_in_list "$FILE_MIME" "$PAR_MIME" || continue
            fi

            if [[ "$PAR_TYPE" == "directory" ]]; then
                continue
            fi

        # Validation for directories
        elif [[ -d "$INPUT_FILE" ]]; then

            if [[ "$PAR_TYPE" == "file" ]]; then
                continue
            fi
        fi

        # Add the valid file in the final list 'OUTPUT_FILES'
        VALID_FILES_COUNT=$((VALID_FILES_COUNT + 1))
        if [[ -n "$OUTPUT_FILES" ]]; then
            OUTPUT_FILES+=$_DEFAULT_IFS
        fi
        OUTPUT_FILES+=$INPUT_FILE
    done

    # Check if there is at last one valid file
    if ((VALID_FILES_COUNT == 0)); then
        _display_error_box "Error: there are no valid files in the selection!"
        _exit_error
    fi

    if [[ -n "$PAR_MIN_FILES" ]] && ((VALID_FILES_COUNT < PAR_MIN_FILES)); then
        _display_error_box "Error: there are $VALID_FILES_COUNT files in the selection, but the minimum is $PAR_MIN_FILES!"
        _exit_error
    fi

    if [[ -n "$PAR_MAX_FILES" ]] && ((VALID_FILES_COUNT > PAR_MAX_FILES)); then
        _display_error_box "Error: there are $VALID_FILES_COUNT files in the selection, but the maximum is $PAR_MAX_FILES!"
        _exit_error
    fi

    echo "$OUTPUT_FILES"
}

_get_output_dir() {
    local BASE_DIR=$PWD
    local OUTPUT_DIR=""

    # Check directories available to put the 'output' dir
    [[ ! -w "$BASE_DIR" ]] && BASE_DIR=$HOME
    [[ ! -w "$BASE_DIR" ]] && BASE_DIR="/tmp"
    OUTPUT_DIR="$BASE_DIR/$_PREFIX_OUTPUT_DIR"

    if [[ ! -w "$BASE_DIR" ]]; then
        _display_error_box "Error: could not find a directory with write permissions!"
        return 1
    fi

    # If the file already exists, add a suffix
    OUTPUT_DIR=$(_get_filename_suffix "$OUTPUT_DIR")

    mkdir --parents "$OUTPUT_DIR"
    echo "$OUTPUT_DIR"
}

_get_parameter_value() {
    local PARAMETERS=$1
    local PARAMETER_KEY=$2
    local PARAMETER_VALUE=""

    # Return if the 'PARAMETER_KEY' not found in the 'PARAMETERS'
    if [[ "$PARAMETERS" != *"$PARAMETER_KEY="* ]]; then
        return 1
    fi

    IFS="; "
    for PARAMETER in $PARAMETERS; do
        PARAMETER_VALUE=${PARAMETER##*=}
        if [[ "$PARAMETER_KEY" == "${PARAMETER%%=*}" ]]; then
            IFS=$_DEFAULT_IFS
            echo "$PARAMETER_VALUE"
            return 0
        fi
    done
    IFS=$_DEFAULT_IFS

    return 1
}

_get_script_name() {
    basename "$0"
}

_log_error() {
    local ERROR_MESSAGE=$1
    local INPUT_FILE=$2
    local STD_OUTPUT=$3
    local LOG_TEMP_FILE=""
    LOG_TEMP_FILE=$(mktemp --tmpdir="$_TEMP_DIR_LOG" --suffix="-error")

    {
        echo "[$(date "+%Y-%m-%d %H:%M:%S")] ERROR while processing the input file: $INPUT_FILE."
        echo -e "\tError message: $ERROR_MESSAGE"
        echo -e "\tStandard output: $STD_OUTPUT\n"
    } >"$LOG_TEMP_FILE"
}

_move_file() {
    local PARAMETERS=$1
    local FILE_SRC=$2
    local FILE_DST=$3
    local EXIT_CODE=0
    local PAR_WHEN_CONFLICT=""

    # Add the './' prefix in the path
    if ! [[ "$FILE_SRC" == "/"* ]] && ! [[ "$FILE_SRC" == "./"* ]] && ! [[ "$FILE_SRC" == "." ]]; then
        FILE_SRC="./$FILE_SRC"
    fi
    if ! [[ "$FILE_DST" == "/"* ]] && ! [[ "$FILE_DST" == "./"* ]] && ! [[ "$FILE_DST" == "." ]]; then
        FILE_DST="./$FILE_DST"
    fi

    # Ignore move to the same file
    if [[ "$FILE_SRC" == "$FILE_DST" ]]; then
        return 0
    fi

    # Read values from the parameters
    PAR_WHEN_CONFLICT=$(_get_parameter_value "$PARAMETERS" "when_conflict")

    # Process the parameter "when_conflict":
    # what to do when the 'FILE_DST' already exists
    case "$PAR_WHEN_CONFLICT" in
    "overwrite")
        :
        ;;
    "rename")
        # Rename the file (add a suffix)
        FILE_DST=$(_get_filename_suffix "$FILE_DST")
        ;;
    "skip")
        # Skip, do not move the file
        if [[ -e "$FILE_DST" ]]; then
            return 0
        fi
        ;;
    *)
        _display_error_box "Error: invalid value for the parameter 'conflict' in the function '_move_file'."
        _exit_error
        ;;
    esac

    # Move the file
    mv -f "$FILE_SRC" "$FILE_DST"
    EXIT_CODE=$?

    return "$EXIT_CODE"
}

_move_temp_file_to_output() {
    local INPUT_FILE=$1
    local TEMP_FILE=$2
    local OUTPUT_FILE=$3
    local STD_OUTPUT=""

    # Check if the result file is different from the input file, then replace it
    if ! cmp --silent "$INPUT_FILE" "$TEMP_FILE"; then

        # If 'INPUT_FILE' is same as 'OUTPUT_FILE', create a backup
        if [[ "$INPUT_FILE" == "$OUTPUT_FILE" ]]; then
            BACKUP_FILE="$INPUT_FILE.bak"

            # Create a backup of the original file
            STD_OUTPUT=$(_move_file "when_conflict=rename" "$INPUT_FILE" "$BACKUP_FILE" 2>&1)
            _check_result "$?" "$STD_OUTPUT" "$INPUT_FILE" "$BACKUP_FILE" || return 1
        fi

        # Move the 'TEMP_FILE' to 'OUTPUT_FILE'
        STD_OUTPUT=$(_move_file "when_conflict=rename" "$TEMP_FILE" "$OUTPUT_FILE" 2>&1)
        _check_result "$?" "$STD_OUTPUT" "$INPUT_FILE" "$OUTPUT_FILE" || return 1

        # Preserve the same permissions of 'INPUT_FILE'
        STD_OUTPUT=$(chmod --reference="$INPUT_FILE" "$OUTPUT_FILE" 2>&1)
        _check_result "$?" "$STD_OUTPUT" "$INPUT_FILE" "$OUTPUT_FILE" || return 1
    fi

    # Remove the temporary file
    rm -rf "$TEMP_FILE"
}

_run_main_task_parallel() {
    local INPUT_FILES=$1
    local OUTPUT_DIR=$2

    # Export variables and functions to use inside a new shell
    export _TEMP_DIR_LOG
    export TASK_DATA
    export TEMP_DIR_TASK
    export -f _check_result
    export -f _close_wait_box
    export -f _display_error_box
    export -f _exit_error
    export -f _get_filename_extension
    export -f _get_filename_suffix
    export -f _get_filename_without_extension
    export -f _log_error
    export -f _main_task
    export -f _move_file
    export -f _move_temp_file_to_output
    export -f _get_parameter_value

    # Run '_main_task' for each file in parallel using 'xargs'
    echo -n "$INPUT_FILES" | xargs \
        --delimiter="$_DEFAULT_IFS" \
        --max-procs="$(nproc --all --ignore=1)" \
        --replace="{}" \
        bash -c "_main_task \"{}\" \"$OUTPUT_DIR\""
}
