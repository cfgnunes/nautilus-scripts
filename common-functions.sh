#!/usr/bin/env bash
# shellcheck disable=SC2001

# This file contains common functions that the scripts will source.

set -u

# -----------------------------------------------------------------------------
# CONSTANT GLOBAL VARIABLES
# -----------------------------------------------------------------------------

FILENAME_SEPARATOR=$'\r'       # The field separator used in 'loop' commands to iterate over files.
IGNORE_FIND_PATH="*.git/*"     # Path to ignore in the 'find' command.
PREFIX_ERROR_LOG_FILE="Errors" # Name of 'error' directory.
PREFIX_OUTPUT_DIR="Output"     # Name of 'output' directory.
TEMP_DIR=$(mktemp --directory) # Temp directories for use in scripts.
TEMP_DIR_LOG=$(mktemp --directory --tmpdir="$TEMP_DIR")
TEMP_DIR_TASK=$(mktemp --directory --tmpdir="$TEMP_DIR")
TEMP_DIR_VALID_FILES=$(mktemp --directory --tmpdir="$TEMP_DIR")
TEMP_FIFO="$TEMP_DIR/fifo.txt" # Temporary FIFO to use in the "wait_box".

readonly \
    FILENAME_SEPARATOR \
    IGNORE_FIND_PATH \
    PREFIX_ERROR_LOG_FILE \
    PREFIX_OUTPUT_DIR \
    TEMP_DIR \
    TEMP_DIR_LOG \
    TEMP_DIR_TASK \
    TEMP_DIR_VALID_FILES \
    TEMP_FIFO

IFS=$FILENAME_SEPARATOR
INPUT_FILES=$*

# -----------------------------------------------------------------------------
# FUNCTIONS
# -----------------------------------------------------------------------------

_cleanup_on_exit() {
    rm -rf -- "$TEMP_DIR"
    _print_terminal "End of the script."
}
trap _cleanup_on_exit EXIT

