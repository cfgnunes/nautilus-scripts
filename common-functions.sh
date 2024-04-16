#!/usr/bin/env bash
# shellcheck disable=SC2001

# This file contains common functions that the scripts will source.

set -u

# -----------------------------------------------------------------------------
# CONSTANTS
# -----------------------------------------------------------------------------

FIELD_SEPARATOR=$'\r'          # The main field separator. Used, for example, in 'loops' to iterate over files.
IGNORE_FIND_PATH="*.git/*"     # Path to ignore in the 'find' command.
PREFIX_ERROR_LOG_FILE="Errors" # Name of 'error' directory.
PREFIX_OUTPUT_DIR="Output"     # Name of 'output' directory.
TEMP_DIR=$(mktemp --directory) # Temp directories for use in scripts.
TEMP_DIR_ITEMS_TO_REMOVE="$TEMP_DIR/items_to_remove"
TEMP_DIR_LOGS="$TEMP_DIR/logs"
TEMP_DIR_STORAGE_TEXT="$TEMP_DIR/storage_text"
TEMP_DIR_TASK="$TEMP_DIR/task"
WAIT_BOX_CONTROL="$TEMP_DIR/wait_box_control"         # File control to use in the 'wait_box'.
WAIT_BOX_CONTROL_KDE="$TEMP_DIR/wait_box_control_kde" # File control to use in the KDialog 'wait_box'.
WAIT_BOX_FIFO="$TEMP_DIR/wait_box_fifo"               # FIFO to use in the Zenity 'wait_box'.

readonly \
    FIELD_SEPARATOR \
    IGNORE_FIND_PATH \
    PREFIX_ERROR_LOG_FILE \
    PREFIX_OUTPUT_DIR \
    TEMP_DIR \
    TEMP_DIR_LOGS \
    TEMP_DIR_STORAGE_TEXT \
    TEMP_DIR_TASK \
    WAIT_BOX_CONTROL \
    WAIT_BOX_CONTROL_KDE \
    WAIT_BOX_FIFO

# -----------------------------------------------------------------------------
# GLOBAL VARIABLES
# -----------------------------------------------------------------------------

IFS=$FIELD_SEPARATOR
INPUT_FILES=$*
TEMP_DATA_TASK=""

# -----------------------------------------------------------------------------
# BUILD THE STRUCTURE OF THE 'TEMP_DIR'
# -----------------------------------------------------------------------------

mkdir -p "$TEMP_DIR_ITEMS_TO_REMOVE" # Used to store the path of temporary files or directories to be removed after exit.
mkdir -p "$TEMP_DIR_LOGS"            # Used to store 'error logs'.
mkdir -p "$TEMP_DIR_STORAGE_TEXT"    # Used to store the output text from parallel processes.
mkdir -p "$TEMP_DIR_TASK"            # Used in scripts to store its temporary files.

# -----------------------------------------------------------------------------
# FUNCTIONS
# -----------------------------------------------------------------------------

_cleanup_on_exit() {
    # Remove local temporary dirs or files.
    local items_to_remove=""
    items_to_remove=$(cat -- "$TEMP_DIR_ITEMS_TO_REMOVE/"* 2>/dev/null)

    # Allows the symbol "'" in filenames (inside 'xargs').
    items_to_remove=$(sed -z "s|'|'\\\''|g" <<<"$items_to_remove")

    printf "%s" "$items_to_remove" | xargs \
        --no-run-if-empty \
        --delimiter="$FIELD_SEPARATOR" \
        --max-procs="$(_get_max_procs)" \
        --replace="{}" \
        bash -c "{ chmod -R u+rw -- '{}' && rm -rf -- '{}'; } &>/dev/null"

    # Remove the main temporary dir.
    rm -rf -- "$TEMP_DIR" &>/dev/null
    _print_terminal "End of the script."
}
trap _cleanup_on_exit EXIT

_check_dependencies() {
    local dependencies=$1
    local packages_to_install=""
    local pkg_manager_installed=""

    [[ -z "$dependencies" ]] && return

    # Skip duplicated dependencies in the input list.
    dependencies=$(tr "|" "\n" <<<"$dependencies")
    dependencies=$(tr -d " " <<<"$dependencies")
    dependencies=$(sort -u <<<"$dependencies")
    dependencies=$(_text_remove_empty_lines "$dependencies")

    [[ -z "$dependencies" ]] && return

    # Get the name of the installed package manager.
    pkg_manager_installed=$(_pkg_get_package_manager)
    if [[ -z "$pkg_manager_installed" ]]; then
        _display_error_box "Could not find a package manager!"
        _exit_script
    fi

    # Check all dependencies.
    dependencies=$(tr "\n" "$FIELD_SEPARATOR" <<<"$dependencies")
    local dependency=""
    for dependency in $dependencies; do
        local command=""
        local package=""
        local pkg_manager=""
        # Evaluate the values from the 'dependency' variable.
        eval "$dependency"

        # Ignore installing the dependency if there is a command in the shell.
        if [[ -n "$command" ]] && _command_exists "$command"; then
            continue
        fi

        # Ignore installing the dependency if the installed package managers differ.
        if [[ -n "$pkg_manager" ]] && [[ "$pkg_manager_installed" != "$pkg_manager" ]]; then
            continue
        fi

        # Ignore installing the dependency if the package is already installed
        # (packages that do not have a command).
        if [[ -n "$package" ]] && [[ -z "$command" ]] && _pkg_is_package_installed "$pkg_manager_installed" "$package"; then
            continue
        fi

        # If the package is not specified, use the command name as the package name.
        if [[ -z "$package" ]] && [[ -n "$command" ]]; then
            package=$command
        fi

        # Add the package to the list to install.
        if [[ -n "$package" ]]; then
            packages_to_install+=" $package"
        fi
    done

    # Ask the user to install the packages.
    if [[ -n "$packages_to_install" ]]; then
        local message="These packages were not found:"
        message+=$(sed "s| |\n- |g" <<<"$packages_to_install")
        message+=$'\n'$'\n'
        message+="Would you like to install them?"
        if _display_question_box "$message"; then
            _pkg_install_packages "$pkg_manager_installed" "${packages_to_install/ /}"
        else
            _exit_script
        fi
    fi
}

