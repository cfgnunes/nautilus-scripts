#!/usr/bin/env bash

# Install the scripts for file managers.

set -u

# -----------------------------------------------------------------------------
# CONSTANTS
# -----------------------------------------------------------------------------

COMPATIBLE_FILE_MANAGERS=(
    "nautilus"
    "caja"
    "dolphin"
    "nemo"
    "pcmanfm-qt"
    "thunar")

IGNORE_FIND_PATHS=(
    ! -path "*/Accessed recently*"
    ! -path "*/.assets*"
    ! -path "*/.git*"
)

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

STR_ERROR="[\\e[31mERROR\\e[0m]"
STR_INFO="[\\e[32mINFO\\e[0m]"

readonly \
    COMPATIBLE_FILE_MANAGERS \
    IGNORE_FIND_PATHS \
    SCRIPT_DIR \
    STR_ERROR \
    STR_INFO

# -----------------------------------------------------------------------------
# GLOBAL VARIABLES
# -----------------------------------------------------------------------------

FILE_MANAGER=""
INSTALL_DIR=""
INSTALL_HOME=""
INSTALL_OWNER=""
INSTALL_GROUP=""
SUDO_CMD=""
SUDO_CMD_USER=""

#shellcheck source=.assets/multiselect-menu.sh
source "$SCRIPT_DIR/.assets/multiselect-menu.sh"

# -----------------------------------------------------------------------------
# FUNCTIONS
# -----------------------------------------------------------------------------

# shellcheck disable=SC2034
_main() {
    local categories_defaults=()
    local categories_dirs=()
    local categories_selected=()
    local menu_defaults=()
    local menu_labels=()
    local menu_options=""
    local menu_selected=()

    _check_exist_filemanager

    echo "Scripts installer."
    echo "Select the options (<SPACE> to check):"

    menu_labels=(
        "Install basic dependencies (requires sudo)"
        "Install keyboard shortcuts"
        "Close the file manager to reload its configurations"
        "Choose script categories to install"
        "Preserve previous scripts"
        "Install for all users (requires sudo)"
    )
    menu_defaults=(
        "true"
        "true"
        "true"
        "false"
        "false"
        "false"
    )

    _multiselect_menu menu_selected menu_labels menu_defaults

    [[ ${menu_selected[0]} == "true" ]] && menu_options+="dependencies,"
    [[ ${menu_selected[1]} == "true" ]] && menu_options+="shortcuts,"
    [[ ${menu_selected[2]} == "true" ]] && menu_options+="reload,"
    [[ ${menu_selected[3]} == "true" ]] && menu_options+="categories,"
    [[ ${menu_selected[4]} == "true" ]] && menu_options+="preserve,"
    [[ ${menu_selected[5]} == "true" ]] && menu_options+="allusers,"

    # Get the categories (directories of scripts).
    local dir=""
    while IFS= read -r -d $'\0' dir; do
        categories_dirs+=("$dir")
    done < <(
        find -L "$SCRIPT_DIR" -mindepth 1 -maxdepth 1 -type d \
            "${IGNORE_FIND_PATHS[@]}" \
            -print0 2>/dev/null |
            sed -z "s|^.*/||" |
            sort --zero-terminated --version-sort
    )

    if [[ "$menu_options" == *"categories"* ]]; then
        echo
        echo "Select the categories (<SPACE> to check):"
        _multiselect_menu categories_selected categories_dirs categories_defaults
    fi

    # Install basic dependencies.
    [[ "$menu_options" == *"dependencies"* ]] && _step_install_dependencies

    local install_home_list=""
    if [[ "$menu_options" == *"allusers"* ]]; then
        SUDO_CMD="sudo"

        install_home_list=$(_get_user_homes)
        if [[ -d "/etc/skel" ]]; then
            install_home_list+=$'\n'
            install_home_list+="/etc/skel"
        fi
    else
        install_home_list=$HOME
    fi

    # Install the scripts for each file manager found.
    local file_manager=""
    for file_manager in "${COMPATIBLE_FILE_MANAGERS[@]}"; do
        if ! _command_exists "$file_manager"; then
            continue
        fi

        # Install the scripts for each user.
        for install_home in $install_home_list; do
            INSTALL_HOME=$install_home
            INSTALL_OWNER=$($SUDO_CMD stat -c "%U" "$INSTALL_HOME")
            INSTALL_GROUP=$($SUDO_CMD stat -c "%G" "$INSTALL_HOME")
            if [[ "$menu_options" == *"allusers"* ]]; then
                SUDO_CMD_USER="sudo -u $INSTALL_OWNER -g $INSTALL_GROUP"
            fi

            case "$file_manager" in
            "nautilus")
                INSTALL_DIR="$INSTALL_HOME/.local/share/nautilus/scripts"
                FILE_MANAGER="nautilus"
                ;;
            "caja")
                INSTALL_DIR="$INSTALL_HOME/.config/caja/scripts"
                FILE_MANAGER="caja"
                ;;
            "dolphin")
                INSTALL_DIR="$INSTALL_HOME/.local/share/scripts"
                FILE_MANAGER="dolphin"
                ;;
            "nemo")
                INSTALL_DIR="$INSTALL_HOME/.local/share/nemo/scripts"
                FILE_MANAGER="nemo"
                ;;
            "pcmanfm-qt")
                INSTALL_DIR="$INSTALL_HOME/.local/share/scripts"
                FILE_MANAGER="pcmanfm-qt"
                ;;
            "thunar")
                INSTALL_DIR="$INSTALL_HOME/.local/share/scripts"
                FILE_MANAGER="thunar"
                ;;
            esac

            # Installer steps.
            echo
            echo "Installing the scripts (directory '$install_home', file manager '$file_manager'):"
            _step_install_scripts "$menu_options" categories_selected categories_dirs
            _step_install_menus
            [[ "$menu_options" == *"shortcuts"* ]] && _step_install_shortcuts
        done

        [[ "$menu_options" == *"reload"* ]] && _step_close_filemanager
    done
    echo
    echo "Finished!"
}

