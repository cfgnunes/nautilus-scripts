#!/usr/bin/env bash

# Install the scripts for file managers.

set -eu

# -----------------------------------------------------------------------------
# CONSTANTS
# -----------------------------------------------------------------------------

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
ASSSETS_DIR="$SCRIPT_DIR/.assets"

readonly SCRIPT_DIR ASSSETS_DIR

# -----------------------------------------------------------------------------
# GLOBAL VARIABLES
# -----------------------------------------------------------------------------

ACCELS_FILE=""
COMPATIBLE_FILE_MANAGERS=("nautilus" "caja" "dolphin" "nemo" "pcmanfm-qt" "thunar")
FILE_MANAGER=""
INSTALL_DIR=""

# shellcheck disable=SC1091
source "$ASSSETS_DIR/_multiselect_menu.sh"

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

    printf "Scripts installer.\n\n"
    printf "Select the options (<SPACE> to select, <UP/DOWN> to choose):\n"

    menu_labels=(
        "Install basic dependencies."
        "Install keyboard shortcuts."
        "Close the file manager to reload its configurations."
        "Choose script categories to install."
    )
    menu_defaults=(
        "true"
        "true"
        "true"
        "false"
    )

    if [[ "$FILE_MANAGER" != "dolphin" ]] && [[ "$FILE_MANAGER" != "thunar" ]] && [[ -n "$(ls -A "$INSTALL_DIR" 2>/dev/null)" ]]; then
        menu_labels+=("Preserve previous scripts.")
        menu_defaults+=("false")
    fi

    _multiselect_menu menu_selected menu_labels menu_defaults

    [[ ${menu_selected[0]} == "true" ]] && menu_options+="dependencies,"
    [[ ${menu_selected[1]} == "true" ]] && menu_options+="shortcuts,"
    [[ ${menu_selected[2]} == "true" ]] && menu_options+="reload,"
    [[ ${menu_selected[3]} == "true" ]] && menu_options+="categories,"
    if [[ "$FILE_MANAGER" != "dolphin" ]] && [[ "$FILE_MANAGER" != "thunar" ]] && [[ -n "$(ls -A "$INSTALL_DIR" 2>/dev/null)" ]]; then
        [[ ${menu_selected[4]} == "true" ]] && menu_options+="preserve,"
    fi

    # Get the categories (directories of scripts).
    local cat_dirs_find=""
    cat_dirs_find=$(find -L "$SCRIPT_DIR" -mindepth 1 -maxdepth 1 -type d \
        ! -path "*.git" ! -path "$ASSSETS_DIR" 2>/dev/null | sed "s|^.*/||" | sort --version-sort)

    # Convert the output of the 'find' command to an 'array'.
    cat_dirs_find=$(tr "\n" "\r" <<<"$cat_dirs_find")
    IFS=$'\r' read -r -a categories_dirs <<<"$cat_dirs_find"

    if [[ "$menu_options" == *"categories"* ]]; then
        printf "\nChoose the categories (<SPACE> to select, <UP/DOWN> to choose):\n"
        _multiselect_menu categories_selected categories_dirs categories_defaults
    fi

    # Install for every file manager installed.
    local file_manager=""
    for file_manager in "${COMPATIBLE_FILE_MANAGERS[@]}"; do
        if ! _command_exists "$file_manager"; then
            continue
        fi

        printf "\nStarting the scripts for file manager: %s...\n" "$file_manager"

        case "$file_manager" in
        "nautilus")
            INSTALL_DIR="$HOME/.local/share/nautilus/scripts"
            ACCELS_FILE="$HOME/.config/nautilus/scripts-accels"
            FILE_MANAGER="nautilus"
            ;;
        "caja")
            INSTALL_DIR="$HOME/.config/caja/scripts"
            ACCELS_FILE="$HOME/.config/caja/accels"
            FILE_MANAGER="caja"
            ;;
        "dolphin")
            INSTALL_DIR="$HOME/.local/share/scripts"
            ACCELS_FILE=""
            FILE_MANAGER="dolphin"
            ;;
        "nemo")
            INSTALL_DIR="$HOME/.local/share/nemo/scripts"
            ACCELS_FILE="$HOME/.gnome2/accels/nemo"
            FILE_MANAGER="nemo"
            ;;
        "pcmanfm-qt")
            INSTALL_DIR="$HOME/.local/share/scripts"
            ACCELS_FILE=""
            FILE_MANAGER="pcmanfm-qt"
            ;;
        "thunar")
            INSTALL_DIR="$HOME/.local/share/scripts"
            ACCELS_FILE="$HOME/.config/Thunar/accels.scm"
            FILE_MANAGER="thunar"
            ;;
        esac

        # Installer steps.
        [[ "$menu_options" == *"dependencies"* ]] && _step_install_dependencies
        [[ "$menu_options" == *"shortcuts"* ]] && _step_install_shortcuts
        _step_install_scripts "$menu_options" categories_selected categories_dirs
        [[ "$menu_options" == *"reload"* ]] && _step_close_filemanager
    done

    printf "Finished!\n"
}