_check_dependencies() {
    local dependencies=$*
    local command=""
    local message=""
    local package_name=""

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
            if _command_exists "apt-get"; then
                package_name=$(grep --only-matching "apt:[a-z-]*" <<<"$package_name" | sed "s|.*:||g")
            elif _command_exists "pacman"; then
                package_name=$(grep --only-matching "pacman:[a-z-]*" <<<"$package_name" | sed "s|.*:||g")
            elif _command_exists "dnf"; then
                package_name=$(grep --only-matching "dnf:[a-z-]*" <<<"$package_name" | sed "s|.*:||g")
            else
                _display_error_box "Could not find a package manager!"
                _exit_script
            fi
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

_check_result() {
    local exit_code=$1
    local std_output=$2
    local input_file=$3
    local output_file=$4

    # Check the 'exit_code' and log the error.
    if ((exit_code != 0)); then
        _write_log "Error: Non-zero exit code." "$input_file" "$std_output"
        return 1
    fi

    # Check if there is the word "Error" in stdout.
    if ! grep -q --ignore-case --perl-regexp "[^\w]error" <<<"$input_file"; then
        if grep -q --ignore-case --perl-regexp "[^\w]error" <<<"$std_output"; then
            _write_log "Error: Word 'error' found in the standard output." "$input_file" "$std_output"
            return 1
        fi
    fi

    # Check if the output file exists.
    if [[ -n "$output_file" ]] && ! [[ -e "$output_file" ]]; then
        _write_log "Error: The output file does not exist." "$input_file" "$std_output"
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
        zenity --title "$(_get_script_name)" --file-selection --multiple --directory \
            --separator="$FILENAME_SEPARATOR" 2>/dev/null
    elif _command_exists "kdialog"; then
        local input_files=""
        input_files=$(kdialog --title "$(_get_script_name)" --getexistingdirectory 2>/dev/null)
        input_files=${input_files% }
        input_files=${input_files// \//$FILENAME_SEPARATOR/}
        echo -n "$input_files"
    fi
}

_display_file_selection_box() {
    if _command_exists "zenity"; then
        zenity --title "$(_get_script_name)" --file-selection --multiple \
            --separator="$FILENAME_SEPARATOR" 2>/dev/null
    elif _command_exists "kdialog"; then
        local input_files=""
        input_files=$(kdialog --title "$(_get_script_name)" --getopenfilename --multiple 2>/dev/null)
        input_files=${input_files% }
        input_files=${input_files// \//$FILENAME_SEPARATOR/}
        echo -n "$input_files"
    fi
}

_display_error_box() {
    local message=$1

    if ! _is_gui_session; then
        echo >&2 "Error: $message"
    elif _command_exists "notify-send"; then
        notify-send -i error "$message" &>/dev/null
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
    elif _command_exists "notify-send"; then
        notify-send "$message" &>/dev/null
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
            --no-wrap --height=400 --width=750 <<<"$message" &>/dev/null
    elif _command_exists "kdialog"; then
        kdialog --title "$(_get_script_name)" --textinputbox "" "$message" &>/dev/null
    elif _command_exists "xmessage"; then
        xmessage -title "$(_get_script_name)" "$message" &>/dev/null
    fi
}

_display_result_box() {
    local output_dir=$1
    _close_wait_box

    local error_log_file=""
    error_log_file=$(_get_log_file "$output_dir")

    # Check if there was some error.
    if [[ -f "$error_log_file" ]]; then
        _display_error_box "Task finished with errors! See the '$error_log_file' for details."
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
            local output_dir_simple=""
            output_dir_simple=$(sed "s|$PWD/|./|g" <<<"$output_dir")
            output_dir_simple=$(sed "s|$HOME/|~/|g" <<<"$output_dir_simple")
            _display_info_box "Task finished! The output files are in '$output_dir_simple'."
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
    local message=$1

    if ! _is_gui_session; then
        echo "$message"
    elif _command_exists "zenity"; then
        rm -f -- "$TEMP_FIFO"
        mkfifo "$TEMP_FIFO"
        # shellcheck disable=SC2002
        cat -- "$TEMP_FIFO" | (
            zenity \
                --title="$(_get_script_name)" \
                --width=400 \
                --progress \
                --pulsate \
                --auto-close \
                --text="$message" ||
                (echo >"$TEMP_FIFO" && _exit_script)
        ) &
    fi
}

_close_wait_box() {
    # Close the zenity progress by FIFO.
    if [[ -p "$TEMP_FIFO" ]]; then
        echo >"$TEMP_FIFO"
    fi
}

_exit_script() {
    local child_pids=""
    local script_pid=$$

    # Get the process ID (PID) of the current script.
    child_pids=$(pstree -p "$script_pid" | grep --only-matching --perl-regexp "\(+\K[^)]+")

    _print_terminal "Aborting the script..."

    # Use xargs and kill to send the SIGTERM signal to all child processes,
    # including the current script.
    # See the: https://www.baeldung.com/linux/safely-exit-scripts
    xargs kill <<<"$child_pids" &>/dev/null
}

_expand_directory() {
    local input_directory=$1
    local par_type=$2
    local par_select_extension=$3
    local par_skip_extension=$4
    local selected_files=""
    local find_type_parameter=""

    # Expand the directories with 'find' command.
    case "$par_type" in
    "all") find_type_parameter="f,d" ;;
    "file") find_type_parameter="f" ;;
    "directory") find_type_parameter="d" ;;
    esac

    if [[ -n "$par_select_extension" ]]; then
        selected_files=$(find "$input_directory" \
            -type "$find_type_parameter" \
            -regextype posix-extended \
            -regex ".*($par_select_extension)$" \
            ! -path "$IGNORE_FIND_PATH" \
            -printf "%p$FILENAME_SEPARATOR" 2>/dev/null)
    elif [[ -n "$par_skip_extension" ]]; then
        selected_files=$(find "$input_directory" \
            -type "$find_type_parameter" \
            -regextype posix-extended \
            ! -regex ".*($par_skip_extension)$" \
            ! -path "$IGNORE_FIND_PATH" \
            -printf "%p$FILENAME_SEPARATOR" 2>/dev/null)
    else
        selected_files=$(find "$input_directory" \
            -type "$find_type_parameter" \
            ! -path "$IGNORE_FIND_PATH" \
            -printf "%p$FILENAME_SEPARATOR" 2>/dev/null)
    fi

    echo -n "$selected_files"
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
        _display_error_box "Could not run the installer as administrator!"
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

_get_distro_name() {
    cat /etc/*-release | grep --ignore-case "^id=" | cut -d "=" -f 2
}

_get_filename_extension() {
    local filename=$1
    grep --ignore-case --only-matching --perl-regexp "(\.tar)?\.[a-z0-9_~-]*$" <<<"$filename"
}

_get_filename_without_extension() {
    local filename=$1
    sed -r "s|(\.tar)?\.[a-z0-9_~-]*$||i" <<<"$filename"
}

_get_filename_suffix() {
    local filename=$1
    local filename_result=$filename
    local filename_base=""
    local filename_extension=""

    filename_base=$(_get_filename_without_extension "$filename")
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
    local filemanager_list=""
    set +u

    # Try to use the list of input files provided by the file manager.
    if [[ -n "$NAUTILUS_SCRIPT_SELECTED_URIS" ]]; then
        filemanager_list=$NAUTILUS_SCRIPT_SELECTED_URIS # Nautilus
    elif [[ -n "$NEMO_SCRIPT_SELECTED_URIS" ]]; then
        filemanager_list=$NEMO_SCRIPT_SELECTED_URIS # Nemo
    elif [[ -n "$CAJA_SCRIPT_SELECTED_URIS" ]]; then
        filemanager_list=$CAJA_SCRIPT_SELECTED_URIS # Caja
    else
        set -u
        echo -n "$INPUT_FILES" # Standard input
        return
    fi

    # Replace '\n' to 'FILENAME_SEPARATOR'.
    filemanager_list=$(sed -z "s|\n|$FILENAME_SEPARATOR|g" <<<"$filemanager_list")

    # Decode the URI list.
    filemanager_list=$(_uri_decode "$filemanager_list")
    filemanager_list=${filemanager_list//file:\/\//}

    set -u
    echo -n "$filemanager_list"
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
    local par_return_pwd="false"
    local par_select_encoding=""
    local par_select_extension=""
    local par_select_mime=""
    local par_skip_encoding=""
    local par_skip_extension=""
    local par_skip_mime=""
    local par_type="file"

    # Read values from the parameters.
    IFS=":, " read -r -a par_array <<<"$parameters"
    for i in "${!par_array[@]}"; do
        case "${par_array[i]}" in
        "max_files") par_max_files=${par_array[i + 1]} ;;
        "min_files") par_min_files=${par_array[i + 1]} ;;
        "recursive") par_recursive=${par_array[i + 1]} ;;
        "get_pwd_if_no_selection") par_return_pwd=${par_array[i + 1]} ;;
        "encoding") par_select_encoding=${par_array[i + 1]} ;;
        "extension") par_select_extension=${par_array[i + 1]} ;;
        "mime") par_select_mime=${par_array[i + 1]} ;;
        "skip_encoding") par_skip_encoding=${par_array[i + 1]} ;;
        "skip_extension") par_skip_extension=${par_array[i + 1]} ;;
        "skip_mime") par_skip_mime=${par_array[i + 1]} ;;
        "type") par_type=${par_array[i + 1]} ;;
        esac
    done

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
    if [[ $par_type != "file" ]] && [[ -n "$par_select_extension" ]]; then
        _display_error_box "To use the parameter 'extension' the value of 'type' must be 'file'!"
        _exit_script
    fi
    if [[ $par_type != "file" ]] && [[ -n "$par_skip_extension" ]]; then
        _display_error_box "To use the parameter 'skip_extension' the value of 'type' must be 'file'!"
        _exit_script
    fi

    # Check if there are input files.
    if [[ -z "$input_files" ]]; then
        # Return the current working directory if there are no
        # files selected (parameter 'get_pwd_if_no_selection=true').
        if [[ "$par_return_pwd" == "true" ]]; then
            echo -n "$PWD"
            return 0
        fi

        # Try selecting the files by opening a file selection box.
        if [[ "$par_type" == "file" ]] || [[ "$par_type" == "all" ]]; then
            input_files=$(_display_file_selection_box)
        else
            input_files=$(_display_dir_selection_box)
        fi
        if [[ -z "$input_files" ]]; then
            _display_error_box "There are no input files!"
            _exit_script
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
    _validate_files_count "$input_files" "$par_min_files" "$par_max_files"

    # Sort the list by filename.
    input_files=$(sed -z "s|\n|//|g" <<<"$input_files")
    input_files=$(sed "s|//$||" <<<"$input_files")
    input_files=$(sed -z "s|$FILENAME_SEPARATOR|\n|g" <<<"$input_files")
    input_files=$(sort --version-sort <<<"$input_files") # Sort the result.
    input_files=$(sed -z "s|\n|$FILENAME_SEPARATOR|g" <<<"$input_files")
    input_files=$(sed -z "s|//|\n|g" <<<"$input_files")

    # Removes the last field separator.
    input_files=${input_files%"$FILENAME_SEPARATOR"}

    echo -n "$input_files"
}

_get_full_path_dir() {
    local input_file=$1

    cd "$input_file" && pwd -P
}

_get_full_path_file() {
    local input_file=$1

    echo "$(cd "$(dirname -- "$input_file")" && pwd -P)/$(basename -- "$input_file")"
}

_get_log_file() {
    local output_dir=$1
    local error_log_file="$output_dir/$PREFIX_ERROR_LOG_FILE.log"

    if [[ -z "$output_dir" ]]; then
        error_log_file="$PWD/$PREFIX_ERROR_LOG_FILE.log"
    else
        error_log_file="$output_dir/$PREFIX_ERROR_LOG_FILE.log"
    fi

    # If the file already exists, add a suffix.
    error_log_file=$(_get_filename_suffix "$error_log_file")

    # Compile log errors in a single file.
    if ls -- "$TEMP_DIR_LOG/"* &>/dev/null; then
        cat -- "$TEMP_DIR_LOG/"* >"$error_log_file"
    fi

    echo "$error_log_file"
}

_get_max_procs() {
    # Return the maximum number of processing units available.
    nproc --all 2>/dev/null
}

_get_output_dir() {
    local parameters=$1
    local base_dir=$PWD
    local output_dir=""
    local par_use_same_dir=""

    # Read values from the parameters.
    IFS=":, " read -r -a par_array <<<"$parameters"
    for i in "${!par_array[@]}"; do
        case "${par_array[i]}" in
        "use_same_dir") par_use_same_dir=${par_array[i + 1]} ;;
        esac
    done

    # Check directories available to put the 'output' dir.
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
    output_dir=$(_get_filename_suffix "$output_dir")

    mkdir --parents "$output_dir"
    echo "$output_dir"
}

_get_output_file() {
    local input_file=$1
    local output_dir=$2
    local parameters=$3
    local output_file=""
    local filename=""
    local par_extension_option="new"
    local par_extension=""
    local par_prefix=""

    # Read values from the parameters.
    IFS=":, " read -r -a par_array <<<"$parameters"
    for i in "${!par_array[@]}"; do
        case "${par_array[i]}" in
        "extension_option") par_extension_option=${par_array[i + 1]} ;;
        "extension") par_extension=${par_array[i + 1]} ;;
        "prefix") par_prefix=$(_read_array_values "$i" "," "${par_array[@]}") ;;
        esac
    done

    filename=$(basename -- "$input_file")
    output_file="$output_dir/"

    # Change the extension of the 'output_file'.
    case "$par_extension_option" in
    "append")
        [[ -n "$par_prefix" ]] && output_file+="$par_prefix "
        output_file+="$filename"
        output_file+=".$par_extension"
        ;;
    "copy")
        [[ -n "$par_prefix" ]] && output_file+="$par_prefix "
        output_file+="$filename"
        ;;
    "new")
        [[ -n "$par_prefix" ]] && output_file+="$par_prefix "
        output_file+="$(_get_filename_without_extension "$filename")"
        output_file+=".$par_extension"
        ;;
    "strip")
        [[ -n "$par_prefix" ]] && output_file+="$par_prefix "
        output_file+="$(_get_filename_without_extension "$filename")"
        ;;
    esac

    # If the file already exists, add a suffix.
    output_file=$(_get_filename_suffix "$output_file")

    echo "$output_file"
}

_get_script_name() {
    basename -- "$0"
}

_move_file() {
    local par_when_conflict=$1
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
        file_dst=$(_get_filename_suffix "$file_dst")
        ;;
    "skip")
        # Skip, do not move the file.
        if [[ -e "$file_dst" ]]; then
            _write_log "Warning: The file already exists." "$file_src" "$file_dst"
            return 0
        fi
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

    # If the result file differs from the input file, then replace it.
    if ! cmp --silent -- "$input_file" "$temp_file"; then

        # If 'input_file' is the same as 'output_file', create a backup.
        if [[ "$input_file" == "$output_file" ]]; then
            backup_file="$input_file.bak"

            # Create a backup of the original file.
            std_output=$(_move_file "rename" "$input_file" "$backup_file" 2>&1)
            _check_result "$?" "$std_output" "$input_file" "$backup_file" || return 1
        fi

        # Move the 'temp_file' to 'output_file'.
        std_output=$(_move_file "rename" "$temp_file" "$output_file" 2>&1)
        _check_result "$?" "$std_output" "$input_file" "$output_file" || return 1

        # Preserve the same permissions of 'input_file'.
        std_output=$(chmod --reference="$input_file" -- "$output_file" 2>&1)
        _check_result "$?" "$std_output" "$input_file" "$output_file" || return 1
    fi

    # Remove the temporary file.
    rm -rf -- "$temp_file"
}

_print_terminal() {
    local message=$1

    if ! _is_gui_session; then
        echo "$message"
    fi
}

_read_array_values() {
    local start_index=$1
    local char_delimiter=$2
    local array=("$@")
    local n="${#array[@]}"
    local value=""

    # Read all values until the 'char_delimiter'
    for ((i = start_index + 3; i < n; i++)); do
        if [[ "${array[i]}" != "$char_delimiter" ]]; then
            value+="${array[i]} "
        fi
    done

    echo "${value% }"
}

_run_task_parallel() {
    local input_files=$1
    local output_dir=$2

    # Export variables and functions inside a new shell (using 'xargs').
    export \
        FILENAME_SEPARATOR \
        TASK_DATA \
        TEMP_DIR_LOG \
        TEMP_DIR_TASK
    export -f \
        _check_result \
        _close_wait_box \
        _display_error_box \
        _exit_script \
        _get_filename_extension \
        _get_filename_suffix \
        _get_filename_without_extension \
        _get_max_procs \
        _get_output_file \
        _main_task \
        _move_file \
        _move_temp_file_to_output \
        _read_array_values \
        _write_log

    # Allows the symbol "'" in filenames (inside 'xargs').
    input_files=$(sed -z "s|'|'\\\''|g" <<<"$input_files")

    # Execute the function '_main_task' for each file in parallel (using 'xargs').
    echo -n "$input_files" | xargs \
        --delimiter="$FILENAME_SEPARATOR" \
        --max-procs="$(_get_max_procs)" \
        --replace="{}" \
        bash -c "_main_task '{}' '$output_dir'"
}

_uri_decode() {
    local uri_encoded=$1

    uri_encoded=${uri_encoded//%/\\x}
    echo -e "$uri_encoded"
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
        file_encoding=$(file --brief --mime-encoding -- "$input_file")

        if [[ -n "$par_skip_encoding" ]]; then
            _has_string_in_list "$file_encoding" "$par_skip_encoding" && return 1
        elif [[ -n "$par_select_encoding" ]]; then
            _has_string_in_list "$file_encoding" "$par_select_encoding" || return 1
        fi
    fi

    # Validation for files (mime).
    if [[ -n "$par_skip_mime" ]] || [[ -n "$par_select_mime" ]]; then
        local file_mime=""
        file_mime=$(file --brief --mime-type -- "$input_file")

        if [[ -n "$par_skip_mime" ]]; then
            _has_string_in_list "$file_mime" "$par_skip_mime" && return 1
        elif [[ -n "$par_select_mime" ]]; then
            _has_string_in_list "$file_mime" "$par_select_mime" || return 1
        fi
    fi

    # Create a temp file containing the name of the valid file.
    local temp_file=""
    temp_file=$(mktemp --tmpdir="$TEMP_DIR_VALID_FILES")
    echo -n "$input_file$FILENAME_SEPARATOR" >"$temp_file"

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

    # Export variables and functions inside a new shell (using 'xargs').
    export \
        FILENAME_SEPARATOR \
        TEMP_DIR_VALID_FILES
    export -f \
        _get_filename_extension \
        _has_string_in_list \
        _validate_file_mime

    # Allows the symbol "'" in filenames (inside 'xargs').
    input_files=$(sed -z "s|'|'\\\''|g" <<<"$input_files")

    # Run '_validate_file_mime' for each file in parallel (using 'xargs').
    echo -n "$input_files" | xargs \
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
    output_files=$(cat -- "$TEMP_DIR_VALID_FILES/"*)
    rm -f -- "$TEMP_DIR_VALID_FILES/"*

    # Removes the last field separator.
    output_files=${output_files%"$FILENAME_SEPARATOR"}

    echo -n "$output_files"
}

_validate_file_preselect() {
    local input_file=$1
    local par_type=$2
    local par_skip_extension=$3
    local par_select_extension=$4
    local par_recursive=$5
    local input_file_valid=""

    if [[ -f "$input_file" ]]; then # If the 'input_file' is a regular file.
        _validate_file_extension "$input_file" "$par_skip_extension" "$par_select_extension" || return 1

        # Add the regular file in the 'input_file_valid'.
        if [[ "$par_type" == "file" ]] || [[ "$par_type" == "all" ]]; then
            input_file_valid=$(_get_full_path_file "$input_file")
            input_file_valid+=$FILENAME_SEPARATOR
        fi
    elif [[ -d "$input_file" ]]; then # If the 'input_file' is a directory.
        if [[ "$par_recursive" == "true" ]]; then
            # Add the expanded files (or directories) in the 'input_file_valid'.
            input_file_valid=$(_expand_directory \
                "$(_get_full_path_dir "$input_file")" \
                "$par_type" \
                "$par_select_extension" \
                "$par_skip_extension")
        else
            # Add the directory in the 'input_file_valid'.
            if [[ "$par_type" == "directory" ]] || [[ "$par_type" == "all" ]]; then
                input_file_valid=$(_get_full_path_dir "$input_file")
                input_file_valid+=$FILENAME_SEPARATOR
            fi
        fi
    fi

    if [[ -z "$input_file_valid" ]]; then
        return 1
    fi

    # Create a temp file containing the name of the valid file.
    local temp_file=""
    temp_file=$(mktemp --tmpdir="$TEMP_DIR_VALID_FILES")
    echo -n "$input_file_valid" >"$temp_file"

    return 0
}

_validate_file_preselect_parallel() {
    local input_files=$1
    local par_type=$2
    local par_skip_extension=$3
    local par_select_extension=$4
    local par_recursive=$5

    # Export variables and functions inside a new shell (using 'xargs').
    export \
        FILENAME_SEPARATOR \
        IGNORE_FIND_PATH \
        TEMP_DIR_VALID_FILES
    export -f \
        _expand_directory \
        _get_filename_extension \
        _get_full_path_dir \
        _get_full_path_file \
        _has_string_in_list \
        _validate_file_extension \
        _validate_file_preselect

    # Allows the symbol "'" in filenames (inside 'xargs').
    input_files=$(sed -z "s|'|'\\\''|g" <<<"$input_files")

    # Run '_validate_file_preselect' for each file in parallel (using 'xargs').
    echo -n "$input_files" | xargs \
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
    output_files=$(cat -- "$TEMP_DIR_VALID_FILES/"*)
    rm -f -- "$TEMP_DIR_VALID_FILES/"*

    # Removes the last field separator.
    output_files=${output_files%"$FILENAME_SEPARATOR"}

    echo -n "$output_files"
}

_validate_files_count() {
    local input_files=$1
    local par_min_files=$2
    local par_max_files=$3

    # Count the number of valid files.
    local valid_files_count=0
    valid_files_count=$(echo -n "$input_files" | tr -cd "$FILENAME_SEPARATOR" | wc -c)
    if [[ -n "$input_files" ]]; then
        valid_files_count=$((valid_files_count + 1))
    fi

    # Check if there is at least one valid file.
    if ((valid_files_count == 0)); then
        _display_error_box "There are no valid files in the selection!"
        _exit_script
    fi

    if [[ -n "$par_min_files" ]] && ((valid_files_count < par_min_files)); then
        _display_error_box "You must select at least $par_min_files valid files!"
        _exit_script
    fi

    if [[ -n "$par_max_files" ]] && ((valid_files_count > par_max_files)); then
        _display_error_box "You must select up to $par_max_files valid files!"
        _exit_script
    fi
}

_write_log() {
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
