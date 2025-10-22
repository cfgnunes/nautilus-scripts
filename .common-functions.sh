#!/usr/bin/env bash
# shellcheck disable=SC2001

# This file contains shared functions and constants sourced by all scripts.

# =============================================================================
# PROJECT: Enhanced File Manager Actions for Linux
# AUTHOR: Cristiano Fraga G. Nunes
# REPOSITORY: https://github.com/cfgnunes/nautilus-scripts
# LICENSE: MIT License
# VERSION: 25.3.2
# =============================================================================

set -u

# -----------------------------------------------------------------------------
# SECTION: Constants ----
# -----------------------------------------------------------------------------

ACCESSED_RECENTLY_DIR="$ROOT_DIR/Accessed recently"
ACCESSED_RECENTLY_LINKS_TO_KEEP=10
FIELD_SEPARATOR=$'\r'          # The main field separator.
GUI_BOX_HEIGHT=550             # Height of the GUI dialog boxes.
GUI_BOX_WIDTH=900              # Width of the GUI dialog boxes.
GUI_INFO_WIDTH=400             # Width of the GUI small dialog boxes.
IGNORE_FIND_PATH="*.git/*"     # Path to ignore in the 'find' command.
PREFIX_ERROR_LOG_FILE="Errors" # Basename of 'Error' log file.
PREFIX_OUTPUT_DIR="Output"     # Basename of 'Output' directory.

# Temporary directories.
TEMP_DIR=$(mktemp --directory)
TEMP_DIR_ITEMS_TO_REMOVE="$TEMP_DIR/items_to_remove"
TEMP_DIR_LOGS="$TEMP_DIR/logs"
TEMP_DIR_FILENAME_LOCKS="$TEMP_DIR/filename_locks"
TEMP_DIR_STORAGE_TEXT="$TEMP_DIR/storage_text"
TEMP_DIR_TASK="$TEMP_DIR/task"

# Temporary files.
TEMP_CONTROL_BATCH_ENABLED="$TEMP_DIR/control_batch_enabled"
TEMP_CONTROL_DISPLAY_LOCKED="$TEMP_DIR/control_display_locked"
TEMP_CONTROL_WAIT_BOX="$TEMP_DIR/control_wait_box"
TEMP_CONTROL_WAIT_BOX_FIFO="$TEMP_DIR/control_wait_box_fifo"
TEMP_CONTROL_WAIT_BOX_KDIALOG="$TEMP_DIR/control_wait_box_kdialog"
TEMP_DATA_TEXT_BOX="$TEMP_DIR/data_text_box"

# Message tags for displaying status messages on terminal.
MSG_ERROR="[\033[0;31mFAILED\033[0m]"
MSG_INFO="[\033[0;32m INFO \033[0m]"

# Defines the priority order of package managers.
PKG_MANAGER_PRIORITY=(
    "brew"
    "nix"
    "apt-get"
    "rpm-ostree"
    "dnf"
    "pacman"
    "zypper"
    "guix"
)

readonly \
    ACCESSED_RECENTLY_DIR \
    ACCESSED_RECENTLY_LINKS_TO_KEEP \
    FIELD_SEPARATOR \
    GUI_BOX_HEIGHT \
    GUI_BOX_WIDTH \
    GUI_INFO_WIDTH \
    IGNORE_FIND_PATH \
    PKG_MANAGER_PRIORITY \
    PREFIX_ERROR_LOG_FILE \
    PREFIX_OUTPUT_DIR \
    TEMP_CONTROL_DISPLAY_LOCKED \
    TEMP_CONTROL_WAIT_BOX \
    TEMP_CONTROL_WAIT_BOX_FIFO \
    TEMP_CONTROL_WAIT_BOX_KDIALOG \
    TEMP_DATA_TEXT_BOX \
    TEMP_DIR \
    TEMP_DIR_FILENAME_LOCKS \
    TEMP_DIR_ITEMS_TO_REMOVE \
    TEMP_DIR_LOGS \
    TEMP_DIR_STORAGE_TEXT \
    TEMP_DIR_TASK

# -----------------------------------------------------------------------------
# SECTION: Global variables ----
# -----------------------------------------------------------------------------

IFS=$FIELD_SEPARATOR
INPUT_FILES=$*

# Variable used to share data between specific parallel task functions
# (e.g., passwords, configuration values).
TEMP_DATA_TASK=""

# -----------------------------------------------------------------------------
# SECTION: Build the structure of the '$TEMP_DIR' ----
# -----------------------------------------------------------------------------

# DESCRIPTION:
#
#   '$TEMP_DIR_FILENAME_LOCKS':
#       This directory is used to store temporary lock directories created by
#       the '_get_filename_next_suffix' function during concurrent executions.
#       Each process creates a uniquely named subdirectory here (using
#       'mkdir'), which acts as a lightweight synchronization mechanism. The
#       idea to prevent name conflicts by race conditions when multiple
#       processes attempt to generate filenames simultaneously.
#
#   '$TEMP_DIR_ITEMS_TO_REMOVE':
#       This directory is used for temporary items scheduled for removal after
#       the scripts' tasks finish executing.
#
#   '$TEMP_DIR_LOGS'
#       This directory stores temporary error logs generated during
#       the execution of the scripts.
#
#   '$TEMP_DIR_STORAGE_TEXT':
#       This directory stores text files from output data produced by parallel
#       tasks during the execution of the scripts.
#
#   '$TEMP_DIR_TASK':
#       This directory is used by the '_make_temp_dir' and '_make_temp_file'
#       functions to store temporary files created during the scripts' tasks.

mkdir -p "$TEMP_DIR_FILENAME_LOCKS"
mkdir -p "$TEMP_DIR_ITEMS_TO_REMOVE"
mkdir -p "$TEMP_DIR_LOGS"
mkdir -p "$TEMP_DIR_STORAGE_TEXT"
mkdir -p "$TEMP_DIR_TASK"

# -----------------------------------------------------------------------------
# SECTION: Core utilities ----
# -----------------------------------------------------------------------------

# FUNCTION: _cleanup_on_exit
#
# DESCRIPTION:
# This function performs cleanup tasks when the script exits. It is
# designed to safely and efficiently remove temporary directories or files
# that were created during the script's execution.
_cleanup_on_exit() {
    # Remove local temporary dirs or files.
    local items_to_remove=""
    items_to_remove=$(cat -- "$TEMP_DIR_ITEMS_TO_REMOVE/"* 2>/dev/null)

    # Escape single quotes in filenames to handle them correctly in 'xargs'
    # with 'bash -c'.
    items_to_remove=$(sed -z "s|'|'\\\''|g" <<<"$items_to_remove")

    printf "%s" "$items_to_remove" | xargs \
        --no-run-if-empty \
        --delimiter="$FIELD_SEPARATOR" \
        --max-procs="$(_get_max_procs)" \
        --replace="{}" \
        bash -c "{ chmod -R u+rw -- '{}' && rm -rf -- '{}'; } 2>/dev/null"

    # Remove the main temporary dir.
    rm -rf -- "$TEMP_DIR" 2>/dev/null

    if ! _is_gui_session; then
        echo -e "$MSG_INFO End." >&2
    fi
}
trap _cleanup_on_exit EXIT

# FUNCTION: _exit_script
#
# DESCRIPTION:
# This function is responsible for safely exiting the script by terminating all
# child processes associated with the current script and printing an exit
# message to the terminal.
_exit_script() {
    _close_wait_box

    local child_pids=""
    local script_pid=$$

    # Get the process ID (PID) of all child processes.
    child_pids=$(pstree -p "$script_pid" |
        grep --only-matching --perl-regexp "\(+\K[^)]+")

    # NOTE: Use 'xargs' and kill to send the SIGTERM signal to all child
    # processes, including the current script.
    # See the: https://www.baeldung.com/linux/safely-exit-scripts
    xargs kill <<<"$child_pids" 2>/dev/null
}

# FUNCTION: _check_output
#
# DESCRIPTION:
# This function validates the success of a command or process based on its
# exit code and output. It logs errors if the command fails or if an
# expected output file is missing.
#
# PARAMETERS:
#   $1 (exit_code): The exit code returned by the command or process.
#   $2 (std_output): The standard output or error from the command.
#   $3 (input_file): The input file associated (if applicable).
#   $4 (output_file): The expected output file to verify its existence.
#
# RETURNS:
#   "0" (true): If the command was successful and the output file exists.
#   "1" (false): If the command failed or the output file does not exist.
_check_output() {
    local exit_code=$1
    local std_output=$2
    local input_file=$3
    local output_file=$4

    # Check the '$exit_code' and log the error.
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

# FUNCTION: _log_error
#
# DESCRIPTION:
# This function writes an error log entry with a specified message,
# including details such as the input file, output file, and terminal
# output. The entry is saved to a temporary log file.
#
# PARAMETERS:
#   $1 (message): The error message to be logged.
#   $2 (input_file): The path of the input file associated with the
#      operation.
#   $3 (std_output): The standard output or result from the operation
#      that will be logged.
#   $4 (output_file): The path of the output file associated with the
#      operation.
_log_error() {
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

# FUNCTION: _logs_consolidate
#
# DESCRIPTION:
# This function gathers all error logs from a temporary directory and
# compiles them into a single consolidated log file. If any error logs are
# found, it displays an error message indicating the location of the
# consolidated log file and terminates the script.
#
# PARAMETERS:
#   $1 (output_dir): Optional. The directory where the consolidated log
#      file will be saved. If not specified, a default directory is used.
_logs_consolidate() {
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

# FUNCTION: _run_task_parallel
#
# DESCRIPTION:
# This function runs a task in parallel for a set of input files, using a
# specified output directory for results.
#
# PARAMETERS:
#   $1 (input_files): A field-separated list of file paths to process.
#   $2 (output_dir): The directory where the output files will be stored.
_run_task_parallel() {
    local input_files=$1
    local output_dir=$2

    # Execute the function '_main_task' for each file in parallel.
    export -f _main_task
    _run_function_parallel \
        "_main_task '{}' '$output_dir'" "$input_files" "$FIELD_SEPARATOR"
}

# FUNCTION: _run_function_parallel
#
# DESCRIPTION:
# This function executes a given Bash expression or command in parallel for
# a list of input items. It uses 'xargs' to distribute execution across
# multiple processes, allowing concurrent processing and improved performance
# on multi-core systems.
#
# PARAMETERS:
#   $1 (expression): The Bash expression or command to execute for each item.
#      The '{}' placeholder inside the expression will be replaced by the
#      current item being processed.
#   $2 (items): A list of items to process, separated by the char delimiter.
#   $3 (delimiter): The character used to separate items in the input list.
_run_function_parallel() {
    local expression=$1
    local items=$2
    local delimiter=$3

    # Export necessary environment variables so they are available
    # within each subshell created by 'xargs'.
    export \
        FIELD_SEPARATOR \
        GUI_BOX_HEIGHT \
        GUI_BOX_WIDTH \
        GUI_INFO_WIDTH \
        IGNORE_FIND_PATH \
        INPUT_FILES \
        TEMP_CONTROL_DISPLAY_LOCKED \
        TEMP_DATA_TASK \
        TEMP_DATA_TEXT_BOX \
        TEMP_DIR_FILENAME_LOCKS \
        TEMP_DIR_ITEMS_TO_REMOVE \
        TEMP_DIR_LOGS \
        TEMP_DIR_STORAGE_TEXT \
        TEMP_DIR_TASK

    # Export functions so they can be called inside
    # the parallel subprocesses executed by 'bash -c'.
    export -f \
        _check_output \
        _cmd_magick_convert \
        _command_exists \
        _convert_delimited_string_to_text \
        _convert_text_to_delimited_string \
        _directory_pop \
        _directory_push \
        _display_lock \
        _display_unlock \
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
        _make_temp_dir \
        _make_temp_dir_local \
        _make_temp_file \
        _get_working_directory \
        _is_directory_empty \
        _is_gui_session \
        _log_error \
        _move_file \
        _storage_text_write \
        _storage_text_write_ln \
        _str_collapse_char \
        _strip_filename_extension \
        _text_remove_empty_lines \
        _text_remove_pwd \
        _text_uri_decode

    # Escape single quotes in items to handle them correctly in 'xargs'
    # with 'bash -c'.
    items=$(sed -z "s|'|'\\\''|g" <<<"$items")

    # Execute the given expression in parallel for each item.
    printf "%s" "$items" | xargs \
        --no-run-if-empty \
        --delimiter="$delimiter" \
        --max-procs="$(_get_max_procs)" \
        --replace="{}" \
        bash -c "$expression"
}

# -----------------------------------------------------------------------------
# SECTION: Dependency management ----
# -----------------------------------------------------------------------------

# FUNCTION: _command_exists
#
# DESCRIPTION:
# This function checks whether a given command is available on the system.
#
# PARAMETERS:
#   $1 (command_check): The name of the command to verify.
#
# RETURNS:
#   "0" (true): If the command is available.
#   "1" (false): If the command is not available.
_command_exists() {
    local command_check=$1

    command -v "$command_check" &>/dev/null || return 1
}

# FUNCTION: _check_dependencies_clipboard
#
# DESCRIPTION:
# This function ensures that clipboard-related dependencies are available
# according to the current display session type (Wayland or X11). Detects the
# session type and adds the proper clipboard tool ('wl-paste' for Wayland or
# 'xclip' for X11) to the dependency list.
#
# PARAMETERS:
#   $1 (dep_keys): Base list of dependency keys to check before adding
#   session-specific clipboard dependencies.
_check_dependencies_clipboard() {
    local dep_keys=$1
    local dep_keys_final="$dep_keys "

    # Try to determine the session type.
    local session_type="${XDG_SESSION_TYPE:-}"

    # Fallback detection in case '$XDG_SESSION_TYPE' is empty.
    if [[ -z "$session_type" ]]; then
        if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
            session_type="wayland"
        elif [[ -n "${DISPLAY:-}" ]]; then
            session_type="x11"
        fi
    fi

    case "$session_type" in
    "wayland") dep_keys_final+="wl-paste" ;;
    "x11") dep_keys_final+="xclip" ;;
    *)
        _display_error_box \
            "Your session type is not supported for clipboard operations."
        _exit_script
        ;;
    esac

    _check_dependencies "$dep_keys_final"
}

