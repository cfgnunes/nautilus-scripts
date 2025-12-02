#!/usr/bin/env bash

# =============================================================================
# PROJECT: Enhanced File Manager Actions for Linux
# AUTHOR: Cristiano Fraga G. Nunes
# REPOSITORY: https://github.com/cfgnunes/fm-scripts
# LICENSE: MIT License
# VERSION: 30.7
# =============================================================================

set -u

#------------------------------------------------------------------------------
#region Constants
#------------------------------------------------------------------------------

APP_NAME="Enhanced File Manager Actions for Linux"
APP_VERSION="30.7"

# Used in:
#  - Directory where scripts are installed located at:
#    "$HOME/.local/share/$INSTALL_NAME_DIR".
#  - Directory where shortcuts (application menu) are stored located at:
#    "$HOME/.local/share/applications/$INSTALL_NAME_DIR".
INSTALL_NAME_DIR="scripts"
INSTALL_PATH=".local/share/$INSTALL_NAME_DIR"
INSTALL_APPS_SHORTCUTS_PATH=".local/share/applications/$INSTALL_NAME_DIR"

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

# Ignored application menu shortcuts during install.
IGNORE_APPS_SHORTCUTS=(
    ! -iname "Code Editor"
    ! -iname "Disk Usage Analyzer"
    ! -iname "Terminal"
    ! -iname "Extract here"
    ! -iname "Create hard link here"
    ! -iname "Create symbolic link here"
    ! -iname "Paste as hard link"
    ! -iname "Paste as symbolic link"
    ! -iname "Paste clipboard content"
)

# Directories to be ignored during install.
IGNORE_FIND_PATHS=(
    ! -path "*/.helpers*"
    ! -path "*/.git*"
    ! -path "*/.po*"
)

# Define the directory of this script. If '$BASH_SOURCE' is available,
# use its path. Otherwise, create a temporary directory for cases like remote
# execution via curl.
if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
    SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
else
    SCRIPT_DIR="."
fi

I18N_DIR="$SCRIPT_DIR/.po"

# Mark constants as read-only to prevent accidental modification.
readonly \
    APP_NAME \
    APP_VERSION \
    COMPATIBLE_FILE_MANAGERS \
    I18N_DIR \
    IGNORE_FIND_PATHS \
    INSTALL_APPS_SHORTCUTS_PATH \
    INSTALL_LOG_NAME \
    INSTALL_LOG_TMP \
    INSTALL_NAME_DIR \
    INSTALL_PATH \
    SCRIPT_DIR

# Use current username if '$USER' is undefined.
USER=${USER:-$(id -un)}

#endregion
#------------------------------------------------------------------------------
#region Global variables
#------------------------------------------------------------------------------

FILE_MANAGER=""  # Current file manager being processed.
I18N_FILE=""     # Current translation file being used.
INSTALL_DIR=""   # Target installation directory for scripts.
INSTALL_HOME=""  # User's home directory where scripts will be installed.
INSTALL_OWNER="" # Owner of the installation directory.
INSTALL_GROUP="" # Group of the installation directory.

# Default main menu options.
OPT_INSTALL_BASIC_DEPS="true"
OPT_REMOVE_SCRIPTS="true"
OPT_INSTALL_ACCELS="true"
OPT_CLOSE_FILE_MANAGER="true"
OPT_INSTALL_APP_SHORTCUTS="false"
OPT_INSTALL_HOMEBREW="false"
OPT_CHOOSE_CATEGORIES="false"
# Default core options.
OPT_INTERACTIVE_INSTALL="true"
OPT_QUIET_INSTALL="false"

# Import helper script for interactive multi-selection menus.
#shellcheck source=.helpers/.multiselect-menu.sh
if [[ -f "$SCRIPT_DIR/.helpers/.multiselect-menu.sh" ]]; then
    source "$SCRIPT_DIR/.helpers/.multiselect-menu.sh"
fi

#endregion
#------------------------------------------------------------------------------
#region Main flow
#------------------------------------------------------------------------------

_on_exit() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        _log "[ERR] Installation terminated with exit code $exit_code."
    fi
}
trap _on_exit EXIT

