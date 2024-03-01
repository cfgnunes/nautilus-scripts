#!/usr/bin/env bash
# shellcheck disable=SC2001

# This file contains common functions that the scripts will source.

set -u

# -----------------------------------------------------------------------------
# CONSTANTS
# -----------------------------------------------------------------------------

FILENAME_SEPARATOR=$'\r'       # The field separator used in 'loop' commands to iterate over files.
IGNORE_FIND_PATH="*.git/*"     # Path to ignore in the 'find' command.
PREFIX_ERROR_LOG_FILE="Errors" # Name of 'error' directory.
PREFIX_OUTPUT_DIR="Output"     # Name of 'output' directory.
TEMP_DIR=$(mktemp --directory) # Temp directories for use in scripts.
TEMP_DIR_LOG="$TEMP_DIR/logs"
TEMP_DIR_TASK="$TEMP_DIR/task"
TEMP_DIR_STORAGE_TEXT="$TEMP_DIR/storage_text"
WAIT_BOX_FIFO="$TEMP_DIR/wait_box_fifo"       # FIFO to use in the 'wait_box'.
WAIT_BOX_CONTROL="$TEMP_DIR/wait_box_control" # File control to use in the 'wait_box'.

readonly \
    FILENAME_SEPARATOR \
    IGNORE_FIND_PATH \
    PREFIX_ERROR_LOG_FILE \
    PREFIX_OUTPUT_DIR \
    TEMP_DIR \
    TEMP_DIR_LOG \
    TEMP_DIR_TASK \
    TEMP_DIR_STORAGE_TEXT \
    WAIT_BOX_CONTROL \
    WAIT_BOX_FIFO

# -----------------------------------------------------------------------------
# GLOBAL VARIABLES
# -----------------------------------------------------------------------------

IFS=$FILENAME_SEPARATOR
INPUT_FILES=$*
TEMP_DATA_TASK=""

# -----------------------------------------------------------------------------
# BUILD THE STRUCTURE OF THE 'TEMP_DIR'
# -----------------------------------------------------------------------------

mkdir -p "$TEMP_DIR_LOG"
mkdir -p "$TEMP_DIR_TASK"
mkdir -p "$TEMP_DIR_STORAGE_TEXT"

# -----------------------------------------------------------------------------
# FUNCTIONS
# -----------------------------------------------------------------------------

_cleanup_on_exit() {
    rm -rf -- "$TEMP_DIR"
    _print_terminal "End of the script."
}
trap _cleanup_on_exit EXIT