# FUNCTION: _check_dependencies
#
# DESCRIPTION:
# This function ensures that all required dependencies are available for the
# scripts. Checks each dependency key, determines the correct package for the
# active package manager, and installs missing packages if necessary.
#
# PARAMETERS:
#   $1 (dep_keys): A list of dependency keys. The list can be delimited either
#      by a space ' ', a comma ',' or by a newline '\n'. These keys and its
#      values are defined on file '.dependencies.sh'.
_check_dependencies() {
    local dep_keys=$1

    [[ -z "$dep_keys" ]] && return

    # Step 1: Normalize and remove duplicates from the dependency list.
    dep_keys=$(tr "\n" " " <<<"$dep_keys")
    dep_keys=$(tr "," " " <<<"$dep_keys")
    dep_keys=$(_str_sort "$dep_keys" " " "true")

    # List of pairs in the format "<pkg_manager>:<package>".
    local pairs=""

    # Step 2: Resolve the package names for each dependency key.
    #
    # This creates a list of pairs in the format "<pkg_manager>:<package>".
    # The first available package manager in '$PKG_MANAGER_PRIORITY'
    # that provides the dependency definition will be used.
    dep_keys=$(tr " " "$FIELD_SEPARATOR" <<<"$dep_keys")
    local dep_key=""
    for dep_key in $dep_keys; do
        local package_names=""
        _command_exists "$dep_key" && continue

        # Try to find a defined package for an available package manager.
        local definitions_found="false"
        local pkg_manager=""
        for pkg_manager in "${PKG_MANAGER_PRIORITY[@]}"; do
            if ! _command_exists "$pkg_manager"; then
                continue
            fi

            # Retrieve the package names from '.dependencies.sh'.
            package_names=$(_deps_get_dependency_value \
                "$dep_key" "$pkg_manager" "DEPENDENCIES_MAP")

            if [[ -n "$package_names" ]]; then
                definitions_found="true"
                break
            fi
        done
        # Abort if no package definition was found.
        if [[ "$definitions_found" == "false" ]]; then
            _display_error_box "Could not find package names to install dependency '$dep_key'!"
            _exit_script
        fi

        # Append resolved packages as "<pkg_manager>:<package>" pairs.
        if [[ -n "$package_names" ]]; then
            package_names=$(sed "s|^|$pkg_manager:|g" <<<"$package_names")
            package_names=$(sed "s| | $pkg_manager:|g" <<<"$package_names")
            pairs+=" $package_names"
        fi
    done

    # Sort and prepare the list of package pairs.
    pairs=$(_str_sort "$pairs" " " "true")

    # Step 3: Verify which packages need installation.
    local post_install_full=""
    local packages_install=""

    # Iterate over each "<pkg_manager>:<package>" pair.
    pairs=$(tr " " "$FIELD_SEPARATOR" <<<"$pairs")
    local pair=""
    for pair in $pairs; do
        local pkg_manager="${pair%%:*}"
        local package="${pair#*:}"
        local post_install=""

        # Skip if the command or package is already available.
        if _command_exists "$package" ||
            _deps_is_package_installed "$pkg_manager" "$package"; then
            continue
        fi

        # Retrieve optional post-install command.
        post_install=$(_deps_get_dependency_value \
            "$package" "$pkg_manager" "POST_INSTALL")

        # Add package and post-install commands to the respective lists.
        [[ -n "$package" ]] && packages_install+=" $pkg_manager:$package"
        if [[ -n "$post_install" ]]; then
            # Append post-install commands. Each entry must follow the format
            # "<pkg_manager>:<commands>" and be separated by '\n'.
            post_install_full+="$pkg_manager:$post_install;"$'\n'
        fi
    done

    # Step 4: Install missing packages and execute post-install actions.
    _deps_install_missing_packages "$packages_install" "$post_install_full"
}

# FUNCTION: _deps_get_dependency_value
#
# DESCRIPTION:
#   Retrieves the value associated with a specific key–subkey pair from an
#   associative array.
#
# PARAMETERS:
#   $1 (key): The key whose value is being queried.
#   $2 (pkg_manager): The package manager to match.
#   $3 (input_array): The name of the associative array that contains
#      the mappings (<subkey>:<value> pairs).
#
# RETURNS:
#   "0" (true): If a matching value is found and printed.
#   "1" (false): If no matching value is found.
_deps_get_dependency_value() {
    local key=$1
    local pkg_manager=$2
    local -n input_array=$3
    local pairs=""

    # Source the configuration file that defines the mapping between commands,
    # packages, and package managers. This file is used by the scripts to check
    # and resolve their own dependencies.
    if [[ ! -v "PACKAGE_NAME" ]]; then
        source "$ROOT_DIR/.dependencies.sh"
    fi

    # Retrieve the raw value from the associative array.
    pairs=${input_array[$key]:-}

    # Remove leading, trailing, and duplicate spaces.
    pairs=$(_str_collapse_char "$pairs" " ")

    # If the key does not exist or has no associated values, return failure.
    if [[ -z "$pairs" ]]; then
        return 0
    fi

    # Replace newlines with '$FIELD_SEPARATOR' for iteration.
    pairs=$(tr "\n" "$FIELD_SEPARATOR" <<<"$pairs")

    # Iterate over each <package_manager>:<key_value> pair.
    local pair=""
    for pair in $pairs; do
        local subkey="${pair%%:*}"
        local value="${pair#*:}"

        # Remove leading, trailing, and duplicate spaces.
        subkey=$(_str_collapse_char "$subkey" " ")
        value=$(_str_collapse_char "$value" " ")

        # Map equivalent package managers for compatibility.
        case "$subkey:$pkg_manager" in
        "apt:apt-get" | "dnf:rpm-ostree")
            subkey=$pkg_manager
            ;;
        esac

        # Special handling for Termux (Android). Since Termux (on Android) uses
        # its own package ecosystem and may share paths with 'proot-distro'
        # containers, we ensure it's a real Termux session by checking that
        # '$HOME' contains "com.termux", the package manager is "pkg", and the
        # system reports "Android".
        if [[ "$subkey" == "pkg" ]] && [[ "${HOME:-}" == *"com.termux"* ]] &&
            [[ "$(uname -o)" == "Android" ]]; then
            printf "%s" "$value"
            return 0
        fi

        # If the package manager matches, print and exit successfully.
        if [[ "$subkey" == "$pkg_manager" ]] || [[ "$subkey" == "*" ]]; then
            printf "%s" "$value"
            return 0
        fi
    done

    # If no match was found, return failure.
    return 1
}

# FUNCTION: _deps_install_missing_packages
_deps_install_missing_packages() {
    local packages_install=$1
    local post_install=$2

    [[ -z "$packages_install" ]] && return

    # Remove leading, trailing, and duplicate spaces.
    packages_install=$(_str_collapse_char "$packages_install" " ")

    # Format the package names for display.
    local pkg_names=""
    pkg_names=$(tr " " "\n" <<<"$packages_install")
    pkg_names=$(sed "s|~[^\n]*||g" <<<"$pkg_names")
    pkg_names=$(sed "s|^\([a-z-]*\):\(.*\)|- \2 (\1)|g" <<<"$pkg_names")

    local message="The following packages are missing:"$'\n'
    message+="$pkg_names"
    message+=$'\n'$'\n'
    message+="Would you like to install them?"
    if ! _display_question_box "$message"; then
        _exit_script
    fi
    _deps_install_packages "$packages_install" "$post_install"
    _deps_installation_check "$packages_install"
}

# FUNCTION: _deps_install_packages
#
# DESCRIPTION:
# This function installs specified packages using the corresponding
# package manager defined for each one. The input list must contain
# pairs in the format "<pkg_manager>:<package>" separated by spaces.
#
# Example:
# _deps_install_packages "apt-get:curl dnf:wget brew:git"
#
# Supported package managers:
# - "apt-get"     : For Debian/Ubuntu systems.
# - "dnf"         : For Fedora/RHEL systems.
# - "rpm-ostree"  : For Fedora Atomic systems.
# - "pacman"      : For Arch Linux systems.
# - "zypper"      : For openSUSE systems.
# - "nix"         : For Nix-based systems.
# - "brew"        : For Homebrew package manager.
# - "guix"        : For GNU Guix systems.
#
# PARAMETERS:
#   $1 (pkg_list): A space-separated list of "<pkg_manager>:<package>" pairs.
#   $2 (post_install): Optional command executed after all installations.
_deps_install_packages() {
    local pairs=$1
    local post_install=$2
    local cmd_admin=""
    local cmd_admin_available=""
    local cmd_inst=""
    local -A pkg_map=()

    # Replace spaces with '$FIELD_SEPARATOR' for iteration.
    pairs=$(tr " " "$FIELD_SEPARATOR" <<<"$pairs")

    # Build a map of <pkg_manager> -> "pkg1 pkg2 ...".
    local pair=""
    for pair in $pairs; do
        local pkg_manager="${pair%%:*}"
        local package="${pair#*:}"
        pkg_map["$pkg_manager"]+="$package "
    done

    # Determine admin command.
    if ! _is_gui_session; then
        _command_exists "sudo" && cmd_admin_available="sudo"
    else
        _command_exists "pkexec" && cmd_admin_available="pkexec"
    fi

    _display_wait_box_message "Installing the packages. Please, wait..." "0"

    # Iterate over each detected package manager.
    for pkg_manager in "${!pkg_map[@]}"; do
        local packages="${pkg_map[$pkg_manager]}"
        packages=$(_str_collapse_char "$packages" " ")
        [[ -z "$packages" ]] && continue

        cmd_inst=""
        cmd_admin="$cmd_admin_available"

        # Define installation commands depending on the package manager.
        case "$pkg_manager" in
        "apt-get")
            cmd_inst+="apt-get update &>/dev/null;"
            cmd_inst+="apt-get -y install $packages &>/dev/null"
            ;;
        "dnf")
            cmd_inst+="dnf check-update &>/dev/null;"
            cmd_inst+="dnf -y install $packages &>/dev/null"
            ;;
        "rpm-ostree")
            cmd_inst+="rpm-ostree install $packages &>/dev/null"
            ;;
        "pacman")
            cmd_inst+="pacman -Syy &>/dev/null;"
            cmd_inst+="pacman --noconfirm -S $packages &>/dev/null"
            ;;
        "zypper")
            cmd_inst+="zypper refresh &>/dev/null;"
            cmd_inst+="zypper --non-interactive install $packages &>/dev/null"
            ;;
        "nix")
            local nix_packages=""
            local nix_channel="nixpkgs"
            if grep --quiet "ID=nixos" /etc/os-release 2>/dev/null; then
                nix_channel="nixos"
            fi

            # Prefix packages with their channel namespace.
            nix_packages="$nix_channel.$packages"
            nix_packages=$(sed "s| $||g" <<<"$nix_packages")
            nix_packages=$(sed "s| | $nix_channel.|g" <<<"$nix_packages")

            cmd_inst+="nix-env -iA $nix_packages &>/dev/null"
            # Nix does not require root for installing user packages.
            cmd_admin=""
            ;;
        "brew")
            # Configure Homebrew for non-interactive and less verbose
            # operation.
            export HOMEBREW_VERBOSE=""
            export HOMEBREW_NO_ANALYTICS="1"
            export HOMEBREW_NO_AUTO_UPDATE="1"
            export HOMEBREW_NO_COLOR="1"
            export HOMEBREW_NO_EMOJI="1"
            export HOMEBREW_NO_ENV_HINTS="1"
            export HOMEBREW_NO_GITHUB_API="1"

            # Replace spaces with '$FIELD_SEPARATOR' for iteration.
            packages=$(tr " " "$FIELD_SEPARATOR" <<<"$packages")

            # Homebrew: prioritize precompiled bottles instead of source
            # builds. Dependencies are installed first, followed by the main
            # packages.

            # Each package is installed separately because installing multiple
            # packages at once can break dependency resolution when using
            # '--force-bottle'.
            local pkg=""
            for pkg in $packages; do
                # Install all dependencies (recursively) using bottles.
                cmd_inst+="brew deps --topological $pkg 2>/dev/null | "
                cmd_inst+="xargs --no-run-if-empty -I{} "
                cmd_inst+="brew install --force-bottle {} &>/dev/null;"
                # Install the requested packages themselves.
                cmd_inst+="brew install --force-bottle $pkg &>/dev/null;"
            done
            cmd_inst=$(_str_collapse_char "$cmd_inst" ";")

            # Homebrew runs as a non-root user.
            cmd_admin=""
            ;;
        "guix")
            cmd_inst="guix package -i $packages &>/dev/null"
            ;;
        esac

        # Execute installation.
        if [[ -n "$cmd_inst" ]]; then
            # Process optional post-install commands (if any). Each entry must
            # follow the format "<pkg_manager>:<commands>" and be separated by
            # newline characters '\n'.
            if [[ -n "$post_install" ]]; then
                local post_install_sel=""
                post_install_sel=$(grep "^$pkg_manager:" <<<"$post_install")
                post_install_sel=$(cut -d ":" -f 2- <<<"$post_install_sel")
                post_install_sel=$(tr -d "\n" <<<"$post_install_sel")

                if [[ -n "$post_install_sel" ]]; then
                    cmd_inst="$cmd_inst; $post_install_sel"
                fi
            fi

            # Execute the installation under the correct privilege context.
            # If root privileges are required, prepend with 'sudo' or 'pkexec'.
            $cmd_admin bash -c "$cmd_inst"
        fi
    done

    # Close the installation progress dialog.
    _close_wait_box
}

