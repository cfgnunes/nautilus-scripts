#!/usr/bin/env bash

# Install the scripts for file managers.

set -u

# -----------------------------------------------------------------------------
# SECTION: Constants ----
# -----------------------------------------------------------------------------

# Defines the name of the directory where application menu shortcuts are
# stored, located at: "$HOME/.local/share/applications/$APP_MENUS_DIR".
APP_MENUS_DIR="nautilus-scripts"

# List of supported file managers.
COMPATIBLE_FILE_MANAGERS=(
    "nautilus"
    "caja"
    "dolphin"
    "nemo"
    "pcmanfm-qt"
    "thunar"
    "unknown")

# Application shortcuts to be ignored during install.
IGNORE_APPLICATION_SHORTCUTS=(
    ! -iname "Code Editor"
    ! -iname "Disk Usage Analyzer"
    ! -iname "Terminal"
    ! -iname "Extract here"
    ! -iname "Create hard link here"
    ! -iname "Create symbolic link here"
    ! -iname "Paste as hard link"
    ! -iname "Paste as symbolic link"
    ! -iname "Paste clipboard as a file"
)

# Directories to be ignored during install.
IGNORE_FIND_PATHS=(
    ! -path "*/Accessed recently*"
    ! -path "*/.assets*"
    ! -path "*/.git*"
)

# Colored status messages for logging.
MSG_ERROR="[\033[0;31mFAILED\033[0m]"
MSG_INFO="[\033[0;32m INFO \033[0m]"

# Define the directory of this script. If '$BASH_SOURCE' is available,
# use its path. Otherwise, create a temporary directory for cases like remote
# execution via curl.
if [[ -v "BASH_SOURCE" ]]; then
    SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
else
    SCRIPT_DIR="."
fi

# Mark constants as read-only to prevent accidental modification.
readonly \
    APP_MENUS_DIR \
    COMPATIBLE_FILE_MANAGERS \
    IGNORE_FIND_PATHS \
    MSG_ERROR \
    MSG_INFO \
    SCRIPT_DIR

# Use current username if $USER is undefined.
USER=${USER:-$(id -un)}

# -----------------------------------------------------------------------------
# SECTION: Global variables ----
# -----------------------------------------------------------------------------

FILE_MANAGER=""  # Current file manager being processed.
INSTALL_DIR=""   # Target installation directory for scripts.
INSTALL_HOME=""  # User's home directory where scripts will be installed.
INSTALL_OWNER="" # Owner of the installation directory.
INSTALL_GROUP="" # Group of the installation directory.
SUDO_CMD=""      # Command prefix for elevated operations.
SUDO_CMD_USER="" # Command prefix for running as target user.

# Default main menu options.
OPT_INSTALL_BASIC_DEPS="true"
OPT_REMOVE_SCRIPTS="true"
OPT_INSTALL_ACCELS="true"
OPT_CLOSE_FILE_MANAGER="true"
OPT_INSTALL_APP_SHORTCUTS="false"
OPT_INSTALL_FOR_ALL_USERS="false"
OPT_INSTALL_HOMEBREW="false"
OPT_CHOOSE_CATEGORIES="false"
# Default core options.
OPT_INTERACTIVE_INSTALL="true"
OPT_QUIET_INSTALL="false"

# Import helper script for interactive multi-selection menus.
#shellcheck source=.assets/.multiselect-menu.sh
if [[ -f "$SCRIPT_DIR/.assets/.multiselect-menu.sh" ]]; then
    source "$SCRIPT_DIR/.assets/.multiselect-menu.sh"
fi

# -----------------------------------------------------------------------------
# SECTION: Main flow ----
# -----------------------------------------------------------------------------

