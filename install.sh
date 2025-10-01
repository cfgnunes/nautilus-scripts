#!/usr/bin/env bash

# Install the scripts for file managers.

set -u

# -----------------------------------------------------------------------------
# CONSTANTS
# -----------------------------------------------------------------------------

APP_SHORTCUT_PREFIX="_script-"

# List of supported file managers. The script will only run if at least one is
# available.
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

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# Colored status messages for logging.
MSG_ERROR="[\033[0;31mFAILED\033[0m]"
MSG_INFO="[\033[0;32m INFO \033[0m]"

# Mark constants as read-only to prevent accidental modification.
readonly \
    APP_SHORTCUT_PREFIX \
    COMPATIBLE_FILE_MANAGERS \
    IGNORE_FIND_PATHS \
    MSG_ERROR \
    MSG_INFO \
    SCRIPT_DIR

# -----------------------------------------------------------------------------
# GLOBAL VARIABLES
# -----------------------------------------------------------------------------

FILE_MANAGER=""  # Current file manager being processed.
INSTALL_DIR=""   # Target installation directory for scripts.
INSTALL_HOME=""  # User's home directory where scripts will be installed.
INSTALL_OWNER="" # Owner of the installation directory.
INSTALL_GROUP="" # Group of the installation directory.
SUDO_CMD=""      # Command prefix for elevated operations.
SUDO_CMD_USER="" # Command prefix for running as target user.

# Import helper script for interactive multi-selection menus.
#shellcheck source=.assets/multiselect-menu.sh
source "$SCRIPT_DIR/.assets/multiselect-menu.sh"

# -----------------------------------------------------------------------------
# FUNCTIONS
# -----------------------------------------------------------------------------

# shellcheck disable=SC2034
_main() {
    local cat_defaults=()
    local cat_dirs=()
    local cat_selected=()
    local menu_defaults=()
    local menu_labels=()
    local menu_options=""
    local menu_selected=()
    local interactive_install="true"

    # Read parammeters from command line.
    if [[ $# -gt 0 ]]; then
        case "$1" in
        "-n" | "--non-interactive")
            interactive_install="false"
            ;;
        *)
            echo "Usage: $0 [-n|--non-interactive]" >&2
            echo "Run the installation in non-interactive mode (no prompts will be shown)." >&2
            exit 1
            ;;
        esac
    fi

    # Available options presented in the interactive menu.
    menu_labels=(
        "Install basic dependencies (may require 'sudo')"
        "Install keyboard shortcuts"
        "Close the file manager to reload its configurations"
        "Remove previously installed scripts"
        "Install application menu shortcuts"
        "Install for all users (may require 'sudo')"
        "Choose which script categories to install"
    )

    # Default states for the menu options.
    menu_defaults=(
        "true"
        "true"
        "true"
        "true"
        "false"
        "false"
        "false"
    )

    if [[ "$interactive_install" == "true" ]]; then
        echo "Scripts installer."
        echo "Select the options (<SPACE> to check):"

        # Display the interactive menu and capture user selections.
        _multiselect_menu menu_selected menu_labels menu_defaults
    else
        echo "Running the installer in non-interactive mode..."
        menu_selected=("${menu_defaults[@]}")
    fi

    # Map menu selections into a comma-separated string of options.
    [[ ${menu_selected[0]} == "true" ]] && menu_options+="dependencies,"
    [[ ${menu_selected[1]} == "true" ]] && menu_options+="accels,"
    [[ ${menu_selected[2]} == "true" ]] && menu_options+="reload,"
    [[ ${menu_selected[3]} == "true" ]] && menu_options+="remove,"
    [[ ${menu_selected[4]} == "true" ]] && menu_options+="appmenu,"
    [[ ${menu_selected[5]} == "true" ]] && menu_options+="allusers,"
    [[ ${menu_selected[6]} == "true" ]] && menu_options+="categories,"

    # Collect all available script categories (directories).
    local dir=""
    while IFS= read -r -d $'\0' dir; do
        cat_dirs+=("$dir")
    done < <(
        find -L "$SCRIPT_DIR" -mindepth 1 -maxdepth 1 -type d \
            "${IGNORE_FIND_PATHS[@]}" \
            -print0 2>/dev/null |
            sed -z "s|^.*/||" |
            sort --zero-terminated --version-sort
    )

    # If requested, let the user select which categories to install.
    if [[ "$menu_options" == *"categories"* ]]; then
        echo
        echo "Select the categories (<SPACE> to check):"
        _multiselect_menu cat_selected cat_dirs cat_defaults
    fi

    # Step 1: Install basic dependencies.
    [[ "$menu_options" == *"dependencies"* ]] && _step_install_dependencies

    # Step 2: Determine target home directories (single user or all users).
    local install_home_list=""
    if [[ "$menu_options" == *"allusers"* ]]; then
        SUDO_CMD="sudo"

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
        if [[ "$menu_options" == *"allusers"* ]]; then
            SUDO_CMD_USER="sudo -u $INSTALL_OWNER -g $INSTALL_GROUP"
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

                if [[ ! -v "DISPLAY" ]]; then
                    echo -e "$MSG_ERROR Could not find any compatible file managers!"
                    exit 1
                fi
                INSTALL_DIR="$INSTALL_HOME/.local/share/scripts"
                ;;
            esac

            # Perform installation steps.
            echo
            echo "Installing the scripts:"
            echo -e "$MSG_INFO User: $INSTALL_OWNER"
            echo -e "$MSG_INFO Directory: $INSTALL_HOME"
            echo -e "$MSG_INFO File manager: $FILE_MANAGER"
            _step_install_scripts "$menu_options" cat_selected cat_dirs
            _step_install_menus
            [[ "$menu_options" == *"accels"* ]] && _step_install_accels

            # Reload file manager to apply changes, if selected.
            if [[ "$USER" == "$INSTALL_OWNER" ]]; then
                [[ "$menu_options" == *"reload"* ]] && _step_close_filemanager
            fi
        done

        # Install application menu shortcuts.
        echo
        echo "Installing application menu shortcuts:"
        echo -e "$MSG_INFO User: $INSTALL_OWNER"

        if [[ "$menu_options" == *"appmenu"* ]]; then
            _step_install_application_shortcuts
            _step_create_gnome_application_folder
        fi
    done

    echo
    echo "Done!"
}