# FUNCTION: _deps_installation_check
#
# DESCRIPTION:
# This function verifies whether the specified packages were successfully
# installed using their respective package managers. It checks each pair in the
# format "<pkg_manager>:<package>" one by one, ensuring that all dependencies
# are properly installed before proceeding.
#
# PARAMETERS:
#   $1 (pairs_check): A space-separated list of "<pkg_manager>:<package>".
_deps_installation_check() {
    local pairs=$1

    # Replace spaces with '$FIELD_SEPARATOR' for iteration.
    pairs=$(tr " " "$FIELD_SEPARATOR" <<<"$pairs")

    # Iterate over each "<pkg_manager>:<package>" pair.
    local pair=""
    for pair in $pairs; do
        local pkg_manager="${pair%%:*}"
        local package="${pair#*:}"

        if _deps_is_package_installed "$pkg_manager" "$package"; then
            continue
        fi

        # Special case for 'rpm-ostree': If the package appears in the
        # rpm-ostree deployment list, it means it is installed but requires a
        # system reboot to take effect.
        if [[ "$pkg_manager" == "rpm-ostree" ]] &&
            rpm-ostree status --json | jq -r ".deployments[0].packages[]" |
            grep -Fxq "$package"; then
            _display_info_box \
                "The package '$package' is installed but you need to reboot to use it!"
            _exit_script
        fi

        # If the package could not be installed, show an error and exit.
        _display_error_box \
            "Could not install the package '$package' using '$pkg_manager'!"
        _exit_script
    done
}

# FUNCTION: _deps_is_package_installed
#
# DESCRIPTION:
# This function checks if a specific package is installed using the given
# package manager.
#
# PARAMETERS:
#   $1 (pkg_manager): The package manager to use for the check.
#      Supported values:
#      - "apt-get"     : For Debian/Ubuntu systems.
#      - "dnf"         : For Fedora/RHEL systems.
#      - "rpm-ostree"  : For Fedora Atomic systems.
#      - "pacman"      : For Arch Linux systems.
#      - "zypper"      : For openSUSE systems.
#      - "nix"         : For Nix-based systems.
#      - "brew"        : For Homebrew package manager.
#      - "guix"        : For GNU Guix systems.
#   $2 (package): The name of the package to check.
#
# RETURNS:
#   "0" (true): If the package is installed.
#   "1" (false): If the package is not installed or an error occurs.
_deps_is_package_installed() {
    local pkg_manager=$1
    local package=$2

    # Keep only the package name after '~' for verification, used when install
    # and check package names differ (e.g., on NixOS).
    if [[ "$package" == *"~"* ]]; then
        package=$(sed "s|[A-Za-z0-9.-]*~||g" <<<"$package")
    fi

    case "$pkg_manager" in
    "apt-get")
        if dpkg -s "$package" &>/dev/null; then
            return 0
        fi
        ;;
    "dnf")
        if dnf repoquery --installed | grep --quiet "$package-"; then
            return 0
        fi
        ;;
    "rpm-ostree")
        if rpm -qa | grep --quiet "$package"; then
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
    "nix")
        if nix-env -q | grep --quiet --ignore-case "$package"; then
            return 0
        fi
        ;;
    "brew")
        if brew list | grep --quiet "$package"; then
            return 0
        fi
        ;;
    "guix")
        if guix package -I "$package" &>/dev/null; then
            return 0
        fi
        ;;
    esac
    return 1
}

# -----------------------------------------------------------------------------
# SECTION: File and directory management ----
# -----------------------------------------------------------------------------

# FUNCTION: _delete_items
#
# DESCRIPTION:
# This function deletes specified files or directories, either by moving
# them to the trash (if supported) or by permanently deleting them.
_delete_items() {
    local items=$1
    local warning_message=""
    local items_count=""
    items_count=$(_get_items_count "$items")
    warning_message="This action will delete the $items_count selected items."
    warning_message="$warning_message\n\nWould you like to continue?"

    if ! _display_question_box "$warning_message"; then
        return
    fi

    # shellcheck disable=SC2086
    if _command_exists "gio"; then
        gio trash -- $items 2>/dev/null
    elif _command_exists "kioclient"; then
        kioclient move -- $items trash:/ 2>/dev/null
    elif _command_exists "gvfs-trash"; then
        gvfs-trash -- $items 2>/dev/null
    else
        rm -rf -- $items 2>/dev/null
    fi

    # Verify if all items were deleted.
    local failed_items=""
    local item=""
    for item in $items; do
        if [[ -e "$item" ]]; then
            failed_items+="$item"$'\n'
        fi
    done

    if [[ -n "$failed_items" ]]; then
        _log_error "Some items could not be deleted." "" "$failed_items" ""
        _logs_consolidate ""
    else
        _display_info_box "All selected items were successfully deleted!"
    fi
}

# FUNCTION: _directory_pop
#
# DESCRIPTION:
# This function pops the top directory off the directory stack and changes
# to the previous directory.
#
# RETURNS:
#   "0" (true): If the directory was successfully popped and changed.
#   "1" (false): If there was an error popping the directory.
_directory_pop() {
    popd &>/dev/null || {
        _log_error "Could not pop a directory." "" "" ""
        return 1
    }
    return 0
}

# FUNCTION: _directory_push
#
# DESCRIPTION:
# This function pushes the specified directory onto the directory stack and
# changes to it.
#
# PARAMETERS:
#   $1 (directory): The target directory to push onto the directory stack
#      and navigate to.
#
# RETURNS:
#   "0" (true): If the directory was successfully pushed and changed.
#   "1" (false): If there was an error pushing the directory.
_directory_push() {
    local directory=$1

    pushd "$directory" &>/dev/null || {
        _log_error "Could not push the directory '$directory'." "" "" ""
        return 1
    }
    return 0
}

# FUNCTION: _find_filtered_files
#
# DESCRIPTION:
# This function filters a list of files or directories based on various
# user-specified criteria, such as file type, extensions, and recursion.
#
# PARAMETERS:
#   $1 (input_files): A space-separated string containing file or
#      directory paths to filter. These paths are passed to the 'find'
#      command.
#   $2 (par_type): A string specifying the type of file to search for.
#      Supported values:
#      - "file": To search for files and symbolic links.
#      - "directory": To search for directories and symbolic links.
#   $3 (par_skip_extension): A string of file extensions to exclude from
#      the search. Only files with extensions not matching this list will be
#      included.
#   $4 (par_select_extension): A string of file extensions to include in
#      the search. Only files with matching extensions will be included.
#   $5 (par_find_parameters): Optional. Additional parameters to be
#      passed directly to the 'find' command.
#
# EXAMPLE:
#   - Input: "dir1 dir2", "file", "", "txt|pdf", "true"
#   - Output: A list of files with extensions ".txt" or ".pdf" from the
#     directories "dir1" and "dir2", searched recursively.
_find_filtered_files() {
    local input_files=$1
    local par_type=$2
    local par_skip_extension=$3
    local par_select_extension=$4
    local par_find_parameters=$5
    local filtered_files=""
    local find_command=""

    input_files=$(sed "s|'|'\"'\"'|g" <<<"$input_files")
    input_files=$(sed "s|$FIELD_SEPARATOR|' '|g" <<<"$input_files")

    # Build a 'find' command.
    find_command="find '$input_files'"

    if [[ -n "$par_find_parameters" ]]; then
        find_command+=" $par_find_parameters"
    fi

    # Expand the directories with the 'find' command.
    case "$par_type" in
    "file") find_command+=" \( -type l -o -type f \)" ;;
    "directory") find_command+=" \( -type l -o -type d \)" ;;
    esac

    if [[ -n "$par_select_extension" ]]; then
        find_command+=" -regextype posix-extended "
        find_command+=" -iregex \".*\.($par_select_extension)$\""
    fi

    if [[ -n "$par_skip_extension" ]]; then
        find_command+=" -regextype posix-extended "
        find_command+=" ! -iregex \".*\.($par_skip_extension)$\""
    fi

    find_command+=" ! -path \"$IGNORE_FIND_PATH\""
    find_command+=" -print0"

    # shellcheck disable=SC2086
    filtered_files=$(eval $find_command 2>/dev/null |
        tr "\0" "$FIELD_SEPARATOR")

    _str_collapse_char "$filtered_files" "$FIELD_SEPARATOR"
}

# FUNCTION: _get_filename_dir
#
# DESCRIPTION:
# This function extracts the directory path from a given file path.
#
# PARAMETERS:
#   $1 (input_filename): The full path or relative path to the file.
_get_filename_dir() {
    local input_filename=$1
    local dir=""

    dir=$(cd -- "$(dirname -- "$input_filename")" &>/dev/null && pwd)

    printf "%s" "$dir"
}

# FUNCTION: _get_filename_extension
#
# DESCRIPTION:
# This function extracts the file extension from a given filename.
#
# PARAMETERS:
#   $1 (filename): The input filename (can be absolute or relative).
_get_filename_extension() {
    local filename=$1
    filename=$(sed -E "s|.*/(\.)*||g" <<<"$filename")
    filename=$(sed -E "s|^(\.)*||g" <<<"$filename")

    grep --ignore-case --only-matching --perl-regexp \
        "(\.tar)?\.[a-z0-9_~-]{0,15}$" <<<"$filename"
}

# FUNCTION: _strip_filename_extension
#
# DESCRIPTION:
# This function removes the file extension from a given filename, if one
# exists.
#
# PARAMETERS:
#   $1 (filename): The filename from which to strip the extension.
#
# RETURNS:
#   - The filename without its extension.
_strip_filename_extension() {
    local filename=$1
    local extension=""
    extension=$(_get_filename_extension "$filename")

    if [[ -z "$extension" ]]; then
        printf "%s" "$filename"
        return 0
    fi

    local len_extension=${#extension}
    filename=${filename::-len_extension}
    printf "%s" "$filename"
}

# FUNCTION: _get_filename_full_path
#
# DESCRIPTION:
# This function returns the full absolute path of a given filename.
#
# PARAMETERS:
#   $1 (input_filename): The input filename or relative path.
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

# FUNCTION: _get_filename_next_suffix
#
# DESCRIPTION:
# This function generates a unique filename by adding a numeric suffix (e.g.
# "file (2)", "file (3)", ...) if a file with the same name already exists.
# This function is designed to work safely when multiple processes run
# concurrently, preventing race conditions that could otherwise lead to
# duplicated or overwritten files.
#
# HOW IT WORKS:
# To avoid race conditions, this function uses 'mkdir' as a synchronization.
# The command 'mkdir' is ATOMIC, meaning that only one process can successfully
# create a directory with a given name at any instant. If another process tries
# to create the same directory at the same time, it will fail immediately.
#
# PARAMETERS:
#   $1 (filename): The input filename or path. This can be an absolute or
#      relative filename. If the input file has an extension, it will be
#      stripped for the purpose of generating the new filename.
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
    # try to add a suffix, as 'file (2)', 'file (3)', ...
    local count=2
    local max_attempts=10000

    while ((count < max_attempts)); do

        # Create a temporary lock directory under '$TEMP_DIR_FILENAME_LOCKS'.
        # The directory name mirrors the candidate filename and serves as an
        # atomic claim for that name.
        local filename_lock="$TEMP_DIR_FILENAME_LOCKS/"
        filename_lock+=$(basename -- "$filename_result")

        # The 'mkdir' succeeds only if the directory does NOT already exist.
        # This makes the operation atomic:  only one process can succeed here.
        if mkdir "$filename_lock" 2>/dev/null &&
            [[ ! -e "$filename_result" ]]; then

            # Return the chosen filename and exit.
            printf "%s" "$filename_result"
            return 0
        fi

        # If mkdir failed, another process of the task claimed this name,
        # try the next suffix.
        filename_result="$filename_base ($count)$filename_extension"
        ((count++))
    done

    # Fallback: if all attempts fail (very unlikely), return the original name.
    printf "%s" "$filename"
}

# FUNCTION: _make_temp_dir
#
# DESCRIPTION:
# This function creates a temporary directory in the '$TEMP_DIR_TASK' directory
# and returns its path. The directory is created using 'mktemp', and the
# directory for the temporary directory is specified by the '$TEMP_DIR_TASK'
# variable.
#
# Output:
#   - The full path to the newly created temporary directory.
_make_temp_dir() {
    mktemp --directory --tmpdir="$TEMP_DIR_TASK"
}

# FUNCTION: _make_temp_dir_local
#
# DESCRIPTION:
# This function creates a temporary directory in a specified location and
# returns its path. The directory is created using 'mktemp', with a custom
# prefix (basename). It also generates a temporary file to track the
# directory to be removed later.
#
# PARAMETERS:
#   $1 (output_dir): The directory where the temporary directory will be
#      created.
#   $2 (basename): The prefix for the temporary directory name.
#
# Output:
#   - The full path to the newly created temporary directory.
_make_temp_dir_local() {
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

# FUNCTION: _make_temp_file
#
# DESCRIPTION:
# This function creates a temporary file in the '$TEMP_DIR_TASK' directory
# and returns its path. The file is created using 'mktemp', and the
# directory for the temporary file is specified by the '$TEMP_DIR_TASK'
# variable.
#
# Output:
#   - The full path to the newly created temporary file.
_make_temp_file() {
    mktemp --tmpdir="$TEMP_DIR_TASK"
}

# FUNCTION: _move_file
#
# DESCRIPTION:
# This function moves a file from the source location to the destination,
# with options to handle conflicts when the destination file already
# exists.
#
# PARAMETERS:
#   $1 (par_when_conflict): Optional, default: "skip". Defines the
#      behavior when the destination file already exists.
#      Supported values:
#      - "rename": Rename the source file to avoid conflicts by adding a
#         suffix to the destination filename.
#      - "skip": Skip moving the file if the destination file exists.
#      - "safe_overwrite": Safely overwrite the destination file, preserving
#        its permissions and creating a backup.
#   $2 (file_src): The path to the source file to be moved.
#   $3 (file_dst): The destination path where the file should be moved.
#
# RETURNS:
#   "0" (true): If the operation is successful or if the source and
#       destination are the same file.
#   "1" (false): If any required parameters are missing, if the move
#       fails, or if an invalid conflict parameter is provided.
_move_file() {
    local par_when_conflict=${1:-"skip"}
    local file_src=$2
    local file_dst=$3

    # Ensure both source and destination are provided.
    if [[ -z "$file_src" ]] || [[ -z "$file_dst" ]]; then
        return 1
    fi

    # Abort if the source file does not exist.
    if [[ ! -e "$file_src" ]]; then
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

    # Skip moving if source and destination are the same file.
    if [[ "$file_src" == "$file_dst" ]]; then
        return 0
    fi

    # Handle conflict behavior when destination already exists.
    case "$par_when_conflict" in
    "rename")
        # Append a numeric suffix to avoid overwriting an existing file.
        file_dst=$(_get_filename_next_suffix "$file_dst")
        mv -n -- "$file_src" "$file_dst" 2>/dev/null
        ;;
    "skip")
        # Do not overwrite if destination already exists.
        mv -n -- "$file_src" "$file_dst" 2>/dev/null
        ;;
    "safe_overwrite")
        # Safely overwrite the destination while preserving attributes and
        # backups.
        if [[ -e "$file_dst" ]]; then
            # Skip empty source files (0 bytes), considered invalid or
            # incomplete.
            if [[ ! -s "$file_src" ]]; then
                return 1
            fi

            # Skip if both files are identical to avoids unnecessary overwrite.
            if cmp --silent -- "$file_src" "$file_dst"; then
                rm -rf -- "$file_src" 2>/dev/null
                return 1
            fi

            # Apply the same permissions from the destination to the new file.
            chmod --reference="$file_dst" -- "$file_src" 2>/dev/null

            # Create a backup of the existing destination file.
            local file_dst_bak="$file_dst.bak"
            file_dst_bak=$(_get_filename_next_suffix "$file_dst_bak")
            mv -n -- "$file_dst" "$file_dst_bak" 2>/dev/null
        fi
        # Move the source file to the destination.
        mv -n -- "$file_src" "$file_dst" 2>/dev/null
        ;;
    esac

    if [[ "$par_when_conflict" != "safe_overwrite" ]] &&
        [[ -e "$file_src" ]]; then
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