# shellcheck disable=SC2034
_main() {
    local cat_defaults=()
    local cat_dirs=()
    local cat_selected=()
    local menu_defaults=()
    local menu_labels=()
    local menu_selected=()

    # Prevent running the installer with sudo/root.
    if [[ "$(id -u)" -eq 0 ]]; then
        _echo_error "Do NOT run this script with 'sudo'! Run with: 'bash install.sh'"
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
    # repository and continue the installation from the extracted files.
    if [[ ! -f "$SCRIPT_DIR/.common-functions.sh" ]]; then
        _bootstrap_repository "$@"
    fi

    # Available options presented in the interactive menu.
    menu_labels=(
        "Install basic dependencies (may require 'sudo')"
        "Remove previously installed scripts"
        "Install keyboard accelerators"
        "Close the file manager to reload its configurations"
        "Add shortcuts to the application menu"
        "Install for all users (may require 'sudo')"
        "Install Homebrew (optional)"
        "Choose which script categories to install"
    )

    # Default states for the menu options.
    menu_defaults=(
        "$OPT_INSTALL_BASIC_DEPS"
        "$OPT_REMOVE_SCRIPTS"
        "$OPT_INSTALL_ACCELS"
        "$OPT_CLOSE_FILE_MANAGER"
        "$OPT_INSTALL_APP_SHORTCUTS"
        "$OPT_INSTALL_FOR_ALL_USERS"
        "$OPT_INSTALL_HOMEBREW"
        "$OPT_CHOOSE_CATEGORIES"
    )

    _echo "Enhanced File Manager Actions for Linux"
    _echo ""

    if [[ "$OPT_INTERACTIVE_INSTALL" == "true" ]]; then
        _echo "Select the options (<SPACE> to check, <ENTER> to confirm):"

        # Display the interactive menu and capture user selections.
        _multiselect_menu menu_selected menu_labels menu_defaults
    else
        _echo_info "Installing in non-interactive mode..."
        menu_selected=("${menu_defaults[@]}")
    fi

    # Map menu selections into a comma-separated string of options.
    OPT_INSTALL_BASIC_DEPS=${menu_selected[0]}
    OPT_REMOVE_SCRIPTS=${menu_selected[1]}
    OPT_INSTALL_ACCELS=${menu_selected[2]}
    OPT_CLOSE_FILE_MANAGER=${menu_selected[3]}
    OPT_INSTALL_APP_SHORTCUTS=${menu_selected[4]}
    OPT_INSTALL_FOR_ALL_USERS=${menu_selected[5]}
    OPT_INSTALL_HOMEBREW=${menu_selected[6]}
    OPT_CHOOSE_CATEGORIES=${menu_selected[7]}

    # Collect all available script categories (directories).
    local dir=""
    while IFS= read -r -d $'\0' dir; do
        cat_dirs+=("$dir")
    done < <(find -L "$SCRIPT_DIR" -mindepth 1 -maxdepth 1 -type d \
        "${IGNORE_FIND_PATHS[@]}" -print0 2>/dev/null |
        sed -z "s|^.*/||" | sort --zero-terminated --version-sort)

    # If requested, let the user select which categories to install.
    if [[ "$OPT_CHOOSE_CATEGORIES" == "true" ]]; then
        _echo ""
        _echo "Select the categories (<SPACE> to check, <ENTER> to confirm):"
        _multiselect_menu cat_selected cat_dirs cat_defaults
    fi

    # Step 1: Install basic dependencies.
    [[ "$OPT_INSTALL_BASIC_DEPS" == "true" ]] && _step_install_dependencies

    # Step 2: Determine target home directories (single user or all users).
    local install_home_list=""
    if [[ "$OPT_INSTALL_FOR_ALL_USERS" == "true" ]]; then
        if _command_exists "sudo"; then
            SUDO_CMD="sudo"
        fi

        # Get the list of all user home directories currently available on the
        # system.
        install_home_list=$(_get_user_homes)

        # Also include the system skeleton directory '/etc/skel'. This
        # directory contains default configuration files that are copied into
        # the home directory of 'new users' when they are created. By
        # installing scripts here, all future accounts will automatically
        # inherit the same setup.
        if [[ -d "/etc/skel" ]]; then
            install_home_list+=$'\n'
            install_home_list+="/etc/skel"
        fi
    else
        install_home_list=$HOME
    fi

    # Step 3: Install scripts for each user home.
    for install_home in $install_home_list; do
        INSTALL_HOME=$install_home
        INSTALL_OWNER=$($SUDO_CMD stat -c "%U" "$INSTALL_HOME")
        INSTALL_GROUP=$($SUDO_CMD stat -c "%G" "$INSTALL_HOME")

        if [[ "$OPT_INSTALL_FOR_ALL_USERS" == "true" ]] &&
            [[ -n "$INSTALL_OWNER" ]] && [[ -n "$INSTALL_GROUP" ]]; then
            if _command_exists "sudo"; then
                SUDO_CMD_USER="sudo -u $INSTALL_OWNER -g $INSTALL_GROUP"
            fi
        fi

        # Install scripts for each detected file manager.
        local file_manager=""
        for file_manager in "${COMPATIBLE_FILE_MANAGERS[@]}"; do
            FILE_MANAGER=$file_manager

            if [[ "$FILE_MANAGER" != "unknown" ]] &&
                ! _command_exists "$FILE_MANAGER"; then
                continue
            fi

            case "$FILE_MANAGER" in
            "nautilus")
                INSTALL_DIR="$INSTALL_HOME/.local/share/nautilus/scripts"
                ;;
            "caja")
                INSTALL_DIR="$INSTALL_HOME/.config/caja/scripts"
                ;;
            "dolphin")
                INSTALL_DIR="$INSTALL_HOME/.local/share/scripts"
                ;;
            "nemo")
                INSTALL_DIR="$INSTALL_HOME/.local/share/nemo/scripts"
                ;;
            "pcmanfm-qt")
                INSTALL_DIR="$INSTALL_HOME/.local/share/scripts"
                ;;
            "thunar")
                INSTALL_DIR="$INSTALL_HOME/.local/share/scripts"
                ;;
            "unknown")
                _check_exist_filemanager && continue
                INSTALL_DIR="$INSTALL_HOME/.local/share/scripts"
                ;;
            esac

            # Perform installation steps.
            _echo ""
            _echo_info "Installing new scripts:"
            _echo_info "> User: $INSTALL_OWNER"
            _echo_info "> Home dir: $INSTALL_HOME"
            _echo_info "> File manager: $FILE_MANAGER"
            _step_install_scripts cat_selected cat_dirs
            _step_install_menus
            [[ "$OPT_INSTALL_ACCELS" == "true" ]] && _step_install_accels

            # Reload file manager to apply changes, if selected.
            if [[ "$USER" == "$INSTALL_OWNER" ]]; then
                [[ "$OPT_CLOSE_FILE_MANAGER" == "true" ]] && _step_close_filemanager
            fi
            _echo_info "> Done!"
        done

        # Add shortcuts to the application menu.
        if [[ "$OPT_INSTALL_APP_SHORTCUTS" == "true" ]]; then
            _echo ""
            _echo_info "Installing application menu shortcuts:"
            _echo_info "> User: $INSTALL_OWNER"

            _step_install_application_shortcuts
            _step_create_gnome_application_folder
            _echo_info "> Done!"
        fi
    done

    # Optional: Install Homebrew.
    if [[ "$OPT_INSTALL_HOMEBREW" == "true" ]]; then
        _step_install_homebrew
    fi

    _echo ""
    _echo_info "Installation completed successfully!"
}

# -----------------------------------------------------------------------------
# SECTION: Printing ----
# -----------------------------------------------------------------------------

_echo() {
    if [[ "$OPT_QUIET_INSTALL" == "true" ]]; then
        return
    fi
    echo "$1"
}

_echo_info() {
    if [[ "$OPT_QUIET_INSTALL" == "true" ]]; then
        return
    fi
    echo -e "$MSG_INFO $1"
}

_echo_error() {
    echo -e "$MSG_ERROR $1"
}

# -----------------------------------------------------------------------------
# SECTION: Validation and checks ----
# -----------------------------------------------------------------------------

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

# -----------------------------------------------------------------------------
# SECTION: File and directory management ----
# -----------------------------------------------------------------------------

_list_scripts() {
    $SUDO_CMD find -L "$INSTALL_DIR" -mindepth 2 -type f \
        "${IGNORE_FIND_PATHS[@]}" \
        -print0 2>/dev/null | sort --zero-terminated
}

_list_scripts_application() {
    $SUDO_CMD find -L "$INSTALL_DIR" -mindepth 2 -type f \
        "${IGNORE_FIND_PATHS[@]}" "${IGNORE_APPLICATION_SHORTCUTS[@]}" \
        -print0 2>/dev/null | sort --zero-terminated
}

