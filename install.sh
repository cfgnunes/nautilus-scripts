#!/usr/bin/env bash
# =============================================================================
# Description: Install the Enhanced File Manager Actions.
#
# Usage:
#   bash install.sh [options]
#
# Options:
#   -c, --check-dependencies        Check for basic dependencies.
#   -C, --no-check-dependencies     Do not check for basic dependencies.
#   -d, --sub-category NAME         Install the scripts in a subcategory.
#   -f, --close-file-manager        Close file manager after install.
#   -F, --no-close-file-manager     Do not close file manager after install.
#   -k, --install-shortcuts         Install keyboard accelerators.
#   -K, --no-install-shortcuts      Do not install keyboard accelerators.
#   -n, --non-interactive           Run without prompts.
#   -q, --quiet                     Suppress all output (silent mode).
#   -p, --install-pkgx              Install pkgx for dependencies.
#   -P, --no-install-pkgx           Do not install pkgx.
#   -h, --help                      Show this help message and exit.
# =============================================================================

set -u

# -----------------------------------------------------------------------------
# SECTION: Constants
# -----------------------------------------------------------------------------

APP_FULL_NAME="Enhanced File Manager Actions"
APP_NAME="nautilus-scripts"
APP_VERSION="33.2"

# Use the home directory from the passwd database if '$HOME' is undefined.
HOME=${HOME:-$(eval echo ~)}
USER_OPT_DIR="$HOME/.local/opt"
INSTALL_DIR="$USER_OPT_DIR/$APP_NAME"

# Constants for logging.
if [[ -z "${TEMP_DIR:-}" ]]; then
    TEMP_DIR=$(mktemp --directory)
    export TEMP_DIR
fi
INSTALL_LOG_NAME="install.log"
INSTALL_LOG_TMP="$TEMP_DIR/$INSTALL_LOG_NAME"

# List of supported file managers.
COMPATIBLE_FILE_MANAGERS=(
    "nautilus"
    "dolphin"
    "nemo"
    "caja"
    "thunar"
    "pcmanfm-qt"
    "pcmanfm"
    "krusader"
)

# Directories to be ignored during install.
IGNORE_FIND_PATHS=(
    ! -path "*/.editorconfig"
    ! -path "*/install.sh"
    ! -path "*/LICENSE.txt"
    ! -path "*/README.md"
    ! -path "*/screenshot.svg"
    ! -path "*/uninstall.sh"
    ! -path "*/.git*"
    ! -path "*/.installer*"
    ! -path "*/.po*"
    ! -path "*/.tests*"
)

# Define the directory of this script. If '$BASH_SOURCE' is available,
# use its path. Otherwise, create a temporary directory for cases like remote
# execution via curl.
if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
    SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
else
    SCRIPT_DIR="."
fi

# Mark constants as read-only to prevent accidental modification.
# shellcheck disable=SC2034
readonly \
    APP_FULL_NAME \
    APP_NAME \
    APP_VERSION \
    COMPATIBLE_FILE_MANAGERS \
    IGNORE_FIND_PATHS \
    INSTALL_DIR \
    INSTALL_LOG_NAME \
    INSTALL_LOG_TMP \
    SCRIPT_DIR \
    USER_OPT_DIR

# Use current username if '$USER' is undefined.
USER=${USER:-$(id -un)}

# -----------------------------------------------------------------------------
# SECTION: Global variables
# -----------------------------------------------------------------------------

INSTALL_OWNER="" # Owner of the installation directory.
INSTALL_GROUP="" # Group of the installation directory.

# Default main menu options.
OPT_INSTALL_BASIC_DEPS="true"
OPT_INSTALL_ACCELS="true"
OPT_CLOSE_FILE_MANAGER="true"
OPT_INSTALL_PKGX="false"
OPT_CHOOSE_CATEGORIES="false"
# Default installer options.
OPT_INTERACTIVE_INSTALL="true"
OPT_QUIET_INSTALL="false"

# Optional sub-category for the installed scripts (e.g. "cfgnunes").
INSTALL_SUBCATEGORY=""

# -----------------------------------------------------------------------------
# SECTION: Imports
# -----------------------------------------------------------------------------