# shellcheck disable=SC2034
_main() {
    local cat_defaults=()
    local cat_dirs=()
    local cat_selected=()
    local menu_defaults=()
    local menu_labels=()
    local menu_selected=()

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
        exit 0
    fi
    _log_system_info
    _i18n_initialize

    # Available options presented in the interactive menu.
    menu_labels=(
        "$(_i18n 'Check for basic dependencies')"
        "$(_i18n 'Remove previously installed scripts')"
        "$(_i18n 'Install keyboard accelerators')"
        "$(_i18n 'Close the file manager to reload configurations')"
        "$(_i18n 'Add shortcuts to the application menu')"
        "$(_i18n 'Install Homebrew (optional)')"
        "$(_i18n 'Choose which script categories to install')"
    )

    # Default states for the menu options.
    menu_defaults=(
        "$OPT_INSTALL_BASIC_DEPS"
        "$OPT_REMOVE_SCRIPTS"
        "$OPT_INSTALL_ACCELS"
        "$OPT_CLOSE_FILE_MANAGER"
        "$OPT_INSTALL_APP_SHORTCUTS"
        "$OPT_INSTALL_HOMEBREW"
        "$OPT_CHOOSE_CATEGORIES"
    )

    _echo "$APP_NAME v$APP_VERSION"
    _echo ""

    _log_variable "APP_VERSION"

    if [[ "$OPT_INTERACTIVE_INSTALL" == "true" ]]; then
        _echo "$(_i18n 'Select the options (<SPACE> to check, <ENTER> to confirm):')"

        # Display the interactive menu and capture user selections.
        _multiselect_menu menu_selected menu_labels menu_defaults
    else
        _echo_info "$(_i18n 'Installing in non-interactive mode...')"
        menu_selected=("${menu_defaults[@]}")
    fi

    # Map menu selections into a comma-separated string of options.
    OPT_INSTALL_BASIC_DEPS=${menu_selected[0]}
    OPT_REMOVE_SCRIPTS=${menu_selected[1]}
    OPT_INSTALL_ACCELS=${menu_selected[2]}
    OPT_CLOSE_FILE_MANAGER=${menu_selected[3]}
    OPT_INSTALL_APP_SHORTCUTS=${menu_selected[4]}
    OPT_INSTALL_HOMEBREW=${menu_selected[5]}
    OPT_CHOOSE_CATEGORIES=${menu_selected[6]}

    _log_variable "OPT_INSTALL_BASIC_DEPS"
    _log_variable "OPT_REMOVE_SCRIPTS"
    _log_variable "OPT_INSTALL_ACCELS"
    _log_variable "OPT_CLOSE_FILE_MANAGER"
    _log_variable "OPT_INSTALL_APP_SHORTCUTS"
    _log_variable "OPT_INSTALL_HOMEBREW"
    _log_variable "OPT_CHOOSE_CATEGORIES"
    _log_variable "OPT_INTERACTIVE_INSTALL"
    _log_variable "OPT_QUIET_INSTALL"

    # Collect all available script categories (directories).
    local dir=""
    while IFS= read -r -d $'\0' dir; do
        cat_dirs+=("$dir")
    done < <(_list_scripts_categories)

    # If requested, let the user select which categories to install.
    if [[ "$OPT_CHOOSE_CATEGORIES" == "true" ]]; then
        _echo ""
        _echo "$(_i18n 'Select the options (<SPACE> to check, <ENTER> to confirm):')"
        _multiselect_menu cat_selected cat_dirs cat_defaults
    fi

    #region Step 1: Check for basic dependencies
    [[ "$OPT_INSTALL_BASIC_DEPS" == "true" ]] && _check_dependencies
    #endregion

    #region Step 2: Install the scripts
    INSTALL_HOME=$HOME
    INSTALL_OWNER=$(stat -c "%U" "$INSTALL_HOME")
    INSTALL_GROUP=$(stat -c "%G" "$INSTALL_HOME")

    _log_variable "INSTALL_OWNER"
    _log_variable "INSTALL_GROUP"

    INSTALL_DIR="$INSTALL_HOME/$INSTALL_PATH"

    _echo ""
    _echo_info "$(_i18n 'Installing:')"
    _echo_info "> $(_i18n 'User'): $INSTALL_OWNER"
    _echo_info "> $(_i18n 'Directory'): $INSTALL_DIR"
    _install_scripts cat_selected cat_dirs
    #endregion

    #region Step 3: Install file manager configurations
    # Install the actions and the keyboard accelerators for
    # each detected file manager.
    local file_manager=""
    for file_manager in "${COMPATIBLE_FILE_MANAGERS[@]}"; do
        FILE_MANAGER=$file_manager
        if ! _command_exists "$FILE_MANAGER"; then
            continue
        fi

        #region Step 3.1: Install the the actions
        _install_actions
        #endregion

        #region Step 3.2: Install the keyboard accelerators
        [[ "$OPT_INSTALL_ACCELS" == "true" ]] && _install_accels
        #endregion

        #region Step 3.3: Reload file manager to apply changes
        [[ "$OPT_CLOSE_FILE_MANAGER" == "true" ]] && _close_filemanager
        _echo_info "> $(_i18n 'Done!')"
        #endregion
    done
    #endregion

    #region Step 4: Install the shortcuts (application menu)
    if [[ "$OPT_INSTALL_APP_SHORTCUTS" == "true" ]]; then
        _echo ""
        _echo_info "$(_i18n 'Installing application menu shortcuts:')"
        _install_application_shortcuts
        _create_gnome_application_folder
        _echo_info "> $(_i18n 'Done!')"
    fi
    #endregion

    #region Step 5: Install Homebrew (optional)
    if [[ "$OPT_INSTALL_HOMEBREW" == "true" ]]; then
        _install_homebrew
    fi
    #endregion

    _echo ""
    _echo_info "$(_i18n 'Installation completed successfully!')"
    _log_finish
}

#endregion
#------------------------------------------------------------------------------
#region Printing
#------------------------------------------------------------------------------

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

#endregion
#------------------------------------------------------------------------------
#region Log functions
#------------------------------------------------------------------------------

_print_date() {
    date +"%Y-%m-%d %T %Z"
}

_log() {
    local message=$1
    printf "%s\n" "$(_print_date) $message" >>"$INSTALL_LOG_TMP"
}

_log_finish() {
    local log_file="$INSTALL_DIR/$INSTALL_LOG_NAME"
    touch -- "$log_file"
    cat -- "$INSTALL_LOG_TMP" >>"$log_file"
}

_log_system_info() {
    local sys_kernel=""
    local sys_os=""
    if _command_exists "lsb_release"; then
        # shellcheck disable=SC2034
        sys_os=$(lsb_release -ds 2>/dev/null)
    fi
    if _command_exists "uname"; then
        # shellcheck disable=SC2034
        sys_kernel=$(uname -srmo 2>/dev/null)
    fi
    _log_variable "USER"
    _log_variable "HOME"
    _log_variable "SHELL"
    _log_variable "LANG"
    _log_variable "sys_kernel"
    _log_variable "sys_os"
    _log_variable "XDG_CURRENT_DESKTOP"
    _log_variable "XDG_SESSION_TYPE"
}

_log_variable() {
    local var_name=$1
    local var_value="${!var_name:-}"
    _log "[VAR] $var_name=\"$var_value\""
}

#endregion
#------------------------------------------------------------------------------
#region Internationalization (i18n)
#------------------------------------------------------------------------------

_i18n_print_desktop_name() {
    local prefix=$1
    local name=$2

    local po_file=""
    while IFS= read -r -d $'\0' po_file; do
        local msg=""
        msg=$(_i18n_get_translation "$I18N_DIR/$po_file" "$name")
        printf "%s\n" "${prefix}[${po_file%.po}]=${msg}"
    done < <(_list_traslation_files)
}

# Translate each directory component in the path.
_i18n_translate_path() {
    local path=$1
    local IFS='/'

    # shellcheck disable=SC2206
    local components=($path)
    local translated_components=()

    for component in "${components[@]}"; do
        translated_components+=("$(_i18n "$component")")
    done

    translated_path=$(
        IFS='/'
        echo "${translated_components[*]}"
    )
    printf "%s" "$translated_path"
}

_i18n() {
    local msgid=$1

    _i18n_get_translation "$I18N_FILE" "$msgid"
}

_i18n_get_translation() {
    local po_file=$1
    local msgid=$2
    local msgstr=""
    msgstr=$(grep -A1 "msgid \"$msgid\"" "$po_file" 2>/dev/null |
        grep "msgstr" | cut -d '"' -f 2)

    if [[ -n "$msgstr" ]]; then
        printf "%s" "$msgstr"
    else
        printf "%s" "$msgid"
    fi
}

_i18n_initialize() {
    # LANG not set: nothing to load
    if [[ -z "${LANG:-}" ]]; then
        return
    fi

    local lang_full="${LANG%%.*}"      # e.g. 'pt_BR.UTF-8' to 'pt_BR'.
    local lang_base="${lang_full%%_*}" # e.g. 'pt_BR to' 'pt'.
    local po_file=""

    # Try full locale first (e.g. pt_BR.po).
    po_file="$I18N_DIR/$lang_full.po"
    if [[ -f "$po_file" ]]; then
        I18N_FILE="$po_file"
        return
    fi

    # Fallback to base language (e.g. pt.po).
    po_file="$I18N_DIR/$lang_base.po"
    if [[ -f "$po_file" ]]; then
        I18N_FILE="$po_file"
    fi
}

#endregion
#------------------------------------------------------------------------------
#region Validation and checks
#------------------------------------------------------------------------------

