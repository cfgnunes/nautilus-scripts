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
    local dir=""
    cat_dirs_find=$(find -L "$SCRIPT_DIR" -mindepth 1 -maxdepth 1 -type d \
        ! -path "*.git" ! -path "$ASSSETS_DIR" 2>/dev/null | sed "s|^.*/||" | sort --version-sort)

    # Convert the output of 'find' command to an 'array'.
    while IFS= read -d $'\n' -r dir; do
        categories_selected+=("true")
        categories_dirs+=("$dir")
    done <<<"$cat_dirs_find"

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

    local common_names="foremost ghostscript jpegoptim optipng pandoc perl-base qpdf rdfind rhash squashfs-tools testdisk unzip wget xclip"
    if _command_exists "sudo"; then
        if _command_exists "apt-get"; then
            # Distro: Ubuntu, Mint, Debian.
            sudo apt-get update || true
            sudo apt-get -y install $common_names libarchive-tools imagemagick xz-utils poppler-utils ffmpeg findimagedupes genisoimage
        elif _command_exists "dnf"; then
            # Distro: Fedora, Red Hat.
            # Missing packages: findimagedupes.
            sudo dnf check-update || true
            sudo dnf -y install $common_names bsdtar ImageMagick xz poppler-utils ffmpeg-free genisoimage
        elif _command_exists "pacman"; then
            # Distro: Manjaro, Arch Linux.
            # Missing packages: findimagedupes.
            sudo pacman -Syy || true
            sudo pacman --noconfirm -S $common_names imagemagick xz poppler poppler-glib ffmpeg
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
        if [[ "${_categories_selected[i]}" == "true" ]]; then
            cp -r -- "$SCRIPT_DIR/${_categories_dirs[i]}" "$INSTALL_DIR"
        fi
    done

    # Set file permissions.
    printf " > Setting file permissions...\n"
    find "$INSTALL_DIR" -mindepth 2 -type f ! -path "*.git/*" -exec chmod +x {} \;

    # Restore previous scripts.
    if [[ "$menu_options" == *"preserve"* ]]; then
        printf " > Restoring previous scripts to the install directory...\n"
        mv "$tmp_install_dir/scripts" "$INSTALL_DIR/User previous scripts"
    fi
}

_step_install_shortcuts() {
    printf " > Installing the keyboard shortcuts...\n"

    mkdir --parents "$(dirname -- "$ACCELS_FILE")"
    mv "$ACCELS_FILE" "$ACCELS_FILE.bak" 2>/dev/null || true

    case "$FILE_MANAGER" in
    "nautilus")
        cp -- "$ASSSETS_DIR/scripts-accels" "$ACCELS_FILE"
        ;;
    "nemo")
        cp -- "$ASSSETS_DIR/accels-gtk2" "$ACCELS_FILE"
        sed -i "s|USER|$USER|g" "$ACCELS_FILE"
        sed -i "s|ACCELS_PATH|local\\\\\\\\sshare\\\\\\\\snemo|g" "$ACCELS_FILE"
        ;;
    "caja")
        cp -- "$ASSSETS_DIR/accels-gtk2" "$ACCELS_FILE"
        sed -i "s|USER|$USER|g" "$ACCELS_FILE"
        sed -i "s|ACCELS_PATH|config\\\\\\\\scaja|g" "$ACCELS_FILE"
        ;;
    esac
}

_step_close_filemanager() {
    printf " > Closing the file manager to reload its configurations...\n"

    eval "$FILE_MANAGER -q &>/dev/null" || true
}

_main "$@"
