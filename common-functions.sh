#!/usr/bin/env bash
# shellcheck disable=SC2001

# This file contains common functions that the scripts will source.

set -u

# -----------------------------------------------------------------------------
# CONSTANTS
# -----------------------------------------------------------------------------

FIELD_SEPARATOR=$'\r'          # The main field separator.
GUI_BOX_HEIGHT=550             # Height of the GUI dialog boxes.
GUI_BOX_WIDTH=900              # Width of the GUI dialog boxes.
GUI_INFO_WIDTH=400             # Width of the GUI small dialog boxes.
IGNORE_FIND_PATH="*.git/*"     # Path to ignore in the 'find' command.
PREFIX_ERROR_LOG_FILE="Errors" # Name of 'error' directory.
PREFIX_OUTPUT_DIR="Output"     # Name of 'output' directory.
TEMP_DIR=$(mktemp --directory) # Temp directories for use in scripts.
TEMP_DIR_ITEMS_TO_REMOVE="$TEMP_DIR/items_to_remove"
TEMP_DIR_LOGS="$TEMP_DIR/logs"
TEMP_DIR_STORAGE_TEXT="$TEMP_DIR/storage_text"
TEMP_DIR_TASK="$TEMP_DIR/task"
WAIT_BOX_CONTROL_KDE="$TEMP_DIR/wait_box_control_kde"
WAIT_BOX_CONTROL="$TEMP_DIR/wait_box_control"
WAIT_BOX_FIFO="$TEMP_DIR/wait_box_fifo"

readonly \
    FIELD_SEPARATOR \
    GUI_BOX_HEIGHT \
    GUI_BOX_WIDTH \
    GUI_INFO_WIDTH \
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

# Store the path of temporary items to be removed after exit.
mkdir -p "$TEMP_DIR_ITEMS_TO_REMOVE"
mkdir -p "$TEMP_DIR_LOGS"         # Store 'error logs'.
mkdir -p "$TEMP_DIR_STORAGE_TEXT" # Store the output from parallel processes.
mkdir -p "$TEMP_DIR_TASK"         # Store temporary files of scripts.

# -----------------------------------------------------------------------------
# FUNCTIONS
# -----------------------------------------------------------------------------

_cleanup_on_exit() {
    # This function performs cleanup tasks when the script exits. It is
    # designed to safely and efficiently remove temporary directories or files
    # that were created during the script's execution.

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

    if ! _is_gui_session; then
        printf "End of the script.\n" >&2
    fi
}
trap _cleanup_on_exit EXIT

_check_dependencies() {
    # This function ensures that all required dependencies are available for
    # the scripts to run. It verifies the presence of specified commands or
    # packages and prompts the user to install missing ones.
    #
    # Parameters:
    #   - $1 (dependencies): A list of dependencies to check, formatted as a
    #     "|" delimited string. Each dependency can specify:
    #     - "command": The name of a command to check for in the shell.
    #     - "package": The package associated with the command (if different).
    #     - "pkg_manager": Optional. The specific package manager.
    #
    # Example:
    #   - _check_dependencies "
    #       command=ffmpeg; pkg_manager=apt; package=ffmpeg |
    #       command=ffmpeg; pkg_manager=dnf; package=ffmpeg-free |
    #       command=ffmpeg; pkg_manager=pacman; package=ffmpeg |
    #       command=ffmpeg; pkg_manager=zypper; package=ffmpeg"

    local dependencies=$1
    local packages_to_install=""
    local pkg_manager_installed=""

    [[ -z "$dependencies" ]] && return

    # Skip duplicated dependencies in the input list.
    dependencies=$(tr "|" "\n" <<<"$dependencies")
    dependencies=$(tr -d " " <<<"$dependencies")
    dependencies=$(sort --unique <<<"$dependencies")
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

        # Evaluate the values parameters from the 'dependency' variable.
        eval "$dependency"

        # Ignore installing the dependency if there is a command in the shell.
        if [[ -n "$command" ]] && _command_exists "$command"; then
            continue
        fi

        # Ignore installing the dependency if the installed
        # package managers differ.
        if [[ -n "$pkg_manager" ]] &&
            [[ "$pkg_manager_installed" != "$pkg_manager" ]]; then
            continue
        fi

        # Ignore installing the dependency if the package is already installed
        # (packages that do not have a command).
        if [[ -n "$package" ]] && [[ -z "$command" ]] &&
            _pkg_is_package_installed "$pkg_manager_installed" "$package"; then
            continue
        fi

        # If the package is not specified, use the command name as
        # the package name.
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
            _pkg_install_packages \
                "$pkg_manager_installed" "${packages_to_install/ /}"
        else
            _exit_script
        fi
    fi
}

_check_output() {
    # This function validates the success of a command or process based on its
    # exit code and output. It logs errors if the command fails or if an
    # expected output file is missing.
    #
    # Parameters:
    #   - $1 (exit_code): The exit code returned by the command or process.
    #   - $2 (std_output): The standard output or error from the command.
    #   - $3 (input_file): The input file associated (if applicable).
    #   - $4 (output_file): The expected output file to verify its existence.

    local exit_code=$1
    local std_output=$2
    local input_file=$3
    local output_file=$4

    # Check the 'exit_code' and log the error.
    if ((exit_code != 0)); then
        _log_error "Command failed with a non-zero exit code." \
            "$input_file" "$std_output" "$output_file"
        return 1
    fi

    # Check if the output file exists.
    if [[ -n "$output_file" ]] && [[ ! -e "$output_file" ]]; then
        _log_error "The output file does not exist." \
            "$input_file" "$std_output" "$output_file"
        return 1
    fi

    return 0
}

_command_exists() {
    # This function checks whether a given command is available on the system.
    #
    # Parameters:
    #   - $1 (command_check): The name of the command to verify.

    local command_check=$1

    if command -v "$command_check" &>/dev/null; then
        return 0
    fi
    return 1
}

_convert_delimited_string_to_text() {
    # This function converts a delimited string of items into
    # newline-separated text.
    #
    # Parameters:
    #   - $1 (input_items): A string containing items separated by the
    #   '$FIELD_SEPARATOR' variable.
    #
    # Returns:
    #   - A string containing the items separated by newlines.

    local input_items=$1
    local new_line="'\$'\\\n''"

    input_items=$(sed -z "s|\n|$new_line|g; s|$new_line$||g" <<<"$input_items")
    input_items=$(tr "$FIELD_SEPARATOR" "\n" <<<"$input_items")

    printf "%s" "$input_items"
}

_directory_pop() {
    # This function pops the top directory off the directory stack and changes
    # to the previous directory.

    popd &>/dev/null || {
        _log_error "Could not pop a directory." "" "" ""
        return 1
    }
    return 0
}

_directory_push() {
    # This function pushes the specified directory onto the directory stack and
    # changes to it.
    #
    # Parameters:
    #   - $1 (directory): The target directory to push onto the directory stack
    #     and navigate to.

    local directory=$1

    pushd "$directory" &>/dev/null || {
        _log_error "Could not push the directory '$directory'." "" "" ""
        return 1
    }
    return 0
}

_convert_text_to_delimited_string() {
    # This function converts newline-separated text into a delimited string of
    # items.
    #
    # Parameters:
    #   - $1 (input_items): A string containing items separated by newlines.
    #
    # Returns:
    #   - A string containing the items separated by the '$FIELD_SEPARATOR'
    #   variable.

    local input_items=$1
    local new_line="'\$'\\\n''"

    input_items=$(tr "\n" "$FIELD_SEPARATOR" <<<"$input_items")
    input_items=$(sed -z "s|$new_line|\n|g" <<<"$input_items")

    input_items=$(_str_remove_empty_tokens "$input_items")
    printf "%s" "$input_items"
}