_check_output() {
    local exit_code=$1
    local std_output=$2
    local input_file=$3
    local output_file=$4

    # Check the 'exit_code' and log the error.
    if ((exit_code != 0)); then
        _log_write "Error: Non-zero exit code." "$input_file" "$std_output" "$output_file"
        return 1
    fi

    # Check if the output file exists.
    if [[ -n "$output_file" ]] && ! [[ -e "$output_file" ]]; then
        _log_write "Error: The output file does not exist." "$input_file" "$std_output" "$output_file"
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

_convert_filenames_to_text() {
    local input_files=$1
    local new_line="'\$'\\\n''"

    input_files=$(sed -z "s|\n|$new_line|g; s|$new_line$||g" <<<"$input_files")
    input_files=$(tr "$FIELD_SEPARATOR" "\n" <<<"$input_files")

    printf "%s" "$input_files"
}

_convert_text_to_filenames() {
    local input_files=$1
    local new_line="'\$'\\\n''"

    input_files=$(tr "\n" "$FIELD_SEPARATOR" <<<"$input_files")
    input_files=$(sed -z "s|$new_line|\n|g" <<<"$input_files")

    input_files=$(_str_remove_empty_tokens "$input_files")
    printf "%s" "$input_files"
}

_display_dir_selection_box() {
    local input_files=""

    if _command_exists "zenity"; then
        input_files=$(zenity --title "$(_get_script_name)" --file-selection --multiple \
            --directory --separator="$FIELD_SEPARATOR" 2>/dev/null) || _exit_script
    elif _command_exists "kdialog"; then
        input_files=$(kdialog --title "$(_get_script_name)" \
            --getexistingdirectory 2>/dev/null) || _exit_script
        # Use parameter expansion to remove the last space.
        input_files=${input_files% }
        input_files=${input_files// \//$FIELD_SEPARATOR/}
    fi

    input_files=$(_str_remove_empty_tokens "$input_files")
    printf "%s" "$input_files"
}

_display_file_selection_box() {
    local input_files=""

    if _command_exists "zenity"; then
        input_files=$(zenity --title "$(_get_script_name)" --file-selection --multiple \
            --separator="$FIELD_SEPARATOR" 2>/dev/null) || _exit_script
    elif _command_exists "kdialog"; then
        input_files=$(kdialog --title "$(_get_script_name)" \
            --getopenfilename --multiple 2>/dev/null) || _exit_script
        # Use parameter expansion to remove the last space.
        input_files=${input_files% }
        input_files=${input_files// \//$FIELD_SEPARATOR/}
    fi

    input_files=$(_str_remove_empty_tokens "$input_files")
    printf "%s" "$input_files"
}

_display_error_box() {
    local message=$1

    if ! _is_gui_session; then
        printf "Error: %s\n" "$message"
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
        printf "Info: %s\n" "$message"
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

_display_list_box() {
    local message=$1
    local columns=$2
    local columns_count=0
    local items_count=0
    local selected_item=""
    local message_select=""
    _close_wait_box

    if [[ -n "$message" ]]; then
        items_count=$(tr -cd "\n" <<<"$message" | wc -c)
        message_select=" Select an item to open its location:"
    else
        # NOTE: Some versions of Zenity crash if the
        # message is empty (Segmentation fault).
        message=" "
    fi

    # Count the number of columns.
    columns_count=$(grep --only-matching "column=" <<<"$columns" | wc -l)

    if ! _is_gui_session; then
        message=$(tr "$FIELD_SEPARATOR" " " <<<"$message")
        printf "%s\n" "$message"
    elif _command_exists "zenity"; then
        columns=$(tr ";" "$FIELD_SEPARATOR" <<<"$columns")
        message=$(tr "\n" "$FIELD_SEPARATOR" <<<"$message")
        # shellcheck disable=SC2086
        selected_item=$(zenity --title "$(_get_script_name)" --list \
            --editable --multiple --separator="$FIELD_SEPARATOR" \
            --width=800 --height=450 --print-column "$columns_count" \
            --text "Total of $items_count items.$message_select" \
            $columns $message 2>/dev/null) || _exit_script

        if ((items_count != 0)) && [[ -n "$selected_item" ]]; then
            # Open the directory of the clicked item in the list.
            _open_items_locations "$selected_item"
        fi
    elif _command_exists "kdialog"; then
        columns=$(sed "s|--column=||g" <<<"$columns")
        columns=$(tr ";" "\t" <<<"$columns")
        message=$(tr "$FIELD_SEPARATOR" "\t" <<<"$message")
        message="$columns"$'\n'$'\n'"$message"
        kdialog --title "$(_get_script_name)" --geometry "800x450" \
            --textinputbox "" "$message" &>/dev/null || _exit_script
    elif _command_exists "xmessage"; then
        columns=$(sed "s|--column=||g" <<<"$columns")
        columns=$(tr ";" "\t" <<<"$columns")
        message=$(tr "$FIELD_SEPARATOR" "\t" <<<"$message")
        message="$columns"$'\n'$'\n'"$message"
        xmessage -title "$(_get_script_name)" "$message" &>/dev/null || _exit_script
    fi
}

_display_password_box() {
    local message="$1"
    local password=""

    # Ask the user for the 'password'.
    if ! _is_gui_session; then
        read -r -p "$message " password >&2
    elif _command_exists "zenity"; then
        sleep 0.1 # Avoid 'wait_box' open before.
        password=$(zenity --title="Password" --entry --hide-text \
            --width=400 --text "$message" 2>/dev/null) || return 1
    elif _command_exists "kdialog"; then
        sleep 0.1 # Avoid 'wait_box' open before.
        password=$(kdialog --title "Password" \
            --password "$message" 2>/dev/null) || return 1
    fi

    printf "%s" "$password"
}

_display_password_box_define() {
    local message="Type your password:"
    local password=""

    password=$(_display_password_box "$message") || return 1

    # Check if the 'password' is not empty.
    if [[ -z "$password" ]]; then
        _display_error_box "The password can not be empty!"
        return 1
    fi

    printf "%s" "$password"
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
        printf "%s\n" "$message"
    elif _command_exists "zenity"; then
        zenity --title "$(_get_script_name)" --text-info \
            --no-wrap --width=800 --height=450 <<<"$message" &>/dev/null || _exit_script
    elif _command_exists "kdialog"; then
        kdialog --title "$(_get_script_name)" --geometry "800x450" \
            --textinputbox "" "$message" &>/dev/null || _exit_script
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
            _display_info_box "Finished, but there is nothing to do."
        fi
    else
        _display_info_box "Finished!"
    fi
}

_display_wait_box() {
    local open_delay=${1:-"2"}
    local message="Running the task. Please, wait..."

    _display_wait_box_message "$message" "$open_delay"
}

_display_wait_box_message() {
    local message=$1
    local open_delay=${2:-"2"}

    if ! _is_gui_session; then
        printf "%s\n" "$message"
    elif _command_exists "zenity"; then
        # Flag to inform that the 'wait_box' will open (if the task takes over 2 seconds).
        touch "$WAIT_BOX_CONTROL"

        # Create the FIFO to use in Zenity 'wait_box'.
        if ! [[ -p "$WAIT_BOX_FIFO" ]]; then
            mkfifo "$WAIT_BOX_FIFO"
        fi

        # Thread to open the Zenity 'wait_box'.
        # shellcheck disable=SC2002
        sleep "$open_delay" && [[ -f "$WAIT_BOX_CONTROL" ]] && cat "$WAIT_BOX_FIFO" | (
            zenity --title="$(_get_script_name)" --progress \
                --width=400 --pulsate --auto-close --text="$message" || _exit_script
        ) &
    elif _command_exists "kdialog"; then
        # Flag to inform that the 'wait_box' will open (if the task takes over 2 seconds).
        touch "$WAIT_BOX_CONTROL"

        # Thread to open the KDialog 'wait_box'.
        sleep "$open_delay" && [[ -f "$WAIT_BOX_CONTROL" ]] && kdialog \
            --title="$(_get_script_name)" --progressbar "$message" 0 >"$WAIT_BOX_CONTROL_KDE" &

        # Thread to check if the KDialog 'wait_box' was closed.
        (
            while [[ -f "$WAIT_BOX_CONTROL" ]] || [[ -f "$WAIT_BOX_CONTROL_KDE" ]]; do
                if [[ -f "$WAIT_BOX_CONTROL_KDE" ]]; then
                    local dbus_ref=""
                    dbus_ref=$(cut -d " " -f 1 <"$WAIT_BOX_CONTROL_KDE")
                    if [[ -n "$dbus_ref" ]]; then
                        qdbus "$dbus_ref" "/ProgressDialog" "wasCancelled" 2>/dev/null || _exit_script
                    fi
                fi
                sleep 1
            done
        ) &
    fi
}

_close_wait_box() {
    # Check if 'wait_box' will open.
    if [[ -f "$WAIT_BOX_CONTROL" ]]; then
        rm -f -- "$WAIT_BOX_CONTROL" # Cancel the future open.
    fi

    # Check if Zenity 'wait_box' is open (waiting for an input in the FIFO).
    if pgrep -fl "$WAIT_BOX_FIFO" &>/dev/null; then
        # Close the Zenity using the FIFO: Send a '\n' for the 'cat'.
        printf "\n" >"$WAIT_BOX_FIFO"
    fi

    # Check if KDialog 'wait_box' is open.
    while [[ -f "$WAIT_BOX_CONTROL_KDE" ]]; do
        local dbus_ref=""
        dbus_ref=$(cut -d " " -f 1 <"$WAIT_BOX_CONTROL_KDE")
        if [[ -n "$dbus_ref" ]]; then
            qdbus "$dbus_ref" "/ProgressDialog" "close" 2>/dev/null
            rm -f -- "$WAIT_BOX_CONTROL_KDE"
        fi
    done
}

_exit_script() {
    local child_pids=""
    local script_pid=$$

    _print_terminal "Exiting the script..."

    # Get the process ID (PID) of all child processes.
    child_pids=$(pstree -p "$script_pid" | grep --only-matching --perl-regexp "\(+\K[^)]+")

    # NOTE: Use 'xargs' and kill to send the SIGTERM signal to all child
    # processes, including the current script.
    # See the: https://www.baeldung.com/linux/safely-exit-scripts
    xargs kill <<<"$child_pids" &>/dev/null
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
    gdbus call --session --dest "$interface" --object-path "$object_path" \
        --method "$interface.$method" "$app_name" 0 "$icon" "$title" "$body" \
        "[]" '{"urgency": <1>}' 5000 &>/dev/null
}

_get_filename_dir() {
    local input_filename=$1
    local dir=""

    dir=$(cd -- "$(dirname -- "$input_filename")" &>/dev/null && pwd)

    printf "%s" "$dir"
}

_get_filename_extension() {
    local filename=$1

    grep --ignore-case --only-matching --perl-regexp "(\.tar)?\.[a-z0-9_~-]{0,15}$" <<<"$filename" || true
}

_get_filename_full_path() {
    local input_filename=$1
    local full_path=$input_filename
    local dir=""

    if [[ $input_filename != "/"* ]]; then
        dir=$(_get_filename_dir "$input_filename")
        full_path=$dir/$(basename -- "$input_filename")
    fi

    printf "%s" "$full_path"
}

_get_filename_next_suffix() {
    local filename=$1
    local filename_result=$filename
    local filename_base=""
    local filename_extension=""

    # Directories do not have an extension.
    if [[ -d "$filename" ]]; then
        filename_base=$filename
    else
        filename_base=$(_strip_filename_extension "$filename")
        filename_extension=$(_get_filename_extension "$filename")
    fi

    # Avoid overwriting a file. If there is a file with the same name,
    # try to add a suffix, as 'file (1)', 'file (2)', ...
    local suffix=0
    while [[ -e "$filename_result" ]]; do
        suffix=$((suffix + 1))
        filename_result="$filename_base ($suffix)$filename_extension"
    done

    printf "%s" "$filename_result"
}

_get_filenames_count() {
    local input_files=$1
    local files_count=0

    if [[ -n "$input_files" ]]; then
        files_count=$(tr -cd "$FIELD_SEPARATOR" <<<"$input_files" | wc -c)
        files_count=$((files_count + 1))
    fi

    printf "%s" "$files_count"
}

_get_filenames_filemanager() {
    local input_files=""

    # Try to use the information provided by the file manager.
    if [[ -v "CAJA_SCRIPT_SELECTED_URIS" ]]; then
        input_files=$CAJA_SCRIPT_SELECTED_URIS
    elif [[ -v "NEMO_SCRIPT_SELECTED_URIS" ]]; then
        input_files=$NEMO_SCRIPT_SELECTED_URIS
    elif [[ -v "NAUTILUS_SCRIPT_SELECTED_URIS" ]]; then
        input_files=$NAUTILUS_SCRIPT_SELECTED_URIS
    fi

    if [[ -n "$input_files" ]]; then
        # Replace '\n' with 'FIELD_SEPARATOR'.
        input_files=$(tr "\n" "$FIELD_SEPARATOR" <<<"$input_files")

        # Decode the URI list.
        input_files=$(_text_uri_decode "$input_files")
    else
        input_files=$INPUT_FILES # Standard input.
    fi

    input_files=$(_str_remove_empty_tokens "$input_files")
    printf "%s" "$input_files"
}

_get_files() {
    local parameters=$1
    local input_files=""
    input_files=$(_get_filenames_filemanager)

    # Parameter: "par_type"
    # Values:
    #   "file": Filter files (default).
    #   "directory": Filter directories.
    #   "all": Filter files and directories.
    #
    # Parameter: "par_recursive"
    # Values:
    #   "false": Do not expand directories (default).
    #   "true": Expand directories.

    # Default values for input parameters.
    local par_get_pwd="false"
    local par_max_items=""
    local par_min_items=""
    local par_recursive="false"
    local par_select_extension=""
    local par_select_mime=""
    local par_skip_extension=""
    local par_sort_list="false"
    local par_type="file"
    local par_validate_conflict=""

    # Evaluate the values from the 'parameters' variable.
    eval "$parameters"

    # Check if there are input files.
    if (($(_get_filenames_count "$input_files") == 0)); then
        if [[ "$par_get_pwd" == "true" ]]; then
            # Return the current working directory if no files have been selected.
            input_files=$(_get_working_directory)
        else
            # Try selecting the files by opening a file selection box.
            if [[ "$par_type" == "directory" ]]; then
                input_files=$(_display_dir_selection_box)
            else
                input_files=$(_display_file_selection_box)
            fi
        fi
    fi

    # If the items are in a remote server, translate the addresses to 'gvfs'.
    if [[ "$input_files" == *"://"* ]]; then
        local working_directory=""
        working_directory=$(_get_working_directory)
        input_files=$(sed "s|[a-z0-9\+_-]*://[^$FIELD_SEPARATOR]*/|$working_directory/|g" <<<"$input_files")
    fi

    # Pre-select the input files. Also, expand it (if 'par_recursive' is true).
    input_files=$(_validate_file_preselect \
        "$input_files" \
        "$par_type" \
        "$par_skip_extension" \
        "$par_select_extension" \
        "$par_recursive")

    # Return the current working directory if no directories have been selected.
    if (($(_get_filenames_count "$input_files") == 0)); then
        if [[ "$par_get_pwd" == "true" ]] && [[ "$par_type" == "directory" ]]; then
            input_files=$(_get_working_directory)
        fi
    fi

    # Validates the mime or encoding of the file.
    input_files=$(_validate_file_mime_parallel \
        "$input_files" \
        "$par_select_mime")

    # Validates the number of valid files.
    _validate_files_count \
        "$input_files" \
        "$par_type" \
        "$par_select_extension" \
        "$par_select_mime" \
        "$par_min_items" \
        "$par_max_items" \
        "$par_recursive"

    # Sort the list by filename.
    if [[ "$par_sort_list" == "true" ]]; then
        input_files=$(_convert_filenames_to_text "$input_files")
        input_files=$(_text_sort "$input_files")
        input_files=$(_convert_text_to_filenames "$input_files")
    fi

    # Validates filenames with the same base name.
    if [[ "$par_validate_conflict" == "true" ]]; then
        _validate_conflict_filenames "$input_files"
    fi

    printf "%s" "$input_files"
}

_get_file_encoding() {
    local filename=$1
    local std_output=""

    std_output=$(file --dereference --brief --mime-encoding -- "$filename" 2>/dev/null)

    if [[ "$std_output" == "cannot"* ]]; then
        return
    fi

    printf "%s" "$std_output"
}

_get_file_mime() {
    local filename=$1
    local std_output=""

    std_output=$(file --dereference --brief --mime-type -- "$filename" 2>/dev/null)

    if [[ "$std_output" == "cannot"* ]]; then
        return
    fi

    printf "%s" "$std_output"
}

_get_max_procs() {
    # Return the maximum number of processing units available.
    nproc --all 2>/dev/null
}

_get_output_dir() {
    local parameters=$1
    local base_dir=""
    local output_dir=""

    # Default values for input parameters.
    local par_use_same_dir=""

    # Evaluate the values from the 'parameters' variable.
    eval "$parameters"

    # Check directories available to put the 'output' dir.
    base_dir=$(_get_working_directory)
    [[ ! -w "$base_dir" ]] && base_dir=$HOME
    [[ ! -w "$base_dir" ]] && base_dir="/tmp"
    if [[ ! -w "$base_dir" ]]; then
        _display_error_box "Could not find a directory with write permissions!"
        _exit_script
    fi

    if [[ "$par_use_same_dir" == "true" ]]; then
        printf "%s" "$base_dir"
        return
    fi

    output_dir="$base_dir/$PREFIX_OUTPUT_DIR"

    # If the file already exists, add a suffix.
    output_dir=$(_get_filename_next_suffix "$output_dir")

    mkdir --parents "$output_dir"
    printf "%s" "$output_dir"
}

_get_output_filename() {
    local input_file=$1
    local output_dir=$2
    local parameters=$3
    local output_file=""
    local filename=""

    # Default values for input parameters.
    local par_extension_opt="preserve"
    local par_extension=""
    local par_prefix=""
    local par_suffix=""

    # Evaluate the values from the 'parameters' variable.
    eval "$parameters"

    filename=$(basename -- "$input_file")
    output_file="$output_dir/"
    [[ -n "$par_prefix" ]] && output_file+="$par_prefix "

    # Define the extension of the 'output_file'.
    case "$par_extension_opt" in
    "append")
        output_file+=$(_strip_filename_extension "$filename")
        [[ -n "$par_suffix" ]] && output_file+=" $par_suffix"
        output_file+=$(_get_filename_extension "$filename")
        output_file+=".$par_extension"
        ;;
    "preserve")
        output_file+=$(_strip_filename_extension "$filename")
        [[ -n "$par_suffix" ]] && output_file+=" $par_suffix"
        output_file+=$(_get_filename_extension "$filename")
        ;;
    "replace")
        output_file+=$(_strip_filename_extension "$filename")
        [[ -n "$par_suffix" ]] && output_file+=" $par_suffix"
        output_file+=".$par_extension"
        ;;
    "strip")
        output_file+=$(_strip_filename_extension "$filename")
        [[ -n "$par_suffix" ]] && output_file+=" $par_suffix"
        ;;
    esac

    # If the file already exists, add a suffix.
    output_file=$(_get_filename_next_suffix "$output_file")

    printf "%s" "$output_file"
}