_chown_file() {
    $SUDO_CMD chown "$INSTALL_OWNER:$INSTALL_GROUP" -- "$1"
}

_chmod_x_file() {
    $SUDO_CMD chmod +x -- "$1"
}

_tee_file() {
    $SUDO_CMD tee -- "$1" >/dev/null
}

# FUNCTION: _item_create_backup
#
# DESCRIPTION:
# This function creates a backup of a file (append .bak) if it exists.
_item_create_backup() {
    local item=$1

    if [[ -e "$item" ]] && [[ ! -e "$item.bak" ]]; then
        $SUDO_CMD mv -- "$item" "$item.bak" 2>/dev/null
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
        $SUDO_CMD_USER gio trash -- $items 2>/dev/null
    elif _command_exists "kioclient"; then
        $SUDO_CMD_USER kioclient move -- $items trash:/ 2>/dev/null
    elif _command_exists "gvfs-trash"; then
        $SUDO_CMD_USER gvfs-trash -- $items 2>/dev/null
    else
        $SUDO_CMD rm -rf -- $items 2>/dev/null
    fi
}

# -----------------------------------------------------------------------------
# SECTION: System information and parameters ----
# -----------------------------------------------------------------------------

# FUNCTION: _get_user_homes
#
# DESCRIPTION:
# This function returns the list of home directories for users who can log
# in. It filters '/etc/passwd' entries for accounts with valid login
# shells.
_get_user_homes() {
    local homes=""

    homes=$(grep --extended-regexp "/(bash|sh|zsh|csh|ksh|tcsh|fish|dash)$" \
        </etc/passwd | cut -d ":" -f 6)

    # Ensure the current user's home is included, in case it's missing
    # from '/etc/passwd'.
    if [[ -v "HOME" ]]; then
        homes+=$'\n'
        homes+=$HOME
    fi

    # Remove empty lines.
    homes=$(grep -v "^\s*$" <<<"$homes")

    # Exclude the root '/' directory.
    homes=$(grep -v "^/$" <<<"$homes")

    # Sort and remove duplicates.
    sort --unique <<<"$homes"
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
        -a | --install-all-users) OPT_INSTALL_FOR_ALL_USERS="true" ;;
        -A | --no-install-all-users) OPT_INSTALL_FOR_ALL_USERS="false" ;;
        -b | --install-homebrew) OPT_INSTALL_HOMEBREW="true" ;;
        -B | --no-install-homebrew) OPT_INSTALL_HOMEBREW="false" ;;
        -d | --remove-scripts) OPT_REMOVE_SCRIPTS="true" ;;
        -D | --no-remove-scripts) OPT_REMOVE_SCRIPTS="false" ;;
        -f | --close-filemanager) OPT_CLOSE_FILE_MANAGER="true" ;;
        -F | --no-close-filemanager) OPT_CLOSE_FILE_MANAGER="false" ;;
        -i | --install-dependencies) OPT_INSTALL_BASIC_DEPS="true" ;;
        -I | --no-install-dependencies) OPT_INSTALL_BASIC_DEPS="false" ;;
        -k | --install-shortcuts) OPT_INSTALL_ACCELS="true" ;;
        -K | --no-install-shortcuts) OPT_INSTALL_ACCELS="false" ;;
        -n | --non-interactive) OPT_INTERACTIVE_INSTALL="false" ;;
        -q | --quiet) OPT_QUIET_INSTALL="true" ;;
        -s | --install-app-shortcuts) OPT_INSTALL_APP_SHORTCUTS="true" ;;
        -S | --no-install-app-shortcuts) OPT_INSTALL_APP_SHORTCUTS="false" ;;
        -h | --help)
            echo "Usage: $0 [options]"
            echo
            echo "  -a, --install-all-users         Install for all users."
            echo "  -A, --no-install-all-users      Do not install for all users."
            echo "  -b, --install-homebrew          Install Homebrew."
            echo "  -B, --no-install-homebrew       Do not install Homebrew."
            echo "  -d, --remove-scripts            Remove previously installed scripts."
            echo "  -D, --no-remove-scripts         Do not remove previously installed scripts."
            echo "  -f, --close-filemanager         Close file manager after install."
            echo "  -F, --no-close-filemanager      Do not close file manager after install."
            echo "  -i, --install-dependencies      Install basic dependencies."
            echo "  -I, --no-install-dependencies   Do not install basic dependencies."
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
# value. Quotes are removed and '|' characters are replaced with ';' for
# consistency.
_get_par_value() {
    local filename=$1
    local parameter=$2

    $SUDO_CMD grep --only-matching -m 1 "$parameter=[^\";]*" "$filename" |
        cut -d "=" -f 2 | tr -d "'" | tr "|" ";" 2>/dev/null
}

# -----------------------------------------------------------------------------
# SECTION: Installation steps ----
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
## Dependencies ----
# -----------------------------------------------------------------------------