_display_dir_selection_box() {
    # This function presents a graphical interface to allow the user to select
    # one or more directories.

    local input_files=""

    if _command_exists "zenity"; then
        input_files=$(zenity --title "$(_get_script_name)" \
            --file-selection --multiple --directory \
            --separator="$FIELD_SEPARATOR" 2>/dev/null) || _exit_script
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

# shellcheck disable=SC2120
_display_file_selection_box() {
    # This function presents a graphical interface to allow the user to select
    # a file.
    #
    # Parameters:
    #   - $1 (file_filter): Optional. File filter pattern to restrict the types
    #     of files shown.

    local file_filter=${1:-""}
    local input_files=""

    if _command_exists "zenity"; then
        input_files=$(zenity --title "$(_get_script_name)" \
            --file-selection \
            ${file_filter:+--file-filter="$file_filter"} \
            --separator="$FIELD_SEPARATOR" 2>/dev/null) || _exit_script
    elif _command_exists "kdialog"; then
        input_files=$(kdialog --title "$(_get_script_name)" \
            --getopenfilename 2>/dev/null) || _exit_script
        # Use parameter expansion to remove the last space.
        input_files=${input_files% }
        input_files=${input_files// \//$FIELD_SEPARATOR/}
    fi

    input_files=$(_str_remove_empty_tokens "$input_files")
    printf "%s" "$input_files"
}

_display_error_box() {
    # This function displays an error message to the user, adapting to the
    # available environment.
    #
    # Parameters:
    #   - $1 (message): The error message to display.

    local message=$1

    if ! _is_gui_session; then
        printf "Error: %s\n" "$message" >&2
    elif [[ -n "$DBUS_SESSION_BUS_ADDRESS" ]]; then
        _gdbus_notify "dialog-error" "$(_get_script_name)" "$message"
    elif _command_exists "zenity"; then
        zenity --title "$(_get_script_name)" --error \
            --width="$GUI_INFO_WIDTH" --text "$message" &>/dev/null
    elif _command_exists "kdialog"; then
        kdialog --title "$(_get_script_name)" --error "$message" &>/dev/null
    elif _command_exists "xmessage"; then
        xmessage -title "$(_get_script_name)" "Error: $message" &>/dev/null
    fi
}

_display_info_box() {
    # This function displays an information message to the user, adapting to
    # the available environment.
    #
    # Parameters:
    #   - $1 (message): The information message to display.

    local message=$1

    if ! _is_gui_session; then
        printf "Info: %s\n" "$message" >&2
    elif [[ -n "$DBUS_SESSION_BUS_ADDRESS" ]]; then
        _gdbus_notify "dialog-information" "$(_get_script_name)" "$message"
    elif _command_exists "zenity"; then
        zenity --title "$(_get_script_name)" --info \
            --width="$GUI_INFO_WIDTH" --text "$message" &>/dev/null
    elif _command_exists "kdialog"; then
        kdialog --title "$(_get_script_name)" --msgbox "$message" &>/dev/null
    elif _command_exists "xmessage"; then
        xmessage -title "$(_get_script_name)" "Info: $message" &>/dev/null
    fi
}

_display_list_box() {
    # This function displays a list box with selectable items, adapting to the
    # available environment.
    #
    # Parameters:
    #   - $1 (message): A string containing the items to display in the list.
    #   - $2 (columns): Column definitions for the list, typically in the
    #   format "--column=<name>;--column=<name>".
    #   - $3 (item_name): A string representing the name of the items in the
    #   list. If not provided, the default value is "items".
    #   - $4 (resolve_links): A boolean-like string ("true" or "false")
    #   indicating whether symbolic links in item paths should be resolved to
    #   their target locations when opening the item's location. Defaults to
    #   "true".

    local message=$1
    local columns=$2
    local item_name=${3:-"items"}
    local resolve_links=${4:-"true"}
    local columns_count=0
    local items_count=0
    local selected_item=""
    local message_select=""
    _close_wait_box
    _logs_consolidate ""

    if [[ -n "$message" ]]; then
        items_count=$(tr -cd "\n" <<<"$message" | wc -c)
        message_select=" Select an item to open its location:"
    fi

    # Count the number of columns.
    columns_count=$(grep --only-matching "column=" <<<"$columns" | wc -l)

    if ! _is_gui_session; then
        if [[ -z "$message" ]]; then
            message="(Empty result)"
            printf "%s\n" "$message" >&2
        else
            message=$(tr "$FIELD_SEPARATOR" " " <<<"$message")
            printf "%s\n" "$message"
        fi
    elif _command_exists "zenity"; then
        if [[ -z "$message" ]]; then
            # NOTE: Some versions of Zenity crash if the
            # message is empty (Segmentation fault).
            message=" "
        fi
        columns=$(tr ";" "$FIELD_SEPARATOR" <<<"$columns")
        message=$(tr "\n" "$FIELD_SEPARATOR" <<<"$message")
        # shellcheck disable=SC2086
        selected_item=$(zenity --title "$(_get_script_name)" --list \
            --editable --multiple --separator="$FIELD_SEPARATOR" \
            --width="$GUI_BOX_WIDTH" --height="$GUI_BOX_HEIGHT" \
            --print-column "$columns_count" \
            --text "Total of $items_count $item_name.$message_select" \
            $columns $message 2>/dev/null) || _exit_script

        if ((items_count != 0)) && [[ -n "$selected_item" ]]; then
            # Open the directory of the clicked item in the list.
            _open_items_locations "$selected_item" "$resolve_links"
        fi
    elif _command_exists "kdialog"; then
        columns=$(sed "s|--column=||g" <<<"$columns")
        columns=$(tr ";" "\t" <<<"$columns")
        message=$(tr "$FIELD_SEPARATOR" "\t" <<<"$message")
        message="$columns"$'\n'$'\n'"$message"
        kdialog --title "$(_get_script_name)" \
            --geometry "${GUI_BOX_WIDTH}x${GUI_BOX_HEIGHT}" \
            --textinputbox "" "$message" &>/dev/null || _exit_script
    elif _command_exists "xmessage"; then
        columns=$(sed "s|--column=||g" <<<"$columns")
        columns=$(tr ";" "\t" <<<"$columns")
        message=$(tr "$FIELD_SEPARATOR" "\t" <<<"$message")
        message="$columns"$'\n'$'\n'"$message"
        xmessage -title "$(_get_script_name)" \
            "$message" &>/dev/null || _exit_script
    fi
}

_display_password_box() {
    # This function prompts the user to enter a password, either via the
    # terminal or a graphical dialog box.
    #
    # Parameters:
    #   - $1 (message): A message to display as a prompt for the password.

    local message="$1"
    local password=""

    # Ask the user for the 'password'.
    if ! _is_gui_session; then
        read -r -p "$message " password >&2
    elif _command_exists "zenity"; then
        sleep 0.2 # Avoid 'wait_box' open before.
        password=$(zenity \
            --title="Password" --entry --hide-text --width="$GUI_INFO_WIDTH" \
            --text "$message" 2>/dev/null) || return 1
    elif _command_exists "kdialog"; then
        sleep 0.2 # Avoid 'wait_box' open before.
        password=$(kdialog --title "Password" \
            --password "$message" 2>/dev/null) || return 1
    fi

    printf "%s" "$password"
}

_display_password_box_define() {
    # This function prompts the user to enter a password and ensures the
    # password is not empty.

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
    # This function prompts the user with a yes/no question and returns the
    # user's response.
    #
    # Parameters:
    #   - $1 (message): The question message to display to the user.

    local message=$1
    local response=""

    if ! _is_gui_session; then
        read -r -p "$message [Y/n] " response
        [[ ${response,,} == *"n"* ]] && return 1
    elif _command_exists "zenity"; then
        zenity --title "$(_get_script_name)" --question \
            --width="$GUI_INFO_WIDTH" --text="$message" &>/dev/null || return 1
    elif _command_exists "kdialog"; then
        kdialog --title "$(_get_script_name)" \
            --yesno "$message" &>/dev/null || return 1
    elif _command_exists "xmessage"; then
        xmessage -title "$(_get_script_name)" \
            -buttons "Yes:0,No:1" "$message" &>/dev/null || return 1
    fi
    return 0
}

_display_text_box() {
    # This function displays a message to the user in a text box, either in the
    # terminal or using a GUI dialog.
    #
    # Parameters:
    #   - $1 (message): The message to display. If empty, a default message
    #     "(Empty result)" is shown.

    local message=$1
    _close_wait_box
    _logs_consolidate ""

    if [[ -z "$message" ]]; then
        message="(Empty result)"
    fi

    if ! _is_gui_session; then
        printf "%s\n" "$message"
    elif _command_exists "zenity"; then
        zenity --title "$(_get_script_name)" --text-info --no-wrap \
            --width="$GUI_BOX_WIDTH" --height="$GUI_BOX_HEIGHT" \
            <<<"$message" &>/dev/null || _exit_script
    elif _command_exists "kdialog"; then
        kdialog --title "$(_get_script_name)" \
            --geometry "${GUI_BOX_WIDTH}x${GUI_BOX_HEIGHT}" \
            --textinputbox "" \
            "$message" &>/dev/null || _exit_script
    elif _command_exists "xmessage"; then
        xmessage -title "$(_get_script_name)" \
            "$message" &>/dev/null || _exit_script
    fi
}

_display_result_box() {
    # This function displays a result summary at the end of a process,
    # including error checking and output directory information.
    #
    # Parameters:
    #   - $1 (output_dir): The directory where output files are stored or
    #     expected to be.

    local output_dir=$1
    _close_wait_box
    _logs_consolidate "$output_dir"

    # If 'output_dir' parameter is defined.
    if [[ -n "$output_dir" ]]; then
        # Try to remove the output directory (if it is empty).
        if [[ "$output_dir" == *"/$PREFIX_OUTPUT_DIR"* ]]; then
            rmdir "$output_dir" &>/dev/null
        fi

        # Check if the output directory still exists.
        if [[ -d "$output_dir" ]]; then
            local dir_label=""
            dir_label=$(_str_human_readable_path "$output_dir")
            _display_info_box \
                "Finished! The output files are in the $dir_label directory."
        else
            _display_info_box "Finished, but there is nothing to do."
        fi
    else
        _display_info_box "Finished!"
    fi
}

_display_wait_box() {
    # This function displays a wait box to inform the user that a task is
    # running and they need to wait.
    #
    # Parameters:
    #   - $1 (open_delay): Optional. The delay (in seconds) before the wait box
    #     is shown. Defaults to 2 seconds if not provided.

    local open_delay=${1:-"2"}
    local message="Running the task. Please, wait..."

    _display_wait_box_message "$message" "$open_delay"
}

_display_wait_box_message() {
    # This function displays a wait box (progress indicator) to inform the user
    # that a task is in progress.
    #
    # Parameters:
    #   - $1 (message): The message to display inside the wait box (e.g.,
    #     "Running the task. Please, wait...").
    #   - $2 (open_delay): Optional. The delay (in seconds) before the wait box
    #     is shown. Defaults to 2 seconds if not provided.

    local message=$1
    local open_delay=${2:-"2"}

    if ! _is_gui_session; then
        # For non-GUI sessions, simply print the message to the console.
        printf "%s\n" "$message" >&2

    # Check if the Zenity is available.
    elif _command_exists "zenity"; then
        # Control flag to inform that a 'wait_box' will open
        # (if the task takes over 2 seconds).
        touch "$WAIT_BOX_CONTROL"

        # Create the FIFO for communication with Zenity 'wait_box'.
        if [[ ! -p "$WAIT_BOX_FIFO" ]]; then
            mkfifo "$WAIT_BOX_FIFO"
        fi

        # Launch a background thread for Zenity 'wait_box':
        #   - Waits for the specified delay.
        #   - Opens the Zenity 'wait_box' if the control flag still exists.
        #   - If Zenity 'wait_box' fails or is cancelled, exit the script.
        # shellcheck disable=SC2002
        sleep "$open_delay" && [[ -f "$WAIT_BOX_CONTROL" ]] &&
            tail -f -- "$WAIT_BOX_FIFO" | (zenity \
                --title="$(_get_script_name)" --progress \
                --width="$GUI_INFO_WIDTH" \
                --pulsate --auto-close --text="$message" || _exit_script) &

    # Check if the KDialog is available.
    elif _command_exists "kdialog"; then
        _get_qdbus_command || return 0
        # Control flag to inform that a 'wait_box' will open
        # (if the task takes over 2 seconds).
        touch "$WAIT_BOX_CONTROL"

        # Launch a background thread for KDialog 'wait_box':
        #   - Waits for the specified delay.
        #   - Opens the KDialog 'wait_box' if the control flag still exists.
        sleep "$open_delay" && [[ -f "$WAIT_BOX_CONTROL" ]] &&
            kdialog --title="$(_get_script_name)" \
                --progressbar "$message" 0 >"$WAIT_BOX_CONTROL_KDE" &

        # Launch another background thread to monitor the KDialog 'wait_box':
        #   - Periodically checks if the dialog has been closed or cancelled.
        #   - If KDialog 'wait_box' is cancelled, exit the script.
        (
            while [[ -f "$WAIT_BOX_CONTROL" ]] ||
                [[ -f "$WAIT_BOX_CONTROL_KDE" ]]; do
                if [[ -f "$WAIT_BOX_CONTROL_KDE" ]]; then
                    # Extract the D-Bus reference for the KDialog instance.
                    local dbus_ref=""
                    dbus_ref=$(cut -d " " -f 1 <"$WAIT_BOX_CONTROL_KDE")
                    if [[ -n "$dbus_ref" ]]; then
                        # Check if the user has cancelled the wait box.
                        $(_get_qdbus_command) "$dbus_ref" "/ProgressDialog" \
                            "wasCancelled" 2>/dev/null || _exit_script
                    fi
                fi
                sleep 0.2
            done
        ) &
    fi
}

_close_wait_box() {
    # This function is responsible for closing any open "wait boxes" (progress
    # indicators) that were displayed during the execution of a task. It checks
    # for both Zenity and KDialog wait boxes and handles their closure.

    # Check if 'wait_box' will open.
    if [[ -f "$WAIT_BOX_CONTROL" ]]; then
        rm -f -- "$WAIT_BOX_CONTROL" # Cancel the future open.
    fi

    # Check if Zenity 'wait_box' is open (waiting for an input in the FIFO).
    if pgrep -fl "$WAIT_BOX_FIFO" &>/dev/null; then
        # Close the Zenity using the FIFO.
        printf "100\n" >"$WAIT_BOX_FIFO"
    fi

    # Check if KDialog 'wait_box' is open.
    while [[ -f "$WAIT_BOX_CONTROL_KDE" ]]; do
        # Extract the D-Bus reference for the KDialog instance.
        local dbus_ref=""
        dbus_ref=$(cut -d " " -f 1 <"$WAIT_BOX_CONTROL_KDE")
        if [[ -n "$dbus_ref" ]]; then
            # Close the KDialog 'wait_box'.
            $(_get_qdbus_command) "$dbus_ref" "/ProgressDialog" \
                "close" 2>/dev/null
            rm -f -- "$WAIT_BOX_CONTROL_KDE"
        fi
        sleep 0.2
    done
}

_exit_script() {
    # This function is responsible for safely exiting the script by terminating
    # all child processes associated with the current script and printing an
    # exit message to the terminal.

    _close_wait_box

    local child_pids=""
    local script_pid=$$

    if ! _is_gui_session; then
        printf "Exiting the script...\n" >&2
    fi

    # Get the process ID (PID) of all child processes.
    child_pids=$(pstree -p "$script_pid" |
        grep --only-matching --perl-regexp "\(+\K[^)]+")

    # NOTE: Use 'xargs' and kill to send the SIGTERM signal to all child
    # processes, including the current script.
    # See the: https://www.baeldung.com/linux/safely-exit-scripts
    xargs kill <<<"$child_pids" &>/dev/null
}

_gdbus_notify() {
    # This function sends a desktop notification using the "gdbus" tool, which
    # interfaces with the D-Bus notification system (specifically the
    # "org.freedesktop.Notifications" service).
    #
    # Parameters:
    #   - $1 (icon): The icon to display with the notification.
    #   - $2 (title): The title of the notification.
    #   - $3 (body): The main message to be displayed in the notification.

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
    # This function extracts the directory path from a given file path.
    #
    # Parameters:
    #   - $1 (input_filename): The full path or relative path to the file.

    local input_filename=$1
    local dir=""

    dir=$(cd -- "$(dirname -- "$input_filename")" &>/dev/null && pwd)

    printf "%s" "$dir"
}

_get_filename_extension() {
    # This function extracts the file extension from a given filename.
    #
    # Parameters:
    #   - $1 (filename): The input filename (can be absolute or relative).

    local filename=$1
    filename=$(sed -E "s|.*/(\.)*||g" <<<"$filename")
    filename=$(sed -E "s|^(\.)*||g" <<<"$filename")

    printf "%s" "$filename" |
        grep --ignore-case --only-matching --perl-regexp \
            "(\.tar)?\.[a-z0-9_~-]{0,15}$" || true
}

_get_filename_full_path() {
    # This function returns the full absolute path of a given filename.
    #
    # Parameters:
    #   - $1 (input_filename): The input filename or relative path.

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
    # This function generates a unique filename by adding a numeric suffix to
    # the base filename if a file with the same name already exists. It ensures
    # that the new filename does not overwrite an existing file.
    #
    # Parameters:
    #   - $1 (filename): The input filename or path. This can be an absolute or
    #   relative filename. If the input file has an extension, it will be
    #   stripped for the purpose of generating the new filename.

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
    local count=1
    while [[ -e "$filename_result" ]]; do
        filename_result="$filename_base ($count)$filename_extension"
        ((count++))
    done

    printf "%s" "$filename_result"
}

_get_filenames_filemanager() {
    # This function retrieves a list of selected filenames or URIs from a file
    # manager (such as Caja, Nemo, or Nautilus) and processes the input
    # accordingly. If no selection is detected, it falls back to using a
    # standard input file list.

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
        # Replace '\n' with '$FIELD_SEPARATOR'.
        input_files=$(_convert_text_to_delimited_string "$input_files")

        # Decode the URI list.
        input_files=$(_text_uri_decode "$input_files")
    else
        input_files=$INPUT_FILES # Standard input.
        input_files=$(_str_remove_empty_tokens "$input_files")
    fi

    printf "%s" "$input_files"
}

_get_files() {
    # This function retrieves a list of files or directories based on the
    # provided parameters and performs various filtering, validation, and
    # sorting operations. The input files can be filtered by type, extension,
    # mime type, etc. It also supports recursive directory expansion and
    # validation of file conflicts.
    #
    # Parameters:
    #   - $1 (parameters): A string containing key-value pairs that configure
    #   the function's behavior. Example: 'par_type=file; par_min_items=2'.
    #
    # Parameters options:
    #   - "par_type": Specifies the type of items to filter:
    #       - "file" (default): Filters files.
    #       - "directory": Filters directories.
    #       - "all": Includes both files and directories.
    #   - "par_recursive": Specifies whether to expand directories recursively:
    #       - "false" (default): Does not expand directories.
    #       - "true": Expands directories recursively.
    #   - "par_get_pwd": If "true", returns the current working directory if no
    #     files are selected.
    #   - "par_max_items", "par_min_items": Limits the number of files.
    #   - "par_select_extension": Filters by file extension.
    #   - "par_select_mime": Filters by MIME type.
    #   - "par_skip_extension": Skips files with specific extensions.
    #   - "par_sort_list": If "true", sorts the list of files.
    #   - "par_validate_conflict": If "true", validates for filenames with the
    #     same base name.

    local parameters=$1
    local input_files=""
    input_files=$(_get_filenames_filemanager)

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
    if (($(_get_items_count "$input_files") == 0)); then
        if [[ "$par_get_pwd" == "true" ]]; then
            # Return the current working directory if no files have been
            # selected.
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
        input_files=$(sed \
            "s|[a-z0-9\+_-]*://[^$FIELD_SEPARATOR]*/|$working_directory/|g" \
            <<<"$input_files")
    fi

    # This workaround allows the scripts to handle cases with a large input
    # list of files. In this case, just select a single directory. Then, the
    # scripts operate on the files within the selected directory. This
    # addresses the GNOME error: "Could not start application: Failed to
    # execute child process "/bin/sh" (Argument list too long)".
    local initial_items_count=0
    initial_items_count=$(_get_items_count "$input_files")
    if ((initial_items_count == 1)) &&
        [[ -d "$input_files" ]] && [[ "${input_files,,}" == *"batch" ]]; then
        input_files=$(find "$input_files" \
            -mindepth 1 -maxdepth 1 ! -path "$IGNORE_FIND_PATH" \
            -printf "%p$FIELD_SEPARATOR")
    fi

    # Pre-select the input files. Also, expand it (if 'par_recursive' is true).
    input_files=$(_validate_file_preselect \
        "$input_files" \
        "$par_type" \
        "$par_skip_extension" \
        "$par_select_extension" \
        "$par_recursive")

    # Return the current working directory if no directories have been
    # selected.
    if (($(_get_items_count "$input_files") == 0)); then
        if [[ "$par_get_pwd" == "true" ]] &&
            [[ "$par_type" == "directory" ]]; then
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
        input_files=$(printf "%s" "$input_files" | tr "$FIELD_SEPARATOR" "\0" |
            sort --zero-terminated --version-sort | tr "\0" "$FIELD_SEPARATOR")
        input_files=$(_str_remove_empty_tokens "$input_files")
    fi

    # Validates filenames with the same base name.
    if [[ "$par_validate_conflict" == "true" ]]; then
        _validate_conflict_filenames "$input_files"
    fi

    printf "%s" "$input_files"
}

_get_file_encoding() {
    # This function retrieves the MIME encoding of a specified file.
    #
    # Parameters:
    #   - $1 (filename): The path to the file whose encoding is to be
    #     determined.

    local filename=$1
    local std_output=""

    std_output=$(file --dereference --brief --mime-encoding \
        -- "$filename" 2>/dev/null)

    if [[ "$std_output" == "cannot"* ]]; then
        return
    fi

    printf "%s" "$std_output"
}

_get_file_mime() {
    # This function retrieves the MIME type of a specified file.
    #
    # Parameters:
    #   - $1 (filename): The path to the file whose MIME is to be determined.

    local filename=$1
    local std_output=""

    std_output=$(file --dereference --brief --mime-type \
        -- "$filename" 2>/dev/null)

    if [[ "$std_output" == "cannot"* ]]; then
        return
    fi

    printf "%s" "$std_output"
}

_get_items_count() {
    # This function counts the number of items in a string, where items are
    # separated by a specific field separator. It assumes that the input string
    # contains a list of items separated by the value of the variable
    # $FIELD_SEPARATOR.
    #
    # Parameters:
    # - $1 (input_files): A string containing a list of items separated by
    #   the defined $FIELD_SEPARATOR.

    local input_files=$1
    local files_count=0

    if [[ -n "$input_files" ]]; then
        files_count=$(tr -cd "$FIELD_SEPARATOR" <<<"$input_files" | wc -c)
        ((files_count++))
    fi

    printf "%s" "$files_count"
}

_get_max_procs() {
    # This function returns the maximum number of processing units (CPU cores)
    # available on the system.

    nproc --all 2>/dev/null
}

_get_output_dir() {
    # This function determines and returns the appropriate output directory
    # path based on the provided parameters and the system's available
    # directories.
    #
    # Parameters:
    #   - $1 (parameters): A string containing key-value pairs that configure
    #   the function's behavior. Example: 'par_use_same_dir=true'.
    #
    # Parameters options:
    #   - "par_use_same_dir": If set to "true", the function uses the base
    #   directory (e.g., current working directory or an alternative with write
    #   permissions) as the output directory. If "false" or not set, a new
    #   subdirectory is created for the output.

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
    # This function generates the output filename based on the given input
    # file, output directory, and a set of optional parameters. It allows for
    # customization of the output filename by adding prefixes, suffixes, and
    # selecting how the file extension should be handled.
    #
    # Parameters:
    #   - $1 (input_file): The input file for which the output filename will be
    #     generated.
    #   - $2 (output_dir): The directory where the output file will be placed.
    #   - $3 (parameters): A string containing optional parameters that define
    #     how the output filename should be constructed. It supports the
    #     following options:
    #     - par_extension_opt: Specifies how to handle the file extension.
    #       Options are:
    #       - "append": Append a new extension "par_extension" to the existing
    #         file extension.
    #       - "preserve": Keep the original file extension.
    #       - "replace": Replace the current extension with a new one
    #         "par_extension".
    #       - "strip": Remove the file extension entirely.
    #     - par_extension: The extension to use when "par_extension_opt" is set
    #       to "append" or "replace". This value is ignored for the "preserve"
    #       and "strip" options.
    #     - par_prefix: A string to be added as prefix to the output filename.
    #     - par_suffix: A string to be added as suffix to the output
    #       filename, placed before the extension.

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

_get_qdbus_command() {
    # This function retrieves the first command matching the pattern "qdbus".
    # The command may vary depending on the Linux distribution and could be
    # "qdbus", "qdbus-qt6", "qdbus6", or similar variations.
    #
    # Returns:
    #   - "0" (true): If a command matching the pattern "qdbus" is found.
    #   - "1" (false): If no command matching the pattern "qdbus" is found.

    compgen -c | grep --perl-regexp -m1 "^qdbus" || return 1
    return 0
}

_get_script_name() {
    # This function returns the name of the currently executing script. It uses
    # the "basename" command to extract the script's filename from the full
    # path provided by "$0".

    basename -- "$0"
}

_get_temp_dir_local() {
    # This function creates a temporary directory in a specified location and
    # returns its path. The directory is created using "mktemp", with a custom
    # prefix ("basename"). It also generates a temporary file to track the
    # directory to be removed later.
    #
    # Parameters:
    #   - $1 (output_dir): The directory where the temporary directory will be
    #     created.
    #   - $2 (basename): The prefix for the temporary directory name.
    #
    # Output:
    #   - The full path to the newly created temporary directory.

    local output_dir=$1
    local basename=$2
    local temp_dir=""
    temp_dir=$(mktemp --directory \
        --tmpdir="$output_dir" "$basename.XXXXXXXX.tmp")

    # Remember to remove this directory after exit.
    item_to_remove=$(mktemp --tmpdir="$TEMP_DIR_ITEMS_TO_REMOVE")
    printf "%s$FIELD_SEPARATOR" "$temp_dir" >"$item_to_remove"

    printf "%s" "$temp_dir"
}

_get_temp_file() {
    # This function creates a temporary file in a specified temporary directory
    # and returns its path. The file is created using "mktemp", and the
    # directory for the temporary file is specified by the $TEMP_DIR_TASK
    # variable.
    #
    # Output:
    #   - The full path to the newly created temporary file.

    local temp_file=""
    temp_file=$(mktemp --tmpdir="$TEMP_DIR_TASK")

    printf "%s" "$temp_file"
}

_get_temp_file_dry() {
    # This function simulates the creation of a temporary file in a specified
    # directory without actually creating the file. It uses the "--dry-run"
    # option with "mktemp", which allows checking what the file path would be
    # if it were to be created.
    #
    # Output:
    #   - The path of the temporary file, without actually creating the file.

    local temp_file=""
    temp_file=$(mktemp --dry-run --tmpdir="$TEMP_DIR_TASK")

    printf "%s" "$temp_file"
}

_get_working_directory() {
    # This function attempts to determine the current working directory in a
    # variety of ways, based on the available environment variables or input
    # files. It first checks if the file manager (e.g., Caja, Nemo, or
    # Nautilus) provides the current URI (directory) of the script. If not, it
    # falls back to other methods. If the working directory cannot be obtained
    # from the file manager or input files, it defaults to the current
    # directory.
    #
    # Output:
    #   - The determined working directory.

    local working_directory=""

    # Try to use the information provided by the file manager.
    if [[ -v "CAJA_SCRIPT_CURRENT_URI" ]]; then
        working_directory=$CAJA_SCRIPT_CURRENT_URI
    elif [[ -v "NEMO_SCRIPT_CURRENT_URI" ]]; then
        working_directory=$NEMO_SCRIPT_CURRENT_URI
    elif [[ -v "NAUTILUS_SCRIPT_CURRENT_URI" ]]; then
        working_directory=$NAUTILUS_SCRIPT_CURRENT_URI
    fi

    if [[ -n "$working_directory" ]] &&
        [[ "$working_directory" == "file://"* ]]; then
        working_directory=$(_text_uri_decode "$working_directory")
    else
        # Files selected in the search screen (or other possible cases).
        working_directory=""
    fi

    if [[ -z "$working_directory" ]]; then
        # NOTE: The working directory can be detected by using the directory
        # name of the first input file. Some file managers do not send the
        # working directory for the scripts, so it is not precise to use the
        # 'pwd' command.
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

_is_directory_empty() {
    # This function checks if a given directory is empty.
    #
    # Parameters:
    #   - $1 (directory): The path of the directory to check.
    #
    # Returns:
    #   - "0" (true): If the directory is empty.
    #   - "1" (false): If the directory contains any files or subdirectories.

    local directory=$1

    if ! find "$directory" -mindepth 1 -maxdepth 1 -print -quit |
        grep --quiet .; then
        return 0
    fi
    return 1
}

_is_gui_session() {
    # This function checks whether the script is running in a graphical user
    # interface (GUI) session. It does so by checking if the DISPLAY
    # environment variable is set, which is typically present in GUI sessions
    # (e.g., X11 or Wayland).

    if env | grep --quiet "^DISPLAY"; then
        return 0
    fi
    return 1
}

_log_error() {
    # This function writes an error log entry with a specified message,
    # including details such as the input file, output file, and terminal
    # output. The entry is saved to a temporary log file.
    #
    # Parameters:
    #   - $1 (message): The error message to be logged.
    #   - $2 (input_file): The path of the input file associated with the
    #     operation.
    #   - $3 (std_output): The standard output or result from the operation
    #     that will be logged.
    #   - $4 (output_file): The path of the output file associated with the
    #     operation.

    local message=$1
    local input_file=$2
    local std_output=$3
    local output_file=$4

    local log_temp_file=""
    log_temp_file=$(mktemp --tmpdir="$TEMP_DIR_LOGS")

    {
        printf "[%s]\n" "$(date "+%Y-%m-%d %H:%M:%S")"
        if [[ -n "$input_file" ]]; then
            printf " > Input file: %s\n" "$input_file"
        fi
        if [[ -n "$output_file" ]]; then
            printf " > Output file: %s\n" "$output_file"
        fi
        printf " > %s\n" "Error: $message"
        if [[ -n "$std_output" ]]; then
            printf " > Standard output:\n"
            printf "%s\n" "$std_output"
        fi
        printf "\n"
    } >"$log_temp_file"
}

_logs_consolidate() {
    # This function gathers all error logs from a temporary directory and
    # compiles them into a single consolidated log file. If any error logs are
    # found, it displays an error message indicating the location of the
    # consolidated log file and terminates the script.
    #
    # Parameters:
    #   $1 (output_dir): Optional. The directory where the consolidated log
    #   file will be saved. If not specified, a default directory is used.

    local output_dir=$1
    local log_file_output="$output_dir/$PREFIX_ERROR_LOG_FILE.log"
    local log_files_count=""

    # Do nothing if there are no error log files.
    log_files_count="$(find "$TEMP_DIR_LOGS" -type f 2>/dev/null | wc -l)"
    if ((log_files_count == 0)); then
        return 0
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

    local log_file=""
    log_file=$(_str_human_readable_path "$log_file_output")
    _display_error_box "Finished with errors! See the $log_file for details."

    _exit_script
}

_move_file() {
    # This function moves a file from the source location to the destination,
    # with options to handle conflicts when the destination file already
    # exists.
    #
    # Parameters:
    #   - $1 (par_when_conflict): Optional, default: "skip". Defines the
    #     behavior when the destination file already exists.
    #     - "overwrite": Overwrite the destination file.
    #     - "rename": Rename the source file to avoid conflicts by adding a
    #       suffix to the destination filename.
    #     - "skip": Skip moving the file if the destination file exists (logs a
    #       error).
    #   - $2 (file_src): The path to the source file to be moved.
    #   - $3 (file_dst): The destination path where the file should be moved.
    #
    # Returns:
    #   - "0" (true): If the operation is successful or if the source and
    #     destination are the same file.
    #   - "1" (false): If any required parameters are missing, if the move
    #     fails, or if an invalid conflict parameter is provided.

    local par_when_conflict=${1:-"skip"}
    local file_src=$2
    local file_dst=$3

    # Check for empty parameters.
    if [[ -z "$file_src" ]] || [[ -z "$file_dst" ]]; then
        return 1
    fi

    # Add the './' prefix in the path.
    if [[ ! "$file_src" == "/"* ]] &&
        [[ ! "$file_src" == "./"* ]] && [[ ! "$file_src" == "." ]]; then
        file_src="./$file_src"
    fi
    if [[ ! "$file_dst" == "/"* ]] &&
        [[ ! "$file_dst" == "./"* ]] && [[ ! "$file_dst" == "." ]]; then
        file_dst="./$file_dst"
    fi

    # Ignore moving to the same file.
    if [[ "$file_src" == "$file_dst" ]]; then
        return 0
    fi

    # Process the parameter "when_conflict": what to do when the 'file_dst'
    # already exists.
    case "$par_when_conflict" in
    "overwrite")
        mv -f -- "$file_src" "$file_dst" 2>/dev/null
        ;;
    "rename")
        # Rename the file (add a suffix).
        file_dst=$(_get_filename_next_suffix "$file_dst")
        mv -n -- "$file_src" "$file_dst" 2>/dev/null
        ;;
    "skip")
        # Do not move the file if the destination file already exists.
        mv -n -- "$file_src" "$file_dst" 2>/dev/null
        ;;
    esac

    if [[ -e "$file_src" ]]; then
        if [[ -e "$file_dst" ]]; then
            _log_error "The destination file already exists." \
                "$file_src" "" "$file_dst"
        else
            _log_error "Unable to move." \
                "$file_src" "" "$file_dst"
        fi
        return 1
    fi

    return 0
}

_move_temp_file_to_output() {
    # This function moves a temporary file to a specified output location,
    # handling various conditions to ensure the move is safe and proper.
    #
    # Parameters:
    #   - $1 (input_file): The path to the original input file, which may be
    #     backed up during the process.
    #   - $2 (temp_file): The temporary file to be moved to the output
    #     location.
    #   - $3 (output_file): The target path where the temp file should be
    #     moved.

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

    # If 'input_file' equals 'output_file', create a backup of 'input_file'.
    if [[ "$input_file" == "$output_file" ]]; then
        _move_file "rename" "$input_file" "$input_file.bak" || return 1
    fi

    # Move the 'temp_file' to 'output_file'.
    _move_file "rename" "$temp_file" "$output_file" || return 1

    # Preserve the same permissions of 'input_file'.
    std_output=$(chmod --reference="$input_file" -- "$output_file" 2>&1)
    _check_output "$?" "$std_output" "$input_file" "$output_file" || return 1

    return 0
}

_open_items_locations() {
    # This function opens the locations of selected items in the appropriate
    # file manager.
    #
    # Parameters:
    #   - $1 (items): A space-separated list of file or directory paths whose
    #   locations will be opened. Paths can be relative or absolute.
    #   - $2 (resolve_links): A boolean-like string ("true" or "false")
    #   indicating whether symbolic links in the provided paths should be
    #   resolved to their target locations before opening.

    local items=$1
    local resolve_links=$2

    # Exit if no items are provided.
    if [[ -z "$items" ]]; then
        return
    fi

    # Detect the currently running file manager.
    local file_manager=""
    if [[ -v "CAJA_SCRIPT_SELECTED_URIS" ]]; then
        file_manager="caja"
    elif [[ -v "NEMO_SCRIPT_SELECTED_URIS" ]]; then
        file_manager="nemo"
    elif [[ -v "NAUTILUS_SCRIPT_SELECTED_URIS" ]]; then
        file_manager="nautilus"
    else
        file_manager=$(pgrep -o -l \
            "caja|dolphin|nautilus|nemo|pcmanfm|pcmanfm-qt|thunar" |
            cut -f 2 -d " ")

        # If no file manager is detected, fall back to the system default.
        if [[ -z "$file_manager" ]]; then
            file_manager=$(_xdg_get_default_app "inode/directory")
        fi
    fi

    # Restore absolute paths for items if relative paths are used.
    local working_directory=""
    working_directory=$(_get_working_directory)
    items=$(sed "s|\./|$working_directory/|g" <<<"$items")

    # Prepare items to be opened by the file manager.
    local item=""
    local items_open=""
    for item in $items; do
        # Skip the root directory ("/") since opening it is redundant.
        if [[ "$item" == "/" ]]; then
            continue
        fi

        # Resolve symbolic links to their target locations if requested.
        if [[ "$resolve_links" == "true" ]] && [[ -L "$item" ]]; then
            item=$(readlink -f "$item")
        fi
        items_open+="$item$FIELD_SEPARATOR"
    done

    # Open the items using the detected file manager.
    case "$file_manager" in
    "nautilus" | "caja" | "dolphin")
        # Open the directory of each item and select it.
        # shellcheck disable=SC2086
        $file_manager --select $items_open &
        ;;
    "nemo" | "thunar")
        # Open the directory of each item (selection not supported).
        # shellcheck disable=SC2086
        $file_manager $items_open &
        ;;
    *)
        # For other file managers (e.g., "pcmanfm-qt"), open the directory of
        # each item.
        local dir=""
        for item in $items_open; do
            # Open the directory of the item.
            dir=$(_get_filename_dir "$item")
            if [[ -z "$dir" ]]; then
                continue
            fi
            $file_manager "$dir" &
        done
        ;;
    esac
}