_get_script_name() {
    basename -- "$0"
}

_get_temp_dir_local() {
    local output_dir=$1
    local basename=$2
    local temp_dir=""
    temp_dir=$(mktemp --directory --tmpdir="$output_dir" "$basename.XXXXXXXX.tmp")

    # Remember to remove this directory after exit.
    item_to_remove=$(mktemp --tmpdir="$TEMP_DIR_ITEMS_TO_REMOVE")
    printf "%s$FIELD_SEPARATOR" "$temp_dir" >"$item_to_remove"

    printf "%s" "$temp_dir"
}

_get_temp_file() {
    local temp_file=""
    temp_file=$(mktemp --tmpdir="$TEMP_DIR_TASK")

    printf "%s" "$temp_file"
}

_get_temp_file_dry() {
    local temp_file=""
    temp_file=$(mktemp --dry-run --tmpdir="$TEMP_DIR_TASK")

    printf "%s" "$temp_file"
}

_get_working_directory() {
    local working_directory=""

    # Try to use the information provided by the file manager.
    if [[ -v "CAJA_SCRIPT_CURRENT_URI" ]]; then
        working_directory=$CAJA_SCRIPT_CURRENT_URI
    elif [[ -v "NEMO_SCRIPT_CURRENT_URI" ]]; then
        working_directory=$NEMO_SCRIPT_CURRENT_URI
    elif [[ -v "NAUTILUS_SCRIPT_CURRENT_URI" ]]; then
        working_directory=$NAUTILUS_SCRIPT_CURRENT_URI
    fi

    if [[ -n "$working_directory" ]] && [[ "$working_directory" == "file://"* ]]; then
        working_directory=$(_text_uri_decode "$working_directory")
    else
        # Files selected in the search screen (or other possible cases).
        working_directory=""
    fi

    if [[ -z "$working_directory" ]]; then
        # NOTE: The working directory can be detected by using the directory name
        # of the first input file. Some file managers do not send the working
        # directory for the scripts, so it is not precise to use the 'pwd' command.
        local item_1=""
        item_1=$(cut -d "$FIELD_SEPARATOR" -f 1 <<<"$INPUT_FILES")

        if [[ -n "$item_1" ]]; then
            working_directory=$(_get_filename_dir "$item_1")
        else
            working_directory=$(pwd)
        fi
    fi

    printf "%s" "$working_directory"
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

    # Do nothing if there are no error log files.
    log_files_count="$(find "$TEMP_DIR_LOGS" -type f 2>/dev/null | wc -l)"
    if ((log_files_count == 0)); then
        return 1
    fi

    if [[ -z "$output_dir" ]]; then
        output_dir=$(_get_output_dir "par_use_same_dir=true")
    fi
    log_file_output="$output_dir/$PREFIX_ERROR_LOG_FILE.log"

    # If the file already exists, add a suffix.
    log_file_output=$(_get_filename_next_suffix "$log_file_output")

    # Compile log errors in a single file.
    {
        printf "Script: '%s'.\n" "$(_get_script_name)"
        printf "Total errors: %s.\n\n" "$log_files_count"
        cat -- "$TEMP_DIR_LOGS/"* 2>/dev/null
    } >"$log_file_output"

    printf "%s" "$log_file_output"
}