# FUNCTION: _check_exist_filemanager
#
# DESCRIPTION:
# This function checks if at least one compatible file manager exists in
# the system by iterating through a predefined list of supported file
# managers defined in '$COMPATIBLE_FILE_MANAGERS'.
#
# RETURNS:
#   "0" (true): If at least one compatible file manager is found.
#   "1" (false): If no compatible file manager is found.
_check_exist_filemanager() {
    local file_manager=""
    for file_manager in "${COMPATIBLE_FILE_MANAGERS[@]}"; do
        if _command_exists "$file_manager"; then
            return 0
        fi
    done
    return 1
}

#endregion
#------------------------------------------------------------------------------
#region File and directory management
#------------------------------------------------------------------------------

_list_scripts() {
    find -L "$INSTALL_DIR" -mindepth 2 -type f \
        "${IGNORE_FIND_PATHS[@]}" \
        -print0 2>/dev/null | sort --zero-terminated
}

_list_scripts_installed() {
    local dir=$1
    find -L "$dir" -mindepth 2 -type f \
        "${IGNORE_FIND_PATHS[@]}" \
        -print0 2>/dev/null | sort --zero-terminated
}

_list_scripts_application() {
    find -L "$INSTALL_DIR" -mindepth 2 -type f \
        "${IGNORE_FIND_PATHS[@]}" "${IGNORE_APPS_SHORTCUTS[@]}" \
        -print0 2>/dev/null | sort --zero-terminated
}

_list_scripts_categories() {
    find -L "$SCRIPT_DIR" -mindepth 1 -maxdepth 1 -type d \
        "${IGNORE_FIND_PATHS[@]}" -print0 2>/dev/null |
        sed -z "s|^.*/||" | sort --zero-terminated
}

_list_traslation_files() {
    find -L "$I18N_DIR" -name "*.po" -type f \
        -printf "%f\0" 2>/dev/null | sort --zero-terminated
}

_chown_file() {
    chown "$INSTALL_OWNER:$INSTALL_GROUP" -- "$1"
}

_chmod_x_file() {
    chmod +x -- "$1"
}

_tee_file() {
    tee -- "$1" >/dev/null
}

# FUNCTION: _item_create_backup
#
# DESCRIPTION:
# This function creates a backup of a file (append .bak) if it exists.
_item_create_backup() {
    local item=$1

    if [[ -e "$item" ]] && [[ ! -e "$item.bak" ]]; then
        mv -- "$item" "$item.bak" 2>/dev/null
    fi
}

# FUNCTION: _delete_items
#
# DESCRIPTION:
# This function deletes or trash items, using the best available method.
_delete_items() {
    local items=$1

    # Attempt to remove empty directories directly (rmdir only removes empty
    # dirs, silently fails otherwise) This avoids sending empty folders to the
    # trash and deletes them outright.
    # shellcheck disable=SC2086
    rmdir -- $items &>/dev/null

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
}

#endregion
#------------------------------------------------------------------------------
#region System information and parameters
#------------------------------------------------------------------------------

_command_exists() {
    local command_check=$1

    command -v "$command_check" &>/dev/null || return 1
}

_get_parameters_command_line() {
    local expanded_args=()

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
        -b | --install-homebrew) OPT_INSTALL_HOMEBREW="true" ;;
        -B | --no-install-homebrew) OPT_INSTALL_HOMEBREW="false" ;;
        -c | --check-dependencies) OPT_INSTALL_BASIC_DEPS="true" ;;
        -C | --no-check-dependencies) OPT_INSTALL_BASIC_DEPS="false" ;;
        -d | --remove-scripts) OPT_REMOVE_SCRIPTS="true" ;;
        -D | --no-remove-scripts) OPT_REMOVE_SCRIPTS="false" ;;
        -f | --close-filemanager) OPT_CLOSE_FILE_MANAGER="true" ;;
        -F | --no-close-filemanager) OPT_CLOSE_FILE_MANAGER="false" ;;
        -k | --install-shortcuts) OPT_INSTALL_ACCELS="true" ;;
        -K | --no-install-shortcuts) OPT_INSTALL_ACCELS="false" ;;
        -n | --non-interactive) OPT_INTERACTIVE_INSTALL="false" ;;
        -q | --quiet) OPT_QUIET_INSTALL="true" ;;
        -s | --install-app-shortcuts) OPT_INSTALL_APP_SHORTCUTS="true" ;;
        -S | --no-install-app-shortcuts) OPT_INSTALL_APP_SHORTCUTS="false" ;;
        -h | --help)
            echo "Usage: $0 [options]"
            echo
            echo "  -b, --install-homebrew          Install Homebrew."
            echo "  -B, --no-install-homebrew       Do not install Homebrew."
            echo "  -c, --check-dependencies        Check for basic dependencies."
            echo "  -C, --no-check-dependencies     Do not check for basic dependencies."
            echo "  -d, --remove-scripts            Remove previously installed scripts."
            echo "  -D, --no-remove-scripts         Do not remove previously installed scripts."
            echo "  -f, --close-filemanager         Close file manager after install."
            echo "  -F, --no-close-filemanager      Do not close file manager after install."
            echo "  -k, --install-shortcuts         Install keyboard accelerators."
            echo "  -K, --no-install-shortcuts      Do not install keyboard accelerators."
            echo "  -n, --non-interactive           Run without prompts."
            echo "  -q, --quiet                     Suppress all output (silent mode)."
            echo "  -s, --install-app-shortcuts     Add shortcuts to the application menu."
            echo "  -S, --no-install-app-shortcuts  Do not add shortcuts to the application menu."
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

# FUNCTION: _get_par_value
#
# DESCRIPTION:
# This function extracts the value of a given parameter from a script file.
# It searches for "parameter=value" inside the file, then returns only the
# value.
_get_par_value() {
    local filename=$1
    local parameter=$2

    grep --only-matching -m 1 "$parameter=.*" "$filename" |
        cut -d "=" -f 2- 2>/dev/null
}

#endregion
#------------------------------------------------------------------------------
#region Installation functions
#------------------------------------------------------------------------------

_sanitize_string() {
    tr -cd ";[:alnum:] -" | tr " " "-" | tr -s "-" | tr "[:upper:]" "[:lower:]"
}

_generate_desktop_filename() {
    local name=$1
    name=$(_sanitize_string <<<"$name")
    printf "%s" "$name.desktop"
}

#------------------------------------------------------------------------------
#region Dependencies
#------------------------------------------------------------------------------