_check_dependencies() {
    local dependencies=$1
    local command=""
    local message=""
    local package_name=""
    local dependency=""
    local pkg_manager=""

    # Check for installed package manager.
    if _command_exists "apt-get"; then
        pkg_manager="apt"
    elif _command_exists "pacman"; then
        pkg_manager="pacman"
    elif _command_exists "dnf"; then
        pkg_manager="dnf"
    else
        _display_error_box "Could not find a package manager!"
        _exit_script
    fi

    # Add basic commands to check.
    dependencies="file xargs(findutils) pstree(psmisc) cmp(diffutils) mkfifo(coreutils) $dependencies"

    # Check all commands in the list 'dependencies'.
    IFS=" "
    for dependency in $dependencies; do
        # Item syntax: command(package), example: photorec(testdisk).
        command=${dependency%%(*}

        # Check if it has the command in the shell.
        if _command_exists "$command"; then
            continue
        fi

        package_name=$(grep --only-matching --perl-regexp "\(+\K[^)]+" <<<"$dependency")

        # Select the package according the package manager.
        if [[ -n "$package_name" ]] && [[ "$package_name" == *":"* ]]; then
            package_name=$(grep --only-matching "$pkg_manager:[a-z0-9-]*" <<<"$package_name" | sed "s|.*:||g")
        fi

        # Ask to the user to install the dependency.
        if [[ -n "$command" ]] && [[ -n "$package_name" ]]; then
            message="The command '$command' was not found (from package '$package_name'). Would you like to install it?"
        elif [[ -n "$command" ]]; then
            message="The command '$command' was not found. Would you like to install it?"
            package_name=$command
        else
            message="The package '$package_name' was not found. Would you like to install it?"
        fi

        # Ask the user to install the package.
        if _display_question_box "$message"; then
            _install_package "$package_name" "$command"
            continue
        fi

        _exit_script
    done
    IFS=$FILENAME_SEPARATOR
}

_check_output() {
    local exit_code=$1
    local std_output=$2
    local input_file=$3
    local output_file=$4

    # Check the 'exit_code' and log the error.
    if ((exit_code != 0)); then
        _log_write "Error: Non-zero exit code." "$input_file" "$std_output"
        return 1
    fi

    # Check if there is the word "Error" in stdout.
    if ! grep -q --ignore-case --perl-regexp "[^\w]error" <<<"$input_file"; then
        if grep -q --ignore-case --perl-regexp "[^\w]error" <<<"$std_output"; then
            _log_write "Error: Word 'error' found in the standard output." "$input_file" "$std_output"
            return 1
        fi
    fi

    # Check if the output file exists.
    if [[ -n "$output_file" ]] && ! [[ -e "$output_file" ]]; then
        _log_write "Error: The output file does not exist." "$input_file" "$std_output"
        return 1
    fi

    return 0
}

_command_exists() {
    local command_check=$1

    if command -v "$command_check" &>/dev/null; then
        return 0
    fi
    return 1
}

_display_dir_selection_box() {
    if _command_exists "zenity"; then
        zenity --title "$(_get_script_name)" --file-selection --multiple \
            --directory --separator="$FILENAME_SEPARATOR" 2>/dev/null || _exit_script
    elif _command_exists "kdialog"; then
        local input_files=""
        input_files=$(kdialog --title "$(_get_script_name)" \
            --getexistingdirectory 2>/dev/null) || _exit_script
        input_files=${input_files% }
        input_files=${input_files// \//$FILENAME_SEPARATOR/}
        echo -n "$input_files"
    fi
}

_display_file_selection_box() {
    if _command_exists "zenity"; then
        zenity --title "$(_get_script_name)" --file-selection --multiple \
            --separator="$FILENAME_SEPARATOR" 2>/dev/null || _exit_script
    elif _command_exists "kdialog"; then
        local input_files=""
        input_files=$(kdialog --title "$(_get_script_name)" \
            --getopenfilename --multiple 2>/dev/null) || _exit_script
        input_files=${input_files% }
        input_files=${input_files// \//$FILENAME_SEPARATOR/}
        echo -n "$input_files"
    fi
}

_display_error_box() {
    local message=$1

    if ! _is_gui_session; then
        echo >&2 "Error: $message"
    elif [[ -n "$DBUS_SESSION_BUS_ADDRESS" ]]; then
        _gdbus_notify "dialog-error" "$(_get_script_name)" "$message"
    elif _command_exists "zenity"; then
        zenity --title "$(_get_script_name)" --error --width=300 --text "$message" &>/dev/null
    elif _command_exists "kdialog"; then
        kdialog --title "$(_get_script_name)" --error "$message" &>/dev/null
    elif _command_exists "xmessage"; then
        xmessage -title "$(_get_script_name)" "Error: $message" &>/dev/null
    fi
}

_display_info_box() {
    local message=$1

    if ! _is_gui_session; then
        echo "Info: $message"
    elif [[ -n "$DBUS_SESSION_BUS_ADDRESS" ]]; then
        _gdbus_notify "dialog-information" "$(_get_script_name)" "$message"
    elif _command_exists "zenity"; then
        zenity --title "$(_get_script_name)" --info --width=300 --text "$message" &>/dev/null
    elif _command_exists "kdialog"; then
        kdialog --title "$(_get_script_name)" --msgbox "$message" &>/dev/null
    elif _command_exists "xmessage"; then
        xmessage -title "$(_get_script_name)" "Info: $message" &>/dev/null
    fi
}

_display_password_box() {
    local message="Type your password"
    local password=""

    # Ask the user for the 'password'.
    if ! _is_gui_session; then
        read -r -p "$message: " password >&2
    elif _command_exists "zenity"; then
        password=$(zenity --title="$(_get_script_name)" \
            --password 2>/dev/null) || _exit_script
    elif _command_exists "kdialog"; then
        password=$(kdialog --title "$(_get_script_name)" \
            --password "$message" 2>/dev/null) || _exit_script
    fi

    # Check if the 'password' is not empty.
    if [[ -z "$password" ]]; then
        _display_error_box "You must define a password!"
        _exit_script
    fi

    echo "$password"
}

_display_question_box() {
    local message=$1
    local response=""

    if ! _is_gui_session; then
        read -r -p "$message [Y/n] " response
        [[ ${response,,} == *"n"* ]] && return 1
    elif _command_exists "zenity"; then
        zenity --title "$(_get_script_name)" --question --width=300 --text="$message" &>/dev/null || return 1
    elif _command_exists "kdialog"; then
        kdialog --title "$(_get_script_name)" --yesno "$message" &>/dev/null || return 1
    elif _command_exists "xmessage"; then
        xmessage -title "$(_get_script_name)" -buttons "Yes:0,No:1" "$message" &>/dev/null || return 1
    fi
    return 0
}

_display_text_box() {
    local message=$1
    _close_wait_box

    if [[ -z "$message" ]]; then
        message="(Empty result)"
    fi

    if ! _is_gui_session; then
        echo "$message"
    elif _command_exists "zenity"; then
        zenity --title "$(_get_script_name)" --text-info \
            --no-wrap --height=400 --width=750 <<<"$message" &>/dev/null || _exit_script
    elif _command_exists "kdialog"; then
        kdialog --title "$(_get_script_name)" --textinputbox "" "$message" &>/dev/null || _exit_script
    elif _command_exists "xmessage"; then
        xmessage -title "$(_get_script_name)" "$message" &>/dev/null || _exit_script
    fi
}

_display_result_box() {
    local output_dir=$1
    _close_wait_box

    local error_log_file=""
    error_log_file=$(_log_compile "$output_dir")

    # Check if there was some error.
    if [[ -f "$error_log_file" ]]; then
        _display_error_box "Finished with errors! See the $(_str_human_readable_path "$error_log_file") for details."
        _exit_script
    fi

    # If 'output_dir' parameter is defined.
    if [[ -n "$output_dir" ]]; then
        # Try to remove the output directory (if it is empty).
        if [[ "$output_dir" == *"/$PREFIX_OUTPUT_DIR"* ]]; then
            rmdir "$output_dir" &>/dev/null
        fi

        # Check if the output directory still exists.
        if [[ -d "$output_dir" ]]; then
            _display_info_box "Finished! The output files are in the $(_str_human_readable_path "$output_dir") directory."
        else
            _display_info_box "Finished, but there are no output files!"
        fi
    else
        _display_info_box "Finished!"
    fi
}

_display_wait_box() {
    _display_wait_box_message "Running the task. Please, wait..."
}

_display_wait_box_message() {
    local message=$1

    if ! _is_gui_session; then
        echo "$message"
    elif _command_exists "zenity"; then
        if ! [[ -p "$WAIT_BOX_FIFO" ]]; then
            mkfifo "$WAIT_BOX_FIFO"
        fi

        # Tells the script that the 'wait_box' will open if the task takes more than 2 seconds.
        if ! [[ -f "$WAIT_BOX_CONTROL" ]]; then
            touch "$WAIT_BOX_CONTROL"
        fi

        # shellcheck disable=SC2002
        sleep 2 && [[ -f "$WAIT_BOX_CONTROL" ]] && cat "$WAIT_BOX_FIFO" | (
            zenity \
                --title="$(_get_script_name)" \
                --width=400 \
                --progress \
                --pulsate \
                --auto-close \
                --text="$message" || _exit_script
        ) &
    fi
}

_close_wait_box() {
    # If 'wait_box' is open (waiting an input in the 'fifo').
    if pgrep -fl "$WAIT_BOX_FIFO" &>/dev/null; then
        # Close the zenity progress by FIFO: Send a 'echo' for the 'cat' command.
        echo >"$WAIT_BOX_FIFO"
    fi

    # If 'wait_box' will open.
    if [[ -f "$WAIT_BOX_CONTROL" ]]; then
        rm -f -- "$WAIT_BOX_CONTROL" # Cancel the future open.
    fi
}

_exit_script() {
    local child_pids=""
    local script_pid=$$

    _print_terminal "Exiting the script..."

    # Get the process ID (PID) of all child processes.
    child_pids=$(pstree -p "$script_pid" | grep --only-matching --perl-regexp "\(+\K[^)]+")

    # NOTE: Use xargs and kill to send the SIGTERM signal to all child processes,
    # including the current script.
    # See the: https://www.baeldung.com/linux/safely-exit-scripts
    xargs kill <<<"$child_pids" &>/dev/null
}

_expand_directory() {
    local input_directory=$1
    local par_type=$2
    local par_select_extension=$3
    local par_skip_extension=$4
    local find_command=""

    # Build a 'find' command.
    find_command="find \"$input_directory\""

    # Expand the directories with 'find' command.
    case "$par_type" in
    "file") find_command+=" ! -type d" ;;
    "directory") find_command+=" -type d" ;;
    esac

    if [[ -n "$par_select_extension" ]]; then
        find_command+=" -regextype posix-extended "
        find_command+=" -regex \".*($par_select_extension)$\""
    elif [[ -n "$par_skip_extension" ]]; then
        find_command+=" -regextype posix-extended "
        find_command+=" ! -regex \".*($par_skip_extension)$\""
    fi

    find_command+=" ! -path \"$IGNORE_FIND_PATH\""
    # shellcheck disable=SC2089
    find_command+=" -printf \"%p$FILENAME_SEPARATOR\""

    # shellcheck disable=SC2086
    eval $find_command 2>/dev/null
}

_gdbus_notify() {
    local icon=$1
    local title=$2
    local body=$3
    local app_name=$title
    local method="Notify"
    local interface="org.freedesktop.Notifications"
    local object_path="/org/freedesktop/Notifications"

    # Use 'gdbus' to send the notification.
    gdbus call --session \
        --dest "$interface" \
        --object-path "$object_path" \
        --method "$interface.$method" \
        "$app_name" 0 "$icon" "$title" "$body" \
        "[]" '{"urgency": <1>}' 5000 &>/dev/null
}

_get_filename_extension() {
    local filename=$1

    grep --ignore-case --only-matching --perl-regexp "(\.tar)?\.[a-z0-9_~-]{0,15}$" <<<"$filename" || true
}

_get_filename_next_suffix() {
    local filename=$1
    local filename_result=$filename
    local filename_base=""
    local filename_extension=""

    filename_base=$(_strip_filename_extension "$filename")
    filename_extension=$(_get_filename_extension "$filename")

    # Avoid overwriting a file. If there is a file with the same name,
    # try to add a suffix, as 'file (1)', 'file (2)', ...
    local suffix=0
    while [[ -e "$filename_result" ]]; do
        suffix=$((suffix + 1))
        filename_result="$filename_base ($suffix)$filename_extension"
    done

    echo "$filename_result"
}

_get_filemanager_list() {
    local input_files=""
    local var_filemanager=""

    # Try to use the list of input files provided by the file manager.
    var_filemanager=$(printenv | grep --only-matching -m 1 ".*SCRIPT_SELECTED_URIS")

    if [[ -n "$var_filemanager" ]] && [[ -n "${!var_filemanager}" ]]; then
        input_files=${!var_filemanager}

        # Replace '\n' to 'FILENAME_SEPARATOR'.
        input_files=$(tr "\n" "$FILENAME_SEPARATOR" <<<"$input_files")

        # Decode the URI list.
        input_files=$(_text_uri_decode "$input_files")
        input_files=${input_files//file:\/\//}
    else
        input_files=$INPUT_FILES # Standard input
    fi

    # Removes last field separators.
    input_files=$(sed "s|$FILENAME_SEPARATOR*$||" <<<"$input_files")

    echo -n "$input_files"
}

_get_files() {
    local parameters=$1
    local input_files=""
    input_files=$(_get_filemanager_list)

    # Parameter: "type"
    # Values:
    #   "file": Filter files (default).
    #   "directory": Filter directories.
    #   "all": Filter files and directories.
    #
    # Parameter: "recursive"
    # Values:
    #   "false": Do not expand directories (default).
    #   "true": Expand directories.

    # Default values for the the parameters.
    local par_max_files=""
    local par_min_files=""
    local par_recursive="false"
    local par_get_pwd="false"
    local par_select_encoding=""
    local par_select_extension=""
    local par_select_mime=""
    local par_skip_encoding=""
    local par_skip_extension=""
    local par_skip_mime=""
    local par_type="file"
    local par_validate_conflict=""

    # Read values from the parameters.
    par_max_files=$(_get_parameter_value "$parameters" "max_files")
    par_min_files=$(_get_parameter_value "$parameters" "min_files")
    par_recursive=$(_get_parameter_value "$parameters" "recursive")
    par_get_pwd=$(_get_parameter_value "$parameters" "get_pwd_if_no_selection")
    par_select_encoding=$(_get_parameter_value "$parameters" "encoding")
    par_select_extension=$(_get_parameter_value "$parameters" "extension")
    par_select_mime=$(_get_parameter_value "$parameters" "mime")
    par_skip_encoding=$(_get_parameter_value "$parameters" "skip_encoding")
    par_skip_extension=$(_get_parameter_value "$parameters" "skip_extension")
    par_skip_mime=$(_get_parameter_value "$parameters" "skip_mime")
    par_type=$(_get_parameter_value "$parameters" "type")
    par_validate_conflict=$(_get_parameter_value "$parameters" "validate_conflict")

    # Check the parameters.
    if [[ -n "$par_skip_extension" ]] && [[ -n "$par_select_extension" ]]; then
        _display_error_box "Not possible to use 'skip_extension' and 'select_extension' together!"
        _exit_script
    fi
    if [[ -n "$par_skip_encoding" ]] && [[ -n "$par_select_encoding" ]]; then
        _display_error_box "Not possible to use 'skip_encoding' and 'select_encoding' together!"
        _exit_script
    fi
    if [[ -n "$par_skip_mime" ]] && [[ -n "$par_select_mime" ]]; then
        _display_error_box "Not possible to use 'skip_mime' and 'select_mime' together!"
        _exit_script
    fi

    # Check if there are input files.
    if [[ -z "$input_files" ]]; then
        if [[ "$par_get_pwd" == "true" ]]; then
            # Return the current working directory if there are no files selected.
            input_files=$(pwd)
        else
            # Try selecting the files by opening a file selection box.
            if [[ "$par_type" == "directory" ]]; then
                input_files=$(_display_dir_selection_box)
            else
                input_files=$(_display_file_selection_box)
            fi
            if [[ -z "$input_files" ]]; then
                _display_error_box "There are no input files!"
                _exit_script
            fi
        fi
    fi

    # Pre-select the input files. Also, expand it (if 'par_recursive' is true).
    input_files=$(_validate_file_preselect_parallel \
        "$input_files" \
        "$par_type" \
        "$par_skip_extension" \
        "$par_select_extension" \
        "$par_recursive")

    # Validates the mime or encoding of the file.
    input_files=$(_validate_file_mime_parallel \
        "$input_files" \
        "$par_select_encoding" \
        "$par_select_mime" \
        "$par_skip_encoding" \
        "$par_skip_mime")

    # Validates the number of valid files.
    _validate_files_count \
        "$input_files" \
        "$par_type" \
        "$par_select_extension" \
        "$par_select_mime" \
        "$par_skip_encoding" \
        "$par_min_files" \
        "$par_max_files"

    # Sort the list by filename.
    input_files=$(tr "\n" "\v" <<<"$input_files")
    input_files=$(sed "s|\v$||" <<<"$input_files")
    input_files=$(tr "$FILENAME_SEPARATOR" "\n" <<<"$input_files")
    input_files=$(_text_sort "$input_files")
    input_files=$(tr "\n" "$FILENAME_SEPARATOR" <<<"$input_files")
    input_files=$(tr "\v" "\n" <<<"$input_files")

    # Validates filenames with same base name.
    if [[ "$par_validate_conflict" == "true" ]]; then
        _validate_conflict_filenames "$input_files"
    fi

    # Removes last field separators.
    input_files=$(sed "s|$FILENAME_SEPARATOR*$||" <<<"$input_files")

    echo -n "$input_files"
}

_get_full_path_filename() {
    local input_filename=$1
    local full_path=""
    local dir=""

    dir=$(cd -- "$(dirname -- "$input_filename")" &>/dev/null && pwd -P)
    full_path=$dir/$(basename -- "$input_filename")

    echo -n "$full_path"
}

_get_max_procs() {
    # Return the maximum number of processing units available.
    nproc --all 2>/dev/null
}

_get_output_dir() {
    local parameters=$1
    local base_dir=""
    local output_dir=""
    local par_use_same_dir=""

    # Read values from the parameters.
    par_use_same_dir=$(_get_parameter_value "$parameters" "use_same_dir")

    # Check directories available to put the 'output' dir.
    base_dir=$(pwd)
    [[ ! -w "$base_dir" ]] && base_dir=$HOME
    [[ ! -w "$base_dir" ]] && base_dir="/tmp"
    if [[ ! -w "$base_dir" ]]; then
        _display_error_box "Could not find a directory with write permissions!"
        _exit_script
    fi

    if [[ "$par_use_same_dir" == "true" ]]; then
        echo "$base_dir"
        return
    fi

    output_dir="$base_dir/$PREFIX_OUTPUT_DIR"

    # If the file already exists, add a suffix.
    output_dir=$(_get_filename_next_suffix "$output_dir")

    mkdir --parents "$output_dir"
    echo "$output_dir"
}

_get_output_filename() {
    local input_file=$1
    local output_dir=$2
    local parameters=$3
    local output_file=""
    local filename=""
    local par_extension_opt="preserve"
    local par_extension=""
    local par_prefix=""
    local par_suffix=""

    # Read values from the parameters.
    par_extension_opt=$(_get_parameter_value "$parameters" "extension_opt")
    par_extension=$(_get_parameter_value "$parameters" "extension")
    par_prefix=$(_get_parameter_value "$parameters" "prefix")
    par_suffix=$(_get_parameter_value "$parameters" "suffix")

    # Directories does not have an extension.
    if [[ -d "$input_file" ]]; then
        par_extension_opt="append"
    fi

    filename=$(basename -- "$input_file")
    output_file="$output_dir/"
    [[ -n "$par_prefix" ]] && output_file+="$par_prefix "

    # Define the extension of the 'output_file'.
    case "$par_extension_opt" in
    "append")
        output_file+="$(_strip_filename_extension "$filename")"
        [[ -n "$par_suffix" ]] && output_file+=" $par_suffix"
        output_file+="$(_get_filename_extension "$filename")"
        output_file+=".$par_extension"
        ;;
    "preserve")
        output_file+="$(_strip_filename_extension "$filename")"
        [[ -n "$par_suffix" ]] && output_file+=" $par_suffix"
        output_file+="$(_get_filename_extension "$filename")"
        ;;
    "replace")
        output_file+="$(_strip_filename_extension "$filename")"
        [[ -n "$par_suffix" ]] && output_file+=" $par_suffix"
        output_file+=".$par_extension"
        ;;
    "strip")
        output_file+="$(_strip_filename_extension "$filename")"
        [[ -n "$par_suffix" ]] && output_file+=" $par_suffix"
        ;;
    esac

    # If the file already exists, add a suffix.
    output_file=$(_get_filename_next_suffix "$output_file")

    echo "$output_file"
}