_pkg_get_package_manager() {
    # This function detects and returns the name of the package manager
    # available on the system.
    #
    # Output:
    #   - Prints the name of the detected package manager. Possible values are:
    #     - "apt": Indicates that "apt-get" (Debian/Ubuntu) is available.
    #     - "dnf": Indicates that "dnf" (Fedora/RHEL) is available.
    #     - "pacman": Indicates that "pacman" (Arch Linux) is available.
    #     - "zypper": Indicates that "zypper" (openSUSE) is available.
    #   - If no supported package manager is found, the output is an empty
    #     string.

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
    # This function installs specified packages using the given package
    # manager.
    #
    # Parameters:
    #   - $1 (pkg_manager): The package manager to use for installation.
    #   Supported values are:
    #       - "apt": For Debian/Ubuntu systems.
    #       - "dnf": For Fedora/RHEL systems.
    #       - "pacman": For Arch Linux systems.
    #       - "zypper": For openSUSE systems.
    #   - $2 (packages): A space-separated list of package names to install.

    local pkg_manager=$1
    local packages=$2

    _display_wait_box_message "Installing the packages. Please, wait..."

    # Install the packages.
    if ! _command_exists "pkexec"; then
        _display_error_box \
            "Could not run the installer with administrator permission!"
        _exit_script
    fi

    case "$pkg_manager" in
    "apt")
        pkexec bash -c \
            "apt-get update; apt-get -y install $packages &>/dev/null"
        ;;
    "dnf")
        pkexec bash -c \
            "dnf check-update; dnf -y install $packages &>/dev/null"
        ;;
    "pacman")
        pkexec bash -c \
            "pacman -Syy; pacman --noconfirm -S $packages &>/dev/null"
        ;;
    "zypper")
        pkexec bash -c \
            "zypper refresh; zypper --non-interactive install $packages &>/dev/null"
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
    # This function checks if a specific package is installed using the given
    # package manager.
    #
    # Parameters:
    #   - $1 (pkg_manager): The package manager to use for the check.
    #   Supported values are:
    #       - "apt": For Debian/Ubuntu systems.
    #       - "dnf": For Fedora/RHEL systems.
    #       - "pacman": For Arch Linux systems.
    #       - "zypper": For openSUSE systems.
    #   - $2 (package): The name of the package to check.
    #
    # Returns:
    #   - "0" (true): If the package is installed.
    #   - "1" (false): If the package is not installed or an error occurs.

    local pkg_manager=$1
    local package=$2

    case "$pkg_manager" in
    "apt")
        if dpkg -s "$package" &>/dev/null; then
            return 0
        fi
        ;;
    "dnf")
        if dnf repoquery --installed | grep --quiet "$package"; then
            return 0
        fi
        ;;
    "pacman")
        if pacman -Q "$package" &>/dev/null; then
            return 0
        fi
        ;;
    "zypper")
        if zypper search --installed-only "$package" | grep --quiet "^i"; then
            return 0
        fi
        ;;
    esac
    return 1
}