# shellcheck disable=SC2086
_check_dependencies() {
    _echo ""
    _echo_info "$(_i18n 'Checking for basic dependencies:')"

    local packages=""

    # Basic packages to run the script '.common-functions.sh'.
    _command_exists "basename" || packages+="coreutils "
    _command_exists "file" || packages+="file "
    _command_exists "pstree" || packages+="psmisc "
    _command_exists "xdg-open" || packages+="xdg-utils "

    # Packages for dialogs.
    if [[ -n "${XDG_CURRENT_DESKTOP:-}" ]]; then
        if ! _command_exists "zenity" && ! _command_exists "yad"; then
            if [[ "${XDG_CURRENT_DESKTOP,,}" == *"gnome"* ]]; then
                packages+="zenity "
            else
                packages+="yad "
            fi
        fi
    fi

    if _command_exists "nix-env"; then
        # Package manager 'nix-env': For Nix-based systems.
        _command_exists "pgrep" || packages+="procps "
        _install_packages "nix-env" "$packages"
    elif _command_exists "apt-get"; then
        # Package manager 'apt-get': For Debian/Ubuntu systems.
        _command_exists "pgrep" || packages+="procps "
        _install_packages "apt-get" "$packages"
    elif _command_exists "rpm-ostree"; then
        # Package manager 'rpm-ostree': For Fedora/RHEL atomic systems.
        _command_exists "pgrep" || packages+="procps-ng "
        _install_packages "rpm-ostree" "$packages"
    elif _command_exists "dnf"; then
        # Package manager 'dnf': For Fedora/RHEL systems.
        _command_exists "pgrep" || packages+="procps-ng "
        _install_packages "dnf" "$packages"
    elif _command_exists "pacman"; then
        # Package manager 'pacman': For Arch Linux systems.
        _command_exists "pgrep" || packages+="procps "
        # NOTE: Force update GTK4 packages on Arch Linux.
        if [[ "$packages" == *"zenity"* ]]; then
            packages+="gtk4 zlib glib2 "
        fi
        _install_packages "pacman" "$packages"
    elif _command_exists "zypper"; then
        # Package manager 'zypper': For openSUSE systems.
        _command_exists "pgrep" || packages+="procps-ng "
        _install_packages "zypper" "$packages"
    elif _command_exists "guix"; then
        # Package manager 'guix': For GNU Guix systems.
        _command_exists "pgrep" || packages+="procps "
        _install_packages "guix" "$packages"
    elif _command_exists "xbps-install"; then
        # Package manager 'xbps': For Void Linux systems.
        _command_exists "pgrep" || packages+="procps-ng "
        # NOTE: Update dependencies on Void Linux.
        if [[ "$packages" == *"yad"* ]]; then
            packages+="libavcodec6 libheif "
        fi
        _install_packages "xbps-install" "$packages"
    else
        if [[ -n "$packages" ]]; then
            _log "[ERR] Missing package manager."
            _echo_error "$(_i18n 'Could not find a package manager!')"
            exit 1
        fi
    fi

    if [[ -z "$packages" ]]; then
        _echo_info "> $(_i18n 'All dependencies are already satisfied.')"
    fi
    _echo_info "> $(_i18n 'Done!')"
}

_install_packages() {
    local pkg_manager=$1
    local packages=$2
    local cmd_admin=""
    local cmd_admin_available=""
    local cmd_inst=""

    # Remove the last space char.
    packages=${packages% }

    _log "[INF] Package manager: $pkg_manager"

    [[ -z "$packages" ]] && return

    _echo_info "> $(_i18n 'The following packages are missing:') $packages"

    _command_exists "sudo" && cmd_admin_available="sudo"

    cmd_inst=""
    cmd_admin="$cmd_admin_available"

    case "$pkg_manager" in
    "apt-get")
        cmd_inst+="apt-get update;"
        cmd_inst+="apt-get -y install $packages"
        ;;
    "dnf")
        cmd_inst+="dnf check-update;"
        cmd_inst+="dnf -y install $packages"
        ;;
    "guix")
        cmd_inst="guix package -i $packages"
        ;;
    "nix-env")
        local nix_packages=""
        local nix_channel="nixpkgs"
        if grep --quiet "ID=nixos" /etc/os-release 2>/dev/null; then
            nix_channel="nixos"
        fi

        # Prefix packages with their channel namespace.
        nix_packages="$nix_channel.$packages"
        # shellcheck disable=SC2001
        nix_packages=$(sed "s| $||g" <<<"$nix_packages")
        # shellcheck disable=SC2001
        nix_packages=$(sed "s| | $nix_channel.|g" <<<"$nix_packages")

        cmd_inst+="nix-env -iA $nix_packages"
        # Nix does not require root for installing user packages.
        cmd_admin=""
        ;;
    "pacman")
        cmd_inst+="pacman -Syy;"
        cmd_inst+="pacman --noconfirm -S $packages"
        ;;
    "rpm-ostree")
        cmd_inst+="rpm-ostree install $packages"
        ;;
    "xbps-install")
        cmd_inst+="xbps-install -S;"
        cmd_inst+="xbps-install -y -u xbps;"
        cmd_inst+="xbps-install -y $packages"
        ;;
    "zypper")
        cmd_inst+="zypper refresh;"
        cmd_inst+="zypper --non-interactive install $packages"
        ;;
    esac

    # Execute installation.
    if [[ -n "$cmd_inst" ]]; then
        _echo_info "> $(_i18n 'Installing the packages. Please, wait...')"
        # If root privileges are required, prepend with 'sudo'.
        $cmd_admin bash -c "$cmd_inst"
    fi
}

#endregion
#------------------------------------------------------------------------------
#region Install scripts
#------------------------------------------------------------------------------

# FUNCTION: _install_scripts
#
# DESCRIPTION:
# This function installs scripts into the target directory.
# Steps:
#   1. Optionally remove any previously installed scripts.
#   2. Copy common and category-specific script files.
#   3. Set proper ownership and permissions.
_install_scripts() {
    local -n _cat_selected=$1
    local -n _cat_dirs=$2

    rm -rf -- "$INSTALL_DIR" 2>/dev/null
    rm -rf -- "${INSTALL_HOME:?}/$INSTALL_APPS_SHORTCUTS_PATH" 2>/dev/null

    _echo_info "> $(_i18n 'Copying files...')"
    mkdir --parents -- "$INSTALL_DIR"

    # Always copy important files and directories.
    cp -- "$SCRIPT_DIR/.common-functions.sh" "$INSTALL_DIR"
    cp -- "$SCRIPT_DIR/.dependencies.sh" "$INSTALL_DIR"
    cp -r -- "$SCRIPT_DIR/.po" "$INSTALL_DIR"

    # Copy scripts by category. If the user selected specific categories, only
    # those are installed. Otherwise, all categories are copied by default.
    local i=0
    for i in "${!_cat_dirs[@]}"; do
        if [[ ${_cat_selected[$i]+_} ]]; then
            if [[ ${_cat_selected[i]} == "true" ]]; then
                cp -r -- "$SCRIPT_DIR/${_cat_dirs[i]}" "$INSTALL_DIR"
            fi
        else
            cp -r -- "$SCRIPT_DIR/${_cat_dirs[i]}" "$INSTALL_DIR"
        fi
    done

    # Adjust ownership and permissions. Ensures all files belong to
    # the correct user/group and are executable.
    chown -R "$INSTALL_OWNER:$INSTALL_GROUP" -- "$INSTALL_DIR"
    find -L "$INSTALL_DIR" -mindepth 2 -type f \
        "${IGNORE_FIND_PATHS[@]}" -exec chmod +x -- {} +
}

