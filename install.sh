#!/usr/bin/env bash

# Install the scripts for the GNOME Files (Nautilus), Caja and Nemo file managers.

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
    local menu_options=""
    local menu_defaults=()
    local menu_labels=()
    local menu_selected=()

    _check_default_filemanager

    printf "Scripts installer.\n\n"
    printf "Select the options (<SPACE> to select, <UP/DOWN> to choose):\n"

    menu_labels=(
        "Install basic dependencies."
        "Install keyboard shortcuts."
        "Close the file manager to reload its configurations."
        "Preserve previous scripts (if any)."
        "Choose script categories to install."
    )
    menu_defaults=(
        "true"
        "true"
        "true"
        "false"
        "false"
    )

    _multiselect_menu menu_selected menu_labels menu_defaults

    [[ ${menu_selected[0]} == "true" ]] && menu_options+="dependencies,"
    [[ ${menu_selected[1]} == "true" ]] && menu_options+="shortcuts,"
    [[ ${menu_selected[2]} == "true" ]] && menu_options+="reload,"
    [[ ${menu_selected[3]} == "true" ]] && [[ -n "$(ls -A "$INSTALL_DIR" 2>/dev/null)" ]] && menu_options+="preserve,"
    [[ ${menu_selected[4]} == "true" ]] && menu_options+="categories,"

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

    printf "\nStarting the installation...\n"

    # Installer steps.
    [[ "$menu_options" == *"dependencies"* ]] && _step_install_dependencies
    [[ "$menu_options" == *"shortcuts"* ]] && _step_install_shortcuts
    _step_install_scripts "$menu_options" categories_selected categories_dirs
    [[ "$menu_options" == *"reload"* ]] && _step_close_filemanager

    printf "Finished!\n"
}

_check_default_filemanager() {
    # Get the default file manager.
    if _command_exists "nautilus"; then
        INSTALL_DIR="$HOME/.local/share/nautilus/scripts"
        ACCELS_FILE="$HOME/.config/nautilus/scripts-accels"
        FILE_MANAGER="nautilus"
    elif _command_exists "nemo"; then
        INSTALL_DIR="$HOME/.local/share/nemo/scripts"
        ACCELS_FILE="$HOME/.gnome2/accels/nemo"
        FILE_MANAGER="nemo"
    elif _command_exists "caja"; then
        INSTALL_DIR="$HOME/.config/caja/scripts"
        ACCELS_FILE="$HOME/.config/caja/accels"
        FILE_MANAGER="caja"
    elif _command_exists "thunar"; then
        ACCELS_FILE="$HOME/.config/Thunar/accels.scm"
        FILE_MANAGER="thunar"
        INSTALL_DIR="$HOME/.local/scripts"
    else
        printf "Error: could not find any compatible file managers!\n"
        exit 1
    fi
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
    common_names+="perl-base rdfind rhash wget xclip "

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

    # Install the menus for the 'Thunar' file manager.
    if [[ "$FILE_MANAGER" == "thunar" ]]; then
        printf " > Installing Thunar custom actions...\n"
        _step_make_thunar_custom_actions
    fi
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
    "nemo")
        cp -- "$ASSSETS_DIR/accels-mint.scm" "$ACCELS_FILE"
        sed -i "s|SED_USER|$USER|g" "$ACCELS_FILE"
        sed -i "s|SED_ACCELS_PATH|local\\\\\\\\sshare\\\\\\\\snemo|g" "$ACCELS_FILE"
        ;;
    "caja")
        cp -- "$ASSSETS_DIR/accels-mint.scm" "$ACCELS_FILE"
        sed -i "s|SED_USER|$USER|g" "$ACCELS_FILE"
        sed -i "s|SED_ACCELS_PATH|config\\\\\\\\scaja|g" "$ACCELS_FILE"
        ;;
    "thunar")
        cp -- "$ASSSETS_DIR/accels-thunar.scm" "$ACCELS_FILE"
        sed -i "s|SED_USER|$USER|g" "$ACCELS_FILE"
        sed -i "s|SED_ACCELS_PATH|config\\\\\\\\scaja|g" "$ACCELS_FILE"
        ;;
    esac
}

_step_close_filemanager() {
    printf " > Closing the file manager to reload its configurations...\n"

    eval "$FILE_MANAGER -q &>/dev/null" || true
}