# shellcheck disable=SC2086
_step_install_dependencies() {
    _echo ""
    _echo_info "Installing basic dependencies:"

    local packages=""
    local admin_cmd=""

    if _command_exists "sudo"; then
        admin_cmd="sudo"
    fi

    # Basic packages to run the script '.common-functions.sh'.
    _command_exists "basename" || packages+="coreutils "
    _command_exists "file" || packages+="file "
    _command_exists "pstree" || packages+="psmisc "
    _command_exists "xdg-open" || packages+="xdg-utils "

    # Packages for dialogs.
    if [[ -n "${XDG_CURRENT_DESKTOP:-}" ]]; then
        if ! _command_exists "zenity" && ! _command_exists "kdialog"; then
            packages+="zenity "
        fi
    fi

    if _command_exists "nix-env"; then
        _command_exists "pgrep" || packages+="procps "

        # Package manager 'nix': no root required.
        if [[ -n "$packages" ]]; then
            local nix_packages=""
            local nix_channel="nixpkgs"
            if grep --quiet "ID=nixos" /etc/os-release 2>/dev/null; then
                nix_channel="nixos"
            fi

            nix_packages="$nix_channel.$packages"
            # shellcheck disable=SC2001
            nix_packages=$(sed "s| $||g" <<<"$nix_packages")
            # shellcheck disable=SC2001
            nix_packages=$(sed "s| | $nix_channel.|g" <<<"$nix_packages")

            nix-env -iA $nix_packages
        fi
    elif _command_exists "guix"; then
        _command_exists "pgrep" || packages+="procps "

        # Package manager 'guix': no root required.
        if [[ -n "$packages" ]]; then
            guix install $packages
        fi
    elif _command_exists "apt-get"; then
        # Package manager 'apt-get': For Debian/Ubuntu systems.
        _command_exists "pgrep" || packages+="procps "

        if [[ -n "$packages" ]]; then
            $admin_cmd apt-get update
            $admin_cmd apt-get -y install $packages
        fi
    elif _command_exists "rpm-ostree"; then
        # Package manager 'rpm-ostree': For Fedora/RHEL atomic systems.
        _command_exists "pgrep" || packages+="procps-ng "

        if [[ -n "$packages" ]]; then
            $admin_cmd rpm-ostree install $packages
        fi
    elif _command_exists "dnf"; then
        # Package manager 'dnf': For Fedora/RHEL systems.
        _command_exists "pgrep" || packages+="procps-ng "

        if [[ -n "$packages" ]]; then
            $admin_cmd dnf check-update
            $admin_cmd dnf -y install $packages
        fi
    elif _command_exists "pacman"; then
        # Package manager 'pacman': For Arch Linux systems.
        _command_exists "pgrep" || packages+="procps "

        # NOTE: Force update GTK4 packages on Arch Linux.
        if [[ "$packages" == *"zenity"* ]]; then
            packages+="gtk4 zlib glib2 "
        fi

        if [[ -n "$packages" ]]; then
            $admin_cmd pacman -Syy
            $admin_cmd pacman --noconfirm -S $packages
        fi
    elif _command_exists "zypper"; then
        # Package manager 'zypper': For openSUSE systems.
        _command_exists "pgrep" || packages+="procps-ng "

        if [[ -n "$packages" ]]; then
            $admin_cmd zypper refresh
            $admin_cmd zypper --non-interactive install $packages
        fi
    else
        if [[ -n "$packages" ]]; then
            _echo_error "Could not find a package manager!"
            exit 1
        fi
    fi

    if [[ -z "$packages" ]]; then
        _echo_info "> All dependencies are already satisfied."
    fi
    _echo_info "> Done!"
}

# FUNCTION: _step_install_scripts
#
# DESCRIPTION:
# This function installs scripts into the target directory.
# Steps:
#   1. Optionally remove any previously installed scripts.
#   2. Copy common and category-specific script files.
#   3. Set proper ownership and permissions.
_step_install_scripts() {
    local -n _cat_selected=$1
    local -n _cat_dirs=$2

    # Remove previous scripts if requested.
    if [[ "$OPT_REMOVE_SCRIPTS" == "true" ]]; then
        _echo_info "> Removing previously installed scripts..."
        _delete_items "$INSTALL_DIR"
        # Also remove application menu shortcuts if they exist.
        local app_menus_path="$INSTALL_HOME/.local/share/applications/$APP_MENUS_DIR"
        if [[ -d "$app_menus_path" ]]; then
            _echo_info "> Removing application menu shortcuts..."
            _delete_items "$app_menus_path"
        fi
    fi

    _echo_info "> Installing the scripts..."
    $SUDO_CMD_USER mkdir --parents "$INSTALL_DIR"

    # Always copy the '.common-functions.sh' and the '.dependencies.sh' files.
    $SUDO_CMD cp -- "$SCRIPT_DIR/.common-functions.sh" "$INSTALL_DIR"
    $SUDO_CMD cp -- "$SCRIPT_DIR/.dependencies.sh" "$INSTALL_DIR"

    # Copy scripts by category. If the user selected specific categories, only
    # those are installed. Otherwise, all categories are copied by default.
    local i=0
    for i in "${!_cat_dirs[@]}"; do
        if [[ -v "_cat_selected[i]" ]]; then
            if [[ ${_cat_selected[i]} == "true" ]]; then
                $SUDO_CMD cp -r -- "$SCRIPT_DIR/${_cat_dirs[i]}" "$INSTALL_DIR"
            fi
        else
            $SUDO_CMD cp -r -- "$SCRIPT_DIR/${_cat_dirs[i]}" "$INSTALL_DIR"
        fi
    done

    # Adjust ownership and permissions. Ensures all files belong to the correct
    # user/group and are executable.
    $SUDO_CMD chown -R "$INSTALL_OWNER:$INSTALL_GROUP" -- "$INSTALL_DIR"
    $SUDO_CMD find -L "$INSTALL_DIR" -mindepth 2 -type f \
        "${IGNORE_FIND_PATHS[@]}" -exec chmod +x -- {} \;
}

# -----------------------------------------------------------------------------
## Keyboard accellerators ----
# -----------------------------------------------------------------------------

# FUNCTION: _step_install_accels
#
# DESCRIPTION:
# Install keyboard accelerators (shortcuts) for specific file managers.
_step_install_accels() {
    _echo_info "> Installing keyboard accelerators..."

    case "$FILE_MANAGER" in
    "nautilus")
        _step_install_accels_nautilus \
            "$INSTALL_HOME/.config/nautilus/scripts-accels"
        ;;
    "caja")
        _step_install_accels_gnome2 \
            "$INSTALL_HOME/.config/caja/accels"
        ;;
    "nemo")
        _step_install_accels_gnome2 \
            "$INSTALL_HOME/.gnome2/accels/nemo"
        ;;
    "thunar")
        _step_install_accels_thunar \
            "$INSTALL_HOME/.config/Thunar/accels.scm"
        ;;
    esac
}

_step_install_accels_nautilus() {
    local accels_file=$1
    $SUDO_CMD_USER mkdir --parents "$(dirname -- "$accels_file")"

    # Create a backup of older custom actions.
    _item_create_backup "$accels_file"
    _delete_items "$accels_file"

    {
        local filename=""
        while IFS= read -r -d $'\0' filename; do
            local keyboard_shortcut=""
            keyboard_shortcut=$(_get_par_value \
                "$filename" "install_keyboard_shortcut")

            if [[ -n "$keyboard_shortcut" ]]; then
                local name=""
                name=$(basename -- "$filename")
                printf "%s\n" "$keyboard_shortcut $name"
            fi
        done < <(_list_scripts)

    } | _tee_file "$accels_file"

    _chown_file "$accels_file"
}