_check_exist_filemanager() {
    # This function checks if at least one compatible file manager exists in
    # the system by iterating through a predefined list of supported file
    # managers defined in '$COMPATIBLE_FILE_MANAGERS'.
    #
    # Returns:
    #   - "0" (true): If at least one compatible file manager is found.
    #   - "1" (false): If no compatible file manager is found.

    local file_manager=""
    for file_manager in "${COMPATIBLE_FILE_MANAGERS[@]}"; do
        if _command_exists "$file_manager"; then
            return 0
        fi
    done
    return 1
}

_command_exists() {
    # This function checks whether a given command is available on the system.
    #
    # Parameters:
    #   - $1 (command_check): The name of the command to verify.
    #
    # Returns:
    #   - "0" (true): If the command is available.
    #   - "1" (false): If the command is not available.

    local command_check=$1

    if command -v "$command_check" &>/dev/null; then
        return 0
    fi
    return 1
}

_item_create_backup() {
    # This function creates a backup of a file (append .bak) if it exists.

    local item=$1

    if [[ -e "$item" ]] && [[ ! -e "$item.bak" ]]; then
        $SUDO_CMD mv -- "$item" "$item.bak" 2>/dev/null
    fi
}

_delete_items() {
    # This function deletes or trash items, using the best available method.

    local items=$1

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

# shellcheck disable=SC2086
_step_install_dependencies() {
    echo
    echo "Installing basic dependencies:"

    local packages=""

    # Basic packages to run the script 'common-functions.sh'.
    _command_exists "bash" || packages+="bash "
    _command_exists "basename" || packages+="coreutils "
    _command_exists "find" || packages+="findutils "
    _command_exists "grep" || packages+="grep "
    _command_exists "sed" || packages+="sed "
    _command_exists "awk" || packages+="gawk "
    _command_exists "xdg-open" || packages+="xdg-utils "
    _command_exists "file" || packages+="file "

    # Packages for dialogs.
    if [[ -n "${XDG_CURRENT_DESKTOP:-}" ]]; then
        if ! _command_exists "zenity" && ! _command_exists "kdialog"; then
            packages+="zenity "
        fi
    fi

    if _command_exists "guix"; then
        _command_exists "pgrep" || packages+="procps "

        # Package manager 'guix': no root required.
        if [[ -n "$packages" ]]; then
            guix install $packages
        fi
    elif _command_exists "nix"; then
        _command_exists "pgrep" || packages+="procps "

        local nix_channel="nixos"
        packages="$nix_channel.$packages"
        # shellcheck disable=SC2001
        packages=$(sed "s| $||g" <<<"$packages")
        # shellcheck disable=SC2001
        packages=$(sed "s| | $nix_channel.|g" <<<"$packages")

        # Package manager 'nix': no root required.
        if [[ -n "$packages" ]]; then
            nix-env -iA $packages
        fi
    elif _command_exists "sudo"; then
        if _command_exists "apt-get"; then
            # Package manager 'apt-get': For Debian/Ubuntu systems.
            _command_exists "pgrep" || packages+="procps "
            _command_exists "pkexec" || packages+="pkexec "

            if [[ -n "$packages" ]]; then
                sudo apt-get update
                sudo apt-get -y install $packages
            fi
        elif _command_exists "dnf"; then
            # Package manager 'dnf': For Fedora/RHEL systems.
            _command_exists "pgrep" || packages+="procps-ng "
            _command_exists "pkexec" || packages+="polkit "

            if [[ -n "$packages" ]]; then
                sudo dnf check-update
                sudo dnf -y install $packages
            fi
        elif _command_exists "pacman"; then
            # Package manager 'pacman': For Arch Linux systems.
            _command_exists "pgrep" || packages+="procps "
            _command_exists "pkexec" || packages+="polkit "

            # FIXME: Force update GTK4 packages on Arch Linux.
            if [[ "$packages" == *"zenity"* ]]; then
                packages+="gtk4 zlib glib2 "
            fi

            if [[ -n "$packages" ]]; then
                sudo pacman -Syy
                sudo pacman --noconfirm -S $packages
            fi
        elif _command_exists "zypper"; then
            # Package manager 'zypper': For openSUSE systems.
            _command_exists "pgrep" || packages+="procps-ng "
            _command_exists "pkexec" || packages+="polkit "

            if [[ -n "$packages" ]]; then
                sudo zypper refresh
                sudo zypper --non-interactive install $packages
            fi
        else
            if [[ -n "$packages" ]]; then
                echo -e "$MSG_ERROR Could not find a package manager!"
                exit 1
            fi
        fi
    else
        echo -e "$MSG_ERROR Could not find the 'sudo' command!"
        exit 1
    fi

    # Fix permissions in ImageMagick to write PDF files.
    local imagemagick_policy=""
    imagemagick_policy=$(find /etc/ImageMagick-[0-9]*/policy.xml 2>/dev/null)
    if [[ -f "$imagemagick_policy" ]]; then
        echo -e "$MSG_INFO Fixing write permission with PDF in ImageMagick..."
        sudo sed -i \
            's/rights="none" pattern="PDF"/rights="read|write" pattern="PDF"/g' \
            "$imagemagick_policy"
        sudo sed -i 's/".GiB"/"8GiB"/g' "$imagemagick_policy"
    fi
}

_step_install_scripts() {
    local menu_options=$1
    local -n _cat_selected=$2
    local -n _cat_dirs=$3

    # Install scripts into the target directory.
    # Steps:
    #   1. Optionally remove any previously installed scripts.
    #   2. Copy common and category-specific script files.
    #   3. Set proper ownership and permissions.

    # Remove previous scripts if requested.
    if [[ "$menu_options" == *"remove"* ]]; then
        echo -e "$MSG_INFO Removing previous scripts..."
        _delete_items "$INSTALL_DIR"
    fi

    echo -e "$MSG_INFO Installing new scripts..."
    $SUDO_CMD_USER mkdir --parents "$INSTALL_DIR"

    # Always copy the 'common-functions.sh' file.
    $SUDO_CMD cp -- "$SCRIPT_DIR/common-functions.sh" "$INSTALL_DIR"

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
    echo -e "$MSG_INFO Setting file permissions..."
    $SUDO_CMD chown -R "$INSTALL_OWNER:$INSTALL_GROUP" -- "$INSTALL_DIR"
    $SUDO_CMD find -L "$INSTALL_DIR" -mindepth 2 -type f \
        "${IGNORE_FIND_PATHS[@]}" \
        -exec chmod +x -- {} \;
}

_step_install_accels() {
    # Install keyboard shortcuts (accels) for specific file managers.

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
    echo -e "$MSG_INFO Installing keyboard shortcuts for Nautilus..."

    local accels_file=$1
    $SUDO_CMD_USER mkdir --parents "$(dirname -- "$accels_file")"

    # Create a backup of older custom actions.
    _item_create_backup "$accels_file"
    _delete_items "$accels_file"

    {
        local filename=""
        $SUDO_CMD find -L "$INSTALL_DIR" -mindepth 2 -type f \
            "${IGNORE_FIND_PATHS[@]}" \
            -print0 2>/dev/null |
            sort --zero-terminated |
            while IFS= read -r -d "" filename; do

                local keyboard_shortcut=""
                keyboard_shortcut=$(_get_par_value \
                    "$filename" "install_keyboard_shortcut")

                if [[ -n "$keyboard_shortcut" ]]; then
                    local name=""
                    name=$(basename -- "$filename")
                    printf "%s\n" "$keyboard_shortcut $name"
                fi
            done

    } | $SUDO_CMD tee "$accels_file" >/dev/null
    $SUDO_CMD chown "$INSTALL_OWNER:$INSTALL_GROUP" -- "$accels_file"
}

_step_install_accels_gnome2() {
    echo -e "$MSG_INFO Installing keyboard shortcuts..."

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
        $SUDO_CMD find -L "$INSTALL_DIR" -mindepth 2 -type f \
            "${IGNORE_FIND_PATHS[@]}" \
            -print0 2>/dev/null |
            sort --zero-terminated |
            while IFS= read -r -d "" filename; do

                local keyboard_shortcut=""
                keyboard_shortcut=$(_get_par_value \
                    "$filename" "install_keyboard_shortcut")
                keyboard_shortcut=${keyboard_shortcut//Control/Primary}

                if [[ -n "$keyboard_shortcut" ]]; then
                    # shellcheck disable=SC2001
                    filename=$(sed "s|/|\\\\\\\\s|g; s| |%20|g" <<<"$filename")
                    printf "%s\n" '(gtk_accel_path "<Actions>/ScriptsGroup/script_file:\\s\\s'"$filename"'" "'"$keyboard_shortcut"'")'
                fi
            done

    } | $SUDO_CMD tee "$accels_file" >/dev/null
    $SUDO_CMD chown "$INSTALL_OWNER:$INSTALL_GROUP" -- "$accels_file"
}

_step_install_accels_thunar() {
    echo -e "$MSG_INFO Installing keyboard shortcuts for Thunar..."

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
        # Disable  "<Primary><Shift>p".
        printf "%s\n" '(gtk_accel_path "<Actions>/ThunarActionManager/open-in-new-tab" "")'
        # Disable "<Primary><Shift>o".
        printf "%s\n" '(gtk_accel_path "<Actions>/ThunarActionManager/open-in-new-window" "")'
        # Disable "<Primary>e".
        printf "%s\n" '(gtk_accel_path "<Actions>/ThunarWindow/view-side-pane-tree" "")'

        local filename=""
        $SUDO_CMD find -L "$INSTALL_DIR" -mindepth 2 -type f \
            "${IGNORE_FIND_PATHS[@]}" \
            -print0 2>/dev/null |
            sort --zero-terminated |
            while IFS= read -r -d "" filename; do

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
            done

    } | $SUDO_CMD tee "$accels_file" >/dev/null
    $SUDO_CMD chown "$INSTALL_OWNER:$INSTALL_GROUP" -- "$accels_file"
}