# FUNCTION: _get_working_directory
#
# DESCRIPTION:
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
_get_working_directory() {
    local working_dir=""

    # Try to use the information provided by the file manager.
    if [[ -v "NAUTILUS_SCRIPT_CURRENT_URI" ]]; then
        working_dir=$NAUTILUS_SCRIPT_CURRENT_URI
    elif [[ -v "NEMO_SCRIPT_CURRENT_URI" ]]; then
        working_dir=$NEMO_SCRIPT_CURRENT_URI
    elif [[ -v "CAJA_SCRIPT_CURRENT_URI" ]]; then
        working_dir=$CAJA_SCRIPT_CURRENT_URI
    fi

    # If the working directory is a URI, decode it.
    if [[ -n "$working_dir" ]] && [[ "$working_dir" == "file://"* ]]; then
        # Decode the URI to get the directory path.
        working_dir=$(_text_uri_decode "$working_dir")
    else
        # Cases:
        # - Files selected in the search screen;
        # - Files opened remotely (sftp, smb);
        # - File managers that don't set current directory variables;
        #
        # Strategy: Get the directory from first selected file's path. Using
        # 'pwd' command is unreliable as it reflects the shell's working
        # directory, not necessarily the file manager's current view.
        local item_1=""
        item_1=$(cut -d "$FIELD_SEPARATOR" -f 1 <<<"$INPUT_FILES")

        if [[ -n "$item_1" ]]; then
            # Get the directory name of the first input file.
            working_dir=$(_get_filename_dir "$item_1")
        else
            # As a last resort, use the 'pwd' command.
            working_dir=$(pwd)
        fi
    fi

    printf "%s" "$working_dir"
}

# FUNCTION: _is_directory_empty
#
# DESCRIPTION:
# This function checks if a given directory is empty.
#
# PARAMETERS:
#   $1 (directory): The path of the directory to check.
#
# RETURNS:
#   "0" (true): If the directory is empty.
#   "1" (false): If the directory contains any files or subdirectories.
_is_directory_empty() {
    local directory=$1

    if ! find "$directory" -mindepth 1 -maxdepth 1 -print -quit |
        grep --quiet .; then
        return 0
    fi
    return 1
}

# -----------------------------------------------------------------------------
# SECTION: User interface ----
# -----------------------------------------------------------------------------

# FUNCTION: _display_dir_selection_box
#
# DESCRIPTION:
# This function presents a graphical interface to allow the user to select
# one or more directories.
_display_dir_selection_box() {
    local input_files=""

    _display_lock
    if ! _is_gui_session; then
        input_files=$(_get_working_directory)
    elif _command_exists "zenity"; then
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
    _display_unlock

    _str_collapse_char "$input_files" "$FIELD_SEPARATOR"
}

# shellcheck disable=SC2120
# FUNCTION: _display_file_selection_box
#
# DESCRIPTION:
# This function presents a graphical interface to allow the user to select
# a file.
#
# PARAMETERS:
#   $1 (file_filter): Optional. File filter pattern to restrict the types
#      of files shown.
#   $2 (title): Optional. Title of the window.
#   $3 (multiple): Optional. Accepts "true" or "false". If "true", allows
#      multiple file selection (only applies for Zenity).
_display_file_selection_box() {
    local file_filter=${1:-""}
    local title=${2:-"$(_get_script_name)"}
    local multiple=${3:-"false"}
    local input_files=""
    local multiple_flag=""

    _display_lock
    if ! _is_gui_session; then
        return 0
    elif _command_exists "zenity"; then
        # Add --multiple only if explicitly enabled.
        if [[ "$multiple" == "true" ]]; then
            multiple_flag="--multiple"
        fi

        input_files=$(zenity --title "$title" \
            --file-selection "$multiple_flag" \
            ${file_filter:+--file-filter="$file_filter"} \
            --separator="$FIELD_SEPARATOR" 2>/dev/null) || _exit_script
    elif _command_exists "kdialog"; then
        input_files=$(kdialog --title "$title" \
            --getopenfilename 2>/dev/null) || _exit_script
        # Use parameter expansion to remove the last space.
        input_files=${input_files% }
        input_files=${input_files// \//$FIELD_SEPARATOR/}
    fi
    _display_unlock

    _str_collapse_char "$input_files" "$FIELD_SEPARATOR"
}

# FUNCTION: _display_error_box
#
# DESCRIPTION:
# This function displays an error message to the user, adapting to the
# available environment.
#
# PARAMETERS:
#   $1 (message): The error message to display.
_display_error_box() {
    local message=$1

    _display_lock
    if ! _is_gui_session; then
        # For non-GUI sessions, simply print the message to the console.
        echo -e "$MSG_ERROR $message" >&2
    elif [[ -n "$DBUS_SESSION_BUS_ADDRESS" ]]; then
        _display_gdbus_notify "dialog-error" "$(_get_script_name)" \
            "$message" "2"
    elif _command_exists "zenity"; then
        zenity --title "$(_get_script_name)" --error \
            --width="$GUI_INFO_WIDTH" --text "$message" &>/dev/null
    elif _command_exists "kdialog"; then
        kdialog --title "$(_get_script_name)" --error "$message" &>/dev/null
    elif _command_exists "xmessage"; then
        xmessage -title "$(_get_script_name)" "Error: $message" &>/dev/null
    fi
    _display_unlock
}

# FUNCTION: _display_info_box
#
# DESCRIPTION:
# This function displays an information message to the user, adapting to
# the available environment.
#
# PARAMETERS:
#   $1 (message): The information message to display.
_display_info_box() {
    local message=$1

    _display_lock
    if ! _is_gui_session; then
        # For non-GUI sessions, simply print the message to the console.
        echo -e "$MSG_INFO $message" >&2
    elif [[ -n "$DBUS_SESSION_BUS_ADDRESS" ]]; then
        _display_gdbus_notify "dialog-information" "$(_get_script_name)" \
            "$message" "1"
    elif _command_exists "zenity"; then
        zenity --title "$(_get_script_name)" --info \
            --width="$GUI_INFO_WIDTH" --text "$message" &>/dev/null
    elif _command_exists "kdialog"; then
        kdialog --title "$(_get_script_name)" --msgbox "$message" &>/dev/null
    elif _command_exists "xmessage"; then
        xmessage -title "$(_get_script_name)" "Info: $message" &>/dev/null
    fi
    _display_unlock
}

# FUNCTION: _display_list_box
#
# DESCRIPTION:
# This function displays a list box with selectable items, adapting to the
# available environment.
#
# PARAMETERS:
#   $1 (message): A string containing the items to display in the list.
#   $1 (parameters): A string containing key-value pairs that configure
#      the function's behavior. Example: 'par_item_name=files'.
#
# PARAMETERS OPTIONS:
#   - "par_columns": Column definitions for the list, typically in the
#      format "--column:<name>,--column:<name>".
#   - "par_item_name": A string representing the name of the items in the
#      list. If not provided, the default value is 'items'.
#   - "par_action": The action to perform on the selected items.
#      Supported values:
#      - "open_file": Opens the selected files with the default
#        application.
#      - "open_location": Opens the file manager at the location of the
#        selected items.
#      - "open_url": Opens the selected URLs in the default web browser.
#      - "delete_item": Deletes the selected items after user
#     confirmation.
#   - "par_resolve_links": A boolean-like string ('true' or 'false')
#     indicating whether symbolic links in item paths should be resolved to
#     their target locations when opening the item's location. Defaults to
#     'true'.
#   - "par_checkbox": A boolean-like string ('true' or 'false') indicating
#     the list should include checkboxes for item selection. Defaults to
#     'false'.
#   - "par_checkbox_value": A boolean-like string ('true' or 'false')
#     defining the default state of the checkboxes (checked or unchecked)
#     when the list is initially displayed. Defaults to 'false'.
_display_list_box() {
    local message=$1
    local parameters=$2

    # Default values for input parameters.
    local par_columns=""
    local par_item_name="items"
    local par_action=""
    local par_resolve_links="true"
    local par_checkbox="false"
    local par_checkbox_value="false"

    # Evaluate the values from the '$parameters' variable.
    eval "$parameters"

    _close_wait_box
    _logs_consolidate ""

    _display_lock
    if ! _is_gui_session; then
        _display_list_box_terminal "$message"
    elif _command_exists "zenity"; then
        _display_list_box_zenity "$message" "$par_columns" \
            "$par_item_name" "$par_action" "$par_resolve_links" \
            "$par_checkbox" "$par_checkbox_value"
    elif _command_exists "kdialog"; then
        _display_list_box_kdialog "$message" "$par_columns"
    elif _command_exists "xmessage"; then
        _display_list_box_xmessage "$message" "$par_columns"
    fi
    _display_unlock
}

# FUNCTION: _display_list_box_terminal
_display_list_box_terminal() {
    local message=$1

    if [[ -z "$message" ]]; then
        message="(Empty result)"
        printf "%s\n" "$message" >&2
    else
        message=$(tr "$FIELD_SEPARATOR" " " <<<"$message")
        printf "%s\n" "$message"
    fi
}

# FUNCTION: _display_list_box_zenity
_display_list_box_zenity() {
    local message=$1
    local par_columns=$2
    local par_item_name=$3
    local par_action=$4
    local par_resolve_links=$5
    local par_checkbox=$6
    local par_checkbox_value=$7

    local columns_count=0
    local items_count=0
    local selected_items=""
    local message_select=""
    local header_label=""

    # Transform to uppercase.
    par_checkbox_value=${par_checkbox_value^^}

    if [[ "$par_checkbox" == "true" ]]; then
        par_columns="--column=Select$FIELD_SEPARATOR$par_columns"
        par_columns="--checklist$FIELD_SEPARATOR$par_columns"
    fi

    if [[ -n "$par_columns" ]]; then
        par_columns=$(tr ":" "=" <<<"$par_columns")
        # Count the number of columns.
        columns_count=$(
            grep --only-matching "column=" <<<"$par_columns" | wc -l
        )
    fi

    if [[ -n "$message" ]]; then
        items_count=$(tr -cd "\n" <<<"$message" | wc -c)
    fi

    # Set the selection message based on the action and item count.
    if ((items_count > 0)); then

        # Add the prefix 'TRUE/FALSE' in each item.
        if [[ "$par_checkbox" == "true" ]]; then
            message=$(sed "s|^\(.*\)$|$par_checkbox_value$FIELD_SEPARATOR\1|" \
                <<<"$message")
        fi

        case "$par_action" in
        "open_file")
            message_select="Select the ones to open:"
            ;;
        "open_location")
            message_select="Select the ones to open in the file manager:"
            ;;
        "open_url")
            message_select="Select the ones to open in the web browser:"
            ;;
        "delete_item")
            message_select="Select the ones to delete:"
            ;;
        esac
        header_label="Total: $items_count $par_item_name. $message_select"
    else
        header_label="No $par_item_name."
    fi

    if [[ -z "$message" ]]; then
        # NOTE: Some versions of Zenity crash if the
        # message is empty (Segmentation fault).
        message=" "
    fi

    par_columns=$(tr "," "$FIELD_SEPARATOR" <<<"$par_columns")
    message=$(tr "\n" "$FIELD_SEPARATOR" <<<"$message")

    # Avoid leading '-' in the variable to use in command line.
    message=$(sed "s|$FIELD_SEPARATOR-|$FIELD_SEPARATOR|g" <<<"$message")

    # Get the system limit for arguments.
    local arg_max=""
    local msg_size=""
    local safet_margin=65536 # Reserve space for extra args.
    arg_max=$(getconf "ARG_MAX")
    msg_size=$(printf "%s" "$message" | wc -c)

    if ((msg_size > arg_max - safet_margin)); then
        # Alternative strategy: use stdin instead of passing arguments directly
        # This avoids the "Argument list too long" error when '$message' is too
        # large.
        # shellcheck disable=SC2086
        selected_items=$(
            zenity --title "$(_get_script_name)" --list \
                --multiple --separator="$FIELD_SEPARATOR" \
                --width="$GUI_BOX_WIDTH" --height="$GUI_BOX_HEIGHT" \
                --print-column "$columns_count" \
                --text "$header_label" \
                $par_columns <<<"$message" 2>/dev/null
        ) || _exit_script
    else
        # Default strategy: pass '$message' directly as arguments (fast).
        # shellcheck disable=SC2086
        selected_items=$(
            zenity --title "$(_get_script_name)" --list \
                --multiple --separator="$FIELD_SEPARATOR" \
                --width="$GUI_BOX_WIDTH" --height="$GUI_BOX_HEIGHT" \
                --print-column "$columns_count" \
                --text "$header_label" \
                $par_columns $message 2>/dev/null
        ) || _exit_script
    fi

    # Open the selected items.
    if ((items_count > 0)) && [[ -n "$selected_items" ]]; then
        case "$par_action" in
        "open_file") xdg-open "$selected_items" ;;
        "open_location")
            _open_items_locations "$selected_items" "$par_resolve_links"
            ;;
        "open_url") _open_urls "$selected_items" ;;
        "delete_item") _delete_items "$selected_items" ;;
        esac
    fi
}