_run_task_parallel() {
    # This function runs a task in parallel for a set of input files, using a
    # specified output directory for results.
    #
    # Parameters:
    #   - $1 (input_files): A field-separated list of file paths to process.
    #   - $2 (output_dir): The directory where the output files will be stored.

    local input_files=$1
    local output_dir=$2

    # Allows the symbol "'" in filenames (inside 'xargs').
    input_files=$(sed -z "s|'|'\\\''|g" <<<"$input_files")

    # Export variables to be used inside new shells (when using 'xargs').
    export \
        FIELD_SEPARATOR \
        GUI_BOX_HEIGHT \
        GUI_BOX_WIDTH \
        GUI_INFO_WIDTH \
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
        _convert_delimited_string_to_text \
        _convert_text_to_delimited_string \
        _directory_pop \
        _directory_push \
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
        _is_directory_empty \
        _is_gui_session \
        _log_error \
        _main_task \
        _move_file \
        _move_temp_file_to_output \
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
    # This function clears all temporary text storage files.

    rm -f -- "$TEMP_DIR_STORAGE_TEXT/"* &>/dev/null
}

_storage_text_read_all() {
    # This function concatenates and outputs the content of all temporary text
    # storage files.

    cat -- "$TEMP_DIR_STORAGE_TEXT/"* 2>/dev/null
}