_check_exist_filemanager() {
    local file_manager=""
    for file_manager in "${COMPATIBLE_FILE_MANAGERS[@]}"; do
        if _command_exists "$file_manager"; then
            return
        fi
    done
    echo -e "$STR_ERROR Could not find any compatible file managers!"
    exit 1
}

_command_exists() {
    local command_check=$1

    if command -v "$command_check" &>/dev/null; then
        return 0
    fi
    return 1
}

_item_create_backup() {
    local item=$1

    if [[ -e "$item" ]] && [[ ! -e "$item.bak" ]]; then
        $SUDO_CMD mv -- "$item" "$item.bak" 2>/dev/null
    fi
}

_delete_items() {
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
    printf "\nInstalling basic dependencies...\n"

    local packages=""

    # Basic packages to run the script 'common-functions.sh'.
    _command_exists "bash" || packages+="bash "
    _command_exists "basename" || packages+="coreutils "
    _command_exists "find" || packages+="findutils "
    _command_exists "grep" || packages+="grep "
    _command_exists "sed" || packages+="sed "
    _command_exists "awk" || packages+="gawk "
    _command_exists "mktemp" || packages+="util-linux "
    _command_exists "xdg-open" || packages+="xdg-utils "
    _command_exists "file" || packages+="file "

    # Packages for dialogs.
    if ! _command_exists "zenity" && ! _command_exists "kdialog"; then
        packages+="zenity "
    fi

    if _command_exists "guix"; then
        # Package manager 'guix': For Guix systems (no root required).
        if [[ -n "$packages" ]]; then
            guix install $packages
        fi
    elif _command_exists "sudo"; then
        if _command_exists "apt-get"; then
            # Package manager 'apt-get': For Debian/Ubuntu systems.
            _command_exists "pgrep" || packages+="procps "
            _command_exists "pkexec" || packages+="policykit-1 "

            if _command_exists "kdialog"; then
                if ! dpkg -s "qtchooser" &>/dev/null; then
                    packages+="qtchooser "
                fi
                if ! dpkg -s "qdbus-qt5" &>/dev/null; then
                    packages+="qdbus-qt5 "
                fi
            fi
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
            _command_exists "pgrep" || packages+="procps-ng "
            _command_exists "pkexec" || packages+="polkit "

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
            echo -e "$STR_ERROR Could not find a package manager!"
            exit 1
        fi
    else
        echo -e "$STR_ERROR Could not run as administrator!"
        exit 1
    fi

    # Fix permissions in ImageMagick to write PDF files.
    local imagemagick_policy=""
    imagemagick_policy=$(find /etc/ImageMagick-[0-9]*/policy.xml 2>/dev/null)
    if [[ -f "$imagemagick_policy" ]]; then
        echo -e "$STR_INFO Fixing write permission with PDF in ImageMagick..."
        sudo sed -i \
            's/rights="none" pattern="PDF"/rights="read|write" pattern="PDF"/g' \
            "$imagemagick_policy"
        sudo sed -i 's/".GiB"/"8GiB"/g' "$imagemagick_policy"
    fi
}