# FUNCTION: _display_list_box_kdialog
_display_list_box_kdialog() {
    local message=$1
    local par_columns=$2

    par_columns=$(sed "s|--column:||g" <<<"$par_columns")
    par_columns=$(tr "," "\t" <<<"$par_columns")
    message=$(tr "$FIELD_SEPARATOR" "\t" <<<"$message")
    message="$par_columns"$'\n'$'\n'"$message"

    printf "%s" "$message" >"$TEMP_DATA_TEXT_BOX"
    kdialog --title "$(_get_script_name)" \
        --geometry "${GUI_BOX_WIDTH}x${GUI_BOX_HEIGHT}" \
        --textinputbox "" \
        --textbox "$TEMP_DATA_TEXT_BOX" &>/dev/null || _exit_script
}

# FUNCTION: _display_list_box_xmessage
_display_list_box_xmessage() {
    local message=$1
    local par_columns=$2

    par_columns=$(sed "s|--column:||g" <<<"$par_columns")
    par_columns=$(tr "," "\t" <<<"$par_columns")
    message=$(tr "$FIELD_SEPARATOR" "\t" <<<"$message")
    message="$par_columns"$'\n'$'\n'"$message"

    printf "%s" "$message" >"$TEMP_DATA_TEXT_BOX"
    xmessage -title "$(_get_script_name)" \
        -file "$TEMP_DATA_TEXT_BOX" &>/dev/null || _exit_script
}

# FUNCTION: _display_password_box
#
# DESCRIPTION:
# This function prompts the user to enter a password, either via the
# terminal or a graphical dialog box.
#
# PARAMETERS:
#   $1 (message): A message to display as a prompt for the password.
#
# RETURNS:
#   "0" (true): If the password is successfully obtained.
#   "1" (false): If the user cancels the input or an error occurs.
_display_password_box() {
    local message=$1
    local password=""

    _display_lock
    # Ask the user for the password.
    if ! _is_gui_session; then
        echo -e -n "$MSG_INFO $message " >&2
        read -r -s password </dev/tty
        echo >&2
    elif _command_exists "zenity"; then
        password=$(zenity \
            --title="Password" --entry --hide-text --width="$GUI_INFO_WIDTH" \
            --text "$message" 2>/dev/null) || return 1
    elif _command_exists "kdialog"; then
        password=$(kdialog --title "Password" \
            --password "$message" 2>/dev/null) || return 1
    fi
    _display_unlock

    printf "%s" "$password"
}

# FUNCTION: _display_password_box_define
#
# DESCRIPTION:
# This function prompts the user to enter a password and ensures the
# password is not empty.
#
# RETURNS:
#   "0" (true): If the password is successfully obtained.
#   "1" (false): If the user cancels the input or an error occurs.
_display_password_box_define() {
    local message="Type your password:"
    local password=""

    password=$(_display_password_box "$message") || return 1

    # Check if '$password' is not empty.
    if [[ -z "$password" ]]; then
        _display_error_box "The password can not be empty!"
        return 1
    fi

    printf "%s" "$password"
}

# FUNCTION: _display_question_box
#
# DESCRIPTION:
# This function prompts the user with a yes/no question and returns the
# user's response.
#
# PARAMETERS:
#   $1 (message): The question message to display to the user.
#
# RETURNS:
#   "0" (true): If the user responds with 'yes' or 'y'.
#   "1" (false): If the user responds with 'no' or 'n', or if an error.
_display_question_box() {
    local message=$1
    local response=""

    _display_lock
    if ! _is_gui_session; then
        echo -e -n "$message [Y/n] " >&2
        read -r response </dev/tty
        echo >&2
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
    _display_unlock

    return 0
}

# FUNCTION: _display_text_box
#
# DESCRIPTION:
# This function displays a message to the user in a text box, either in the
# terminal or using a GUI dialog.
#
# PARAMETERS:
#   $1 (message): The message to display. If empty, a default message
#      '(Empty result)' is shown.
_display_text_box() {
    local message=$1

    _close_wait_box
    _logs_consolidate ""

    if [[ -z "$message" ]]; then
        message="(Empty result)"
    fi

    _display_lock
    if ! _is_gui_session; then
        printf "%s\n" "$message"
    elif _command_exists "zenity"; then
        printf "%s" "$message" >"$TEMP_DATA_TEXT_BOX"
        zenity --title "$(_get_script_name)" --text-info --no-wrap \
            --width="$GUI_BOX_WIDTH" --height="$GUI_BOX_HEIGHT" \
            --filename="$TEMP_DATA_TEXT_BOX" &>/dev/null || _exit_script
    elif _command_exists "kdialog"; then
        printf "%s" "$message" >"$TEMP_DATA_TEXT_BOX"
        kdialog --title "$(_get_script_name)" \
            --geometry "${GUI_BOX_WIDTH}x${GUI_BOX_HEIGHT}" \
            --textinputbox "" \
            --textbox "$TEMP_DATA_TEXT_BOX" &>/dev/null || _exit_script
    elif _command_exists "xmessage"; then
        printf "%s" "$message" >"$TEMP_DATA_TEXT_BOX"
        xmessage -title "$(_get_script_name)" \
            -file "$TEMP_DATA_TEXT_BOX" &>/dev/null || _exit_script
    fi
    _display_unlock
}

# FUNCTION: _display_result_box
#
# DESCRIPTION:
# This function displays a result summary at the end of a process,
# including error checking and output directory information.
#
# PARAMETERS:
#   $1 (output_dir): The directory where output files are stored or
#      expected to be.
_display_result_box() {
    local output_dir=$1
    _close_wait_box
    _logs_consolidate "$output_dir"

    # If '$output_dir' parameter is defined.
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

# FUNCTION: _display_wait_box
#
# DESCRIPTION:
# This function displays a wait box to inform the user that a task is
# running and they need to wait.
#
# PARAMETERS:
#   $1 (open_delay): Optional. The delay (in seconds) before the wait box
#      is shown. Defaults to 2 seconds if not provided.
_display_wait_box() {
    local open_delay=${1:-"2"}
    local message="Running the task. Please, wait..."

    _display_wait_box_message "$message" "$open_delay"
}

# FUNCTION: _display_wait_box_message
#
# DESCRIPTION:
# This function displays a wait box (progress indicator) to inform the user
# that a task is in progress.
#
# PARAMETERS:
#   $1 (message): The message to display inside the wait box (e.g.,
#      "Running the task. Please, wait...").
#   $2 (open_delay): Optional. The delay (in seconds) before the wait box
#      is shown. Defaults to 2 seconds if not provided.
_display_wait_box_message() {
    local message=$1
    local open_delay=${2:-"2"}

    # Avoid open more than one 'wait box'.
    [[ -f "$TEMP_CONTROL_WAIT_BOX" ]] && return 0

    if ! _is_gui_session; then
        # For non-GUI sessions, simply print the message to the console.
        echo -e "$MSG_INFO $message" >&2

    # Check if the Zenity is available.
    elif _command_exists "zenity"; then
        # Control flag to inform that a 'wait box' will open
        # (if the task takes over 2 seconds).
        touch -- "$TEMP_CONTROL_WAIT_BOX"

        # Create the FIFO for communication with Zenity 'wait box'.
        if [[ ! -p "$TEMP_CONTROL_WAIT_BOX_FIFO" ]]; then
            mkfifo "$TEMP_CONTROL_WAIT_BOX_FIFO"
        fi

        # Launch a background thread for Zenity 'wait box':
        #   - Waits for the specified delay.
        #   - Opens the Zenity 'wait box' if the control flag still exists.
        #   - If Zenity 'wait box' fails or is cancelled, exit the script.
        # shellcheck disable=SC2002
        (
            sleep "$open_delay"

            # Wait another window close.
            while [[ -f "$TEMP_CONTROL_DISPLAY_LOCKED" ]]; do
                # Short delay to avoid high CPU usage in the loop.
                sleep 0.3
            done

            # Check if the task has already finished.
            [[ ! -d "$TEMP_DIR" ]] && return 0

            # Check if the 'wait box' should open.
            [[ ! -f "$TEMP_CONTROL_WAIT_BOX" ]] && return 0

            tail -f -- "$TEMP_CONTROL_WAIT_BOX_FIFO" | (zenity \
                --title="$(_get_script_name)" --progress \
                --width="$GUI_INFO_WIDTH" \
                --pulsate --auto-close --text="$message" || _exit_script)
        ) &

    # Check if the KDialog is available.
    elif _command_exists "kdialog"; then
        _get_qdbus_command &>/dev/null || return 0
        # Control flag to inform that a 'wait box' will open
        # (if the task takes over 2 seconds).
        touch -- "$TEMP_CONTROL_WAIT_BOX"

        # Launch the "background thread 1", for KDialog 'wait box':
        #   - Waits for the specified delay.
        #   - Opens the KDialog 'wait box' if the control flag still exists.
        (
            sleep "$open_delay"

            # Wait another window close.
            while [[ -f "$TEMP_CONTROL_DISPLAY_LOCKED" ]]; do
                # Short delay to avoid high CPU usage in the loop.
                sleep 0.3
            done

            # Check if the task has already finished.
            [[ ! -d "$TEMP_DIR" ]] && return 0

            # Check if the 'wait box' should open.
            [[ ! -f "$TEMP_CONTROL_WAIT_BOX" ]] && return 0

            kdialog --title="$(_get_script_name)" \
                --progressbar "$message" 0 >"$TEMP_CONTROL_WAIT_BOX_KDIALOG" \
                2>/dev/null
        ) &

        # Launch the "background thread 2", to monitor the KDialog 'wait box':
        #   - Periodically checks if the dialog has been closed/cancelled.
        #   - If KDialog 'wait box' is cancelled, exit the script.
        (
            sleep "$open_delay"
            # Wait the 'wait box' finish to write the output file.
            sleep 0.1

            while [[ -f "$TEMP_CONTROL_WAIT_BOX" ]] ||
                [[ -f "$TEMP_CONTROL_WAIT_BOX_KDIALOG" ]]; do
                # Extract the D-Bus reference for the KDialog instance.
                local dbus_ref=""
                dbus_ref=$(cut -d " " -f 1 <"$TEMP_CONTROL_WAIT_BOX_KDIALOG")

                # Check if the user has cancelled the wait box.
                local std_output=""
                std_output=$($(_get_qdbus_command) "$dbus_ref" \
                    "/ProgressDialog" "wasCancelled" 2>&1)

                if [[ "${std_output,,}" == *"does not exist"* ]]; then
                    _exit_script
                fi

                # Short delay to avoid high CPU usage in the loop.
                sleep 0.3
            done
        ) &
    fi
}

# FUNCTION: _close_wait_box
#
# DESCRIPTION:
# This function is responsible for closing any open 'wait box' (progress
# indicators) that were displayed during the execution of a task. It checks
# for both Zenity and KDialog wait boxes and handles their closure.
_close_wait_box() {
    if [[ ! -f "$TEMP_CONTROL_WAIT_BOX" ]]; then
        return 0
    fi
    # Cancel the future open of any 'wait box'.
    rm -f -- "$TEMP_CONTROL_WAIT_BOX"

    # Wait the 'wait box' finish to write the control file.
    sleep 0.1

    # Check if Zenity 'wait box' is open, (waiting for an input in the FIFO).
    if pgrep -fl "$TEMP_CONTROL_WAIT_BOX_FIFO" &>/dev/null; then
        # Close the Zenity using the FIFO.
        printf "100\n" >"$TEMP_CONTROL_WAIT_BOX_FIFO"
    fi

    if [[ -f "$TEMP_CONTROL_WAIT_BOX_KDIALOG" ]]; then
        # Extract the D-Bus reference for the KDialog instance.
        local dbus_ref=""
        dbus_ref=$(cut -d " " -f 1 <"$TEMP_CONTROL_WAIT_BOX_KDIALOG")

        # Stop the loop of "background thread 2".
        rm -f -- "$TEMP_CONTROL_WAIT_BOX_KDIALOG"

        # Wait the "background thread 2" main loop stop
        # before close the KDialog 'wait box'.
        sleep 0.3

        # Close the KDialog 'wait box'.
        $(_get_qdbus_command) "$dbus_ref" "/ProgressDialog" \
            "close" &>/dev/null
    fi
}

# FUNCTION: _display_lock
#
# DESCRIPTION:
# This function creates a temporary lock file used to indicate that the
# wait box should not be opened at this time. In this case,
# '_display_wait_box' will wait until '_display_unlock' is executed.
_display_lock() {
    touch -- "$TEMP_CONTROL_DISPLAY_LOCKED"
}

# FUNCTION: _display_unlock
#
# DESCRIPTION:
# This function removes the temporary lock file created by '_display_lock'.
# By doing so, it signals that the wait box can now be displayed.
_display_unlock() {
    rm -f -- "$TEMP_CONTROL_DISPLAY_LOCKED"
}

# FUNCTION: _display_gdbus_notify
#
# DESCRIPTION:
# This function sends a desktop notification using the 'gdbus' tool, which
# interfaces with the D-Bus notification system (specifically the
# 'org.freedesktop.Notifications' service).
#
# PARAMETERS:
#   $1 (icon): The icon to display with the notification.
#   $2 (title): The title of the notification.
#   $3 (body): The main message to be displayed in the notification.
#   $4 (urgency): Optional. The urgency level of the notification.
_display_gdbus_notify() {
    local icon=$1
    local title=$2
    local body=$3
    local urgency=${4:-1} # Default urgency is 1 (normal).
    local app_name=$title
    local method="Notify"
    local interface="org.freedesktop.Notifications"
    local object_path="/org/freedesktop/Notifications"

    # Use 'gdbus' to send the notification.
    gdbus call --session --dest "$interface" --object-path "$object_path" \
        --method "$interface.$method" "$app_name" 0 "$icon" "$title" "$body" \
        "[]" "{\"urgency\": <$urgency>}" 5000 &>/dev/null
}

# FUNCTION: _get_qdbus_command
#
# DESCRIPTION:
# This function retrieves the first command matching the pattern 'qdbus'.
# The command may vary depending on the Linux distribution and could be
# 'qdbus', 'qdbus-qt6', 'qdbus6', or similar variations.
#
# RETURNS:
#   "0" (true): If a command matching the pattern "qdbus" is found.
#   "1" (false): If no command matching the pattern "qdbus" is found.
_get_qdbus_command() {
    compgen -c | grep --perl-regexp -m1 "^qdbus[0-9]*(-qt[0-9])?$" || return 1
    return 0
}

# -----------------------------------------------------------------------------
# SECTION: System and environment ----
# -----------------------------------------------------------------------------

# FUNCTION: _get_available_app
#
# DESCRIPTION:
# This function iterates through a list of applications and returns the
# first one that is available. It relies on the helper function
# '_command_exists' to check for the existence of each command.
#
# PARAMETERS:
#   $1 (_apps): An array of application names to check, in order of
#      preference.
#
# RETURNS:
#   "0" (true): If an available application is found, prints its name.
#   "1" (false): If no applications from the list are found.
_get_available_app() {
    local -n _apps=$1

    local app=""
    for app in "${_apps[@]}"; do
        if _command_exists "$app"; then
            printf "%s" "$app"
            return 0
        fi
    done

    return 1
}

# FUNCTION: _get_available_file_manager
#
# DESCRIPTION:
# This function detects the default or an available file manager on the
# system.
#
# RETURNS:
#   "0" (true): If a file manager is found, prints its name.
#   "1" (false): If no file manager is found.
#
# BEHAVIOR:
#   1. Attempts to get the system's default file manager using
#      '_xdg_get_default_app' for the 'inode/directory' MIME type.
#   2. If none is found, iterates through a predefined list of common file
#      managers and returns the first one that is installed.
_get_available_file_manager() {
    local available_app=""
    local default_app=""
    default_app=$(_xdg_get_default_app "inode/directory" "true")

    local apps=(
        "nautilus"
        "dolphin"
        "nemo"
        "caja"
        "thunar"
        "pcmanfm-qt"
        "pcmanfm"
    )

    # Step 1: Validate if the detected default application matches one of the
    # known file managers.
    local app=""
    for app in "${apps[@]}"; do
        if [[ "$default_app" == *"$app" ]]; then
            printf "%s" "$app"
            return 0
        fi
    done

    # Step 2: If no valid default found, check which file managers from the
    # list are installed on the system and return the first match.
    available_app=$(_get_available_app "apps")
    if [[ -n "$available_app" ]]; then
        printf "%s" "$available_app"
        return 0
    fi

    # Step 3: If 'xdg-mime' returned something but it's not in the predefined
    # list, return it anyway as a last attempt.
    if [[ -n "$default_app" ]]; then
        printf "%s" "$default_app"
        return 0
    fi

    # Step 4: No file manager found. return error code 1.
    return 1
}

# FUNCTION: _get_script_name
#
# DESCRIPTION:
# This function returns the name of the currently executing script. It uses
# the 'basename' command to extract the script's filename from the full
# path provided by '$0'.
#
# If the script starts with two digits followed by a space (e.g., "01 My
# Script"), used in naming of 'Accessed recently' directory, that prefix is
# removed.
_get_script_name() {
    local output=""
    output=$(basename -- "$0")

    # Remove 'dd ' (two digits + space) at the beginning.
    sed "s|^[0-9]\{2\} ||" <<<"$output"
}

# FUNCTION: _is_gui_session
#
# DESCRIPTION:
# This function checks whether the script is running in a graphical user
# interface (GUI) session. It does so by checking if the 'DISPLAY'
# environment variable is set, which is typically present in GUI sessions
# (e.g., X11 or Wayland).
#
# RETURNS:
#   "0" (true): If is a GUI session.
#   "1" (false): If is not a GUI session.
_is_gui_session() {
    if [[ -v "DISPLAY" ]]; then
        return 0
    fi
    return 1
}

# FUNCTION: _is_qt_desktop
#
# DESCRIPTION:
# This function determines whether the current desktop environment
# (as specified by the XDG_CURRENT_DESKTOP variable) is Qt-based.
#
# RETURNS:
#   "0" (true): If the desktop is Qt-based.
#   "1" (false): Otherwise.
_is_qt_desktop() {
    local qt_desktops=("kde" "lxqt" "tde" "trinity" "razor" "lumina")
    local current_desktop=""

    if [[ -z "${XDG_CURRENT_DESKTOP:-}" ]]; then
        return 1
    fi

    current_desktop=${XDG_CURRENT_DESKTOP,,}

    local qt_desktop=""
    for qt_desktop in "${qt_desktops[@]}"; do
        if [[ "$current_desktop" == *"$qt_desktop"* ]]; then
            return 0
        fi
    done

    return 1
}

# FUNCTION: _get_max_procs
#
# DESCRIPTION:
# This function returns the maximum number of processing units (CPU cores)
# available on the system.
_get_max_procs() {
    nproc --all 2>/dev/null
}

# FUNCTION: _unset_global_variables_file_manager
#
# DESCRIPTION:
# This function unset global variables that may have been set by different
# file managers (Caja, Nautilus, Nemo) during script execution.
_unset_global_variables_file_manager() {
    local var=""
    while IFS= read -r var; do
        unset "$var"
    done < <(compgen -v | grep "_SCRIPT_")
}

# FUNCTION: _xdg_get_default_app
#
# DESCRIPTION:
# This function retrieves the default application associated with a
# specific MIME type using the 'xdg-mime' command.
#
# PARAMETERS:
#   $1 (mime): MIME type (e.g., 'application/pdf', 'image/png').
#   $2 (quiet, optional): If set to 'true', the function will return 1 on
#      errors without displaying any dialog or exiting. Default is 'false'.
#
# RETURNS:
#   "0" (true): If the default application is found, prints its executable.
#   "1" (false): If no default application is set or found.
#
# EXAMPLE:
#   - Input: 'application/pdf'
#   - Output: The function prints the default application's executable for
#     opening PDF files (e.g., 'evince' or 'okular').
_xdg_get_default_app() {
    local mime=$1
    local quiet=${2:-"false"}
    local desktop_file=""
    local desktop_path=""
    local default_app=""

    # Get '.desktop' file from xdg-mime.
    desktop_file=$(xdg-mime query default "$mime" 2>/dev/null)
    if [[ -z "$desktop_file" ]]; then
        if [[ "$quiet" == "true" ]]; then
            return 1
        fi
        _display_error_box \
            "No default application set for MIME type '$mime'!"
        _exit_script
    fi

    # Get standard XDG application directories.
    local xdg_dirs="${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
    if [[ -n "${HOME:-}" ]]; then
        xdg_dirs+=":$HOME/.local/share"
    fi

    # Append the directory 'applications'.
    xdg_dirs=$(sed "s|/:|:|g; s|:|/applications:|g; s|/$||" <<<"$xdg_dirs")
    xdg_dirs+="/applications"

    # Locate the '.desktop' file.
    xdg_dirs=$(tr ":" "$FIELD_SEPARATOR" <<<"$xdg_dirs")
    local xdg_dir=""
    for xdg_dir in $xdg_dirs; do
        desktop_path="$xdg_dir/$desktop_file"
        if [[ -f "$desktop_path" ]]; then
            # Extract Exec line, normalize to get only the binary.
            default_app=$(grep -m1 "^Exec=" "$desktop_path" |
                sed "s|Exec=||" | cut -d " " -f 1)

            if _command_exists "$default_app"; then
                break
            else
                default_app=""
            fi
        fi
    done

    if [[ -z "$default_app" ]]; then
        if [[ "$quiet" == "true" ]]; then
            return 1
        fi
        _display_error_box \
            "Could not find the executable to open MIME type '$mime'!"
        _exit_script
    fi

    printf "%s" "$default_app"
}

# -----------------------------------------------------------------------------
# SECTION: Clipboard management ----
# -----------------------------------------------------------------------------

# FUNCTION: _get_clipboard_data
#
# DESCRIPTION:
# This function retrieves the current content of the clipboard, adapting
# the method according to the session type.
_get_clipboard_data() {
    case "${XDG_SESSION_TYPE:-}" in
    "wayland") wl-paste 2>/dev/null ;;
    "x11") xclip -quiet -selection clipboard -o 2>/dev/null ;;
    esac
}