_step_install_accels_gnome2() {
    local accels_file=$1
    $SUDO_CMD_USER mkdir --parents "$(dirname -- "$accels_file")"

    # Create a backup of older custom actions.
    _item_create_backup "$accels_file"
    _delete_items "$accels_file"

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
                filename=$(sed "s|/|\\\\\\\\s|g; s| |%20|g" <<<"$filename")
                printf "%s\n" '(gtk_accel_path "<Actions>/ScriptsGroup/script_file:\\s\\s'"$filename"'" "'"$keyboard_shortcut"'")'
            fi
        done < <(_list_scripts)

    } | _tee_file "$accels_file"

    _chown_file "$accels_file"
}

_step_install_accels_thunar() {
    local accels_file=$1
    $SUDO_CMD_USER mkdir --parents "$(dirname -- "$accels_file")"

    # Create a backup of older custom actions.
    _item_create_backup "$accels_file"
    _delete_items "$accels_file"

    {
        # Default Thunar shortcuts.
        printf "%s\n" '(gtk_accel_path "<Actions>/ThunarActions/uca-action-1-1" "")'
        printf "%s\n" '(gtk_accel_path "<Actions>/ThunarActions/uca-action-4-4" "")'
        printf "%s\n" '(gtk_accel_path "<Actions>/ThunarActions/uca-action-3-3" "")'
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
                local name=""
                local submenu=""
                local unique_id=""
                name=$(basename -- "$filename")
                submenu=$(dirname -- "$filename" | sed "s|.*scripts/|Scripts/|g")
                unique_id=$(md5sum <<<"$submenu$name" 2>/dev/null |
                    sed "s|[^0-9]*||g" | cut -c 1-8)

                printf "%s\n" '(gtk_accel_path "<Actions>/ThunarActions/uca-action-'"$unique_id"'" "'"$keyboard_shortcut"'")'
            fi
        done < <(_list_scripts)

    } | _tee_file "$accels_file"

    _chown_file "$accels_file"
}

# -----------------------------------------------------------------------------
## Application shortcuts ----
# -----------------------------------------------------------------------------