_step_install_application_shortcuts() {
    local filename=""
    local menu_file=""
    local name=""
    local script_relative=""
    local submenu=""
    local menus_dir="$INSTALL_HOME/.local/share/applications"

    echo -e "$MSG_INFO Creating '.desktop' files..."

    # Remove previously installed '.desktop' files.
    $SUDO_CMD rm -f -- "$menus_dir/$APP_SHORTCUT_PREFIX"*.desktop

    $SUDO_CMD_USER mkdir --parents "$menus_dir"

    # Create a '.desktop' file for each script.
    $SUDO_CMD find -L "$INSTALL_DIR" -mindepth 2 -type f \
        "${IGNORE_FIND_PATHS[@]}" \
        "${IGNORE_APPLICATION_SHORTCUTS[@]}" \
        -print0 2>/dev/null |
        sort --zero-terminated |
        while IFS= read -r -d "" filename; do
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
            menu_file="${menus_dir}/$APP_SHORTCUT_PREFIX$menu_file.desktop"

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
            } | $SUDO_CMD tee "$menu_file" >/dev/null
            $SUDO_CMD chown "$INSTALL_OWNER:$INSTALL_GROUP" -- "$menu_file"
            $SUDO_CMD chmod +x "$menu_file"
        done
}

_step_install_menus() {
    # This function install custom context menus for supported file managers.
    # Delegates to the appropriate function depending on the detected file
    # manager.

    case "$FILE_MANAGER" in
    "dolphin") _step_install_menus_dolphin ;;
    "pcmanfm-qt") _step_install_menus_pcmanfm ;;
    "thunar") _step_install_menus_thunar ;;
    esac
}