_step_make_thunar_custom_actions() {
    local menus_file="$HOME/.config/Thunar/uca.xml"

    # Create a backup of older custom actions.
    if [[ -f "$menus_file" ]] && ! [[ -f "$menus_file.bak" ]]; then
        mv "$menus_file" "$menus_file.bak" 2>/dev/null || true
    fi

    {
        printf "%s\n" "<?xml version="1.0" encoding="UTF-8"?>"
        printf "%s\n" "<actions>"
        printf "%s\n" "<action>"
        printf "%s\n" "    <icon>utilities-terminal</icon>"
        printf "%s\n" "    <name>Open Terminal Here</name>"
        printf "%s\n" "    <submenu></submenu>"
        printf "%s\n" "    <unique-id>1-1</unique-id>"
        printf "%s\n" "    <command>exo-open --working-directory %f --launch TerminalEmulator</command>"
        printf "%s\n" "    <description>Open terminal in containing directory</description>"
        printf "%s\n" "    <range></range>"
        printf "%s\n" "    <patterns>*</patterns>"
        printf "%s\n" "    <startup-notify/>"
        printf "%s\n" "    <directories/>"
        printf "%s\n" "</action>"
        printf "%s\n" "<action>"
        printf "%s\n" "    <icon>edit-find</icon>"
        printf "%s\n" "    <name>Find in this folder</name>"
        printf "%s\n" "    <submenu></submenu>"
        printf "%s\n" "    <unique-id>3-3</unique-id>"
        printf "%s\n" "    <command>catfish --path=%f</command>"
        printf "%s\n" "    <description>Search for files within this folder</description>"
        printf "%s\n" "    <range></range>"
        printf "%s\n" "    <patterns>*</patterns>"
        printf "%s\n" "    <directories/>"
        printf "%s\n" "</action>"
        printf "%s\n" "<action>"
        printf "%s\n" "    <icon>document-print</icon>"
        printf "%s\n" "    <name>Print file(s)</name>"
        printf "%s\n" "    <submenu></submenu>"
        printf "%s\n" "    <unique-id>4-4</unique-id>"
        printf "%s\n" "    <command>thunar-print %F</command>"
        printf "%s\n" "    <description>Send one or multiple files to the default printer</description>"
        printf "%s\n" "    <range></range>"
        printf "%s\n" "    <patterns>*.asc;*.brf;*.css;*.doc;*.docm;*.docx;*.dotm;*.dotx;*.fodg;*.fodp;*.fods;*.fodt;*.gif;*.htm;*.html;*.jpe;*.jpeg;*.jpg;*.odb;*.odf;*.odg;*.odm;*.odp;*.ods;*.odt;*.otg;*.oth;*.otp;*.ots;*.ott;*.pbm;*.pdf;*.pgm;*.png;*.pnm;*.pot;*.potm;*.potx;*.ppm;*.ppt;*.pptm;*.pptx;*.rtf;*.shtml;*.srt;*.text;*.tif;*.tiff;*.txt;*.xbm;*.xls;*.xlsb;*.xlsm;*.xlsx;*.xltm;*.xltx;*.xpm;*.xwd</patterns>"
        printf "%s\n" "    <image-files/>"
        printf "%s\n" "    <other-files/>"
        printf "%s\n" "    <text-files/>"
        printf "%s\n" "</action>"

        local filename=""
        local name=""
        local submenu=""
        local unique_id=""
        find "$INSTALL_DIR" -mindepth 2 -type f ! -path "*.git/*" ! -path "*.assets/*" -print0 2>/dev/null | sort --zero-terminated |
            while IFS= read -r -d "" filename; do
                name=$(basename -- "$filename" 2>/dev/null)
                submenu=$(dirname -- "$filename" 2>/dev/null | sed "s|.*scripts/|Scripts/|g")
                unique_id=$(md5sum <<<"$name" 2>/dev/null | tr -d "a-z- ")
                printf "%s\n" "<action>"
                printf "%s\n" "    <icon></icon>"
                printf "%s\n" "    <name>$name</name>"
                printf "%s\n" "    <submenu>$submenu</submenu>"
                printf "%s\n" "    <unique-id>$unique_id-1</unique-id>"
                printf "%s\n" "    <command>bash &quot;$filename&quot; %F</command>"
                printf "%s\n" "    <description></description>"
                printf "%s\n" "    <patterns>*</patterns>"
                printf "%s\n" "    <directories/>"
                printf "%s\n" "    <audio-files/>"
                printf "%s\n" "    <image-files/>"
                printf "%s\n" "    <other-files/>"
                printf "%s\n" "    <text-files/>"
                printf "%s\n" "    <video-files/>"
                printf "%s\n" "</action>"
            done

        printf "%s\n" "<actions>"
    } >"$menus_file"
}

_main "$@"