_create_links() {
    local destination_dir=$1

    # Remove previous scripts if requested.
    if [[ "$OPT_REMOVE_SCRIPTS" == "true" ]]; then
        _delete_items "$destination_dir"
    else
        # Remove broken links.
        find "$destination_dir" -type l -delete 2>/dev/null
        # Remove empty dirs.
        find "$destination_dir" -type d -empty -delete 2>/dev/null
    fi

    mkdir --parents -- "$destination_dir"
    ln -sf -- "$INSTALL_DIR/.po" "$destination_dir/.po"

    local dir=""
    local name=""
    local relative_path=""

    # Process all files and directories recursively.
    local file_path=""
    while IFS= read -r -d $'\0' file_path; do
        relative_path="${file_path#"$INSTALL_DIR"/}"
        dir=$(dirname -- "$relative_path")
        name=$(basename -- "$file_path")

        # Skip the .po directory (already linked).
        [[ "$relative_path" == ".po" ]] && continue

        # Create translated directory path.
        local translated_dir=""
        translated_dir=$(_i18n_translate_path "$dir")

        # Create destination path.
        local destination_path="$destination_dir"
        if [[ -n "$translated_dir" ]]; then
            destination_path="$destination_dir/$translated_dir"
        fi

        if [[ -d "$file_path" ]]; then
            # Create translated directory.
            mkdir --parents -- "$destination_path/$(_i18n "$name")"
        else
            # Create parent directories and link file.
            mkdir --parents -- "$destination_path"
            ln -sf -- "$file_path" "$destination_path/$(_i18n "$name")"
        fi
    done < <(find -L "$INSTALL_DIR" \
        -mindepth 1 "${IGNORE_FIND_PATHS[@]}" -print0 2>/dev/null)
}

#endregion
#------------------------------------------------------------------------------
#region Keyboard accellerators
#------------------------------------------------------------------------------

# FUNCTION: _install_accels
#
# DESCRIPTION:
# Install keyboard accelerators for specific file managers.
_install_accels() {
    _echo_info "> ($FILE_MANAGER) $(_i18n 'Installing keyboard accelerators...')"

    case "$FILE_MANAGER" in
    "nautilus") _install_accels_nautilus "$INSTALL_HOME/.config/nautilus/scripts-accels" ;;
    "caja") _install_accels_gnome2 "$INSTALL_HOME/.config/caja/accels" "$INSTALL_HOME/.config/caja/scripts" ;;
    "nemo") _install_accels_gnome2 "$INSTALL_HOME/.gnome2/accels/nemo" "$INSTALL_HOME/.local/share/nemo/scripts" ;;
    "thunar") _install_accels_thunar "$INSTALL_HOME/.config/Thunar/accels.scm" ;;
    esac
}

_install_accels_nautilus() {
    local accels_file=$1
    mkdir --parents -- "$(dirname -- "$accels_file")"

    # Create a backup of older custom actions.
    _item_create_backup "$accels_file"
    rm -f -- "$accels_file"

    {
        local filename=""
        while IFS= read -r -d $'\0' filename; do
            local keyboard_shortcut=""
            keyboard_shortcut=$(_get_par_value \
                "$filename" "install_keyboard_shortcut")

            if [[ -n "$keyboard_shortcut" ]]; then
                local name=""
                name=$(basename -- "$filename")
                printf "%s\n" "$keyboard_shortcut $(_i18n "$name")"
            fi
        done < <(_list_scripts)

    } | _tee_file "$accels_file"
    _chown_file "$accels_file"
}

_encode_path_gtk() {
    local string=$1
    local length="${#string}"

    local c=""
    local i=""
    for ((i = 0; i < length; i++)); do
        c="${string:i:1}"
        # shellcheck disable=SC1001
        case "$c" in
        [a-zA-Z0-9\:\'\(\)\.\_\~\-\\]) printf '%s' "$c" ;;
        *) printf '%s' "$c" | hexdump -v -e '/1 "-%02X" ' | sed "s|-|\%|g" ;;
        esac
    done
}