_step_install_menus_dolphin() {
    echo -e "$MSG_INFO Installing Dolphin actions..."

    local menus_dir="$INSTALL_HOME/.local/share/kio/servicemenus"

    _delete_items "$menus_dir"
    $SUDO_CMD_USER mkdir --parents "$menus_dir"

    local filename=""
    local name=""
    local script_relative=""
    local submenu=""

    # Create a '.desktop' file for each script.
    $SUDO_CMD find -L "$INSTALL_DIR" -mindepth 2 -type f \
        "${IGNORE_FIND_PATHS[@]}" \
        -print0 2>/dev/null |
        sort --zero-terminated |
        while IFS= read -r -d "" filename; do
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
            } | $SUDO_CMD tee "$menu_file" >/dev/null
            $SUDO_CMD chown "$INSTALL_OWNER:$INSTALL_GROUP" -- "$menu_file"
            $SUDO_CMD chmod +x "$menu_file"
        done
}

_step_install_menus_pcmanfm() {
    echo -e "$MSG_INFO Installing PCManFM-Qt actions..."

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
            -printf "%f\n" 2>/dev/null | sort | tr $'\n' ";"
        printf "\n"
    } | $SUDO_CMD tee "${menus_dir}/Scripts.desktop" >/dev/null
    $SUDO_CMD chown "$INSTALL_OWNER:$INSTALL_GROUP" -- \
        "${menus_dir}/Scripts.desktop"
    $SUDO_CMD chmod +x "${menus_dir}/Scripts.desktop"

    # Create a '.desktop' file for each sub-category (sub-menus).
    local filename=""
    local name=""
    local dir_items=""
    $SUDO_CMD find -L "$INSTALL_DIR" -mindepth 1 -type d \
        "${IGNORE_FIND_PATHS[@]}" \
        -print0 2>/dev/null |
        sort --zero-terminated |
        while IFS= read -r -d "" filename; do
            name=${filename##*/}
            dir_items=$($SUDO_CMD find -L "$filename" -mindepth 1 -maxdepth 1 \
                "${IGNORE_FIND_PATHS[@]}" \
                -printf "%f\n" 2>/dev/null | sort | tr $'\n' ";")
            if [[ -z "$dir_items" ]]; then
                continue
            fi

            {
                printf "%s\n" "[Desktop Entry]"
                printf "%s\n" "Type=Menu"
                printf "%s\n" "Name=$name"
                printf "%s\n" "ItemsList=$dir_items"

            } | $SUDO_CMD tee "${menus_dir}/$name.desktop" >/dev/null
            $SUDO_CMD chown "$INSTALL_OWNER:$INSTALL_GROUP" -- \
                "${menus_dir}/$name.desktop"
            $SUDO_CMD chmod +x "${menus_dir}/$name.desktop"
        done

    # Create a '.desktop' file for each script.
    $SUDO_CMD find -L "$INSTALL_DIR" -mindepth 2 -type f \
        "${IGNORE_FIND_PATHS[@]}" \
        -print0 2>/dev/null |
        sort --zero-terminated |
        while IFS= read -r -d "" filename; do
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
            } | $SUDO_CMD tee "$menu_file" >/dev/null
            $SUDO_CMD chown "$INSTALL_OWNER:$INSTALL_GROUP" -- "$menu_file"
            $SUDO_CMD chmod +x "$menu_file"
        done
}