_get_parameter_value() {
    local parameters=$1
    local key=$2
    local value=""

    if [[ -z "$key" ]]; then
        return
    fi

    # Separate parameters in 'key:value'.
    value="$(grep --only-matching --perl-regexp "([^,]*):([^,]*)" <<<"$parameters")"
    value=$(_str_trim_whitespace "$value")

    # Select the line of the specified key.
    value="$(grep "^$key:" <<<"$value")"

    # Get the value.
    value="$(sed "s|.*:\(.*\)|\1|" <<<"$value")"
    value=$(_str_trim_whitespace "$value")

    echo "$value"
}

_get_script_name() {
    basename -- "$0"
}

_has_string_in_list() {
    local string=$1
    local list=$2

    if grep -q --ignore-case --perl-regexp "($list)" <<<"$string"; then
        return 0
    fi

    return 1
}

_install_package() {
    local package_name=$1
    local command_check=$2

    _display_wait_box_message "Installing the package '$package_name'. Please, wait..."

    # Install the package.
    if _command_exists "pkexec"; then
        if _command_exists "apt-get"; then
            pkexec bash -c "apt-get update; apt-get -y install $package_name &>/dev/null"
        elif _command_exists "pacman"; then
            pkexec bash -c "pacman -Syy; pacman --noconfirm -S $package_name &>/dev/null"
        elif _command_exists "dnf"; then
            pkexec bash -c "dnf check-update; dnf -y install $package_name &>/dev/null"
        else
            _display_error_box "Could not find a package manager!"
            _exit_script
        fi
    else
        _display_error_box "Could not run the installer with administrator permission!"
        _exit_script
    fi

    _close_wait_box

    # Check if the package was installed.
    if [[ -n "$command_check" ]] && ! _command_exists "$command_check"; then
        _display_error_box "Could not install the package '$package_name'!"
        _exit_script
    fi

    _display_info_box "The package '$package_name' has been successfully installed!"
}