_step_install_scripts() {
    local menu_options=$1
    local -n _categories_selected=$2
    local -n _categories_dirs=$3
    local tmp_install_dir=""

    # 'Preserve' or 'Remove' previous scripts.
    if [[ "$menu_options" == *"preserve"* ]]; then
        echo -e "$STR_INFO Preserving previous scripts to a temporary directory..."
        tmp_install_dir=$(mktemp -d)
        $SUDO_CMD mv -- "$INSTALL_DIR" "$tmp_install_dir"
    else
        echo -e "$STR_INFO Removing previous scripts..."
        _delete_items "$INSTALL_DIR"
    fi

    echo -e "$STR_INFO Installing new scripts..."
    $SUDO_CMD_USER mkdir --parents "$INSTALL_DIR"

    # Copy the script files.
    $SUDO_CMD cp -- "$SCRIPT_DIR/common-functions.sh" "$INSTALL_DIR"
    local i=0
    for i in "${!_categories_dirs[@]}"; do
        if [[ -v "_categories_selected[i]" ]]; then
            if [[ ${_categories_selected[i]} == "true" ]]; then
                $SUDO_CMD cp -r -- "$SCRIPT_DIR/${_categories_dirs[i]}" "$INSTALL_DIR"
            fi
        else
            $SUDO_CMD cp -r -- "$SCRIPT_DIR/${_categories_dirs[i]}" "$INSTALL_DIR"
        fi
    done

    # Set file permissions.
    echo -e "$STR_INFO Setting file permissions..."
    $SUDO_CMD chown -R "$INSTALL_OWNER:$INSTALL_GROUP" -- "$INSTALL_DIR"
    $SUDO_CMD find -L "$INSTALL_DIR" -type f ! \
        "${IGNORE_FIND_PATHS[@]}" \
        ! -exec chmod -x -- {} \;
    $SUDO_CMD find -L "$INSTALL_DIR" -mindepth 2 -type f \
        "${IGNORE_FIND_PATHS[@]}" \
        -exec chmod +x -- {} \;

    # Restore previous scripts.
    if [[ "$menu_options" == *"preserve"* ]]; then
        echo -e "$STR_INFO Restoring previous scripts to the install directory..."
        $SUDO_CMD mv -- "$tmp_install_dir/scripts" "$INSTALL_DIR/User previous scripts"
    fi
}

_step_install_menus() {
    # Install menus for specific file managers.

    case "$FILE_MANAGER" in
    "dolphin") _step_install_menus_dolphin ;;
    "pcmanfm-qt") _step_install_menus_pcmanfm ;;
    "thunar") _step_install_menus_thunar ;;
    esac
}