_step_install_menus_thunar() {
    echo -e "$MSG_INFO Installing Thunar actions..."

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
        $SUDO_CMD find -L "$INSTALL_DIR" -mindepth 2 -type f \
            "${IGNORE_FIND_PATHS[@]}" \
            -print0 2>/dev/null |
            sort --zero-terminated |
            while IFS= read -r -d "" filename; do
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
            done

        printf "%s\n" "</actions>"
    } | $SUDO_CMD tee "$menus_file" >/dev/null
    $SUDO_CMD chown "$INSTALL_OWNER:$INSTALL_GROUP" -- "$menus_file"
}

_step_close_filemanager() {
    # This function closes the current file manager so that it reloads its
    # configurations. For most file managers, the `-q` option is used to quit
    # gracefully.

    case "$FILE_MANAGER" in
    "nautilus" | "caja" | "nemo" | "thunar")
        echo -e "$MSG_INFO Closing the file manager '$FILE_MANAGER' to reload its configurations..."
        $FILE_MANAGER -q &>/dev/null &
        ;;
    "pcmanfm-qt")
        echo -e "$MSG_INFO Closing the file manager '$FILE_MANAGER' to reload its configurations..."
        # FIXME: Restore desktop after kill PCManFM-Qt.
        killall "$FILE_MANAGER" &>/dev/null &
        ;;
    esac
}