_check_exist_filemanager() {
    local file_manager=""
    for file_manager in "${COMPATIBLE_FILE_MANAGERS[@]}"; do
        if _command_exists "$file_manager"; then
            return
        fi
    done
    printf "Error: could not find any compatible file managers!\n"
    exit 1
}

_command_exists() {
    local command_check=$1

    if command -v "$command_check" &>/dev/null; then
        return 0
    fi
    return 1
}

# shellcheck disable=SC2086
_step_install_dependencies() {
    printf " > Installing dependencies...\n"

    local common_names=""

    # Packages for dialogs...
    case "${XDG_CURRENT_DESKTOP,,}" in
    *"kde"* | *"lxqt"*) common_names+="kdialog " ;;
    *) common_names+="zenity " ;;
    esac

    # Packages session type...
    case "${XDG_SESSION_TYPE,,}" in
    "wayland") ommon_names+="wl-clipboard " ;;
    *) common_names+="xclip " ;;
    esac

    # Packages for compress/decompress archives...
    common_names+="bzip2 gzip squashfs-tools tar unzip zip "
    # Packages for documents...
    common_names+="pandoc "
    # Packages for images...
    common_names+="jpegoptim optipng "
    # Packages for PDF...
    common_names+="ghostscript qpdf "
    # Packages for forensic...
    common_names+="foremost testdisk "
    # Packages for other scripts...
    common_names+="perl-base rdfind rhash wget "

    if _command_exists "sudo"; then
        if _command_exists "apt-get"; then
            # Distro: Ubuntu, Mint, Debian.
            sudo apt-get update || true
            sudo apt-get -y install $common_names p7zip-full imagemagick xz-utils poppler-utils ffmpeg genisoimage
        elif _command_exists "dnf"; then
            # Distro: Fedora, Red Hat.
            sudo dnf check-update || true
            sudo dnf -y install $common_names p7zip ImageMagick xz poppler-utils ffmpeg-free genisoimage
        elif _command_exists "pacman"; then
            # Distro: Manjaro, Arch Linux.
            sudo pacman -Syy || true
            sudo pacman --noconfirm -S $common_names p7zip imagemagick xz poppler poppler-glib ffmpeg
        else
            printf "Error: could not find a package manager!\n"
            exit 1
        fi
    else
        printf "Error: could not run as administrator!\n"
        exit 1
    fi

    # Fix permissions in ImageMagick to write PDF files.
    local imagemagick_config="/etc/ImageMagick-6/policy.xml"
    if [[ -f "$imagemagick_config" ]]; then
        printf " > Fixing write permission with PDF in ImageMagick...\n"
        sudo sed -i 's/rights="none" pattern="PDF"/rights="read|write" pattern="PDF"/' "$imagemagick_config"
        sudo sed -i 's/1GiB/8GiB/' "$imagemagick_config"
        sudo sed -i '/shared-secret/d' "$imagemagick_config"
    fi
}

_step_install_scripts() {
    local menu_options=$1
    local -n _categories_selected=$2
    local -n _categories_dirs=$3
    local tmp_install_dir=""

    # 'Preserve' or 'Remove' previous scripts.
    if [[ "$menu_options" == *"preserve"* ]]; then
        printf " > Preserving previous scripts to a temporary directory...\n"
        tmp_install_dir=$(mktemp -d)
        mv "$INSTALL_DIR" "$tmp_install_dir" || true
    else
        printf " > Removing previous scripts...\n"
        rm -rf -- "$INSTALL_DIR"
    fi

    printf " > Installing new scripts...\n"
    mkdir --parents "$INSTALL_DIR"

    # Copy the script files.
    cp -- "$SCRIPT_DIR/common-functions.sh" "$INSTALL_DIR"
    local i=0
    for i in "${!_categories_dirs[@]}"; do
        if [[ -v "_categories_selected[i]" ]]; then
            if [[ ${_categories_selected[i]} == "true" ]]; then
                cp -r -- "$SCRIPT_DIR/${_categories_dirs[i]}" "$INSTALL_DIR"
            fi
        else
            cp -r -- "$SCRIPT_DIR/${_categories_dirs[i]}" "$INSTALL_DIR"
        fi
    done

    # Set file permissions.
    printf " > Setting file permissions...\n"
    find "$INSTALL_DIR" -mindepth 2 -type f ! -path "*.git/*" -exec chmod +x -- {} \;

    # Restore previous scripts.
    if [[ "$menu_options" == *"preserve"* ]]; then
        printf " > Restoring previous scripts to the install directory...\n"
        mv "$tmp_install_dir/scripts" "$INSTALL_DIR/User previous scripts"
    fi

    # Install menus for specific file managers.
    case "$FILE_MANAGER" in
    "dolphin")
        printf " > Installing Dolphin actions...\n"
        _step_make_dolphin_actions
        ;;
    "pcmanfm-qt")
        printf " > Installing PCManFM-Qt actions...\n"
        _step_make_pcmanfm_actions
        ;;
    "thunar")
        printf " > Installing Thunar actions...\n"
        _step_make_thunar_actions
        ;;
    esac
}