_step_install_menus_dolphin() {
    echo -e "$STR_INFO Installing Dolphin actions..."

    local desktop_menus_dir="$INSTALL_HOME/.local/share/kio/servicemenus"
    _delete_items "$desktop_menus_dir"
    $SUDO_CMD_USER mkdir --parents "$desktop_menus_dir"

    local filename=""
    local name_sub=""
    local name=""
    local script_relative=""
    local submenu=""

    # Generate a '.desktop' file for each script.
    $SUDO_CMD find -L "$INSTALL_DIR" -mindepth 2 -type f \
        "${IGNORE_FIND_PATHS[@]}" \
        -print0 2>/dev/null |
        sort --zero-terminated |
        while IFS= read -r -d "" filename; do
            # shellcheck disable=SC2001
            script_relative=$(sed "s|.*scripts/||g" <<<"$filename")
            name_sub=${script_relative#*/}
            # shellcheck disable=SC2001
            name_sub=$(sed "s|/| - |g" <<<"$name_sub")
            name=${script_relative##*/}
            submenu=${script_relative%%/*}

            # Set the mime requirements.
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

            local desktop_filename=""
            desktop_filename="${desktop_menus_dir}/${submenu} - ${name}.desktop"
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
                printf "%s\n" "Name=$name_sub"
                printf "%s\n" "Exec=bash \"$filename\" %F"
            } | $SUDO_CMD tee "$desktop_filename" >/dev/null
            $SUDO_CMD chown "$INSTALL_OWNER:$INSTALL_GROUP" -- "$desktop_filename"
            $SUDO_CMD chmod +x "$desktop_filename"
        done
}

_step_install_menus_pcmanfm() {
    echo -e "$STR_INFO Installing PCManFM-Qt actions..."

    local desktop_menus_dir="$INSTALL_HOME/.local/share/file-manager/actions"
    _delete_items "$desktop_menus_dir"
    $SUDO_CMD_USER mkdir --parents "$desktop_menus_dir"

    # Create the 'Scripts.desktop' menu.
    {
        printf "%s\n" "[Desktop Entry]"
        printf "%s\n" "Type=Menu"
        printf "%s\n" "Name=Scripts"
        printf "%s" "ItemsList="
        $SUDO_CMD find -L "$INSTALL_DIR" -mindepth 1 -maxdepth 1 -type d \
            "${IGNORE_FIND_PATHS[@]}" \
            -printf "%f\n" 2>/dev/null | sort | tr $'\n' ";"
        printf "\n"
    } | $SUDO_CMD tee "${desktop_menus_dir}/Scripts.desktop" >/dev/null
    $SUDO_CMD chown "$INSTALL_OWNER:$INSTALL_GROUP" -- "${desktop_menus_dir}/Scripts.desktop"
    $SUDO_CMD chmod +x "${desktop_menus_dir}/Scripts.desktop"

    # Create a '.desktop' file for each directory (for sub-menus).
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

            } | $SUDO_CMD tee "${desktop_menus_dir}/$name.desktop" >/dev/null
            $SUDO_CMD chown "$INSTALL_OWNER:$INSTALL_GROUP" -- "${desktop_menus_dir}/$name.desktop"
            $SUDO_CMD chmod +x "${desktop_menus_dir}/$name.desktop"
        done

    # Create a '.desktop' file for each script.
    $SUDO_CMD find -L "$INSTALL_DIR" -mindepth 2 -type f \
        "${IGNORE_FIND_PATHS[@]}" \
        -print0 2>/dev/null |
        sort --zero-terminated |
        while IFS= read -r -d "" filename; do
            name=${filename##*/}

            # Set the mime requirements.
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

            local desktop_filename=""
            desktop_filename="${desktop_menus_dir}/${name}.desktop"
            {
                printf "%s\n" "[Desktop Entry]"
                printf "%s\n" "Type=Action"
                printf "%s\n" "Name=$name"
                printf "%s\n" "Profiles=scriptAction"
                printf "\n"
                printf "%s\n" "[X-Action-Profile scriptAction]"
                printf "%s\n" "MimeTypes=$par_select_mime"
                printf "%s\n" "Exec=bash \"$filename\" %F"
            } | $SUDO_CMD tee "$desktop_filename" >/dev/null
            $SUDO_CMD chown "$INSTALL_OWNER:$INSTALL_GROUP" -- "$desktop_filename"
            $SUDO_CMD chmod +x "$desktop_filename"
        done
}

_step_install_menus_thunar() {
    echo -e "$STR_INFO Installing Thunar actions..."

    local menus_file="$INSTALL_HOME/.config/Thunar/uca.xml"

    # Create a backup of older custom actions.
    _item_create_backup "$menus_file"
    _delete_items "$menus_file"

    $SUDO_CMD_USER mkdir --parents "$INSTALL_HOME/.config/Thunar"

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
                submenu=$(dirname -- "$filename" | sed "s|.*scripts/|Scripts/|g")

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

                # Set the type requirements.
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

        printf "%s\n" "<actions>"
    } | $SUDO_CMD tee "$menus_file" >/dev/null
    $SUDO_CMD chown "$INSTALL_OWNER:$INSTALL_GROUP" -- "$menus_file"
}

_step_install_shortcuts() {
    # Install keyboard shortcuts for specific file managers.

    case "$FILE_MANAGER" in
    "nautilus")
        _step_install_shortcuts_nautilus "$INSTALL_HOME/.config/nautilus/scripts-accels"
        ;;
    "caja")
        _step_install_shortcuts_gnome2 "$INSTALL_HOME/.config/caja/accels"
        ;;
    "nemo")
        _step_install_shortcuts_gnome2 "$INSTALL_HOME/.gnome2/accels/nemo"
        ;;
    "thunar")
        _step_install_shortcuts_thunar "$INSTALL_HOME/.config/Thunar/accels.scm"
        ;;
    esac
}

_step_install_shortcuts_nautilus() {
    echo -e "$STR_INFO Installing the keyboard shortcuts for Nautilus..."

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

_step_install_shortcuts_gnome2() {
    echo -e "$STR_INFO Installing the keyboard shortcuts..."

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

_step_install_shortcuts_thunar() {
    echo -e "$STR_INFO Installing the keyboard shortcuts for Thunar..."

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

_step_close_filemanager() {
    echo -e "$STR_INFO Closing the file manager '$FILE_MANAGER' to reload its configurations..."

    case "$FILE_MANAGER" in
    "nautilus" | "caja" | "nemo" | "thunar")
        $FILE_MANAGER -q &>/dev/null &
        ;;
    "pcmanfm-qt")
        # FIXME: Restore desktop after kill PCManFM-Qt.
        killall "$FILE_MANAGER" &>/dev/null &
        ;;
    esac
}

_get_user_homes() {
    getent passwd | grep -v "/nologin\|/false\|/sync" | cut -d: -f6
}

_get_par_value() {
    local filename=$1
    local parameter=$2

    $SUDO_CMD grep --only-matching -m 1 "$parameter=[^\";]*" "$filename" |
        cut -d "=" -f 2 | tr -d "'" | tr "|" ";" 2>/dev/null
}

_main "$@"
