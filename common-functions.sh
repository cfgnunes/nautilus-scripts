#!/usr/bin/env bash

# This file contains common functions that the scripts will source.

# shellcheck disable=SC2001

set -u

# Use an 'Output' directory instead of the current directory for the output.
readonly USE_OUTPUT_DIR=true
readonly PREFIX_ERROR_LOG_FILE="Errors"
readonly PREFIX_OUTPUT_DIR="Output"

# Define the field separator used in 'for' commands to iterate over files.
readonly FILENAME_SEPARATOR=$'\r'
IFS=$FILENAME_SEPARATOR

# Create temp directories for use in scripts.
TEMP_DIR=$(mktemp --directory)
TEMP_DIR_LOG=$(mktemp --directory --tmpdir="$TEMP_DIR")
TEMP_DIR_TASK=$(mktemp --directory --tmpdir="$TEMP_DIR")
TEMP_DIR_VALID_FILES=$(mktemp --directory --tmpdir="$TEMP_DIR")

# A temporary FIFO to use in the "wait_box".
readonly TEMP_FIFO="$TEMP_DIR/fifo.txt"

# Remove the temp directory in an unexpected exit.
_cleanup() {
    rm -rf "$TEMP_DIR"
    _print_terminal "End of the script."
}
trap _cleanup EXIT

_command_exists() {
    local command_check="$1"

    if command -v "$command_check" &>/dev/null; then
        return 0
    fi
    return 1
}

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

        package_name=$(grep --only-matching -P "\(+\K[^)]+" <<<"$dependency")
        if [[ -n "$package_name" ]]; then
            message="The command '$command' was not found (from package '$package_name'). Would you like to install it?"
        else
            message="The command '$command' was not found. Would you like to install it?"
            package_name=$command
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
    if ! grep --quiet --ignore-case --perl-regexp "[^\w]error" <<<"$input_file"; then
        if grep --quiet --ignore-case --perl-regexp "[^\w]error" <<<"$std_output"; then
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

    if _is_terminal_session; then
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

    if _is_terminal_session; then
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
    if _is_terminal_session; then
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

    if _is_terminal_session; then
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

    if _is_terminal_session; then
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
    local error_log_file="$output_dir/$PREFIX_ERROR_LOG_FILE.log"
    _close_wait_box

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

    if _is_terminal_session; then
        echo "$message"
    elif _command_exists "zenity"; then
        rm -f "$TEMP_FIFO"
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
    child_pids=$(pstree -p "$script_pid" | grep --only-matching -P "\(+\K[^)]+")

    _print_terminal "Aborting the script..."

    # Use xargs and kill to send the SIGTERM signal to all child processes, including the current script.
    # See the: https://www.baeldung.com/linux/safely-exit-scripts
    xargs kill <<<"$child_pids" &>/dev/null
}

_has_string_in_list() {
    local string=$1
    local list=$2

    IFS=", "
    for item in $list; do
        if [[ "$string" == *"$item"* ]]; then
            IFS=$FILENAME_SEPARATOR
            return 0
        fi
    done
    IFS=$FILENAME_SEPARATOR

    return 1
}

_install_package() {
    local package_name=$1
    local command=$2

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
    if ! _command_exists "$command"; then
        _display_error_box "Could not install the package '$package_name'!"
        _exit_script
    fi

    _display_info_box "The package '$package_name' has been successfully installed!"
}

_is_terminal_session() {
    if env | grep --quiet "^TERM"; then
        return 0
    fi
    return 1
}