_install_accels_gnome2() {
    local accels_file=$1
    local scripts_installed_dir=$2

    mkdir --parents -- "$(dirname -- "$accels_file")"

    # Create a backup of older custom actions.
    _item_create_backup "$accels_file"
    rm -f -- "$accels_file"

    {
        # Disable the shortcut for 'OpenAlternate' (<control><shift>o).
        printf "%s\n" '(gtk_accel_path "<Actions>/DirViewActions/OpenAlternate" "")'
        # Disable the shortcut for 'OpenInNewTab' (<control><shift>o).
        printf "%s\n" '(gtk_accel_path "<Actions>/DirViewActions/OpenInNewTab" "")'
        # Disable the shortcut for 'Show Hide Extra Pane' (F3).
        printf "%s\n" '(gtk_accel_path "<Actions>/NavigationActions/Show Hide Extra Pane" "")'
        printf "%s\n" '(gtk_accel_path "<Actions>/ShellActions/Show Hide Extra Pane" "")'

        local filename=""
        while IFS= read -r -d $'\0' filename; do
            local keyboard_shortcut=""
            keyboard_shortcut=$(_get_par_value \
                "$filename" "install_keyboard_shortcut")
            keyboard_shortcut=${keyboard_shortcut//Control/Primary}

            if [[ -n "$keyboard_shortcut" ]]; then
                # shellcheck disable=SC2001
                filename=$(sed "s|/|\\\\\\\\s|g" <<<"$filename")
                filename=$(_encode_path_gtk "$filename")

                printf "%s\n" '(gtk_accel_path "<Actions>/ScriptsGroup/script_file:\\s\\s'"$filename"'" "'"$keyboard_shortcut"'")'
            fi
        done < <(_list_scripts_installed "$scripts_installed_dir")

    } | _tee_file "$accels_file"
    _chown_file "$accels_file"
}

_install_accels_thunar() {
    local accels_file=$1
    mkdir --parents -- "$(dirname -- "$accels_file")"

    # Create a backup of older custom actions.
    _item_create_backup "$accels_file"
    rm -f -- "$accels_file"

    {
        # Default Thunar shortcuts.
        printf "%s\n" '(gtk_accel_path "<Actions>/ThunarActions/uca-action-1-1" "")'
        printf "%s\n" '(gtk_accel_path "<Actions>/ThunarActions/uca-action-2-2" "")'
        printf "%s\n" '(gtk_accel_path "<Actions>/ThunarActions/uca-action-3-3" "<Primary><Shift>f")'
        printf "%s\n" '(gtk_accel_path "<Actions>/ThunarActions/uca-action-4-4" "")'
        # Disable "<Primary><Shift>o".
        printf "%s\n" '(gtk_accel_path "<Actions>/ThunarActionManager/open-in-new-window" "")'
        # Disable "<Primary>e".
        printf "%s\n" '(gtk_accel_path "<Actions>/ThunarWindow/view-side-pane-tree" "")'

        local filename=""
        while IFS= read -r -d $'\0' filename; do
            local keyboard_shortcut=""
            keyboard_shortcut=$(_get_par_value \
                "$filename" "install_keyboard_shortcut")
            keyboard_shortcut=${keyboard_shortcut//Control/Primary}

            if [[ -n "$keyboard_shortcut" ]]; then
                local msg_scripts=""
                msg_scripts=$(_i18n 'Scripts')
                local name=""
                local submenu=""
                local unique_id=""
                name=$(basename -- "$filename")
                submenu=$(dirname -- "$filename" | sed "s|.*scripts/|$msg_scripts/|g")
                unique_id=$(md5sum <<<"$submenu$name" 2>/dev/null |
                    sed "s|[^0-9]*||g" | cut -c 1-8)

                printf "%s\n" '(gtk_accel_path "<Actions>/ThunarActions/uca-action-'"$unique_id"'" "'"$keyboard_shortcut"'")'
            fi
        done < <(_list_scripts)

    } | _tee_file "$accels_file"
    _chown_file "$accels_file"
}

#endregion
#------------------------------------------------------------------------------
#region Application shortcuts
#------------------------------------------------------------------------------

_install_application_shortcuts() {
    local menu_file=""
    local name=""
    local script_relative=""
    local submenu=""
    local app_menus_path="$INSTALL_HOME/$INSTALL_APPS_SHORTCUTS_PATH"

    _echo_info "> $(_i18n 'Creating shortcuts to the application menu...')"

    # Remove previously installed '.desktop' files.
    rm -rf -- "$app_menus_path" 2>/dev/null

    # Create the directory for menu entries.
    mkdir --parents -- "$app_menus_path"

    # Create a '.desktop' file for each script.
    local filename=""
    while IFS= read -r -d $'\0' filename; do
        # shellcheck disable=SC2001
        script_relative=$(sed "s|.*scripts/||g" <<<"$filename")
        name=${script_relative##*/}
        submenu=${script_relative%/*}
        # shellcheck disable=SC2001
        submenu=$(sed "s|/| - |g" <<<"$submenu")

        menu_file=$(_generate_desktop_filename "$name")
        menu_file="$app_menus_path/$menu_file"
        {
            printf "%s\n" "[Desktop Entry]"
            printf "%s\n" "Categories=Scripts;"
            printf "%s\n" "Exec=\"$filename\" %F"
            printf "%s\n" "Name=$name"
            _i18n_print_desktop_name "Name" "$name"
            printf "%s\n" "Icon=application-x-executable"
            printf "%s\n" "Terminal=false"
            printf "%s\n" "Type=Application"

        } | _tee_file "$menu_file"
        _chown_file "$menu_file"
        _chmod_x_file "$menu_file"

    done < <(_list_scripts_application)
}

_create_gnome_application_folder() {
    local folder_name="Scripts"
    local translated_folder_name=""
    translated_folder_name=$(_i18n "$folder_name")
    # Configure the application folder in GNOME.

    # Exit if not running under GNOME.
    if [[ -z "${XDG_CURRENT_DESKTOP:-}" ||
        "${XDG_CURRENT_DESKTOP,,}" != *"gnome"* ]]; then
        return
    fi

    # Check if 'gsettings' is available and the GNOME schemas are present. If
    # not, skip folder creation.
    if ! _command_exists "gsettings" || ! gsettings list-schemas |
        grep -qxF "org.gnome.desktop.app-folders"; then
        return
    fi

    _echo_info "> $(_i18n 'Creating GNOME Shell application folder...')"

    # Retrieve the current list of GNOME app folders.
    # If the folder does not exist, append it to the list.
    local current_folders=""
    current_folders=$(gsettings get org.gnome.desktop.app-folders folder-children)
    if [[ "$current_folders" != *"'$folder_name'"* ]]; then
        # shellcheck disable=SC2001
        gsettings set \
            org.gnome.desktop.app-folders folder-children "$(sed "s/]/,'$folder_name']/" <<<"$current_folders")" &>/dev/null
    fi

    # Set the display name for the new GNOME application folder.
    gsettings set \
        org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/$folder_name/ \
        name "$translated_folder_name" &>/dev/null

    # Build a list of all .desktop files in the scripts directory to be added
    # under this GNOME application folder.
    local list_scripts=""
    local app_menus_path="$INSTALL_HOME/$INSTALL_APPS_SHORTCUTS_PATH"
    list_scripts=$(find "$app_menus_path" \
        -maxdepth 1 -type f -name "*.desktop" \
        -printf "'$INSTALL_NAME_DIR-%f', " |
        sed 's/, $//; s/^/[/' | sed 's/$/]/')

    # Assign all found .desktop files to the folder in GNOME settings.
    gsettings set \
        org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/$folder_name/ \
        apps "$list_scripts" &>/dev/null
}

#endregion
#------------------------------------------------------------------------------
#region File manager actions (context menus)
#------------------------------------------------------------------------------

# FUNCTION: _install_actions
#
# DESCRIPTION:
# This function install actions (context menus) for supported
# file managers. Delegates to the appropriate function depending on
# the detected file manager.
_install_actions() {
    _echo_info "> ($FILE_MANAGER) $(_i18n 'Installing actions in the context menu...')"

    case "$FILE_MANAGER" in
    "nautilus") _create_links "$INSTALL_HOME/.local/share/nautilus/scripts" ;;
    "caja") _create_links "$INSTALL_HOME/.config/caja/scripts" ;;
    "nemo") _create_links "$INSTALL_HOME/.local/share/nemo/scripts" ;;
    "dolphin") _install_actions_kio_servicemenus ;;
    "pcmanfm"*) _install_actions_pcmanfm ;;
    "thunar") _install_actions_thunar ;;
    "krusader") _install_actions_kio_servicemenus ;;
    esac
}

_install_actions_kio_servicemenus() {
    local menu_file=""
    local menus_path="$INSTALL_HOME/.local/share/kio/servicemenus"
    find "$menus_path" -name "$INSTALL_NAME_DIR-*.desktop" \
        -type f -delete 2>/dev/null
    mkdir --parents -- "$menus_path"

    # -------------------------------------------------------------------------
    # Create a '.desktop' file for each script.
    # -------------------------------------------------------------------------
    local name=""
    local script_relative=""
    local submenu=""
    local filename=""
    while IFS= read -r -d $'\0' filename; do
        # shellcheck disable=SC2001
        script_relative=$(sed "s|.*scripts/||g" <<<"$filename")
        name=${script_relative##*/}
        submenu=${script_relative%%/*}

        menu_file=$(_generate_desktop_filename "$name")
        menu_file="$menus_path/$INSTALL_NAME_DIR-$menu_file"
        {
            printf "%s\n" "[Desktop Entry]"
            printf "%s\n" "Type=Service"
            printf "%s\n" "X-KDE-ServiceTypes=KonqPopupMenu/Plugin"
            printf "%s\n" "Actions=scriptAction;"
            printf "%s\n" "MimeType=all/all;"
            printf "%s\n" "Encoding=UTF-8"
            printf "%s\n" "X-KDE-Submenu=$submenu"
            _i18n_print_desktop_name "X-KDE-Submenu" "$submenu"
            printf "\n"
            printf "%s\n" "[Desktop Action scriptAction]"
            printf "%s\n" "Name=$name"
            _i18n_print_desktop_name "Name" "$name"
            printf "%s\n" "Exec=bash \"$filename\" %F"

        } | _tee_file "$menu_file"
        _chown_file "$menu_file"
        _chmod_x_file "$menu_file"

    done < <(_list_scripts)
}

_install_actions_pcmanfm() {
    local menu_file=""
    local menus_path="$INSTALL_HOME/.local/share/file-manager/actions"
    find "$menus_path" -name "$INSTALL_NAME_DIR-*.desktop" \
        -type f -delete 2>/dev/null
    mkdir --parents -- "$menus_path"

    # -------------------------------------------------------------------------
    # Create the 'scripts.desktop' for the categories (main menu).
    # -------------------------------------------------------------------------
    local msg_scripts=""
    msg_scripts=$(_i18n 'Scripts')
    menu_file="$menus_path/$INSTALL_NAME_DIR-main.desktop"
    {
        printf "%s\n" "[Desktop Entry]"
        printf "%s\n" "Type=Menu"
        printf "%s\n" "Name=$msg_scripts"
        _i18n_print_desktop_name "Name" "$msg_scripts"
        printf "%s\n" "Icon=inode-directory"
        printf "%s" "ItemsList="
        find -L "$INSTALL_DIR" -mindepth 1 -maxdepth 1 -type d \
            "${IGNORE_FIND_PATHS[@]}" \
            -printf "$INSTALL_NAME_DIR-%f\0" 2>/dev/null |
            sort --zero-terminated | tr "\0" ";" | _sanitize_string
        printf "\n"

    } | _tee_file "$menu_file"
    _chown_file "$menu_file"
    _chmod_x_file "$menu_file"

    # -------------------------------------------------------------------------
    # Create a '.desktop' file for each sub-category (sub-menus).
    # -------------------------------------------------------------------------
    local dir_items=""
    local name=""
    local filename=""
    while IFS= read -r -d $'\0' filename; do
        name=${filename##*/}
        dir_items=$(find -L "$filename" -mindepth 1 -maxdepth 1 \
            "${IGNORE_FIND_PATHS[@]}" \
            -printf "$INSTALL_NAME_DIR-%f\0" 2>/dev/null |
            sort --zero-terminated | tr "\0" ";" | _sanitize_string)
        if [[ -z "$dir_items" ]]; then
            continue
        fi

        menu_file=$(_generate_desktop_filename "$name")
        menu_file="$menus_path/$INSTALL_NAME_DIR-$menu_file"
        {
            printf "%s\n" "[Desktop Entry]"
            printf "%s\n" "Type=Menu"
            printf "%s\n" "Name=$name"
            _i18n_print_desktop_name "Name" "$name"
            printf "%s\n" "Icon=inode-directory"
            printf "%s\n" "ItemsList=$dir_items"

        } | _tee_file "$menu_file"
        _chown_file "$menu_file"
        _chmod_x_file "$menu_file"

    done < <(find -L "$INSTALL_DIR" -mindepth 1 -type d \
        "${IGNORE_FIND_PATHS[@]}" \
        -print0 2>/dev/null | sort --zero-terminated)

    # -------------------------------------------------------------------------
    # Create a '.desktop' file for each script.
    # -------------------------------------------------------------------------
    while IFS= read -r -d $'\0' filename; do
        name=${filename##*/}

        menu_file=$(_generate_desktop_filename "$name")
        menu_file="$menus_path/$INSTALL_NAME_DIR-$menu_file"
        {
            printf "%s\n" "[Desktop Entry]"
            printf "%s\n" "Type=Action"
            printf "%s\n" "Name=$name"
            _i18n_print_desktop_name "Name" "$name"
            printf "%s\n" "Profiles=scriptAction"
            printf "\n"
            printf "%s\n" "[X-Action-Profile scriptAction]"
            printf "%s\n" "Exec=bash \"$filename\" %F"

        } | _tee_file "$menu_file"
        _chown_file "$menu_file"
        _chmod_x_file "$menu_file"

    done < <(_list_scripts)
}

_install_actions_thunar() {
    local menu_file=""
    local menus_path="$INSTALL_HOME/.config/Thunar"
    mkdir --parents -- "$menus_path"
    menu_file="$menus_path/uca.xml"

    # Create a backup of older custom actions.
    _item_create_backup "$menu_file"
    rm -f -- "$menu_file"

    # -------------------------------------------------------------------------
    # Create the file "~/.config/Thunar/uca.xml".
    # -------------------------------------------------------------------------
    {
        printf "%s\n" "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
        printf "%s\n" "<actions>"
        printf "%s\n" "<action>"
        printf "\t%s\n" "<icon>utilities-terminal</icon>"
        printf "\t%s\n" "<name>Open Terminal Here</name>"
        printf "\t%s\n" "<submenu></submenu>"
        printf "\t%s\n" "<unique-id>1-1</unique-id>"
        printf "\t%s\n" "<command>exo-open --working-directory %f --launch TerminalEmulator</command>"
        printf "\t%s\n" "<description>Open terminal in containing directory</description>"
        printf "\t%s\n" "<range></range>"
        printf "\t%s\n" "<patterns>*</patterns>"
        printf "\t%s\n" "<startup-notify/>"
        printf "\t%s\n" "<directories/>"
        printf "%s\n" "</action>"
        printf "%s\n" "<action>"
        printf "\t%s\n" "<icon>edit-find</icon>"
        printf "\t%s\n" "<name>Find in this folder</name>"
        printf "\t%s\n" "<submenu></submenu>"
        printf "\t%s\n" "<unique-id>3-3</unique-id>"
        printf "\t%s\n" "<command>catfish --path=%f</command>"
        printf "\t%s\n" "<description>Search for files within this folder</description>"
        printf "\t%s\n" "<range></range>"
        printf "\t%s\n" "<patterns>*</patterns>"
        printf "\t%s\n" "<directories/>"
        printf "%s\n" "</action>"

        local filename=""
        local name=""
        local submenu=""
        local unique_id=""
        local msg_scripts=""
        msg_scripts=$(_i18n 'Scripts')

        while IFS= read -r -d $'\0' filename; do
            name=$(basename -- "$filename")
            submenu=$(dirname -- "$filename" |
                sed "s|.*scripts/|$msg_scripts/|g")

            printf "%s\n" "<action>"
            printf "\t%s\n" "<icon></icon>"
            printf "\t%s\n" "<name>$(_i18n "$name")</name>"
            printf "\t%s\n" "<submenu>$(_i18n_translate_path "$submenu")</submenu>"

            # Generate a unique id.
            unique_id=$(md5sum <<<"$submenu$name" 2>/dev/null |
                sed "s|[^0-9]*||g" | cut -c 1-8)
            printf "\t%s\n" "<unique-id>$unique_id</unique-id>"

            printf "\t%s\n" "<command>bash &quot;$filename&quot; %F</command>"
            printf "\t%s\n" "<description></description>"
            printf "\t%s\n" "<range></range>"
            printf "\t%s\n" "<patterns>*</patterns>"
            printf "\t%s\n" "<directories/>"
            printf "\t%s\n" "<audio-files/>"
            printf "\t%s\n" "<image-files/>"
            printf "\t%s\n" "<text-files/>"
            printf "\t%s\n" "<video-files/>"
            printf "\t%s\n" "<other-files/>"
            printf "%s\n" "</action>"
        done < <(_list_scripts)

        printf "%s\n" "</actions>"

    } | _tee_file "$menu_file"
    _chown_file "$menu_file"
}

#endregion
#------------------------------------------------------------------------------
#region Close filemanager
#------------------------------------------------------------------------------

# FUNCTION: _close_filemanager
#
# DESCRIPTION:
# This function closes the current file manager so that it reloads its
# configurations. For most file managers, the `-q` option is used to quit
# gracefully.
_close_filemanager() {
    if [[ -z "$FILE_MANAGER" ||
        "$FILE_MANAGER" == "dolphin" ||
        "$FILE_MANAGER" == "krusader" ]]; then
        return
    fi

    _echo_info "> ($FILE_MANAGER) $(_i18n 'Closing the file manager...')"

    case "$FILE_MANAGER" in
    "nautilus" | "nemo" | "thunar")
        # These file managers support the '-q' option to quit gracefully.
        $FILE_MANAGER -q &>/dev/null
        ;;
    "caja")
        # Close Caja gracefully.
        caja -q &>/dev/null

        # Reload the file manager in background to restore desktop session.
        if [[ -n "${XDG_CURRENT_DESKTOP:-}" ]]; then
            # Only restart if running under MATE.
            if [[ "${XDG_CURRENT_DESKTOP,,}" == *"mate"* ]]; then
                nohup "$FILE_MANAGER" --force-desktop \
                    --no-default-window &>/dev/null &
            fi
        fi
        ;;
    "pcmanfm"*)
        # NOTE: 'pcmanfm-qt' does not reload automatically after quitting.
        # We need to capture its current launch command to restart it.
        local session_cmd=""
        session_cmd=$(pgrep -a "$FILE_MANAGER" | head -n1 | cut -d " " -f 2-)

        # Kill all existing 'pcmanfm-qt' processes.
        killall "$FILE_MANAGER" &>/dev/null

        # Reload the file manager in background to restore desktop session.
        if [[ -n "${XDG_CURRENT_DESKTOP:-}" ]]; then
            # Only restart if running under LXDE or LXQT.
            if [[ "${XDG_CURRENT_DESKTOP,,}" == *"lxde"* ||
                "${XDG_CURRENT_DESKTOP,,}" == *"lxqt"* ]]; then
                if [[ -n "$session_cmd" ]]; then
                    # shellcheck disable=SC2086
                    nohup $session_cmd &>/dev/null &
                else
                    # Fallback: start 'pcmanfm-qt' with default settings.
                    nohup "$FILE_MANAGER" --desktop &>/dev/null &
                fi
            fi
        fi
        ;;
    esac
}

#endregion
#------------------------------------------------------------------------------
#region Homebrew
#------------------------------------------------------------------------------

# FUNCTION: _install_homebrew
#
# DESCRIPTION:
# This function installs Homebrew if the user requested it and it is not
# already installed.
_install_homebrew() {

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

    _echo ""
    _echo_info "$(_i18n 'Installing Homebrew:')"

    # Homebrew install directory.
    local homebrew_dir="$HOME/.local/apps/homebrew"
    local brew_cmd="$homebrew_dir/bin/brew"

    # Check if Homebrew is already installed.
    if [[ -e "$brew_cmd" ]]; then
        _echo_info "> $(_i18n 'Homebrew is already installed.')"
        _echo_info "> $(_i18n 'Done!')"
        return
    fi

    _echo_info "> $(_i18n 'Installing Homebrew to:') ~/.local/apps/homebrew"
    mkdir --parents -- "$homebrew_dir"

    _echo_info "> $(_i18n 'Downloading the package...')"

    # Download and extract Homebrew.
    {
        local url="https://github.com/Homebrew/brew/tarball/main"
        if [[ "$downloader" == "curl" ]]; then
            curl -fsSL "$url" | tar -xz --strip-components=1 -C "$homebrew_dir"
        else
            wget -qO- "$url" | tar -xz --strip-components=1 -C "$homebrew_dir"
        fi
    } 2>/dev/null

    # Verify installation.
    if [[ ! -e "$brew_cmd" ]]; then
        _echo_error "$(_i18n 'Homebrew installation failed!')"
        exit 1
    fi

    _echo_info "> $(_i18n 'Done!')"
}

#endregion
#------------------------------------------------------------------------------
#region Online installation
#------------------------------------------------------------------------------

# FUNCTION: _bootstrap_repository
#
# DESCRIPTION:
# This function ensures that the repository files are available before
# running the installation.
_bootstrap_repository() {
    local repo_owner="cfgnunes"
    local repo_name="fm-scripts"
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

    # Create a temporary directory for the installation.
    local temp_dir
    temp_dir=$(mktemp --directory)

    # Download and extract the HEAD of the branch.
    local tarball_url="https://github.com/${repo_owner}/${repo_name}/archive/refs/heads/${branch}.tar.gz"
    {
        if [[ "$downloader" == "curl" ]]; then
            curl -fsSL "$tarball_url" | tar -xz -C "$temp_dir"
        else
            wget -qO- "$tarball_url" | tar -xz -C "$temp_dir"
        fi
    } 2>/dev/null

    # Identify the extracted directory.
    local extracted_dir
    extracted_dir=$(
        find "$temp_dir" -maxdepth 1 -type d -name "${repo_name}*" | head -n 1
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

    rm -rf -- "$temp_dir"
}
#endregion
#endregion

_main "$@"