_step_install_shortcuts() {
    printf " > Installing the keyboard shortcuts...\n"

    mkdir --parents "$(dirname -- "$ACCELS_FILE")"

    # Create a backup of older shortcuts.
    if [[ -f "$ACCELS_FILE" ]] && ! [[ -f "$ACCELS_FILE.bak" ]]; then
        mv "$ACCELS_FILE" "$ACCELS_FILE.bak" 2>/dev/null || true
    fi

    case "$FILE_MANAGER" in
    "nautilus")
        cp -- "$ASSSETS_DIR/accels-gnome.scm" "$ACCELS_FILE"
        ;;
    "caja")
        cp -- "$ASSSETS_DIR/accels-mint.scm" "$ACCELS_FILE"
        sed -i "s|SED_USER|$USER|g" "$ACCELS_FILE"
        sed -i "s|SED_ACCELS_PATH|config\\\\\\\\scaja|g" "$ACCELS_FILE"
        ;;
    "nemo")
        cp -- "$ASSSETS_DIR/accels-mint.scm" "$ACCELS_FILE"
        sed -i "s|SED_USER|$USER|g" "$ACCELS_FILE"
        sed -i "s|SED_ACCELS_PATH|local\\\\\\\\sshare\\\\\\\\snemo|g" "$ACCELS_FILE"
        ;;
    "thunar")
        cp -- "$ASSSETS_DIR/accels-thunar.scm" "$ACCELS_FILE"
        sed -i "s|SED_USER|$USER|g" "$ACCELS_FILE"
        ;;
    esac
}

_step_close_filemanager() {
    printf " > Closing the file manager to reload its configurations...\n"

    case "$FILE_MANAGER" in
    "nautilus" | "caja" | "nemo" | "thunar") $FILE_MANAGER -q &>/dev/null || true & ;;
    "pcmanfm-qt") killall "$FILE_MANAGER" &>/dev/null || true & ;;
    esac
}

_step_make_dolphin_actions() {
    local desktop_menus_dir="$HOME/.local/share/kio/servicemenus"

    rm -rf "$desktop_menus_dir" 2>/dev/null || true
    mkdir --parents "$desktop_menus_dir"

    local filename=""
    local name_sub=""
    local name=""
    local script_relative=""
    local submenu=""

    # Generate a '.desktop' file for each script.
    find "$INSTALL_DIR" -mindepth 2 -type f ! -path "*.git/*" ! -path "*.assets/*" -print0 2>/dev/null | sort --zero-terminated |
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
            par_recursive=$(_get_script_parameter_value "$filename" "par_recursive")
            par_select_mime=$(_get_script_parameter_value "$filename" "par_select_mime")

            if [[ -z "$par_select_mime" ]]; then
                local par_type=""
                par_type=$(_get_script_parameter_value "$filename" "par_type")

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
            local par_min_files=""
            local par_max_files=""
            par_min_files=$(_get_script_parameter_value "$filename" "par_min_files")
            par_max_files=$(_get_script_parameter_value "$filename" "par_max_files")

            local desktop_filename=""
            desktop_filename="${desktop_menus_dir}/${submenu} - ${name}.desktop"
            {
                printf "%s\n" "[Desktop Entry]"
                printf "%s\n" "Type=Service"
                printf "%s\n" "X-KDE-ServiceTypes=KonqPopupMenu/Plugin"
                printf "%s\n" "Actions=scriptAction;"
                printf "%s\n" "MimeType=$par_select_mime"

                if [[ -n "$par_min_files" ]]; then
                    printf "%s\n" "X-KDE-MinNumberOfUrls=$par_min_files"
                fi

                if [[ -n "$par_max_files" ]]; then
                    printf "%s\n" "X-KDE-MaxNumberOfUrls=$par_max_files"
                fi

                printf "%s\n" "Encoding=UTF-8"
                printf "%s\n" "X-KDE-Submenu=$submenu"
                printf "\n"
                printf "%s\n" "[Desktop Action scriptAction]"
                printf "%s\n" "Name=$name_sub"
                printf "%s\n" "Exec=bash \"$filename\" %F"
            } >"$desktop_filename"
            chmod +x "$desktop_filename"
        done
}