_is_gui_session() {
    if env | grep -q "^DISPLAY"; then
        return 0
    fi
    return 1
}

_log_compile() {
    local output_dir=$1
    local log_file_output="$output_dir/$PREFIX_ERROR_LOG_FILE.log"
    local log_files_count=""

    # Do nothing if there is no error log files.
    log_files_count="$(find "$TEMP_DIR_LOG" -type f | wc -l 2>/dev/null)"
    if ((log_files_count == 0)); then
        return 1
    fi

    if [[ -z "$output_dir" ]]; then
        output_dir=$(_get_output_dir "use_same_dir:true")
    fi
    log_file_output="$output_dir/$PREFIX_ERROR_LOG_FILE.log"

    # If the file already exists, add a suffix.
    log_file_output=$(_get_filename_next_suffix "$log_file_output")

    # Compile log errors in a single file.
    {
        echo "Script: '$(_get_script_name)'."
        echo "Total errors: $log_files_count."
        echo
        cat -- "$TEMP_DIR_LOG/"* 2>/dev/null
    } >"$log_file_output"

    echo "$log_file_output"
}

_log_write() {
    local message=$1
    local input_file=$2
    local std_output=$3
    local log_temp_file=""
    log_temp_file=$(mktemp --tmpdir="$TEMP_DIR_LOG")

    {
        echo "[$(date "+%Y-%m-%d %H:%M:%S")]"
        echo " > Input file: $input_file"
        echo " > $message"
        echo " > Output:"
        echo "$std_output"
        echo
    } >"$log_temp_file"
}