_step_create_gnome_application_folder() {
    local folder_name="Scripts"

    # Configure the "Scripts" application folder in GNOME.
    if _command_exists "gsettings" && gsettings list-schemas |
        grep --quiet '^org.gnome.desktop.app-folders$'; then

        echo -e "$MSG_INFO Creating '$folder_name' GNOME application folder..."

        local gsettings_user="gsettings"
        if _command_exists "machinectl" && [[ "$USER" != "$INSTALL_OWNER" ]]; then
            gsettings_user="sudo machinectl --quiet shell $INSTALL_OWNER@ $(which "gsettings")"
        fi

        local current_folders=""
        current_folders=$($gsettings_user get org.gnome.desktop.app-folders folder-children)
        if [[ "$current_folders" != *"'$folder_name'"* ]]; then
            # shellcheck disable=SC2001
            $gsettings_user set \
                org.gnome.desktop.app-folders folder-children "$(sed "s/]/,'$folder_name']/" <<<"$current_folders")" &>/dev/null
        fi

        $gsettings_user set \
            org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/$folder_name/ \
            name "$folder_name" &>/dev/null

        local list_scripts=""
        list_scripts=$(
            $SUDO_CMD find "$INSTALL_HOME/.local/share/applications" \
                -maxdepth 1 -type f -name "$APP_SHORTCUT_PREFIX*.desktop" \
                -printf "'%f', " |
                sed 's/, $//; s/^/[/' | sed 's/$/]/'
        )
        $gsettings_user set \
            org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/$folder_name/ \
            apps "$list_scripts" &>/dev/null
    fi
}

_get_user_homes() {
    # This function returns the list of home directories for users who can log
    # in. It filters '/etc/passwd' entries for accounts with valid login
    # shells.

    getent passwd |
        grep --extended-regexp "/(bash|sh|zsh|csh|ksh|tcsh|fish|dash)$" |
        cut -d ":" -f 6 |
        sort --unique
}

_get_par_value() {
    # This function extracts the value of a given parameter from a script file.
    # It searches for "parameter=value" inside the file, then returns only the
    # value. Quotes are removed and '|' characters are replaced with ';' for
    # consistency.

    local filename=$1
    local parameter=$2

    $SUDO_CMD grep --only-matching -m 1 "$parameter=[^\";]*" "$filename" |
        cut -d "=" -f 2 | tr -d "'" | tr "|" ";" 2>/dev/null
}

_main "$@"