_log_write() {
    local message=$1
    local input_file=$2
    local std_output=$3
    local output_file=$4

    local log_temp_file=""
    log_temp_file=$(mktemp --tmpdir="$TEMP_DIR_LOGS")

    {
        printf "[%s]\n" "$(date "+%Y-%m-%d %H:%M:%S")"
        printf " > Input file: %s\n" "$input_file"
        printf " > Output file: %s\n" "$output_file"
        printf " > %s\n" "$message"
        printf " > Terminal output:\n"
        printf "%s\n\n" "$std_output"
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
            _log_write "Warning: The file already exists." "$file_src" "" "$file_dst"
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

    # If 'input_file' equals 'output_file', create a backup of the 'input_file'.
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

_open_items_locations() {
    local items=$1
    local dir=""

    if [[ -z "$items" ]]; then
        return
    fi

    # Try to detect the file manager running.
    local file_manager=""
    if [[ -v "CAJA_SCRIPT_SELECTED_URIS" ]]; then
        file_manager="caja"
    elif [[ -v "NEMO_SCRIPT_SELECTED_URIS" ]]; then
        file_manager="nemo"
    elif [[ -v "NAUTILUS_SCRIPT_SELECTED_URIS" ]]; then
        file_manager="nautilus"
    else
        # Use the default application that opens directories.
        file_manager=$(_xdg_get_default_app "inode/directory")
    fi

    # Restore the working directory from path (if it was removed before).
    local working_directory=""
    working_directory=$(_get_working_directory)
    items=$(sed "s|\./|$working_directory/|g" <<<"$items")

    # Open the location of each item.
    local item=""
    local items_open=""
    for item in $items; do
        if [[ "$item" == "/" ]]; then
            continue
        fi

        if [[ -L "$item" ]]; then
            item=$(readlink -f "$item")
        fi
        items_open+="$item$FIELD_SEPARATOR"

        case "$file_manager" in
        "nautilus" | "caja" | "dolphin" | "nemo" | "thunar") : ;;
        *)
            # Open the directory of the item.
            dir=$(_get_filename_dir "$item")
            if [[ -z "$dir" ]]; then
                continue
            fi
            $file_manager "$dir" &
            ;;
        esac
    done

    case "$file_manager" in
    "nautilus" | "caja" | "dolphin")
        # Open the directory of the item and select it.
        # shellcheck disable=SC2086
        $file_manager --select $items_open &
        ;;
    "nemo" | "thunar")
        # Open the directory of the item and select it.
        # shellcheck disable=SC2086
        $file_manager $items_open &
        ;;
    esac
}