_move_file() {
    local par_when_conflict=${1:-"skip"}
    local file_src=$2
    local file_dst=$3
    local exit_code=0

    # Check for empty parameters.
    if [[ -z "$file_src" ]] || [[ -z "$file_dst" ]]; then
        return 1
    fi

    # Add the './' prefix in the path.
    if ! [[ "$file_src" == "/"* ]] && ! [[ "$file_src" == "./"* ]] && ! [[ "$file_src" == "." ]]; then
        file_src="./$file_src"
    fi
    if ! [[ "$file_dst" == "/"* ]] && ! [[ "$file_dst" == "./"* ]] && ! [[ "$file_dst" == "." ]]; then
        file_dst="./$file_dst"
    fi

    # Ignore moving to the same file.
    if [[ "$file_src" == "$file_dst" ]]; then
        return 0
    fi

    # Process the parameter "when_conflict": what to do when the 'file_dst' already exists.
    case "$par_when_conflict" in
    "overwrite") : ;;
    "rename")
        # Rename the file (add a suffix).
        file_dst=$(_get_filename_next_suffix "$file_dst")
        ;;
    "skip")
        # Skip, do not move the file.
        if [[ -e "$file_dst" ]]; then
            _log_write "Warning: The file already exists." "$file_src" "$file_dst"
            return 0
        fi
        ;;
    *)
        _display_error_box "Wrong parameter '$par_when_conflict' in '${FUNCNAME[1]}'!"
        _exit_script
        ;;
    esac

    # Move the file.
    mv -f -- "$file_src" "$file_dst"
    exit_code=$?

    return "$exit_code"
}