# FUNCTION: _set_clipboard_data
#
# DESCRIPTION:
# This function sets the content of the clipboard with the provided input
# data, adapting the method according to the session type.
#
# PARAMETERS:
#   $1 (input_data): The text string to be copied into the clipboard.
_set_clipboard_data() {
    local input_data=$1

    case "${XDG_SESSION_TYPE:-}" in
    "wayland") wl-copy <<<"$input_data" 2>/dev/null ;;
    "x11") xclip -selection clipboard -i <<<"$input_data" 2>/dev/null ;;
    esac
}

# FUNCTION: _set_clipboard_file
#
# DESCRIPTION:
# This function sets the content of the clipboard with the provided input
# file, adapting the method according to the session type.
#
# PARAMETERS:
#   $1 (input_file): The file to be copied into the clipboard.
_set_clipboard_file() {
    local input_file=$1

    case "${XDG_SESSION_TYPE:-}" in
    "wayland") wl-copy <"$input_file" 2>/dev/null ;;
    "x11") xclip -selection clipboard -i <"$input_file" 2>/dev/null ;;
    esac
}

# -----------------------------------------------------------------------------
# SECTION: Input files ----
# -----------------------------------------------------------------------------

# FUNCTION: _get_filenames_filemanager
#
# DESCRIPTION:
# This function retrieves a list of selected filenames or URIs from a file
# manager (such as Caja, Nemo, or Nautilus) and processes the input
# accordingly. If no selection is detected, it falls back to using a
# standard input file list.
_get_filenames_filemanager() {
    local input_files=""

    # Try to use the information provided by the file manager.
    if [[ -v "NAUTILUS_SCRIPT_SELECTED_URIS" ]]; then
        input_files=$NAUTILUS_SCRIPT_SELECTED_URIS
    elif [[ -v "NEMO_SCRIPT_SELECTED_URIS" ]]; then
        input_files=$NEMO_SCRIPT_SELECTED_URIS
    elif [[ -v "CAJA_SCRIPT_SELECTED_URIS" ]]; then
        input_files=$CAJA_SCRIPT_SELECTED_URIS
    fi

    if [[ -n "$input_files" ]]; then
        # Replace '\n' with '$FIELD_SEPARATOR'.
        input_files=$(_convert_text_to_delimited_string "$input_files")

        # Decode the URI list.
        input_files=$(_text_uri_decode "$input_files")
    else
        input_files=$INPUT_FILES # Standard input.
        input_files=$(_str_collapse_char "$input_files" "$FIELD_SEPARATOR")
    fi

    printf "%s" "$input_files"
}

# FUNCTION: _get_files
#
# DESCRIPTION:
# This function retrieves a list of files or directories based on the
# provided parameters and performs various filtering, validation, and
# sorting operations. The input files can be filtered by type, extension,
# mime type, etc. It also supports recursive directory expansion and
# validation of file conflicts.
#
# PARAMETERS:
#   $1 (parameters): A string containing key-value pairs that configure
#      the function's behavior. Example: 'par_type=file; par_min_items=2'.
#
# PARAMETERS OPTIONS:
#   - "par_type": Specifies the type of items to filter.
#      Supported values:
#      - "file" (default): Filters files.
#      - "directory": Filters directories.
#      - "all": Includes both files and directories.
#   - "par_recursive": Specifies whether to expand directories recursively.
#      Supported values:
#      - "false" (default): Does not expand directories.
#      - "true": Expands directories recursively.
#   - "par_max_items", "par_min_items": Limits the number of files.
#   - "par_select_extension": Filters by file extension.
#   - "par_select_mime": Filters by MIME type.
#   - "par_skip_extension": Skips files with specific extensions.
#   - "par_skip_encoding": Skips files with specific encodings.
#   - "par_sort_list": If 'true', sorts the list of files.
_get_files() {
    local parameters=$1
    local input_files=""
    input_files=$(_get_filenames_filemanager)

    # Default values for input parameters.
    local par_max_items=""
    local par_min_items=""
    local par_recursive="false"
    local par_select_extension=""
    local par_select_mime=""
    local par_skip_encoding=""
    local par_skip_extension=""
    local par_sort_list="false"
    local par_type="file"

    # Evaluate the values from the '$parameters' variable.
    eval "$parameters"

    # Check if there are input files.
    if (($(_get_items_count "$input_files") == 0)); then
        # Detect if running in a supported file manager context.
        if [[ -v "NAUTILUS_SCRIPT_SELECTED_URIS" ]] ||
            [[ -v "NEMO_SCRIPT_SELECTED_URIS" ]] ||
            [[ -v "CAJA_SCRIPT_SELECTED_URIS" ]]; then
            if [[ "$par_type" != "file" ]] ||
                [[ "$par_recursive" == "true" ]]; then
                # Return the current working directory if no files have been
                # selected.
                input_files=$(_get_working_directory)
            fi
        fi
    fi

    # If still no files available, prompt user with selection dialog.
    if (($(_get_items_count "$input_files") == 0)); then
        if [[ "$par_type" != "file" ]] ||
            [[ "$par_recursive" == "true" ]]; then
            input_files=$(_display_dir_selection_box)
        else
            input_files=$(_display_file_selection_box \
                "" "$(_get_script_name)" "true")
        fi
    fi

    # Handle remote file URIs (http://, ftp://, etc.) by translating to local
    # 'gvfs' paths.
    if [[ "$input_files" == *"://"* ]]; then
        local working_dir=""
        working_dir=$(_get_working_directory)

        # Convert remote URIs to local 'gvfs' paths for processing.
        input_files=$(sed \
            "s|[a-z0-9\+_-]*://[^$FIELD_SEPARATOR]*/|$working_dir/|g" \
            <<<"$input_files")
    fi

    local initial_items_count=0
    initial_items_count=$(_get_items_count "$input_files")

    local find_parameters=""
    if ((initial_items_count == 1)) && [[ -d "$input_files" ]] &&
        [[ "$par_recursive" == "false" ]] &&
        printf "%s" "$(basename -- "$input_files")" |
        grep --quiet --ignore-case --word-regexp "batch"; then
        # This workaround allows the scripts to handle cases with a large input
        # list of files. In this case, just select a single directory  with a
        # name that includes the word 'batch'. Then, the scripts operate on the
        # files within the selected directory. This addresses the GNOME error:
        # "Could not start application: Failed to execute child process
        # "/bin/sh" (Argument list too long)".

        local batch_message=""
        batch_message+="Batch mode detected: Each file inside this"
        batch_message+=" directory will be processed individually."
        batch_message+="\n\nWould you like to continue?"
        if ! _display_question_box "$batch_message"; then
            _exit_script
        fi
        touch -- "$TEMP_CONTROL_BATCH_ENABLED"
        find_parameters="-mindepth 1 -maxdepth 1"
    elif [[ "$par_recursive" == "false" ]]; then
        # Default non-recursive mode: process only explicitly selected items.
        find_parameters="-maxdepth 0"
    fi

    # Pre-select the input files.
    input_files=$(_find_filtered_files \
        "$input_files" \
        "$par_type" \
        "$par_skip_extension" \
        "$par_select_extension" \
        "$find_parameters")

    # Handle the case where a file is selected in the file manager, but
    # 'par_type=directory'. This is particularly useful for scripts like 'Open
    # with Terminal' where a file is selected, but the intention is to open the
    # working directory.
    if (($(_get_items_count "$input_files") == 0)); then
        # Detect if running in a supported file manager context.
        if [[ -v "NAUTILUS_SCRIPT_SELECTED_URIS" ]] ||
            [[ -v "NEMO_SCRIPT_SELECTED_URIS" ]] ||
            [[ -v "CAJA_SCRIPT_SELECTED_URIS" ]]; then
            if [[ "$par_type" == "directory" ]]; then
                # Return the current working directory if no files have been
                # selected.
                input_files=$(_get_working_directory)
            fi
        fi
    fi

    # Validates the mime or encoding of the file.
    if [[ -n "$par_select_mime" ]] || [[ -n "$par_skip_encoding" ]]; then
        input_files=$(_validate_file_mime_parallel \
            "$input_files" \
            "$par_select_mime" \
            "$par_skip_encoding")
    fi

    # Validate that the final file count meets requirements.
    _validate_files_count \
        "$input_files" \
        "$par_type" \
        "$par_select_extension" \
        "$par_select_mime" \
        "$par_min_items" \
        "$par_max_items" \
        "$par_recursive"

    # Sort file list if requested.
    if [[ "$par_sort_list" == "true" ]]; then
        input_files=$(_str_sort "$input_files" "$FIELD_SEPARATOR" "false")
    fi

    # Return the final processed file list.
    printf "%s" "$input_files"
}