# Import the helper scripts for the installer.
for _helper in "$SCRIPT_DIR"/.installer/*.sh; do
    if [[ -f "$_helper" ]]; then
        #shellcheck source=/dev/null
        source "$_helper"
    fi
done
unset _helper

# -----------------------------------------------------------------------------
# SECTION: Command line
# -----------------------------------------------------------------------------

_get_parameters_command_line() {
    local -a expanded_args=()

    # Expand combined short options (e.g. -ia -> -i -a).
    while [[ $# -gt 0 ]]; do
        if [[ "$1" =~ ^-[a-zA-Z]{2,}$ ]]; then
            # Split combined short options (e.g. -ia -> -i -a).
            local arg="${1#-}"
            local i=""
            for ((i = 0; i < ${#arg}; i++)); do
                expanded_args+=("-${arg:i:1}")
            done
        else
            expanded_args+=("$1")
        fi
        shift
    done

    # Replace positional parameters with expanded arguments.
    if ((${#expanded_args[@]})); then
        set -- "${expanded_args[@]}"
    else
        set --
    fi

    # Read parameters from command line.
    while [[ $# -gt 0 ]]; do
        case "$1" in
        -c | --check-dependencies) OPT_INSTALL_BASIC_DEPS="true" ;;
        -C | --no-check-dependencies) OPT_INSTALL_BASIC_DEPS="false" ;;
        -f | --close-file-manager) OPT_CLOSE_FILE_MANAGER="true" ;;
        -F | --no-close-file-manager) OPT_CLOSE_FILE_MANAGER="false" ;;
        -k | --install-shortcuts) OPT_INSTALL_ACCELS="true" ;;
        -K | --no-install-shortcuts) OPT_INSTALL_ACCELS="false" ;;
        -d | --sub-category)
            INSTALL_SUBCATEGORY=${2:-}
            shift
            if [[ -z "$INSTALL_SUBCATEGORY" ||
                "/$INSTALL_SUBCATEGORY/" == *"/../"* ]]; then
                echo "Invalid sub-category name." >&2
                exit 1
            fi
            INSTALL_SUBCATEGORY=${INSTALL_SUBCATEGORY#/}
            INSTALL_SUBCATEGORY=${INSTALL_SUBCATEGORY%/}
            ;;
        -n | --non-interactive) OPT_INTERACTIVE_INSTALL="false" ;;
        -p | --install-pkgx) OPT_INSTALL_PKGX="true" ;;
        -P | --no-install-pkgx) OPT_INSTALL_PKGX="false" ;;
        -q | --quiet) OPT_QUIET_INSTALL="true" ;;
        -h | --help)
            echo "Usage: $0 [options]"
            echo
            echo "  -c, --check-dependencies        Check for basic dependencies."
            echo "  -C, --no-check-dependencies     Do not check for basic dependencies."
            echo "  -d, --sub-category NAME         Install the scripts in a subcategory."
            echo "  -f, --close-file-manager        Close file manager after install."
            echo "  -F, --no-close-file-manager     Do not close file manager after install."
            echo "  -k, --install-shortcuts         Install keyboard accelerators."
            echo "  -K, --no-install-shortcuts      Do not install keyboard accelerators."
            echo "  -n, --non-interactive           Run without prompts."
            echo "  -q, --quiet                     Suppress all output (silent mode)."
            echo "  -p, --install-pkgx              Install pkgx for dependencies."
            echo "  -P, --no-install-pkgx           Do not install pkgx."
            echo "  -h, --help                      Show this help message and exit."
            echo
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Use --help for usage information." >&2
            exit 1
            ;;
        esac
        shift
    done
}

# -----------------------------------------------------------------------------
# SECTION: Main flow
# -----------------------------------------------------------------------------

_on_exit() {
    rm -rf -- "$TEMP_DIR" 2>/dev/null
}
trap _on_exit EXIT

# shellcheck disable=SC2034
_main() {
    # Variables for the main menu.
    local -a menu_labels=()
    local -a menu_initial_values=()
    local -a menu_checked_values=()
    # Variables for the categories menu.
    local -a cat_dirs=()
    local -a cat_dirs_translated=()
    local -a cat_initial_values=()
    local -a cat_checked_values=()

    _log "[INF] Installation started."

    # Prevent running the installer with sudo/root.
    if [[ "$(id -u)" -eq 0 ]]; then
        _echo_error "Do NOT run as root! Use: 'bash install.sh'"
        exit 1
    fi

    _get_parameters_command_line "$@"

    # If quiet mode is enabled, automatically disable interactive mode to
    # ensure a fully silent and non-interactive installation.
    if [[ "$OPT_QUIET_INSTALL" == "true" ]]; then
        OPT_INTERACTIVE_INSTALL="false"
    fi

    # If the file ".common-functions.sh" is missing, it means the installer is
    # being executed remotely (e.g., via 'curl'). In that case, download the
    # tarball and continue the installation from the extracted files.
    if [[ ! -f "$SCRIPT_DIR/.common-functions.sh" ]]; then
        _log "[INF] Running remote installer."
        _bootstrap_repository "$@"
        exit $?
    fi
    _log_system_variables
    _i18n_initialize

    # Available options presented in the interactive menu.
    menu_labels=(
        "$(_i18n 'Check for basic dependencies')"
        "$(_i18n 'Install keyboard accelerators')"
        "$(_i18n 'Close the file manager to reload configuration')"
        "$(_i18n 'Install pkgx for dependencies')"
        "$(_i18n 'Choose script categories to install')"
    )

    # Default states for the menu options.
    menu_initial_values=(
        "$OPT_INSTALL_BASIC_DEPS"
        "$OPT_INSTALL_ACCELS"
        "$OPT_CLOSE_FILE_MANAGER"
        "$OPT_INSTALL_PKGX"
        "$OPT_CHOOSE_CATEGORIES"
    )

    _echo "$APP_FULL_NAME v$APP_VERSION"
    _echo ""

    _log_variable "APP_VERSION"

    if [[ "$OPT_INTERACTIVE_INSTALL" == "true" ]]; then
        _echo "$(_i18n 'Select the options (<SPACE> to check, <ENTER> to confirm):')"
        _multiselect_menu \
            menu_labels \
            menu_initial_values \
            menu_checked_values || return 1
    else
        _echo_info "$(_i18n 'Installing in non-interactive mode...')"
        menu_checked_values=("${menu_initial_values[@]}")
    fi

    # Map menu selections into a comma-separated string of options.
    OPT_INSTALL_BASIC_DEPS=${menu_checked_values[0]}
    OPT_INSTALL_ACCELS=${menu_checked_values[1]}
    OPT_CLOSE_FILE_MANAGER=${menu_checked_values[2]}
    OPT_INSTALL_PKGX=${menu_checked_values[3]}
    OPT_CHOOSE_CATEGORIES=${menu_checked_values[4]}

    _log_variable "OPT_INSTALL_BASIC_DEPS"
    _log_variable "OPT_INSTALL_ACCELS"
    _log_variable "OPT_CLOSE_FILE_MANAGER"
    _log_variable "OPT_INSTALL_PKGX"
    _log_variable "OPT_CHOOSE_CATEGORIES"
    _log_variable "OPT_INTERACTIVE_INSTALL"
    _log_variable "OPT_QUIET_INSTALL"
    _log_variable "INSTALL_SUBCATEGORY"

    # Collect all available script categories (directories).
    local dir=""
    while IFS= read -r -d '' dir; do
        cat_dirs+=("$dir")
        cat_dirs_translated+=("$(_i18n "$dir")")
        cat_initial_values+=("true")
    done < <(_list_scripts_categories)

    # If requested, let the user select which categories to install.
    if [[ "$OPT_CHOOSE_CATEGORIES" == "true" ]]; then
        _echo ""
        _echo "$(_i18n 'Select the options (<SPACE> to check, <ENTER> to confirm):')"
        _multiselect_menu \
            cat_dirs_translated \
            cat_initial_values \
            cat_checked_values || return 1
    fi

    # Step 1: Check for basic dependencies.
    [[ "$OPT_INSTALL_BASIC_DEPS" == "true" ]] && _check_dependencies

    # Step 2: Install the scripts.
    INSTALL_OWNER=$(stat -c "%U" "$HOME")
    INSTALL_GROUP=$(stat -c "%G" "$HOME")

    _log_variable "INSTALL_OWNER"
    _log_variable "INSTALL_GROUP"

    _echo ""
    _echo_info "$(_i18n 'Installing:')"
    _echo_info "> $(_i18n 'User'): $INSTALL_OWNER"
    _echo_info "> $(_i18n 'Directory'): $INSTALL_DIR"
    _install_scripts cat_checked_values cat_dirs

    # Step 3: Install file manager configurations.
    # Install the actions and the keyboard accelerators for
    # each detected file manager.
    local file_manager=""
    for file_manager in "${COMPATIBLE_FILE_MANAGERS[@]}"; do
        if ! _command_exists "$file_manager"; then
            continue
        fi

        # Step 3.1: Install the actions.
        _install_actions "$file_manager"

        # Step 3.2: Install the keyboard accelerators.
        [[ "$OPT_INSTALL_ACCELS" == "true" ]] && _install_accels "$file_manager"

        # Step 3.3: Close file manager to reload its configuration.
        [[ "$OPT_CLOSE_FILE_MANAGER" == "true" ]] && _close_file_manager "$file_manager"
        _echo_info "> $(_i18n 'Done!')"
    done

    # Step 4: Install pkgx (optional).
    if [[ "$OPT_INSTALL_PKGX" == "true" ]]; then
        _install_pkgx
    fi

    _echo ""
    _echo_info "$(_i18n 'Installation completed successfully!')"
    _log "[INF] Installation completed successfully!"

    # Step 5: Move the temporary log file to the installation directory and
    # remove the temporary directory.
    mv -- "$INSTALL_LOG_TMP" "$INSTALL_DIR/$INSTALL_LOG_NAME" 2>/dev/null
}

# -----------------------------------------------------------------------------
# SECTION: Online installation
# -----------------------------------------------------------------------------

# Function: _bootstrap_repository
#
# Description:
#   This function ensures that the repository files are available before
#   running the installation.
_bootstrap_repository() {
    local repo_owner="cfgnunes"
    local repo_name="nautilus-scripts"
    local branch="main"

    # Check if 'curl' or 'wget' is available.
    local downloader=""
    if _command_exists "curl"; then
        downloader="curl"
    elif _command_exists "wget"; then
        downloader="wget"
    else
        _echo_error "Neither 'curl' nor 'wget' is installed! Please install one of them to continue."
        exit 1
    fi

    _echo_info "Downloading the installer package..."

    # Download and extract the HEAD of the branch.
    local tarball_url="https://github.com/${repo_owner}/${repo_name}/archive/refs/heads/${branch}.tar.gz"
    {
        if [[ "$downloader" == "curl" ]]; then
            curl -fsL "$tarball_url" | tar -xz -C "$TEMP_DIR"
        else
            wget -qO- "$tarball_url" | tar -xz -C "$TEMP_DIR"
        fi
    } 2>/dev/null

    # Identify the extracted directory.
    local extracted_dir=""
    local install_exit=0
    extracted_dir=$(
        find "$TEMP_DIR" -maxdepth 1 -type d -name "${repo_name}*" | head -n 1
    )

    # Validate extracted content.
    if [[ ! -f "$extracted_dir/install.sh" ]]; then
        _echo_error "Could not find 'install.sh' in extracted files."
        exit 1
    fi

    # Run the installer from the extracted directory.
    _echo_info "Running installation from extracted files..."
    _echo ""
    cd "$extracted_dir" || exit 1
    bash install.sh "$@"
    install_exit=$?

    return "$install_exit"
}

# -----------------------------------------------------------------------------
# SECTION: Output and logging
# -----------------------------------------------------------------------------

_echo() {
    local message=$1
    if [[ -n "$message" ]]; then
        _log "[MSG] $message"
    fi

    if [[ "$OPT_QUIET_INSTALL" == "true" ]]; then
        return
    fi

    echo "$message"
}

_echo_info() {
    local message=$1
    _log "[MSG] $message"

    if [[ "$OPT_QUIET_INSTALL" == "true" ]]; then
        return
    fi

    local msg_info="[\033[0;32m INFO \033[0m]"
    echo -e "$msg_info $message"
}

_echo_error() {
    local message=$1
    _log "[ERR] $message"

    local msg_error="[\033[0;31mFAILED\033[0m]"
    echo -e "$msg_error $message"
}

_print_date() {
    date +"%Y-%m-%d %T %Z"
}

_log() {
    local message=$1
    printf "%s\n" "$(_print_date) $message" >>"$INSTALL_LOG_TMP"
}

_log_system_variables() {
    _log_variable "USER"
    _log_variable "HOME"
    _log_variable "SHELL"
    _log_variable "LANG"
    _log_variable "XDG_CURRENT_DESKTOP"
    _log_variable "XDG_SESSION_TYPE"
}

_log_variable() {
    local var_name=$1
    local var_value="${!var_name:-}"
    _log "[VAR] $var_name=\"$var_value\""
}

# -----------------------------------------------------------------------------
# SECTION: Utilities
# -----------------------------------------------------------------------------

_tee_file() {
    tee -- "$1" >/dev/null
}

_tee_file_append() {
    tee --append -- "$1" >/dev/null
}

_item_create_backup() {
    local item=$1

    if [[ -e "$item" && ! -e "$item.bak" ]]; then
        cp -a -- "$item" "$item.bak" 2>/dev/null
    fi
}

_replace_file() {
    local src_file=$1
    local dst_file=$2

    _item_create_backup "$dst_file"
    mv -f -- "$src_file" "$dst_file"
}

_command_exists() {
    local command_check=$1

    command -v "$command_check" &>/dev/null || return 1
}

_get_par_value() {
    local filename=$1
    local parameter=$2

    grep --only-matching -m 1 "$parameter=.*" "$filename" |
        cut -d "=" -f 2- 2>/dev/null
}

_sanitize_string() {
    tr -cd ";[:alnum:] -" | tr " " "-" | tr -s "-" | tr "[:upper:]" "[:lower:]"
}

# -----------------------------------------------------------------------------
# SECTION: Scripts
# -----------------------------------------------------------------------------

_install_scripts() {
    local -n _cat_checked_values=$1
    local -n _cat_dirs=$2

    rm -rf -- "$INSTALL_DIR" 2>/dev/null

    _echo_info "> $(_i18n 'Copying files...')"
    mkdir --parents -- "$INSTALL_DIR"
    cp -rf -- "$SCRIPT_DIR/." "$INSTALL_DIR"

    # Remove unselected categories from the install directory.
    if [[ ${#_cat_checked_values[@]} -gt 0 ]]; then
        local i=0
        for i in "${!_cat_dirs[@]}"; do
            if [[ ${_cat_checked_values[i]} == "false" ]]; then
                rm -rf -- "$INSTALL_DIR/${_cat_dirs[i]:?}"
            fi
        done
    fi

    # Adjust ownership and permissions. Ensures all files belong to
    # the correct user/group and are executable.
    chown -R "$INSTALL_OWNER:$INSTALL_GROUP" -- "$INSTALL_DIR"
    find -L "$INSTALL_DIR" -mindepth 2 -type f \
        "${IGNORE_FIND_PATHS[@]}" -exec chmod +x -- {} +
}

_list_scripts() {
    find -L "$INSTALL_DIR" -mindepth 2 -type f \
        "${IGNORE_FIND_PATHS[@]}" \
        -print0 2>/dev/null | sort --zero-terminated
}

_list_scripts_categories() {
    find -L "$SCRIPT_DIR" -mindepth 1 -maxdepth 1 -type d \
        "${IGNORE_FIND_PATHS[@]}" -print0 2>/dev/null |
        sed -z "s|^.*/||" | sort --zero-terminated
}