_move_temp_file_to_output() {
    local input_file=$1
    local temp_file=$2
    local output_file=$3
    local std_output=""

    # Skip empty files.
    if [[ ! -s "$temp_file" ]]; then
        return 1
    fi

    # Skip files if the content of 'temp_file' is equal to the 'input_file'.
    if cmp --silent -- "$temp_file" "$input_file"; then
        return 1
    fi

    # If 'input_file' euqual 'output_file', create a backup of the 'input_file'.
    if [[ "$input_file" == "$output_file" ]]; then
        std_output=$(_move_file "rename" "$input_file" "$input_file.bak" 2>&1)
        _check_output "$?" "$std_output" "$input_file" "$input_file.bak" || return 1
    fi

    # Move the 'temp_file' to 'output_file'.
    std_output=$(_move_file "rename" "$temp_file" "$output_file" 2>&1)
    _check_output "$?" "$std_output" "$input_file" "$output_file" || return 1

    # Preserve the same permissions of 'input_file'.
    std_output=$(chmod --reference="$input_file" -- "$output_file" 2>&1)
    _check_output "$?" "$std_output" "$input_file" "$output_file" || return 1

    return 0
}

_print_terminal() {
    local message=$1

    if ! _is_gui_session; then
        echo "$message"
    fi
}

_run_task_parallel() {
    local input_files=$1
    local output_dir=$2

    # Allows the symbol "'" in filenames (inside 'xargs').
    input_files=$(sed -z "s|'|'\\\''|g" <<<"$input_files")

    export -f _main_task

    # Execute the function '_main_task' for each file in parallel (using 'xargs').
    echo -n "$input_files" | sed "s|$FILENAME_SEPARATOR*$||" | xargs \
        --delimiter="$FILENAME_SEPARATOR" \
        --max-procs="$(_get_max_procs)" \
        --replace="{}" \
        bash -c "_main_task '{}' '$output_dir'"
}

_storage_text_clean() {
    rm -f -- "$TEMP_DIR_STORAGE_TEXT/"* &>/dev/null
}

_storage_text_read_all() {
    # Read all files.
    cat -- "$TEMP_DIR_STORAGE_TEXT/"* 2>/dev/null
}

_storage_text_write() {
    local input_text=$1
    local temp_file=""

    # Save the text to be compiled into a single file.
    temp_file=$(mktemp --tmpdir="$TEMP_DIR_STORAGE_TEXT")
    echo -n "$input_text" >"$temp_file"
}

_storage_text_write_ln() {
    local input_text=$1
    _storage_text_write "$input_text"$'\n'
}

_str_human_readable_path() {
    local input_path=$1
    local output_path=""

    output_path=$(_text_remove_pwd "$input_path")
    output_path=$(_text_remove_home "$output_path")
    output_path=$(sed "s|^\./||g" <<<"$output_path")

    if [[ "$output_path" == "." ]]; then
        output_path="same"
    elif [[ "$output_path" == "~" ]]; then
        output_path="home"
    elif [[ "$output_path" == "" ]]; then
        output_path="(none)"
    else
        output_path="'$output_path'"
    fi

    echo -n "$output_path"
}