_storage_text_write() {
    # This function writes a given input text to temporary text storage files.
    #
    # Parameters:
    #   - $1 (input_text): The text to be stored in a temporary file.

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
    # This function writes a given input text, followed by a newline character,
    # to a temporary text storage file.

    local input_text=$1

    if [[ -z "$input_text" ]]; then
        return
    fi

    _storage_text_write "$input_text"$'\n'
}

_str_human_readable_path() {
    # This function transforms a given file path into a more human-readable
    # format.
    #
    # Parameters:
    #   - $1 (input_path): The input file path to process.

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
    # This function removes empty tokens from a string, ensuring it is compact
    # and well-formed.
    #
    # Parameters:
    #   - $1 (input_str): The input string containing tokens separated by
    #     $FIELD_SEPARATOR.

    local input_str=$1
    input_str=$(tr -s "$FIELD_SEPARATOR" <<<"$input_str")
    input_str=$(sed "s|$FIELD_SEPARATOR$||" <<<"$input_str")

    printf "%s" "$input_str"
}

_strip_filename_extension() {
    # This function removes the file extension from a given filename, if one
    # exists.
    #
    # Parameters:
    #   - $1 (filename): The filename from which to strip the extension.
    #
    # Returns:
    #   - The filename without its extension.

    local filename=$1
    local extension=""
    extension=$(_get_filename_extension "$filename")

    if [[ -z "$extension" ]]; then
        printf "%s" "$filename"
        return 0
    fi

    local len_extension=${#extension}
    printf "%s" "${filename::-len_extension}"
}

_text_remove_empty_lines() {
    local input_text=$1

    grep -v "^\s*$" <<<"$input_text" || true
}

_text_remove_home() {
    # This function replaces the user's home directory path in a given string
    # with the tilde ("~") symbol for brevity.
    #
    # Parameters:
    #   - $1 (input_text): The input string that may contain the user's home
    #     directory path.
    #
    # Returns:
    #   - The modified string with the home directory replaced by "~", or the
    #     original string if "$HOME" is not defined.
    #
    # Examples:
    #   - Input: "/home/user/documents/file.txt" (assuming $HOME is
    #     "/home/user")
    #   - Output: "~/documents/file.txt"
    #
    #   - Input: "/etc/config" (assuming $HOME is "/home/user")
    #   - Output: "/etc/config"

    local input_text=$1

    if [[ -n "$HOME" ]]; then
        sed "s|$HOME|~|g" <<<"$input_text"
    else
        printf "%s" "$input_text"
    fi
}

_text_remove_pwd() {
    # This function replaces the current working directory path in a given
    # string with a dot (".") for brevity.
    #
    # Parameters:
    #   - $1 (input_text): The input string that may contain the current
    #     working directory path.
    #
    # Returns:
    #   - The modified string with the working directory replaced by ".", or
    #     the original string if the working directory is not found.
    #
    # Examples:
    #   - Input: "/home/user/project/file.txt" (assuming current directory is
    #     "/home/user/project")
    #   - Output: "./file.txt"
    #
    #   - Input: "/etc/config" (assuming current directory is
    #     "/home/user/project")
    #   - Output: "/etc/config"

    local input_text=$1
    local working_directory=""
    working_directory=$(_get_working_directory)

    sed "s|$working_directory|.|g" <<<"$input_text"
}

_text_sort() {
    # This function sorts the lines of a given text input in a version-aware
    # manner.
    #
    # Parameters:
    #   - $1 (input_text): The input text to be sorted, where each line is
    #     treated as a separate string.
    #
    # Returns:
    #   - The sorted text with each line in the correct order.

    local input_text=$1

    sort --version-sort <<<"$input_text"
}

_text_uri_decode() {
    # This function decodes a URI-encoded string by converting percent-encoded
    # characters back to their original form.
    #
    # Parameters:
    #   - $1 (uri_encoded): The URI-encoded string that needs to be decoded.
    #
    # Returns:
    #   - The decoded URI string, with percent-encoded characters replaced and
    #     the "file://" prefix removed.
    #
    # Example:
    #   - Input: "file:///home/user%20name/file%20name.txt"
    #   - Output: "/home/user name/file name.txt"

    local uri_encoded=$1

    uri_encoded=${uri_encoded//%/\\x}
    uri_encoded=${uri_encoded//file:\/\//}

    # shellcheck disable=SC2059
    printf "$uri_encoded"
}

_unset_global_variables_file_manager() {
    # This function unset global variables that may have been set by different
    # file managers (Caja, Nautilus, Nemo) during script execution.

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
    # This function checks if there are any files with the same base name in
    # the provided list of input files.
    #
    # Parameters:
    #   - $1 (input_files): A string containing a list of file paths, where
    #       each file path can include extensions. This list is checked for
    #       duplicates based on the base file name (excluding extensions).
    #
    # Example:
    #   - Input: "file1.txt file2.txt file1.jpg"
    #   - Output: An error box will be displayed indicating that "file1" is
    #     duplicated.

    local input_files=$1
    local dup_files=""

    dup_files=$(printf "%s" "$input_files" | tr "$FIELD_SEPARATOR" "\0" |
        sed --null-data "s|/\.|//|" | # Ignore hidden files without extension.
        sed --regexp-extended --null-data \
            "s|(\.tar)?\.[a-z0-9_~-]{0,15}$||I" | # Remove file extensions.
        sort --zero-terminated --version-sort |   # Sort files.
        uniq --zero-terminated --repeated)        # Find duplicate base names.

    # If duplicates are found, display an error and exit the script.
    if [[ -n "$dup_files" ]]; then
        _display_error_box "There are selected files with the same base name!"
        _exit_script
    fi
}

_validate_file_mime() {
    # This function validates the MIME type of a given file against a specified
    # MIME type pattern.
    #
    # Parameters:
    #   - $1 (input_file): The path to the file that is being validated. This
    #       is the file whose MIME type will be checked.
    #   - $2 (par_select_mime): The MIME type pattern (or regular expression)
    #       to compare the file's MIME type against. If no MIME type pattern is
    #       provided, no validation occurs.
    #
    # Example:
    #   - Input: File path "example.txt", MIME pattern "text/plain"
    #   - Output: If the MIME type of "example.txt" is "text/plain", the file
    #       name will be written to storage.

    local input_file=$1
    local par_select_mime=$2

    # Validation for files (mime).
    if [[ -n "$par_select_mime" ]]; then
        local file_mime=""
        file_mime=$(_get_file_mime "$input_file")
        par_select_mime=${par_select_mime//+/\\+}
        grep --quiet --ignore-case --perl-regexp \
            "($par_select_mime)" <<<"$file_mime" || return
    fi

    # Create a temp file containing the name of the valid file.
    _storage_text_write "$input_file$FIELD_SEPARATOR"
}

_validate_file_mime_parallel() {
    # This function validates the MIME type of a list of files in parallel,
    # based on a specified MIME type pattern.
    #
    # Parameters:
    #   - $1 (input_files): A space-separated string containing the paths of
    #     the files to validate. These files will be checked for the MIME type
    #     pattern.
    #   - $2 (par_select_mime): The MIME type pattern (or regular expression)
    #     to compare the files' MIME types against. If this parameter is empty,
    #     the function returns the input files without any MIME type
    #     validation.
    #
    # Example:
    #   - Input: File paths "file1.txt file2.png", MIME pattern "text/plain".
    #   - Output: If "file1.txt" has a MIME type of "text/plain", it will be
    #     included in the output, but "file2.png" will be excluded if its MIME
    #     type doesn't match.

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

    # Execute the function '_validate_file_mime' for each file in parallel
    # (using 'xargs').
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
    # This function filters a list of files or directories based on various
    # user-specified criteria, such as file type, extensions, and recursion.
    #
    # Parameters:
    #   - $1 (input_files): A space-separated string containing file or
    #     directory paths to filter. These paths are passed to the "find"
    #     command.
    #   - $2 (par_type): A string specifying the type of file to search for. It
    #     can be:
    #     - "file": To search for files and symbolic links.
    #     - "directory": To search for directories and symbolic links.
    #   - $3 (par_skip_extension): A string of file extensions to exclude from
    #     the search. Only files with extensions not matching this list will be
    #     included.
    #   - $4 (par_select_extension): A string of file extensions to include in
    #     the search. Only files with matching extensions will be included.
    #   - $5 (par_recursive): A boolean string ("true" or any other value)
    #     indicating whether to search directories recursively. If set to
    #     "true", directories will be searched recursively; otherwise, only the
    #     immediate directory level will be searched.
    #
    # Example:
    #   - Input: "dir1 dir2", "file", "", "txt|pdf", "true"
    #   - Output: A list of files with extensions ".txt" or ".pdf" from the
    #     directories "dir1" and "dir2", searched recursively.

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
    find_command+=" -print0"

    # shellcheck disable=SC2086
    input_files_valid=$(eval $find_command 2>/dev/null |
        tr "\0" "$FIELD_SEPARATOR")
    input_files_valid=$(_str_remove_empty_tokens "$input_files_valid")

    # Create a temp file containing the name of the valid file.
    printf "%s" "$input_files_valid"
}

_validate_files_count() {
    # This function validates the number of selected files or directories based
    # on several criteria, such as type, extension, MIME type, and minimum or
    # maximum item count.
    #
    # Parameters:
    #   - $1 (input_files): A space-separated string containing the paths of
    #     files or directories to be validated.
    #   - $2 (par_type): A string indicating the type of items to validate.
    #     Possible values:
    #     - "file": Validate files only.
    #     - "directory": Validate directories only.
    #     - "all": Validate both files and directories.
    #   - $3 (par_select_extension): A pipe-separated list of file extensions
    #     to filter the files. Files must have one of these extensions.
    #   - $4 (par_select_mime): A string representing MIME types to filter the
    #     files by. Only files with matching MIME types are selected.
    #   - $5 (par_min_items): The minimum number of valid items required. If
    #     fewer valid items are selected, an error is displayed.
    #   - $6 (par_max_items): The maximum number of valid items allowed. If
    #     more valid items are selected, an error is displayed.
    #   - $7 (par_recursive): A string indicating whether the validation should
    #     be recursive. If "true", directories will be searched recursively.
    #
    # Example:
    #   - Input: "dir1 dir2", "file", "txt|pdf", "", 1, 5, "true"
    #   - Output: The function checks if the directories "dir1" and "dir2"
    #     contain at least 1 and no more than 5 ".txt" or ".pdf" files,
    #     recursively.

    local input_files=$1
    local par_type=$2
    local par_select_extension=$3
    local par_select_mime=$4
    local par_min_items=$5
    local par_max_items=$6
    local par_recursive=$7

    # Define a label for a valid file.
    local valid_file_label="valid files"
    if [[ "$par_type" == "directory" ]]; then
        valid_file_label="directories"
    elif [[ -n "$par_select_mime" ]]; then
        valid_file_label="$par_select_mime"
        valid_file_label=$(sed "s|\|| or |g" <<<"$par_select_mime")
        valid_file_label=$(sed "s|/$||g; s|/ | |g" <<<"$valid_file_label")
        valid_file_label+=" files"
    elif [[ "$par_type" == "file" ]]; then
        valid_file_label="files"
    elif [[ "$par_type" == "all" ]]; then
        valid_file_label="files or directories"
    fi

    # Count the number of valid files.
    local valid_items_count=0
    valid_items_count=$(_get_items_count "$input_files")

    # Define a label for the extension.
    local extension_label=""
    if [[ -n "$par_select_extension" ]]; then
        extension_label="'.${par_select_extension//|/\' or \'.}'"
    fi

    # Check if there is at least one valid file.
    if ((valid_items_count == 0)); then
        if [[ "$par_recursive" == "true" ]]; then
            if [[ -n "$par_select_extension" ]]; then
                _display_error_box \
                    "No files with extension: $extension_label were selected!"
            else
                _display_error_box "No $valid_file_label were selected!"
            fi
        else
            if [[ -n "$par_select_extension" ]]; then
                _display_error_box \
                    "You must select files with extension: $extension_label!"
            else
                _display_error_box "You must select $valid_file_label!"
            fi
        fi
        _exit_script
    fi

    if [[ -n "$par_min_items" ]] && ((valid_items_count < par_min_items)); then
        _display_error_box \
            "You must select at least $par_min_items $valid_file_label!"
        _exit_script
    fi

    if [[ -n "$par_max_items" ]] && ((valid_items_count > par_max_items)); then
        _display_error_box \
            "You must select up to $par_max_items $valid_file_label!"
        _exit_script
    fi
}

_xdg_get_default_app() {
    # This function retrieves the default application associated with a
    # specific MIME type on a Linux system using the "xdg-mime" command.
    #
    # Parameters:
    #   - $1 (mime): The MIME type (e.g., "application/pdf", "image/png") for
    #     which to find the default application.
    #
    # Example:
    #   - Input: "application/pdf"
    #   - Output: The function prints the default application's executable for
    #     opening PDF files (e.g., "evince" or "okular").

    local mime=$1
    local desktop_file=""
    local default_app=""

    desktop_file=$(xdg-mime query default "$mime" 2>/dev/null)

    default_app=$(grep -m1 "^Exec" "/usr/share/applications/$desktop_file" |
        sed "s|Exec=||g" | cut -d " " -f 1)

    if [[ -z "$default_app" ]]; then
        _display_error_box \
            "Could not find the default application to open '$mime' files!"
        _exit_script
    fi

    printf "%s" "$default_app"
}

# -----------------------------------------------------------------------------
# INCLUDE HELPER SCRIPTS
# -----------------------------------------------------------------------------

if [[ -f "$ROOT_DIR/.helper-scripts/accessed-recently.sh" ]]; then
    #shellcheck source=.helper-scripts/accessed-recently.sh
    source "$ROOT_DIR/.helper-scripts/accessed-recently.sh"
fi