# FUNCTION: _validate_file_mime
#
# DESCRIPTION:
# This function validates the MIME type and optionally the encoding of a
# given file. It checks whether the file's MIME type matches a specified
# pattern (regex) and, if provided, whether the file's encoding matches
# another specified pattern.
#
# PARAMETERS:
#   $1 (input_file): The path to the file that is being validated. This
#      is the file whose MIME type will be checked.
#   $2 (par_select_mime): A MIME type pattern (or regular expression)
#      used to validate the file's MIME type. If this parameter is empty,
#      MIME type validation is skipped.
#   $3 (par_skip_encoding): An optional encoding pattern (or regular
#      expression) used to validate the file's encoding. If this parameter
#      is empty, encoding validation is skipped.
_validate_file_mime() {
    local input_file=$1
    local par_select_mime=$2
    local par_skip_encoding=$3

    # Validate MIME type if a pattern is provided.
    if [[ -n "$par_select_mime" ]]; then
        local file_mime=""
        file_mime=$(_get_file_mime "$input_file")
        par_select_mime=${par_select_mime//+/\\+}
        grep --quiet --ignore-case --perl-regexp \
            "($par_select_mime)" <<<"$file_mime" || return
    fi

    # Validate encoding if a pattern is provided.
    if [[ -n "$par_skip_encoding" ]]; then
        local file_encoding=""
        file_encoding=$(_get_file_encoding "$input_file")
        par_skip_encoding=${par_skip_encoding//+/\\+}
        grep --quiet --ignore-case --perl-regexp \
            "($par_skip_encoding)" <<<"$file_encoding" && return
    fi

    # Create a temp file containing the name of the valid file.
    _storage_text_write "$input_file$FIELD_SEPARATOR"
}

# FUNCTION: _validate_file_mime_parallel
#
# DESCRIPTION:
# This function validates the MIME types of multiple files in parallel,
# based on a specified MIME type pattern. It processes a list of file paths
# concurrently using `xargs` and calls the `_validate_file_mime` function
# for each file.
#
# PARAMETERS:
#   $1 (input_files): A space-separated string containing the paths of
#      the files to validate. These files will be checked for the MIME type
#      pattern.
#   $2 (par_select_mime): The MIME type pattern (or regular expression)
#      used to validate the files' MIME types. If this parameter is empty,
#      no MIME type validation is performed, and all input files are
#      returned as valid.
#   $3 (par_skip_encoding): An optional encoding pattern (or regular
#      expression) used to validate the files' encodings. If this parameter
#      is empty, no encoding validation is performed.
#
# EXAMPLE:
#   - Input: File paths "file1.txt file2.png", MIME pattern "text/plain".
#   - Output: If "file1.txt" has a MIME type of "text/plain", it will be
#     included in the output, but "file2.png" will be excluded if its MIME
#     type doesn't match.
_validate_file_mime_parallel() {
    local input_files=$1
    local par_select_mime=$2
    local par_skip_encoding=$3

    # Execute the function '_validate_file_mime' for each file in parallel.
    export -f _validate_file_mime
    _run_function_parallel \
        "_validate_file_mime '{}' '$par_select_mime' '$par_skip_encoding'" \
        "$input_files" "$FIELD_SEPARATOR"

    # Compile valid files in a single list.
    input_files=$(_storage_text_read_all)
    _storage_text_clean

    _str_collapse_char "$input_files" "$FIELD_SEPARATOR"
}

# FUNCTION: _validate_files_count
#
# DESCRIPTION:
# This function validates the number of selected files or directories based
# on several criteria, such as type, extension, MIME type, and minimum or
# maximum item count.
#
# PARAMETERS:
#   $1 (input_files): A space-separated string containing the paths of
#      files or directories to be validated.
#   $2 (par_type): A string indicating the type of items to validate.
#      Supported values:
#      - "file": Validate files only.
#      - "directory": Validate directories only.
#      - "all": Validate both files and directories.
#   $3 (par_select_extension): A pipe-separated list of file extensions
#      to filter the files. Files must have one of these extensions.
#   $4 (par_select_mime): A string representing MIME types to filter the
#      files by. Only files with matching MIME types are selected.
#   $5 (par_min_items): The minimum number of valid items required. If
#      fewer valid items are selected, an error is displayed.
#   $6 (par_max_items): The maximum number of valid items allowed. If
#      more valid items are selected, an error is displayed.
#   $7 (par_recursive): A string indicating whether the validation should
#      be recursive. If 'true', directories will be searched recursively.
#
# EXAMPLE:
#   - Input: "dir1 dir2", "file", "txt|pdf", "", 1, 5, "true"
#   - Output: The function checks if the directories "dir1" and "dir2"
#     contain at least 1 and no more than 5 ".txt" or ".pdf" files,
#     recursively.
_validate_files_count() {
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

# -----------------------------------------------------------------------------
# SECTION: Output files ----
# -----------------------------------------------------------------------------

# FUNCTION: _get_output_dir
#
# DESCRIPTION:
# This function determines and returns the appropriate output directory
# path based on the provided parameters and the system's available
# directories.
#
# PARAMETERS:
#   $1 (parameters): A string containing key-value pairs that configure
#      the function's behavior. Example: 'par_use_same_dir=true'.
#
# PARAMETERS OPTIONS:
#   - "par_use_same_dir": If set to 'true', the function uses the base
#     directory (e.g., current working directory or an alternative with write
#     permissions) as the output directory. If 'false' or not set, a new
#     subdirectory is created for the output.
_get_output_dir() {
    local parameters=$1
    local output_dir=""

    # Default values for input parameters.
    local par_use_same_dir=""

    # Evaluate the values from the '$parameters' variable.
    eval "$parameters"

    # Check directories available to put the output dir.
    output_dir=$(_get_working_directory)
    [[ ! -w "$output_dir" ]] && output_dir=${HOME:-/tmp}
    if [[ ! -w "$output_dir" ]]; then
        _display_error_box "Could not find a directory with write permissions!"
        _exit_script
    fi

    if [[ "$par_use_same_dir" == "true" ]] &&
        [[ ! -f "$TEMP_CONTROL_BATCH_ENABLED" ]]; then
        printf "%s" "$output_dir"
        return
    fi

    output_dir="$output_dir/$PREFIX_OUTPUT_DIR"

    # If the file already exists, add a suffix.
    output_dir=$(_get_filename_next_suffix "$output_dir")

    mkdir --parents "$output_dir"
    printf "%s" "$output_dir"
}

# FUNCTION: _get_output_filename
#
# DESCRIPTION:
# This function generates the output filename based on the given input
# file, output directory, and a set of optional parameters. It allows for
# customization of the output filename by adding prefixes, suffixes, and
# selecting how the file extension should be handled.
#
# PARAMETERS:
#   $1 (input_file): The input file for which the output filename will be
#      generated.
#   $2 (output_dir): The directory where the output file will be placed.
#   $3 (parameters): A string containing optional parameters that define
#      how the output filename should be constructed.
#
# PARAMETERS OPTIONS:
#   - "par_extension_opt": Specifies how to handle the file extension.
#      Supported values:
#      - "append": Append a new extension 'par_extension' to the existing
#         file extension.
#      - "preserve": Keep the original file extension.
#      - "replace": Replace the current extension with a new one
#        'par_extension'.
#      - "strip": Remove the file extension entirely.
#   - "par_extension": The extension to use when 'par_extension_opt' is set
#     to 'append' or 'replace'. This value is ignored for the 'preserve'
#     and 'strip' options.
#   - "par_prefix": A string to be added as prefix to the output filename.
#   - "par_suffix": A string to be added as suffix to the output
#     filename, placed before the extension.
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

    # Evaluate the values from the '$parameters' variable.
    eval "$parameters"

    filename=$(basename -- "$input_file")

    # Start constructing the output file path with the output directory.
    output_file="$output_dir/"
    [[ -n "$par_prefix" ]] && output_file+="$par_prefix "

    if [[ -d "$input_file" ]]; then
        # Handle case where input_file is a directory.
        case "$par_extension_opt" in
        "append" | "replace")
            output_file+=$filename
            output_file+=".$par_extension"
            ;;
        "preserve" | "strip")
            output_file+=$filename
            ;;
        esac
    else
        # Handle case where input_file is a regular file.
        case "$par_extension_opt" in
        "append")
            # Append the new extension to the existing one.
            output_file+=$(_strip_filename_extension "$filename")
            [[ -n "$par_suffix" ]] && output_file+=" $par_suffix"
            output_file+=$(_get_filename_extension "$filename")
            output_file+=".$par_extension"
            ;;
        "preserve")
            # Preserve the original extension.
            output_file+=$(_strip_filename_extension "$filename")
            [[ -n "$par_suffix" ]] && output_file+=" $par_suffix"
            output_file+=$(_get_filename_extension "$filename")
            ;;
        "replace")
            # Replace the existing extension with the new one.
            output_file+=$(_strip_filename_extension "$filename")
            [[ -n "$par_suffix" ]] && output_file+=" $par_suffix"
            output_file+=".$par_extension"
            ;;
        "strip")
            # Remove the extension.
            output_file+=$(_strip_filename_extension "$filename")
            [[ -n "$par_suffix" ]] && output_file+=" $par_suffix"
            ;;
        esac
    fi

    # If the file already exists, add a suffix.
    output_file=$(_get_filename_next_suffix "$output_file")

    printf "%s" "$output_file"
}