_step_make_pcmanfm_actions() {
    local desktop_menus_dir="$HOME/.local/share/file-manager/actions"

    rm -rf "$desktop_menus_dir" 2>/dev/null || true
    mkdir --parents "$desktop_menus_dir"

    local filename=""
    local name=""
    local script_relative=""
    local submenu=""

    # Generate a '.desktop' file for each script.
    find "$INSTALL_DIR" -mindepth 2 -type f ! -path "*.git/*" ! -path "*.assets/*" -print0 2>/dev/null | sort --zero-terminated |
        while IFS= read -r -d "" filename; do
            # shellcheck disable=SC2001
            script_relative=$(sed "s|.*scripts/||g" <<<"$filename")
            name=${script_relative##*/}
            submenu=${script_relative%%/*}

            # Set the mime requirements.
            local par_recursive=""
            local par_select_mime=""
            par_recursive=$(_get_script_parameter_value "$filename" "par_recursive")
            par_select_mime=$(_get_script_parameter_value "$filename" "par_select_mime")

            if [[ -z "$par_select_mime" ]]; then
                local par_type=""
                par_type=$(_get_script_parameter_value "$filename" "par_type")

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
            local par_min_files=""
            local par_max_files=""
            par_min_files=$(_get_script_parameter_value "$filename" "par_min_files")
            par_max_files=$(_get_script_parameter_value "$filename" "par_max_files")

            local desktop_filename=""
            desktop_filename="${desktop_menus_dir}/${submenu} - ${name}.desktop"
            {
                printf "%s\n" "[Desktop Entry]"
                printf "%s\n" "Type=Action"
                printf "%s\n" "Name=$submenu - $name"
                printf "%s\n" "Profiles=scriptAction"
                printf "\n"
                printf "%s\n" "[X-Action-Profile scriptAction]"
                printf "%s\n" "MimeTypes=$par_select_mime"
                printf "%s\n" "Exec=bash \"$filename\" %F"
            } >"$desktop_filename"
            chmod +x "$desktop_filename"
        done
}

_step_make_thunar_actions() {
    local menus_file="$HOME/.config/Thunar/uca.xml"

    # Create a backup of older custom actions.
    if [[ -f "$menus_file" ]] && ! [[ -f "$menus_file.bak" ]]; then
        mv "$menus_file" "$menus_file.bak" 2>/dev/null || true
    fi

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
        find "$INSTALL_DIR" -mindepth 2 -type f ! -path "*.git/*" ! -path "*.assets/*" -print0 2>/dev/null | sort --zero-terminated |
            while IFS= read -r -d "" filename; do
                name=$(basename -- "$filename" 2>/dev/null)
                submenu=$(dirname -- "$filename" 2>/dev/null | sed "s|.*scripts/|Scripts/|g")

                printf "%s\n" "<action>"
                printf "\t%s\n" "<icon></icon>"
                printf "\t%s\n" "<name>$name</name>"
                printf "\t%s\n" "<submenu>$submenu</submenu>"

                # Generate a unique id.
                unique_id=$(md5sum <<<"$submenu$name" 2>/dev/null | sed "s|[^0-9]*||g" | cut -c 1-8)
                printf "\t%s\n" "<unique-id>$unique_id</unique-id>"

                printf "\t%s\n" "<command>bash &quot;$filename&quot; %F</command>"
                printf "\t%s\n" "<description></description>"

                # Set the min/max files requirements.
                local par_min_files=""
                local par_max_files=""
                par_min_files=$(_get_script_parameter_value "$filename" "par_min_files")
                par_max_files=$(_get_script_parameter_value "$filename" "par_max_files")
                if [[ -n "$par_min_files" ]] && [[ -n "$par_max_files" ]]; then
                    printf "\t%s\n" "<range>$par_min_files-$par_max_files</range>"
                else
                    printf "\t%s\n" "<range></range>"
                fi

                printf "\t%s\n" "<patterns>*</patterns>"

                # Set the type requirements.
                local par_recursive=""
                local par_type=""
                par_recursive=$(_get_script_parameter_value "$filename" "par_recursive")
                par_type=$(_get_script_parameter_value "$filename" "par_type")
                if [[ "$par_type" == "all" ]] || [[ "$par_type" == "directory" ]] || [[ "$par_recursive" == "true" ]]; then
                    printf "\t%s\n" "<directories/>"
                fi

                # Set the type requirements.
                local par_select_mime=""
                par_select_mime=$(_get_script_parameter_value "$filename" "par_select_mime")

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
    } >"$menus_file"
}

_get_script_parameter_value() {
    local filename=$1
    local parameter=$2

    grep --only-matching -m 1 "$parameter=[^\";]*" "$filename" | cut -d "=" -f 2 | tr -d "'" | tr "|" ";" 2>/dev/null
}

_main "$@"