# -----------------------------------------------------------------------------
# SECTION: File managers
# -----------------------------------------------------------------------------

# Function: _check_exist_file_manager
#
# Description:
#   This function checks if at least one compatible file manager exists in the
#   system by iterating through a predefined list of supported file managers
#   defined in '$COMPATIBLE_FILE_MANAGERS'.
_check_exist_file_manager() {
    local file_manager=""
    for file_manager in "${COMPATIBLE_FILE_MANAGERS[@]}"; do
        if _command_exists "$file_manager"; then
            return 0
        fi
    done
    return 1
}

_install_accels() {
    local file_manager=$1

    _echo_info "> ($file_manager) $(_i18n 'Installing keyboard accelerators...')"

    case "$file_manager" in
    "nautilus") _install_accels_nautilus ;;
    "caja") _install_accels_caja ;;
    "nemo") _install_accels_nemo ;;
    "thunar") _install_accels_thunar ;;
    esac
}

# Function: _install_actions
#
# Description:
#   This function install actions (context menus) for supported file managers.
#   Delegates to the appropriate function depending on the detected file
#   manager.
_install_actions() {
    local file_manager=$1

    _echo_info "> ($file_manager) $(_i18n 'Installing actions in the context menu...')"

    case "$file_manager" in
    "nautilus") _install_actions_nautilus ;;
    "caja") _install_actions_caja ;;
    "nemo") _install_actions_nemo ;;
    "dolphin") _install_actions_dolphin ;;
    "pcmanfm" | "pcmanfm-qt") _install_actions_pcmanfm ;;
    "thunar") _install_actions_thunar ;;
    "krusader") _install_actions_krusader ;;
    esac
}

_close_file_manager() {
    local file_manager=$1

    if [[ -z "$file_manager" ||
        "$file_manager" == "dolphin" ||
        "$file_manager" == "krusader" ]]; then
        return
    fi

    _echo_info "> ($file_manager) $(_i18n 'Closing the file manager...')"

    case "$file_manager" in
    "nautilus") _close_file_manager_nautilus ;;
    "caja") _close_file_manager_caja ;;
    "nemo") _close_file_manager_nemo ;;
    "thunar") _close_file_manager_thunar ;;
    "pcmanfm" | "pcmanfm-qt") _close_file_manager_pcmanfm "$file_manager" ;;
    esac
}

_main "$@"