_step_install_application_shortcuts() {
    local filename=""
    local menu_file=""
    local name=""
    local script_relative=""
    local submenu=""
    local app_menus_path="$INSTALL_HOME/.local/share/applications/$APP_MENUS_DIR"

    _echo_info "> Creating '.desktop' files..."

    # Remove previously installed '.desktop' files.
    $SUDO_CMD rm -rf -- "$app_menus_path"

    # Create the directory for menu entries.
    $SUDO_CMD_USER mkdir --parents "$app_menus_path"

    # Create a '.desktop' file for each script.
    while IFS= read -r -d $'\0' filename; do
        # shellcheck disable=SC2001
        script_relative=$(sed "s|.*scripts/||g" <<<"$filename")
        name=${script_relative##*/}
        submenu=${script_relative%/*}
        # shellcheck disable=SC2001
        submenu=$(sed "s|/| - |g" <<<"$submenu")

        menu_file=$name
        menu_file=$(tr -cd "[:alnum:]- " <<<"$menu_file")
        menu_file=$(tr " " "-" <<<"$menu_file")
        menu_file=$(tr -s "-" <<<"$menu_file")
        menu_file=${menu_file,,}
        menu_file="$app_menus_path/$menu_file.desktop"

        {
            printf "%s\n" "[Desktop Entry]"
            printf "%s\n" "Categories=Scripts;"
            printf "%s\n" "Exec=\"$filename\" %F"
            printf "%s\n" "Name=$name"
            #printf "%s\n" "GenericName=$submenu - $name"
            #printf "%s\n" "Comment=$submenu"
            printf "%s\n" "Icon=application-x-executable"
            printf "%s\n" "Terminal=false"
            printf "%s\n" "Type=Application"
        } | _tee_file "$menu_file"

        _chown_file "$menu_file"
        _chmod_x_file "$menu_file"
    done < <(_list_scripts_application)
}

_step_create_gnome_application_folder() {
    local folder_name="Scripts"
    # Configure the "Scripts" application folder in GNOME.

    # Exit if not running under a GNOME desktop environment.
    if [[ -v "XDG_CURRENT_DESKTOP" ]]; then
        if [[ "${XDG_CURRENT_DESKTOP,,}" != *"gnome"* ]]; then
            return
        fi
    else
        return
    fi

    # Check if 'gsettings' is available and the GNOME schemas are present. If
    # not, skip folder creation.
    if ! _command_exists "gsettings" || ! gsettings list-schemas |
        grep --quiet '^org.gnome.desktop.app-folders$'; then
        return
    fi

    _echo_info "> Creating '$folder_name' GNOME application folder..."

    # Determine which 'gsettings' command to use:
    # - Use 'machinectl' when modifying another user's GNOME settings.
    # - Otherwise, use the local 'gsettings' command.
    local gsettings_user="gsettings"
    if _command_exists "machinectl" && [[ "$USER" != "$INSTALL_OWNER" ]]; then
        gsettings_user="sudo machinectl --quiet shell $INSTALL_OWNER@ $(which "gsettings")"
    fi

    # Retrieve the current list of GNOME app folders.
    # If the "Scripts" folder does not exist, append it to the list.
    local current_folders=""
    current_folders=$($gsettings_user get org.gnome.desktop.app-folders folder-children)
    if [[ "$current_folders" != *"'$folder_name'"* ]]; then
        # shellcheck disable=SC2001
        $gsettings_user set \
            org.gnome.desktop.app-folders folder-children "$(sed "s/]/,'$folder_name']/" <<<"$current_folders")" &>/dev/null
    fi

    # Set the display name for the new GNOME application folder.
    $gsettings_user set \
        org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/$folder_name/ \
        name "$folder_name" &>/dev/null

    # Build a list of all .desktop files in the scripts directory to be added
    # under this GNOME application folder.
    local list_scripts=""
    local app_menus_path="$INSTALL_HOME/.local/share/applications/$APP_MENUS_DIR"
    list_scripts=$(
        $SUDO_CMD find "$app_menus_path" \
            -maxdepth 1 -type f -name "*.desktop" \
            -printf "'$APP_MENUS_DIR-%f', " |
            sed 's/, $//; s/^/[/' | sed 's/$/]/'
    )

    # Assign all found .desktop files to the "Scripts" folder in GNOME
    # settings.
    $gsettings_user set \
        org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/$folder_name/ \
        apps "$list_scripts" &>/dev/null

}

# -----------------------------------------------------------------------------
## Context menus ----
# -----------------------------------------------------------------------------

# FUNCTION: _step_install_menus
#
# DESCRIPTION:
# This function install custom context menus for supported file managers.
# Delegates to the appropriate function depending on the detected file
# manager.
_step_install_menus() {
    case "$FILE_MANAGER" in
    "dolphin") _step_install_menus_dolphin ;;
    "pcmanfm-qt") _step_install_menus_pcmanfm ;;
    "thunar") _step_install_menus_thunar ;;
    esac
}

_step_install_menus_dolphin() {
    _echo_info "> Installing Dolphin actions..."

    local menus_dir="$INSTALL_HOME/.local/share/kio/servicemenus"

    _delete_items "$menus_dir"
    $SUDO_CMD_USER mkdir --parents "$menus_dir"

    local filename=""
    local name=""
    local script_relative=""
    local submenu=""

    # Create a '.desktop' file for each script.
    while IFS= read -r -d $'\0' filename; do
        # shellcheck disable=SC2001
        script_relative=$(sed "s|.*scripts/||g" <<<"$filename")
        name=${script_relative##*/}
        submenu=${script_relative%%/*}

        # Set the 'MIME' requirements.
        local par_recursive=""
        local par_select_mime=""
        par_recursive=$(_get_par_value "$filename" "par_recursive")
        par_select_mime=$(_get_par_value "$filename" "par_select_mime")

        if [[ -z "$par_select_mime" ]]; then
            local par_type=""
            par_type=$(_get_par_value "$filename" "par_type")

            case "$par_type" in
            "directory") par_select_mime="inode/directory" ;;
            "all") par_select_mime="all/all" ;;
            "file") par_select_mime="all/allfiles" ;;
            *) par_select_mime="all/allfiles" ;;
            esac
        fi

        if [[ "$par_recursive" == "true" ]]; then
            case "$par_select_mime" in
            "inode/directory") : ;;
            "all/all") : ;;
            "all/allfiles") par_select_mime="all/all" ;;
            *) par_select_mime+=";inode/directory" ;;
            esac
        fi

        par_select_mime="$par_select_mime;"
        # shellcheck disable=SC2001
        par_select_mime=$(sed "s|/;|/*;|g" <<<"$par_select_mime")

        # Set the min/max files requirements.
        local par_min_items=""
        local par_max_items=""
        par_min_items=$(_get_par_value "$filename" "par_min_items")
        par_max_items=$(_get_par_value "$filename" "par_max_items")

        local menu_file=""
        menu_file="${menus_dir}/${name}.desktop"
        {
            printf "%s\n" "[Desktop Entry]"
            printf "%s\n" "Type=Service"
            printf "%s\n" "X-KDE-ServiceTypes=KonqPopupMenu/Plugin"
            printf "%s\n" "Actions=scriptAction;"
            printf "%s\n" "MimeType=$par_select_mime"

            if [[ -n "$par_min_items" ]]; then
                printf "%s\n" "X-KDE-MinNumberOfUrls=$par_min_items"
            fi

            if [[ -n "$par_max_items" ]]; then
                printf "%s\n" "X-KDE-MaxNumberOfUrls=$par_max_items"
            fi

            printf "%s\n" "Encoding=UTF-8"
            printf "%s\n" "X-KDE-Submenu=$submenu"
            printf "\n"
            printf "%s\n" "[Desktop Action scriptAction]"
            printf "%s\n" "Name=$name"
            printf "%s\n" "Exec=bash \"$filename\" %F"
        } | _tee_file "$menu_file"

        _chown_file "$menu_file"
        _chmod_x_file "$menu_file"
    done < <(_list_scripts)
}

_step_install_menus_pcmanfm() {
    _echo_info "> Installing PCManFM-Qt actions..."

    local menus_dir="$INSTALL_HOME/.local/share/file-manager/actions"

    _delete_items "$menus_dir"
    $SUDO_CMD_USER mkdir --parents "$menus_dir"

    # Create the 'Scripts.desktop' for the categories (main menu).
    {
        printf "%s\n" "[Desktop Entry]"
        printf "%s\n" "Type=Menu"
        printf "%s\n" "Name=Scripts"
        printf "%s" "ItemsList="
        $SUDO_CMD find -L "$INSTALL_DIR" -mindepth 1 -maxdepth 1 -type d \
            "${IGNORE_FIND_PATHS[@]}" \
            -printf "%f\0" 2>/dev/null | sort --zero-terminated | tr "\0" ";"
        printf "\n"
    } | _tee_file "$menus_dir/Scripts.desktop"

    _chown_file "$menus_dir/Scripts.desktop"
    _chmod_x_file "$menus_dir/Scripts.desktop"

    # Create a '.desktop' file for each sub-category (sub-menus).
    local filename=""
    local name=""
    local dir_items=""
    while IFS= read -r -d $'\0' filename; do
        name=${filename##*/}
        dir_items=$($SUDO_CMD find -L "$filename" -mindepth 1 -maxdepth 1 \
            "${IGNORE_FIND_PATHS[@]}" \
            -printf "%f\0" 2>/dev/null | sort --zero-terminated | tr "\0" ";")
        if [[ -z "$dir_items" ]]; then
            continue
        fi

        {
            printf "%s\n" "[Desktop Entry]"
            printf "%s\n" "Type=Menu"
            printf "%s\n" "Name=$name"
            printf "%s\n" "ItemsList=$dir_items"

        } | _tee_file "$menus_dir/$name.desktop"

        _chown_file "$menus_dir/$name.desktop"
        _chmod_x_file "$menus_dir/$name.desktop"
    done < <($SUDO_CMD find -L "$INSTALL_DIR" -mindepth 1 -type d \
        "${IGNORE_FIND_PATHS[@]}" \
        -print0 2>/dev/null | sort --zero-terminated)

    # Create a '.desktop' file for each script.
    while IFS= read -r -d $'\0' filename; do
        name=${filename##*/}

        # Set the 'MIME' requirements.
        local par_recursive=""
        local par_select_mime=""
        par_recursive=$(_get_par_value "$filename" "par_recursive")
        par_select_mime=$(_get_par_value "$filename" "par_select_mime")

        if [[ -z "$par_select_mime" ]]; then
            local par_type=""
            par_type=$(_get_par_value "$filename" "par_type")

            case "$par_type" in
            "directory") par_select_mime="inode/directory" ;;
            "all") par_select_mime="all/all" ;;
            "file") par_select_mime="all/allfiles" ;;
            *) par_select_mime="all/allfiles" ;;
            esac
        fi

        if [[ "$par_recursive" == "true" ]]; then
            case "$par_select_mime" in
            "inode/directory") : ;;
            "all/all") : ;;
            "all/allfiles") par_select_mime="all/all" ;;
            *) par_select_mime+=";inode/directory" ;;
            esac
        fi

        par_select_mime="$par_select_mime;"
        # shellcheck disable=SC2001
        par_select_mime=$(sed "s|/;|/*;|g" <<<"$par_select_mime")

        local menu_file=""
        menu_file="${menus_dir}/${name}.desktop"
        {
            printf "%s\n" "[Desktop Entry]"
            printf "%s\n" "Type=Action"
            printf "%s\n" "Name=$name"
            printf "%s\n" "Profiles=scriptAction"
            printf "\n"
            printf "%s\n" "[X-Action-Profile scriptAction]"
            printf "%s\n" "MimeTypes=$par_select_mime"
            printf "%s\n" "Exec=bash \"$filename\" %F"
        } | _tee_file "$menu_file"

        _chown_file "$menu_file"
        _chmod_x_file "$menu_file"
    done < <(_list_scripts)
}