_get_distro_name() {
    cat /etc/*-release | grep -i "^id=" | cut -d "=" -f 2
}

_get_filename_extension() {
    local filename=$1
    grep --ignore-case --perl-regexp --only-matching "(\.tar)?\.[a-z0-9_~-]*$" <<<"$filename"
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

_get_files() {
    local input_files=$1
    local parameters=$2
    local input_file=""
    local output_files=""

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

    # Check if there are input files.
    if [[ -z "$input_files" ]]; then
        # Return the current working directory if there are no
        # files selected (parameter 'get_pwd_if_no_selection=true').
        local par_return_pwd=""
        par_return_pwd=$(_get_parameter_value "$parameters" "get_pwd_if_no_selection")
        if [[ "$par_return_pwd" == "true" ]]; then
            echo "$PWD"
            return 0
        fi

        # Try selecting the files by opening a file selection box.
        input_files=$(_display_file_selection_box)
        if [[ -z "$input_files" ]]; then
            _display_error_box "There are no input files!"
            _exit_script
        fi

        # TODO: Add a GUI box to add directories.
    fi

    # Read values from the parameters.
    local par_encoding=""
    local par_extension=""
    local par_max_files=""
    local par_mime=""
    local par_min_files=""
    local par_recursive=""
    local par_skip_encoding=""
    local par_skip_extension=""
    local par_skip_mime=""
    local par_type=""
    par_encoding=$(_get_parameter_value "$parameters" "encoding")
    par_extension=$(_get_parameter_value "$parameters" "extension")
    par_max_files=$(_get_parameter_value "$parameters" "max_files")
    par_mime=$(_get_parameter_value "$parameters" "mime")
    par_min_files=$(_get_parameter_value "$parameters" "min_files")
    par_recursive=$(_get_parameter_value "$parameters" "recursive")
    par_skip_encoding=$(_get_parameter_value "$parameters" "skip_encoding")
    par_skip_extension=$(_get_parameter_value "$parameters" "skip_extension")
    par_skip_mime=$(_get_parameter_value "$parameters" "skip_mime")
    par_type=$(_get_parameter_value "$parameters" "type")

    # Default value for the parameter "type".
    if [[ -z "$par_type" ]]; then
        par_type="file"
    fi

    # Iterate over all 'input_files'.
    local input_files_temp=""
    for input_file in $input_files; do

        if [[ -f "$input_file" ]]; then # If the 'input_file' is a regular file.

            # Get the full path of the regular file.
            local input_file_full=""
            input_file_full=$(cd "$(dirname "$input_file")" && pwd -P)/$(basename "$input_file")

            # Add the regular file in the 'input_files_temp'.
            if [[ "$par_type" == "file" ]] || [[ "$par_type" == "all" ]]; then
                input_files_temp+=$input_file_full
                input_files_temp+=$FILENAME_SEPARATOR
            fi

        elif [[ -d "$input_file" ]]; then # If the 'input_file' is a directory.

            # Get the full path of the directory.
            local input_directory_full=""
            input_directory_full=$(cd "$input_file" && pwd -P)

            if [[ "$par_recursive" == "true" ]]; then
                local find_type_parameter=""

                # Expand the directories with 'find' command.
                case "$par_type" in
                "all") find_type_parameter="f,d" ;;
                "file") find_type_parameter="f" ;;
                "directory") find_type_parameter="d" ;;
                esac

                # Add the expanded files (or directories) in the 'input_files_temp'.
                input_files_temp+=$(find "$input_directory_full" -type "$find_type_parameter" ! -path "*.git/*" -printf "%p$FILENAME_SEPARATOR" 2>/dev/null)

            else

                # Add the directory in the 'input_files_temp'.
                if [[ "$par_type" == "directory" ]] || [[ "$par_type" == "all" ]]; then
                    input_files_temp+=$input_directory_full
                    input_files_temp+=$FILENAME_SEPARATOR
                fi
            fi
        fi

    done
    input_files=$input_files_temp

    # Removes the last field separator.
    input_files=${input_files%"$FILENAME_SEPARATOR"}

    # Allows the symbol "'" in filenames.
    input_files=$(sed -z "s|'|'\\\''|g" <<<"$input_files")

    # Export variables and functions inside a new shell (using 'xargs').
    export -f _get_filename_extension
    export -f _get_parameter_value
    export -f _has_string_in_list
    export -f _validate_file
    export FILENAME_SEPARATOR
    export TEMP_DIR_VALID_FILES

    # Run '_validate_file' for each file in parallel (using 'xargs').
    echo -n "$input_files" | xargs \
        --delimiter="$FILENAME_SEPARATOR" \
        --max-procs="$(_get_max_procs)" \
        --replace="{}" \
        bash -c "_validate_file '{}' \
            '$par_encoding' \
            '$par_extension' \
            '$par_mime' \
            '$par_skip_encoding' \
            '$par_skip_extension' \
            '$par_skip_mime'"

    # Count the number of valid files.
    local valid_files_count=0
    valid_files_count=$(find "$TEMP_DIR_VALID_FILES/" -type f -printf "-\n" | wc -l)

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

    # Compile valid files in a single list 'output_files'.
    output_files=$(cat -- "$TEMP_DIR_VALID_FILES/"*)

    # Sort the list by filename.
    if ((valid_files_count > 1)); then
        output_files=$(sed -z "s|\n|//|g" <<<"$output_files")
        output_files=$(sed "s|//$||" <<<"$output_files")
        output_files=$(sed -z "s|$FILENAME_SEPARATOR|\n|g" <<<"$output_files")
        output_files=$(sort --version-sort <<<"$output_files") # Sort the result.
        output_files=$(sed -z "s|\n|$FILENAME_SEPARATOR|g" <<<"$output_files")
        output_files=$(sed -z "s|//|\n|g" <<<"$output_files")
    fi

    # Removes the last field separator.
    output_files=${output_files%"$FILENAME_SEPARATOR"}

    echo "$output_files"
}

_get_max_procs() {
    # Return the maximum number of proccessing units available (minus one).
    nproc --all --ignore=1 2>/dev/null
}

_get_output_dir() {
    local base_dir=$PWD
    local output_dir=""

    if ! $USE_OUTPUT_DIR; then
        echo "$base_dir"
        return
    fi

    # Check directories available to put the 'output' dir.
    [[ ! -w "$base_dir" ]] && base_dir=$HOME
    [[ ! -w "$base_dir" ]] && base_dir="/tmp"
    output_dir="$base_dir/$PREFIX_OUTPUT_DIR"

    if [[ ! -w "$base_dir" ]]; then
        _display_error_box "Could not find a directory with write permissions!"
        _exit_script
    fi

    # If the file already exists, add a suffix.
    output_dir=$(_get_filename_suffix "$output_dir")

    mkdir --parents "$output_dir"
    echo "$output_dir"
}

_get_output_file() {
    local input_file=$1
    local output_dir=$2
    local extension=$3
    local output_file=""
    local filename=""

    filename=$(basename -- "$input_file")
    output_file="$output_dir/"

    if [[ -z "$extension" ]]; then # Same extension.
        output_file+="$filename"
    elif [[ "$extension" == "." ]]; then # Remove extension.
        output_file+="$(_get_filename_without_extension "$filename")"
    else # Replace extension.
        output_file+="$(_get_filename_without_extension "$filename")"
        output_file+=".$extension"
    fi

    # If the file already exists, add a suffix.
    output_file=$(_get_filename_suffix "$output_file")

    echo "$output_file"
}

_get_parameter_value() {
    local parameters=$1
    local parameter_key=$2
    local parameter_value=""

    # Return if the 'parameter_key' is not found in the 'parameters'
    if [[ "$parameters" != *"$parameter_key="* ]]; then
        return 1
    fi

    IFS="; "
    for parameter in $parameters; do
        parameter_value=${parameter##*=}
        if [[ "$parameter_key" == "${parameter%%=*}" ]]; then
            IFS=$FILENAME_SEPARATOR
            echo "$parameter_value"
            return 0
        fi
    done
    IFS=$FILENAME_SEPARATOR

    return 1
}

_get_script_name() {
    basename -- "$0"
}

_move_file() {
    local parameters=$1
    local file_src=$2
    local file_dst=$3
    local exit_code=0
    local par_when_conflict=""

    # Check for empty parameters.
    if [[ -z "$file_src" ]]; then
        return 1
    fi
    if [[ -z "$file_dst" ]]; then
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

    # Read values from the parameters.
    par_when_conflict=$(_get_parameter_value "$parameters" "when_conflict")

    # Process the parameter "when_conflict": what to do when the 'file_dst' already exists.
    case "$par_when_conflict" in
    "overwrite")
        :
        ;;
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
    *)
        _display_error_box "Invalid value for the parameter 'conflict' in the function '_move_file'."
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

    # If the result file differs from the input file, then replace it.
    if ! cmp --silent -- "$input_file" "$temp_file"; then

        # If 'input_file' is the same as 'output_file', create a backup.
        if [[ "$input_file" == "$output_file" ]]; then
            backup_file="$input_file.bak"

            # Create a backup of the original file.
            std_output=$(_move_file "when_conflict=rename" "$input_file" "$backup_file" 2>&1)
            _check_result "$?" "$std_output" "$input_file" "$backup_file" || return 1
        fi

        # Move the 'temp_file' to 'output_file'.
        std_output=$(_move_file "when_conflict=rename" "$temp_file" "$output_file" 2>&1)
        _check_result "$?" "$std_output" "$input_file" "$output_file" || return 1

        # Preserve the same permissions of 'input_file'.
        std_output=$(chmod --reference="$input_file" -- "$output_file" 2>&1)
        _check_result "$?" "$std_output" "$input_file" "$output_file" || return 1
    fi

    # Remove the temporary file.
    rm -rf "$temp_file"
}

_print_terminal() {
    local message=$1

    if _is_terminal_session; then
        echo "$message"
    fi
}

_run_task_parallel() {
    local input_files=$1
    local output_dir=$2

    # Allows the symbol "'" in filenames.
    input_files=$(sed -z "s|'|'\\\''|g" <<<"$input_files")

    # Export variables and functions inside a new shell (using 'xargs').
    export FILENAME_SEPARATOR
    export TASK_DATA
    export TEMP_DIR_LOG
    export TEMP_DIR_TASK
    export -f _check_result
    export -f _close_wait_box
    export -f _display_error_box
    export -f _exit_script
    export -f _get_filename_extension
    export -f _get_filename_suffix
    export -f _get_filename_without_extension
    export -f _get_max_procs
    export -f _get_output_file
    export -f _get_parameter_value
    export -f _main_task
    export -f _move_file
    export -f _move_temp_file_to_output
    export -f _write_log

    # Execute the function '_main_task' for each file in parallel (using 'xargs').
    echo -n "$input_files" | xargs \
        --delimiter="$FILENAME_SEPARATOR" \
        --max-procs="$(_get_max_procs)" \
        --replace="{}" \
        bash -c "_main_task '{}' '$output_dir'"
}

_validate_file() {
    local input_file=$1
    local par_encoding=$2
    local par_extension=$3
    local par_mime=$4
    local par_skip_encoding=$5
    local par_skip_extension=$6
    local par_skip_mime=$7

    # Validation for files.
    if [[ -f "$input_file" ]]; then

        # Validation for files (extension).
        if [[ -n "$par_skip_extension" ]] || [[ -n "$par_extension" ]]; then
            local file_extension=""
            file_extension=$(_get_filename_extension "$input_file")
            file_extension=${file_extension,,} # Lowercase the file extension.

            if [[ -n "$par_skip_extension" ]]; then
                _has_string_in_list "$file_extension" "$par_skip_extension" && return 1
            fi

            if [[ -n "$par_extension" ]]; then
                _has_string_in_list "$file_extension" "$par_extension" || return 1
            fi
        fi

        # Validation for files (encoding).
        if [[ -n "$par_skip_encoding" ]] || [[ -n "$par_encoding" ]]; then
            local file_encoding=""
            file_encoding=$(file --brief --mime-encoding -- "$input_file")

            if [[ -n "$par_skip_encoding" ]]; then
                _has_string_in_list "$file_encoding" "$par_skip_encoding" && return 1
            fi

            if [[ -n "$par_encoding" ]]; then
                _has_string_in_list "$file_encoding" "$par_encoding" || return 1
            fi
        fi

        # Validation for files (mime).
        if [[ -n "$par_skip_mime" ]] || [[ -n "$par_mime" ]]; then
            local file_mime=""
            file_mime=$(file --brief --mime-type -- "$input_file")

            if [[ -n "$par_skip_mime" ]]; then
                _has_string_in_list "$file_mime" "$par_skip_mime" && return 1
            fi

            if [[ -n "$par_mime" ]]; then
                _has_string_in_list "$file_mime" "$par_mime" || return 1
            fi
        fi

    fi

    # Create a temp file containing the name of the valid file.
    local temp_file=""
    temp_file=$(mktemp --tmpdir="$TEMP_DIR_VALID_FILES")
    echo -n "$input_file$FILENAME_SEPARATOR" >"$temp_file"

    return 0
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