_str_trim_whitespace() {
    local input_str=$1

    sed "s|^[ ]*||;s|[ ]*$||" <<<"$input_str"
}

_strip_filename_extension() {
    local filename=$1

    sed -r "s|(\.tar)?\.[a-z0-9_~-]{0,15}$||i" <<<"$filename"
}

_text_remove_empty_lines() {
    local input_text=$1

    grep -v "^$" <<<"$input_text" || true
}

_text_remove_home() {
    local input_text=$1

    if [[ -n "$HOME" ]]; then
        sed "s|$HOME|~|g" <<<"$input_text"
    else
        echo "$input_text"
    fi
}

_text_remove_pwd() {
    local input_text=$1
    local string_pwd=""
    string_pwd=$(pwd -P)

    sed "s|$string_pwd|.|g; s|\./\./|./|g" <<<"$input_text"
}

_text_sort() {
    local input_text=$1

    sort --version-sort <<<"$input_text"
}

_text_uri_decode() {
    local uri_encoded=$1

    uri_encoded=${uri_encoded//%/\\x}
    echo -e "$uri_encoded"
}

_validate_conflict_filenames() {
    local input_files=$1
    local dup_filenames="$input_files"

    dup_filenames=$(tr "\n" "\v" <<<"$dup_filenames")
    dup_filenames=$(tr "$FILENAME_SEPARATOR" "\n" <<<"$dup_filenames")
    dup_filenames=$(_strip_filename_extension "$dup_filenames")
    dup_filenames=$(uniq -d <<<"$dup_filenames")

    if [[ -n "$dup_filenames" ]]; then
        _display_error_box "There are selected files with the same base name!"
        _exit_script
    fi
}

_validate_file_extension() {
    local input_file=$1
    local par_skip_extension=$2
    local par_select_extension=$3

    # Return 0 if all parameters is empty.
    if [[ -z "$par_skip_extension" ]] && [[ -z "$par_select_extension" ]]; then
        return 0
    fi

    # Get the extension of the file.
    local file_extension=""
    file_extension=$(_get_filename_extension "$input_file")
    file_extension=${file_extension,,} # Lowercase the file extension.

    if [[ -n "$par_skip_extension" ]]; then
        _has_string_in_list "$file_extension" "$par_skip_extension" && return 1
    elif [[ -n "$par_select_extension" ]]; then
        _has_string_in_list "$file_extension" "$par_select_extension" || return 1
    fi

    return 0
}

_validate_file_mime() {
    local input_file=$1
    local par_select_encoding=$2
    local par_select_mime=$3
    local par_skip_encoding=$4
    local par_skip_mime=$5

    # Validation for files (encoding).
    if [[ -n "$par_skip_encoding" ]] || [[ -n "$par_select_encoding" ]]; then
        local file_encoding=""
        file_encoding=$(file --dereference --brief --mime-encoding -- "$input_file")

        if [[ -n "$par_skip_encoding" ]]; then
            _has_string_in_list "$file_encoding" "$par_skip_encoding" && return 1
        elif [[ -n "$par_select_encoding" ]]; then
            _has_string_in_list "$file_encoding" "$par_select_encoding" || return 1
        fi
    fi

    # Validation for files (mime).
    if [[ -n "$par_skip_mime" ]] || [[ -n "$par_select_mime" ]]; then
        local file_mime=""
        file_mime=$(file --dereference --brief --mime-type -- "$input_file")

        if [[ -n "$par_skip_mime" ]]; then
            _has_string_in_list "$file_mime" "$par_skip_mime" && return 1
        elif [[ -n "$par_select_mime" ]]; then
            _has_string_in_list "$file_mime" "$par_select_mime" || return 1
        fi
    fi

    # Create a temp file containing the name of the valid file.
    _storage_text_write "$input_file$FILENAME_SEPARATOR"

    return 0
}

_validate_file_mime_parallel() {
    local input_files=$1
    local par_select_encoding=$2
    local par_select_mime=$3
    local par_skip_encoding=$4
    local par_skip_mime=$5

    # Return the 'input_files' if all parameters is empty.
    if [[ -z "$par_select_encoding$par_select_mime$par_skip_encoding$par_skip_mime" ]]; then
        echo -n "$input_files"
        return
    fi

    # Allows the symbol "'" in filenames (inside 'xargs').
    input_files=$(sed -z "s|'|'\\\''|g" <<<"$input_files")

    # Run '_validate_file_mime' for each file in parallel (using 'xargs').
    echo -n "$input_files" | sed "s|$FILENAME_SEPARATOR*$||" | xargs \
        --delimiter="$FILENAME_SEPARATOR" \
        --max-procs="$(_get_max_procs)" \
        --replace="{}" \
        bash -c "_validate_file_mime '{}' \
            '$par_select_encoding' \
            '$par_select_mime' \
            '$par_skip_encoding' \
            '$par_skip_mime'"

    # Compile valid files in a single list 'output_files'.
    local output_files=""
    output_files=$(_storage_text_read_all)
    _storage_text_clean

    echo -n "$output_files"
}

_validate_file_preselect() {
    local input_file=$1
    local par_type=$2
    local par_skip_extension=$3
    local par_select_extension=$4
    local par_recursive=$5
    local input_file_valid=""

    if [[ ! -d "$input_file" ]]; then # If the 'input_file' is a file.
        _validate_file_extension "$input_file" "$par_skip_extension" "$par_select_extension" || return 1

        # Add the file in the 'input_file_valid'.
        if [[ "$par_type" == "file" ]] || [[ "$par_type" == "all" ]]; then
            input_file_valid=$(_get_full_path_filename "$input_file")
            input_file_valid+=$FILENAME_SEPARATOR
        fi
    else # If the 'input_file' is a directory.
        if [[ "$par_recursive" == "true" ]]; then
            # Add the expanded files (or directories) in the 'input_file_valid'.
            input_file_valid=$(_expand_directory \
                "$(_get_full_path_filename "$input_file")" \
                "$par_type" \
                "$par_select_extension" \
                "$par_skip_extension")
        else
            # Add the directory in the 'input_file_valid'.
            if [[ "$par_type" == "directory" ]] || [[ "$par_type" == "all" ]]; then
                input_file_valid=$(_get_full_path_filename "$input_file")
                input_file_valid+=$FILENAME_SEPARATOR
            fi
        fi
    fi

    if [[ -z "$input_file_valid" ]]; then
        return 1
    fi

    # Create a temp file containing the name of the valid file.
    _storage_text_write "$input_file_valid"

    return 0
}

_validate_file_preselect_parallel() {
    local input_files=$1
    local par_type=$2
    local par_skip_extension=$3
    local par_select_extension=$4
    local par_recursive=$5

    # Allows the symbol "'" in filenames (inside 'xargs').
    input_files=$(sed -z "s|'|'\\\''|g" <<<"$input_files")

    # Run '_validate_file_preselect' for each file in parallel (using 'xargs').
    echo -n "$input_files" | sed "s|$FILENAME_SEPARATOR*$||" | xargs \
        --delimiter="$FILENAME_SEPARATOR" \
        --max-procs="$(_get_max_procs)" \
        --replace="{}" \
        bash -c "_validate_file_preselect '{}' \
            '$par_type' \
            '$par_skip_extension' \
            '$par_select_extension' \
            '$par_recursive'"

    # Compile valid files in a single list 'output_files'.
    local output_files=""
    output_files=$(_storage_text_read_all)
    _storage_text_clean

    echo -n "$output_files"
}

_validate_files_count() {
    local input_files=$1
    local par_type=$2
    local par_select_extension=$3
    local par_select_mime=$4
    local par_skip_encoding=$5
    local par_min_files="${6:-1}"
    local par_max_files=$7

    # Define a term for a valid file.
    local valid_file_term="valid files"
    if [[ "$par_type" == "directory" ]]; then
        valid_file_term="directories"
    elif [[ "$par_select_mime" == *"audio"* ]]; then
        valid_file_term="audio files"
    elif [[ "$par_select_mime" == *"image"* ]]; then
        valid_file_term="image files"
    elif [[ "$par_select_mime" == *"video"* ]]; then
        valid_file_term="video files"
    elif [[ "$par_select_mime" == *"text"* ]]; then
        valid_file_term="plain text files"
    elif [[ "$par_select_mime" == *"pdf"* ]]; then
        valid_file_term="PDF files"
    elif [[ "$par_skip_encoding" == *"binary"* ]]; then
        valid_file_term="plain text files"
    fi

    # Count the number of valid files.
    local valid_files_count=0
    if [[ -n "$input_files" ]]; then
        valid_files_count=$(sed "s|$FILENAME_SEPARATOR*$||" <<<"$input_files")
        valid_files_count=$(echo -n "$valid_files_count" | tr -cd "$FILENAME_SEPARATOR" | wc -c)
        valid_files_count=$((valid_files_count + 1))
    fi

    # Check if there is at least one valid file.
    if ((valid_files_count == 0)) && ((par_min_files != 0)); then
        if [[ -n "$par_select_extension" ]]; then
            _display_error_box "You must select files with extension: '.${par_select_extension//|/\' or \'.}'!"
        else
            _display_error_box "You must select $valid_file_term!"
        fi
        _exit_script
    fi

    if [[ -n "$par_min_files" ]] && ((valid_files_count < par_min_files)); then
        _display_error_box "You must select at least $par_min_files $valid_file_term!"
        _exit_script
    fi

    if [[ -n "$par_max_files" ]] && ((valid_files_count > par_max_files)); then
        _display_error_box "You must select up to $par_max_files $valid_file_term!"
        _exit_script
    fi
}

# -----------------------------------------------------------------------------
# EXPORTS
# -----------------------------------------------------------------------------

# Export variables to be used inside new shells (when using 'xargs').
export \
    FILENAME_SEPARATOR \
    IGNORE_FIND_PATH \
    TEMP_DATA_TASK \
    TEMP_DIR_LOG \
    TEMP_DIR_STORAGE_TEXT \
    TEMP_DIR_TASK

# Export functions to be used inside new shells (when using 'xargs').
export -f \
    _check_output \
    _command_exists \
    _exit_script \
    _expand_directory \
    _get_filename_extension \
    _get_filename_next_suffix \
    _get_full_path_filename \
    _get_max_procs \
    _get_output_filename \
    _get_parameter_value \
    _has_string_in_list \
    _log_write \
    _move_file \
    _move_temp_file_to_output \
    _storage_text_write \
    _storage_text_write_ln \
    _str_trim_whitespace \
    _strip_filename_extension \
    _text_remove_pwd \
    _validate_file_extension \
    _validate_file_mime \
    _validate_file_preselect