_step_install_menus_thunar() {
    _echo_info "> Installing Thunar actions..."

    local menus_file="$INSTALL_HOME/.config/Thunar/uca.xml"

    # Create a backup of older custom actions.
    _item_create_backup "$menus_file"
    _delete_items "$menus_file"

    $SUDO_CMD_USER mkdir --parents "$INSTALL_HOME/.config/Thunar"

    # Create the file "~/.config/Thunar/uca.xml".
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
        printf "%s\n" "<action>"
        printf "\t%s\n" "<icon>document-print</icon>"
        printf "\t%s\n" "<name>Print file(s)</name>"
        printf "\t%s\n" "<submenu></submenu>"
        printf "\t%s\n" "<unique-id>4-4</unique-id>"
        printf "\t%s\n" "<command>thunar-print %F</command>"
        printf "\t%s\n" "<description>Send one or multiple files to the default printer</description>"
        printf "\t%s\n" "<range></range>"
        printf "\t%s\n" "<patterns>*.asc;*.brf;*.css;*.doc;*.docm;*.docx;*.dotm;*.dotx;*.fodg;*.fodp;*.fods;*.fodt;*.gif;*.htm;*.html;*.jpe;*.jpeg;*.jpg;*.odb;*.odf;*.odg;*.odm;*.odp;*.ods;*.odt;*.otg;*.oth;*.otp;*.ots;*.ott;*.pbm;*.pdf;*.pgm;*.png;*.pnm;*.pot;*.potm;*.potx;*.ppm;*.ppt;*.pptm;*.pptx;*.rtf;*.shtml;*.srt;*.text;*.tif;*.tiff;*.txt;*.xbm;*.xls;*.xlsb;*.xlsm;*.xlsx;*.xltm;*.xltx;*.xpm;*.xwd</patterns>"
        printf "\t%s\n" "<image-files/>"
        printf "\t%s\n" "<other-files/>"
        printf "\t%s\n" "<text-files/>"
        printf "%s\n" "</action>"

        local filename=""
        local name=""
        local submenu=""
        local unique_id=""

        while IFS= read -r -d $'\0' filename; do
            name=$(basename -- "$filename")
            submenu=$(dirname -- "$filename" |
                sed "s|.*scripts/|Scripts/|g")

            printf "%s\n" "<action>"
            printf "\t%s\n" "<icon></icon>"
            printf "\t%s\n" "<name>$name</name>"
            printf "\t%s\n" "<submenu>$submenu</submenu>"

            # Generate a unique id.
            unique_id=$(md5sum <<<"$submenu$name" 2>/dev/null |
                sed "s|[^0-9]*||g" | cut -c 1-8)
            printf "\t%s\n" "<unique-id>$unique_id</unique-id>"

            printf "\t%s\n" "<command>bash &quot;$filename&quot; %F</command>"
            printf "\t%s\n" "<description></description>"

            # Set the min/max files requirements.
            local par_min_items=""
            local par_max_items=""
            par_min_items=$(_get_par_value "$filename" "par_min_items")
            par_max_items=$(_get_par_value "$filename" "par_max_items")
            if [[ -n "$par_min_items" ]] && [[ -n "$par_max_items" ]]; then
                printf "\t%s\n" "<range>$par_min_items-$par_max_items</range>"
            else
                printf "\t%s\n" "<range></range>"
            fi

            printf "\t%s\n" "<patterns>*</patterns>"

            # Set the type requirements.
            local par_recursive=""
            local par_type=""
            par_recursive=$(_get_par_value "$filename" "par_recursive")
            par_type=$(_get_par_value "$filename" "par_type")
            if [[ "$par_type" == "all" ]] ||
                [[ "$par_type" == "directory" ]] ||
                [[ "$par_recursive" == "true" ]]; then
                printf "\t%s\n" "<directories/>"
            fi

            # Set the 'MIME' requirements.
            local par_select_mime=""
            par_select_mime=$(_get_par_value "$filename" "par_select_mime")

            if [[ -n "$par_select_mime" ]]; then
                if [[ "$par_select_mime" == *"audio"* ]]; then
                    printf "\t%s\n" "<audio-files/>"
                fi
                if [[ "$par_select_mime" == *"image"* ]]; then
                    printf "\t%s\n" "<image-files/>"
                fi
                if [[ "$par_select_mime" == *"text"* ]]; then
                    printf "\t%s\n" "<text-files/>"
                fi
                if [[ "$par_select_mime" == *"video"* ]]; then
                    printf "\t%s\n" "<video-files/>"
                fi
            else
                printf "\t%s\n" "<audio-files/>"
                printf "\t%s\n" "<image-files/>"
                printf "\t%s\n" "<text-files/>"
                printf "\t%s\n" "<video-files/>"
            fi
            printf "\t%s\n" "<other-files/>"
            printf "%s\n" "</action>"
        done < <(_list_scripts)

        printf "%s\n" "</actions>"
    } | _tee_file "$menus_file"

    _chown_file "$menus_file"
}