_pkg_get_package_manager() {
    local pkg_manager=""

    # Check for an installed package manager.
    if _command_exists "apt-get"; then
        pkg_manager="apt"
    elif _command_exists "dnf"; then
        pkg_manager="dnf"
    elif _command_exists "pacman"; then
        pkg_manager="pacman"
    elif _command_exists "zypper"; then
        pkg_manager="zypper"
    fi

    printf "%s" "$pkg_manager"
}

_pkg_install_packages() {
    local pkg_manager=$1
    local packages=$2

    _display_wait_box_message "Installing the packages. Please, wait..."

    # Install the packages.
    if ! _command_exists "pkexec"; then
        _display_error_box "Could not run the installer with administrator permission!"
        _exit_script
    fi

    case "$pkg_manager" in
    "apt")
        pkexec bash -c "apt-get update; apt-get -y install $packages &>/dev/null"
        ;;
    "dnf")
        pkexec bash -c "dnf check-update; dnf -y install $packages &>/dev/null"
        ;;
    "pacman")
        pkexec bash -c "pacman -Syy; pacman --noconfirm -S $packages &>/dev/null"
        ;;
    "zypper")
        pkexec bash -c "zypper refresh; zypper --non-interactive install $packages &>/dev/null"
        ;;
    esac

    _close_wait_box

    # Check if all packages were installed.
    packages=$(tr " " "$FIELD_SEPARATOR" <<<"$packages")
    local package=""
    for package in $packages; do
        if ! _pkg_is_package_installed "$pkg_manager" "$package"; then
            _display_error_box "Could not install the package '$package'!"
            _exit_script
        fi
    done

    _display_info_box "The packages have been successfully installed!"
}