# FUNCTION: _open_items_locations
#
# DESCRIPTION:
# This function opens the locations of selected items in the appropriate
# file manager.
#
# PARAMETERS:
#   $1 (items): A space-separated list of file or directory paths whose
#      locations will be opened. Paths can be relative or absolute.
#   $2 (resolve_links): A boolean-like string ('true' or 'false')
#      indicating whether symbolic links in the provided paths should be
#      resolved to their target locations before opening.
_open_items_locations() {
    local items=$1
    local par_resolve_links=$2

    # Exit if no items are provided.
    if [[ -z "$items" ]]; then
        return
    fi

    local file_manager=""
    file_manager=$(_get_available_file_manager)

    # Restore absolute paths for items if relative paths are used.
    local working_dir=""
    working_dir=$(_get_working_directory)
    items=$(sed "s|^\./|$working_dir/|g" <<<"$items")
    items=$(sed "s|^\([^/].*\)|$working_dir/\1|g" <<<"$items")

    # Prepare items to be opened by the file manager.
    local items_open=""
    local item=""
    for item in $items; do
        # Skip the root directory ("/") since opening it is redundant.
        if [[ "$item" == "/" ]]; then
            continue
        fi

        # Resolve symbolic links to their target locations if requested.
        if [[ "$par_resolve_links" == "true" ]] && [[ -L "$item" ]]; then
            item=$(readlink -f "$item")
        fi
        items_open+="$item$FIELD_SEPARATOR"
    done

    # Remove leading, trailing, and duplicate field separator.
    items_open=$(_str_collapse_char "$items_open" "$FIELD_SEPARATOR")

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
        # For other file managers (e.g., 'pcmanfm-qt'), open the directory of
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

# FUNCTION: _open_urls
#
# DESCRIPTION:
# This function opens a list of URLs in the system's default web browser.
#
# PARAMETERS:
#   $1 (urls): A space-separated list of URLs to be opened. Each URL
#      should be a valid web address (e.g., "http://example.com").
_open_urls() {
    local urls=$1
    local url=""

    # Exit if no URLs are provided.
    if [[ -z "$urls" ]]; then
        return
    fi

    for url in $urls; do
        # Ensure the URL starts with "http://" or "https://".
        if [[ ! "$url" =~ ^https?:// ]]; then
            url="https://$url"
        fi

        xdg-open "$url" &>/dev/null &
    done
}

# -----------------------------------------------------------------------------
# SECTION: File identification ----
# -----------------------------------------------------------------------------

# FUNCTION: _get_file_encoding
#
# DESCRIPTION:
# This function retrieves the MIME encoding of a specified file.
#
# PARAMETERS:
#   $1 (filename): The path to the file whose encoding is to be
#      determined.
_get_file_encoding() {
    local filename=$1
    local std_output=""

    std_output=$(file --dereference --brief --mime-encoding \
        -- "$filename" 2>/dev/null)

    if [[ "$std_output" == "cannot"* ]]; then
        return
    fi

    printf "%s" "$std_output"
}

# FUNCTION: _get_file_mime
#
# DESCRIPTION:
# This function retrieves the MIME type of a specified file.
#
# PARAMETERS:
#   $1 (filename): The path to the file whose MIME is to be determined.
_get_file_mime() {
    local filename=$1
    local std_output=""

    std_output=$(file --dereference --brief --mime-type \
        -- "$filename" 2>/dev/null)

    if [[ "$std_output" == "cannot"* ]]; then
        return
    fi

    printf "%s" "$std_output"
}

# FUNCTION: _get_items_count
#
# DESCRIPTION:
# This function counts the number of items in a string, where items are
# separated by a specific field separator. It assumes that the input string
# contains a list of items separated by the value of the variable
# '$FIELD_SEPARATOR'.
#
# PARAMETERS:
# - $1 (input_files): A string containing a list of items separated by
#   the defined '$FIELD_SEPARATOR'.
_get_items_count() {
    local input_files=$1
    local items_count=0

    if [[ -n "$input_files" ]]; then
        items_count=$(tr -cd "$FIELD_SEPARATOR" <<<"$input_files" | wc -c)
        ((items_count++))
    fi

    printf "%s" "$items_count"
}

# -----------------------------------------------------------------------------
# SECTION: Storage text management ----
# -----------------------------------------------------------------------------

# FUNCTION: _storage_text_clean
#
# DESCRIPTION:
# This function clears all temporary text storage files.
_storage_text_clean() {
    rm -f -- "$TEMP_DIR_STORAGE_TEXT/"* 2>/dev/null
}

# FUNCTION: _storage_text_read_all
#
# DESCRIPTION:
# This function concatenates and outputs the content of all temporary text
# storage files, from largest to smallest.
_storage_text_read_all() {
    find "$TEMP_DIR_STORAGE_TEXT" -type f -printf "%s %p\n" 2>/dev/null |
        sort -n -r | cut -d " " -f 2 - | xargs -r cat --
}

# FUNCTION: _storage_text_write
#
# DESCRIPTION:
# This function writes a given input text to temporary text storage files.
#
# PARAMETERS:
#   $1 (input_text): The text to be stored in a temporary file.
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

# FUNCTION: _storage_text_write_ln
#
# DESCRIPTION:
# This function writes a given input text, followed by a newline character,
# to a temporary text storage file.
_storage_text_write_ln() {
    local input_text=$1

    if [[ -z "$input_text" ]]; then
        return
    fi

    _storage_text_write "$input_text"$'\n'
}

# -----------------------------------------------------------------------------
# SECTION: String and text processing ----
# -----------------------------------------------------------------------------

# FUNCTION: _convert_delimited_string_to_text
#
# DESCRIPTION:
# This function converts a delimited string of items into
# newline-separated text.
#
# PARAMETERS:
#   $1 (input_items): A string containing items separated by the
#      '$FIELD_SEPARATOR' variable.
#
# RETURNS:
#   - A string containing the items separated by newlines.
_convert_delimited_string_to_text() {
    local input_items=$1
    local new_line="'\$'\\\n''"

    input_items=$(sed -z "s|\n|$new_line|g; s|$new_line$||g" <<<"$input_items")
    input_items=$(tr "$FIELD_SEPARATOR" "\n" <<<"$input_items")

    printf "%s" "$input_items"
}

# FUNCTION: _convert_text_to_delimited_string
#
# DESCRIPTION:
# This function converts newline-separated text into a delimited string of
# items.
#
# PARAMETERS:
#   $1 (input_items): A string containing items separated by newlines.
#
# RETURNS:
#   - A string containing the items separated by the '$FIELD_SEPARATOR'
#   variable.
_convert_text_to_delimited_string() {
    local input_items=$1
    local new_line="'\$'\\\n''"

    input_items=$(tr "\n" "$FIELD_SEPARATOR" <<<"$input_items")
    input_items=$(sed -z "s|$new_line|\n|g" <<<"$input_items")

    _str_collapse_char "$input_items" "$FIELD_SEPARATOR"
}

# FUNCTION: _str_collapse_char
#
# DESCRIPTION:
# This function collapses consecutive occurrences of a given character
# into a single one and removes any leading or trailing occurrences of it.
#
# PARAMETERS:
#   $1 (input_str): The input string to be processed.
#   $2 (char): The character to collapse and trim from the string.
_str_collapse_char() {
    local input_str=$1
    local char=$2

    local sed_p1="s|$char$char*|$char|g"
    local sed_p2="s|^$char||g"
    local sed_p3="s|$char$||g"

    sed "$sed_p1; $sed_p2; $sed_p3" <<<"$input_str"
}

# FUNCTION: _str_sort
#
# DESCRIPTION:
# This function sorts elements from a string based on a given separator.
#
# PARAMETERS:
#   $1 (input_str): The input string containing elements to be sorted.
#   $2 (separator): The character used to separate elements in the string.
#   $3 (unique): Optional flag ("true" or "false") to remove duplicates.
_str_sort() {
    local input_str=$1
    local separator=$2
    local unique=$3

    local unique_opt=""
    [[ "$unique" == "true" ]] && unique_opt="--unique"

    input_str=$(printf "%s" "$input_str" | tr "$separator" "\0" |
        sort --zero-terminated --version-sort $unique_opt |
        tr "\0" "$separator")
    _str_collapse_char "$input_str" "$separator"
}

# FUNCTION: _str_human_readable_path
#
# DESCRIPTION:
# This function transforms a given file path into a more human-readable
# format.
#
# PARAMETERS:
#   $1 (input_path): The input file path to process.
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
        output_path="(None)"
    else
        output_path="'$output_path'"
    fi

    printf "%s" "$output_path"
}

# FUNCTION: _text_remove_empty_lines
_text_remove_empty_lines() {
    local input_text=$1

    grep -v "^\s*$" <<<"$input_text"
}

# FUNCTION: _text_remove_home
#
# DESCRIPTION:
# This function replaces the user's home directory path in a given string
# with the tilde ("~") symbol for brevity.
#
# PARAMETERS:
#   $1 (input_text): The input string that may contain the user's home
#      directory path.
#
# RETURNS:
#   - The modified string with the home directory replaced by "~", or the
#     original string if '$HOME' is not defined.
#
# EXAMPLES:
#   - Input: "/home/user/documents/file.txt" (assuming '$HOME' is
#     "/home/user")
#   - Output: "~/documents/file.txt"
#
#   - Input: "/etc/config" (assuming '$HOME' is "/home/user")
#   - Output: "/etc/config"
_text_remove_home() {
    local input_text=$1

    if [[ -n "${HOME:-}" ]]; then
        sed "s|$HOME|~|g" <<<"$input_text"
    else
        printf "%s" "$input_text"
    fi
}

# FUNCTION: _text_remove_pwd
#
# DESCRIPTION:
# This function replaces the current working directory path in a given
# string with a dot ('.') for brevity.
#
# PARAMETERS:
#   $1 (input_text): The input string that may contain the current
#      working directory path.
#
# RETURNS:
#   - The modified string with the working directory replaced by ".", or
#     the original string if the working directory is not found.
#
# EXAMPLES:
#   - Input: "/home/user/project/file.txt" (assuming current directory is
#     "/home/user/project")
#   - Output: "./file.txt"
#
#   - Input: "/etc/config" (assuming current directory is
#     "/home/user/project")
#   - Output: "/etc/config"
_text_remove_pwd() {
    local input_text=$1
    local working_dir=""
    working_dir=$(_get_working_directory)

    if [[ "$working_dir" != "/" ]]; then
        sed "s|$working_dir/||g" <<<"$input_text"
    else
        printf "%s" "$input_text"
    fi
}

# FUNCTION: _text_sort
#
# DESCRIPTION:
# This function sorts the lines of a given text input in a version-aware
# manner.
#
# PARAMETERS:
#   $1 (input_text): The input text to be sorted, where each line is
#      treated as a separate string.
#
# RETURNS:
#   - The sorted text with each line in the correct order.
_text_sort() {
    local input_text=$1

    sort --version-sort <<<"$input_text"
}

# FUNCTION: _text_uri_decode
#
# DESCRIPTION:
# This function decodes a URI-encoded string by converting percent-encoded
# characters back to their original form.
#
# PARAMETERS:
#   $1 (uri_encoded): The URI-encoded string that needs to be decoded.
#
# RETURNS:
#   - The decoded URI string, with percent-encoded characters replaced and
#     the "file://" prefix removed.
#
# EXAMPLE:
#   - Input: "file:///home/user%20name/file%20name.txt"
#   - Output: "/home/user name/file name.txt"
_text_uri_decode() {
    local uri_encoded=$1

    uri_encoded=${uri_encoded//%/\\x}
    uri_encoded=${uri_encoded//file:\/\//}

    # shellcheck disable=SC2059
    printf "$uri_encoded"
}

# -----------------------------------------------------------------------------
# SECTION: External application wrappers ----
# -----------------------------------------------------------------------------

# FUNCTION: _cmd_magick_convert
#
# DESCRIPTION:
# This function executes ImageMagick's "convert" command in a
# version-compatible way. In ImageMagick 7+, the main executable is "magick",
# so this function calls "magick convert". In ImageMagick 6 (legacy version),
# the command "convert" is used directly.
#
# PARAMETERS:
#   $@ : Arguments to be passed to the convert command.
_cmd_magick_convert() {
    if _command_exists "magick"; then
        magick convert "$@"
    else
        convert "$@"
    fi
}

# FUNCTION: _initialize_homebrew
#
# Initializes the Homebrew environment if it is installed in the user's local
# directory. This function ensures Homebrew commands are available in the
# current shell session and configures environment variables to make it run
# quietly and without analytics.
_initialize_homebrew() {
    # Skip initialization if Homebrew is already available in 'PATH'.
    [[ -n "${HOMEBREW_PREFIX:-}" ]] && return

    local homebrew_dir="$HOME/.local/apps/homebrew"
    local brew_cmd="$homebrew_dir/bin/brew"

    if [[ -f "$brew_cmd" ]]; then
        # Skip initialization if 'curl' and 'git' are not available in 'PATH'.
        if _command_exists "curl" && _command_exists "git"; then
            # Load the Homebrew environment into the current shell session.
            eval "$($brew_cmd shellenv)"
        fi
    fi
}

# -----------------------------------------------------------------------------
# SECTION: Scripts recent history ----
# -----------------------------------------------------------------------------

# FUNCTION: _recent_scripts_add
#
# DESCRIPTION:
# This function adds the running script to the history of recently accessed
# scripts ('$ACCESSED_RECENTLY_DIR').
#
# RETURNS:
#   "0" (true): If the script was added successfully.
#   "1" (false): If there was an error adding the script.
_recent_scripts_add() {
    local running_script=$0
    if [[ "$0" != "/"* ]]; then
        # If '$0' is a relative path, resolve it relative to the current
        # working directory.
        running_script="$SCRIPT_DIR/"$(basename -- "$0")
    fi

    # Resolve symbolic links to their target locations.
    if [[ -L "$running_script" ]]; then
        running_script=$(readlink -f "$running_script")
    fi

    # Create '$ACCESSED_RECENTLY_DIR' if it does not exist.
    if [[ ! -d $ACCESSED_RECENTLY_DIR ]]; then
        mkdir -p "$ACCESSED_RECENTLY_DIR"
    fi

    _directory_push "$ACCESSED_RECENTLY_DIR" || return 1

    # Remove any existing links pointing to the same script.
    find "$ACCESSED_RECENTLY_DIR" -lname "$running_script" \
        -exec rm -f -- "{}" +

    # Create a new symbolic link with a ".00" prefix.
    ln -s -- "$running_script" ".00 $(basename -- "$running_script")"

    _directory_pop || return 1
}

# FUNCTION: _recent_scripts_organize
#
# DESCRIPTION:
# This function organizes the directory containing recently accessed
# scripts ('$ACCESSED_RECENTLY_DIR'). This function manages symbolic links
# in the directory by:
# 1. Keeping only the '$ACCESSED_RECENTLY_LINKS_TO_KEEP' most recently
#    accessed scripts.
# 2. Renaming retained links with numeric prefixes (e.g., "01", "02") to
#    maintain chronological order.
_recent_scripts_organize() {
    local links=()
    local link=""
    while IFS= read -r -d $'\0' link; do
        # Check if the link is broken.
        if [[ ! -e "$link" ]]; then
            # Remove broken links.
            rm -f -- "$link"
        else
            links+=("$link")
        fi
    done < <(find "$ACCESSED_RECENTLY_DIR" -maxdepth 1 -type l \
        -print0 2>/dev/null | sort --zero-terminated --numeric-sort)

    # Process the links, keeping only the '$ACCESSED_RECENTLY_LINKS_TO_KEEP'
    # most recent.
    local count=1
    local link_name=""
    for link in "${links[@]}"; do
        if ((count <= ACCESSED_RECENTLY_LINKS_TO_KEEP)); then
            # Rename the link with a numeric prefix for ordering.
            link_name=$(basename "$link" |
                sed --regexp-extended 's|^.?[0-9]{2} ||')
            mv -f -- "$link" \
                "$ACCESSED_RECENTLY_DIR/$(printf '%02d' "$count") $link_name" \
                2>/dev/null
            ((count++))
        else
            # Remove excess links.
            rm -f -- "$link"
        fi
    done
}

# Execute functions to organize the recently accessed scripts.
_recent_scripts_add
_recent_scripts_organize

# Initialize Homebrew environment if available.
_initialize_homebrew