# -----------------------------------------------------------------------------
## Close filemanager ----
# -----------------------------------------------------------------------------

# FUNCTION: _step_close_filemanager
#
# DESCRIPTION:
# This function closes the current file manager so that it reloads its
# configurations. For most file managers, the `-q` option is used to quit
# gracefully.
_step_close_filemanager() {
    if [[ -z "$FILE_MANAGER" ]]; then
        return
    fi

    _echo_info "> Closing the file manager..."

    case "$FILE_MANAGER" in
    "nautilus" | "nemo" | "thunar")
        # These file managers support the '-q' option to quit gracefully.
        $FILE_MANAGER -q &>/dev/null
        ;;
    "caja")
        # Close Caja gracefully.
        caja -q &>/dev/null
        # Reload Caja in background to restore desktop icons.
        nohup caja --force-desktop --no-default-window &>/dev/null &
        ;;
    "pcmanfm-qt")
        # NOTE: 'pcmanfm-qt' does not reload automatically after quitting.
        # We need to capture its current launch command to restart it.
        local session_command=""
        session_command=$(pgrep -a "pcmanfm-qt" | head -n1 | cut -d " " -f 2-)

        # Kill all existing 'pcmanfm-qt' processes.
        killall "$FILE_MANAGER" &>/dev/null

        # Restart it using the same session command (if found).
        if [[ -n "$session_command" ]]; then
            # shellcheck disable=SC2086
            nohup $session_command &>/dev/null &
        else
            # Fallback: start pcmanfm-qt with default settings.
            nohup pcmanfm-qt --desktop &>/dev/null &
        fi
        ;;
    esac
}

# -----------------------------------------------------------------------------
## Homebrew ----
# -----------------------------------------------------------------------------

# FUNCTION: _step_install_homebrew
#
# DESCRIPTION:
# This function installs Homebrew if the user requested it and it is not
# already installed.
_step_install_homebrew() {

    # Check if 'curl' or 'wget' is available.
    local downloader=""
    if _command_exists "curl"; then
        downloader="curl"
    elif _command_exists "wget"; then
        downloader="wget"
    else
        _echo_error "Neither 'curl' nor 'wget' is installed. Please install one of them to continue."
        exit 1
    fi

    _echo ""
    _echo_info "Installing Homebrew:"

    # Homebrew install directory.
    local homebrew_dir="$HOME/.local/apps/homebrew"
    local brew_cmd="$homebrew_dir/bin/brew"

    # Check if Homebrew is already installed.
    if [[ -e "$brew_cmd" ]]; then
        _echo_info "> Homebrew is already installed."
        return
    fi

    _echo_info "> Installing Homebrew to: ~/.local/apps/homebrew"
    mkdir --parents "$homebrew_dir"

    _echo_info "> Downloading the package..."

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
        _echo_error "Homebrew installation failed." >&2
        exit 1
    fi

    _echo_info "> Done!"
}

# -----------------------------------------------------------------------------
# SECTION: Online install ----
# -----------------------------------------------------------------------------

# FUNCTION: _bootstrap_repository
#
# DESCRIPTION:
# This function ensures that the repository files are available before
# running the installation.
_bootstrap_repository() {
    local repo_owner="cfgnunes"
    local repo_name="nautilus-scripts"

    # Check if 'curl' or 'wget' is available.
    local downloader=""
    if _command_exists "curl"; then
        downloader="curl"
    elif _command_exists "wget"; then
        downloader="wget"
    else
        _echo_error "Neither 'curl' nor 'wget' is installed. Please install one of them to continue."
        exit 1
    fi

    _echo_info "Downloading the installer package:"

    # Create a temporary directory for the installation.
    local temp_dir=""
    temp_dir=$(mktemp --directory)

    _echo_info "> Checking for the latest release..."

    # Retrieve the latest release tag from GitHub,
    # (fallback to HEAD if unavailable).
    local latest_tag=""
    {
        local latest_url="https://api.github.com/repos/${repo_owner}/${repo_name}/releases/latest"
        if [[ "$downloader" == "curl" ]]; then
            latest_tag=$(curl -fsSL "$latest_url" |
                grep -Po '"tag_name": "\K.*?(?=")')
        else
            latest_tag=$(wget -qO- "$latest_url" |
                grep -Po '"tag_name": "\K.*?(?=")')
        fi
    } 2>/dev/null

    # Validate extracted content.
    if [[ -z "$latest_tag" ]]; then
        _echo_error "Could not fetch latest release tag."
        exit 1
    fi

    _echo_info "> Downloading ${repo_name} (${latest_tag})..."

    # Download and extract using available tool.
    {
        local tarball_url="https://github.com/${repo_owner}/${repo_name}/archive/refs/tags/${latest_tag}.tar.gz"
        if [[ "$downloader" == "curl" ]]; then
            curl -fsSL "$tarball_url" | tar -xz -C "$temp_dir"
        else
            wget -qO- "$tarball_url" | tar -xz -C "$temp_dir"
        fi
    } 2>/dev/null

    # Identify the extracted directory (matches nautilus-scripts-<version>).
    local extracted_dir=""
    extracted_dir=$(
        find "$temp_dir" -maxdepth 1 -type d -name "${repo_name}-*" | head -n 1
    )

    # Validate extracted content.
    if [[ ! -f "$extracted_dir/install.sh" ]]; then
        _echo_error "Could not find 'install.sh' in extracted files."
        exit 1
    fi

    # Run the installer from the extracted directory.
    _echo_info "> Running installation from extracted files..."
    _echo ""
    cd "$extracted_dir" || exit 1
    bash install.sh "$@"

    rm -rf -- "$temp_dir"
    exit 0
}

_main "$@"