_pkg_is_package_installed() {
    local pkg_manager=$1
    local package=$2

    case "$pkg_manager" in
    "apt")
        if dpkg -s "$package" &>/dev/null; then
            return 0
        fi
        ;;
    "dnf")
        if dnf list installed | grep -q "$package"; then
            return 0
        fi
        ;;
    "pacman")
        if pacman -Q "$package" &>/dev/null; then
            return 0
        fi
        ;;
    "zypper")
        if zypper search --installed-only "$package" | grep -q "^i"; then
            return 0
        fi
        ;;
    esac
    return 1
}

_print_terminal() {
    local message=$1

    if ! _is_gui_session; then
        printf "%s\n" "$message"
    fi
}

_run_task_parallel() {
    local input_files=$1
    local output_dir=$2

    # Allows the symbol "'" in filenames (inside 'xargs').
    input_files=$(sed -z "s|'|'\\\''|g" <<<"$input_files")

    # Export variables to be used inside new shells (when using 'xargs').
    export \
        FIELD_SEPARATOR \
        IGNORE_FIND_PATH \
        INPUT_FILES \
        TEMP_DATA_TASK \
        TEMP_DIR_ITEMS_TO_REMOVE \
        TEMP_DIR_LOGS \
        TEMP_DIR_STORAGE_TEXT \
        TEMP_DIR_TASK

    # Export functions to be used inside new shells (when using 'xargs').
    export -f \
        _check_output \
        _command_exists \
        _convert_filenames_to_text \
        _convert_text_to_filenames \
        _display_password_box \
        _exit_script \
        _get_file_encoding \
        _get_file_mime \
        _get_filename_dir \
        _get_filename_extension \
        _get_filename_full_path \
        _get_filename_next_suffix \
        _get_max_procs \
        _get_output_filename \
        _get_temp_dir_local \
        _get_temp_file \
        _get_temp_file_dry \
        _get_working_directory \
        _is_gui_session \
        _log_write \
        _main_task \
        _move_file \
        _move_temp_file_to_output \
        _print_terminal \
        _storage_text_write \
        _storage_text_write_ln \
        _str_remove_empty_tokens \
        _strip_filename_extension \
        _text_remove_pwd \
        _text_uri_decode

    printf "%s" "$input_files" | xargs \
        --no-run-if-empty \
        --delimiter="$FIELD_SEPARATOR" \
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

    if [[ -z "$input_text" ]] || [[ "$input_text" == $'\n' ]]; then
        return
    fi

    # Save the text to be compiled into a single file.
    temp_file=$(mktemp --tmpdir="$TEMP_DIR_STORAGE_TEXT")
    printf "%s" "$input_text" >"$temp_file"
}

_storage_text_write_ln() {
    local input_text=$1

    if [[ -z "$input_text" ]]; then
        return
    fi

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

    printf "%s" "$output_path"
}

_str_remove_empty_tokens() {
    local input_str=$1
    input_str=$(tr -s "$FIELD_SEPARATOR" <<<"$input_str")
    input_str=$(sed "s|$FIELD_SEPARATOR$||" <<<"$input_str")

    printf "%s" "$input_str"
}

_strip_filename_extension() {
    local filename=$1

    sed -r "s|(\.tar)?\.[a-z0-9_~-]{0,15}$||i" <<<"$filename"
}

_text_remove_empty_lines() {
    local input_text=$1

    grep -v "^\s*$" <<<"$input_text" || true
}

_text_remove_home() {
    local input_text=$1

    if [[ -n "$HOME" ]]; then
        sed "s|$HOME|~|g" <<<"$input_text"
    else
        printf "%s" "$input_text"
    fi
}

_text_remove_pwd() {
    local input_text=$1
    local working_directory=""
    working_directory=$(_get_working_directory)

    sed "s|$working_directory|.|g" <<<"$input_text"
}

_text_sort() {
    local input_text=$1

    sort --version-sort <<<"$input_text"
}

_text_uri_decode() {
    local uri_encoded=$1

    uri_encoded=${uri_encoded//%/\\x}
    uri_encoded=${uri_encoded//file:\/\//}

    # shellcheck disable=SC2059
    printf "$uri_encoded"
}

_unset_global_variables_file_manager() {
    # Unset some possible global variables set by the file manager.
    unset \
        CAJA_SCRIPT_CURRENT_URI \
        CAJA_SCRIPT_NEXT_PANE_CURRENT_URI \
        CAJA_SCRIPT_NEXT_PANE_SELECTED_FILE_PATHS \
        CAJA_SCRIPT_NEXT_PANE_SELECTED_URIS \
        CAJA_SCRIPT_SELECTED_FILE_PATHS \
        CAJA_SCRIPT_SELECTED_URIS \
        CAJA_SCRIPT_WINDOW_GEOMETRY \
        NAUTILUS_SCRIPT_CURRENT_URI \
        NAUTILUS_SCRIPT_NEXT_PANE_CURRENT_URI \
        NAUTILUS_SCRIPT_NEXT_PANE_SELECTED_FILE_PATHS \
        NAUTILUS_SCRIPT_NEXT_PANE_SELECTED_URIS \
        NAUTILUS_SCRIPT_SELECTED_FILE_PATHS \
        NAUTILUS_SCRIPT_SELECTED_URIS \
        NAUTILUS_SCRIPT_WINDOW_GEOMETRY \
        NEMO_SCRIPT_CURRENT_URI \
        NEMO_SCRIPT_NEXT_PANE_CURRENT_URI \
        NEMO_SCRIPT_NEXT_PANE_SELECTED_FILE_PATHS \
        NEMO_SCRIPT_NEXT_PANE_SELECTED_URIS \
        NEMO_SCRIPT_SELECTED_FILE_PATHS \
        NEMO_SCRIPT_SELECTED_URIS \
        NEMO_SCRIPT_WINDOW_GEOMETRY \
        OLDPWD
}

_validate_conflict_filenames() {
    local input_files=$1
    local dup_filenames="$input_files"

    dup_filenames=$(_convert_filenames_to_text "$dup_filenames")
    dup_filenames=$(_strip_filename_extension "$dup_filenames")
    dup_filenames=$(uniq -d <<<"$dup_filenames")

    if [[ -n "$dup_filenames" ]]; then
        _display_error_box "There are selected files with the same base name!"
        _exit_script
    fi
}

_validate_file_mime() {
    local input_file=$1
    local par_select_mime=$2

    # Validation for files (mime).
    if [[ -n "$par_select_mime" ]]; then
        local file_mime=""
        file_mime=$(_get_file_mime "$input_file")
        par_select_mime=${par_select_mime//+/\\+}
        grep -q --ignore-case --perl-regexp "($par_select_mime)" <<<"$file_mime" || return
    fi

    # Create a temp file containing the name of the valid file.
    _storage_text_write "$input_file$FIELD_SEPARATOR"
}

_validate_file_mime_parallel() {
    local input_files=$1
    local par_select_mime=$2

    # Return the 'input_files' if all parameters are empty.
    if [[ -z "$par_select_mime" ]]; then
        printf "%s" "$input_files"
        return
    fi

    # Allows the symbol "'" in filenames (inside 'xargs').
    input_files=$(sed -z "s|'|'\\\''|g" <<<"$input_files")

    # Export variables to be used inside new shells (when using 'xargs').
    export FIELD_SEPARATOR TEMP_DIR_STORAGE_TEXT

    # Export functions to be used inside new shells (when using 'xargs').
    export -f _get_file_mime _storage_text_write _validate_file_mime

    # Execute the function '_validate_file_mime' for each file in parallel (using 'xargs').
    printf "%s" "$input_files" | xargs \
        --no-run-if-empty \
        --delimiter="$FIELD_SEPARATOR" \
        --max-procs="$(_get_max_procs)" \
        --replace="{}" \
        bash -c "_validate_file_mime '{}' '$par_select_mime'"

    # Compile valid files in a single list.
    input_files=$(_storage_text_read_all)
    _storage_text_clean

    input_files=$(_str_remove_empty_tokens "$input_files")
    printf "%s" "$input_files"
}

_validate_file_preselect() {
    local input_files=$1
    local par_type=$2
    local par_skip_extension=$3
    local par_select_extension=$4
    local par_recursive=$5
    local input_files_valid=""

    input_files=$(sed "s|'|'\"'\"'|g" <<<"$input_files")
    input_files=$(sed "s|$FIELD_SEPARATOR|' '|g" <<<"$input_files")

    # Build a 'find' command.
    find_command="find '$input_files'"

    if [[ "$par_recursive" != "true" ]]; then
        find_command+=" -maxdepth 0"
    fi

    # Expand the directories with the 'find' command.
    case "$par_type" in
    "file") find_command+=" \( -type l -o -type f \)" ;;
    "directory") find_command+=" \( -type l -o -type d \)" ;;
    esac

    if [[ -n "$par_select_extension" ]]; then
        find_command+=" -regextype posix-extended "
        find_command+=" -regex \".*\.($par_select_extension)$\""
    fi

    if [[ -n "$par_skip_extension" ]]; then
        find_command+=" -regextype posix-extended "
        find_command+=" ! -regex \".*\.($par_skip_extension)$\""
    fi

    find_command+=" ! -path \"$IGNORE_FIND_PATH\""
    # shellcheck disable=SC2089
    find_command+=" -printf \"%p\v\""

    # shellcheck disable=SC2086
    input_files_valid=$(eval $find_command 2>/dev/null)
    input_files_valid=$(tr "\v" "$FIELD_SEPARATOR" <<<"$input_files_valid")
    input_files_valid=$(_str_remove_empty_tokens "$input_files_valid")

    # Create a temp file containing the name of the valid file.
    printf "%s" "$input_files_valid"
}

_validate_files_count() {
    local input_files=$1
    local par_type=$2
    local par_select_extension=$3
    local par_select_mime=$4
    local par_min_items=$5
    local par_max_items=$6
    local par_recursive=$7

    # Define a term for a valid file.
    local valid_file_term="valid files"
    if [[ "$par_type" == "directory" ]]; then
        valid_file_term="directories"
    elif [[ -n "$par_select_mime" ]]; then
        valid_file_term="$par_select_mime"
        valid_file_term=$(sed "s|\|| or |g" <<<"$par_select_mime")
        valid_file_term=$(sed "s|/$||g; s|/ | |g" <<<"$valid_file_term")
        valid_file_term+=" files"
    elif [[ "$par_type" == "file" ]]; then
        valid_file_term="files"
    elif [[ "$par_type" == "all" ]]; then
        valid_file_term="files or directories"
    fi

    # Count the number of valid files.
    local valid_items_count=0
    valid_items_count=$(_get_filenames_count "$input_files")

    # Check if there is at least one valid file.
    if ((valid_items_count == 0)); then
        if [[ "$par_recursive" == "true" ]]; then
            if [[ -n "$par_select_extension" ]]; then
                _display_error_box "No files with extension: '.${par_select_extension//|/\' or \'.}' were found in the selection!"
            else
                _display_error_box "No $valid_file_term were found in the selection!"
            fi
        else
            if [[ -n "$par_select_extension" ]]; then
                _display_error_box "You must select files with extension: '.${par_select_extension//|/\' or \'.}'!"
            else
                _display_error_box "You must select $valid_file_term!"
            fi
        fi
        _exit_script
    fi

    if [[ -n "$par_min_items" ]] && ((valid_items_count < par_min_items)); then
        _display_error_box "You must select at least $par_min_items $valid_file_term!"
        _exit_script
    fi

    if [[ -n "$par_max_items" ]] && ((valid_items_count > par_max_items)); then
        _display_error_box "You must select up to $par_max_items $valid_file_term!"
        _exit_script
    fi
}

_xdg_get_default_app() {
    local mime=$1
    local desktop_file=""
    local default_app=""

    desktop_file=$(xdg-mime query default "$mime" 2>/dev/null)

    default_app=$(grep "^Exec" "/usr/share/applications/$desktop_file" | head -n1 | sed "s|Exec=||g" | cut -d " " -f 1)

    if [[ -z "$default_app" ]]; then
        _display_error_box "Could not find the default application to open '$mime' files!"
        _exit_script
    fi

    printf "%s" "$default_app"
}
