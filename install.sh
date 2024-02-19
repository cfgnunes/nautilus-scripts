#!/usr/bin/env bash

# Install the scripts for the GNOME Files (Nautilus), Caja and Nemo file managers.

set -eu

# Global variables
ACCELS_DIR=""
FILE_MANAGER=""
INSTALL_DIR=""

_main() {
    local menu_options=""
    local opt=""

    # Get the default file manager.
    if _command_exists "nautilus"; then
        INSTALL_DIR="$HOME/.local/share/nautilus/scripts"
        ACCELS_DIR="$HOME/.config/nautilus"
        FILE_MANAGER="nautilus"
    elif _command_exists "nemo"; then
        INSTALL_DIR="$HOME/.local/share/nemo/scripts"
        FILE_MANAGER="nemo"
    elif _command_exists "caja"; then
        INSTALL_DIR="$HOME/.config/caja/scripts"
        FILE_MANAGER="caja"
    else
        echo "Error: could not find any compatible file managers!"
        exit 1
    fi

    # Show the main options
    read -r -p "Install basic package dependencies? (Y/n) " opt && [[ "${opt,,}" == *"n"* ]] || menu_options+="dependencies,"
    if [[ -n "$ACCELS_DIR" ]]; then
        read -r -p "Install the file 'scripts-accels'? (Y/n) " opt && [[ "${opt,,}" == *"n"* ]] || menu_options+="accels,"
    fi
    if [[ -n "$(ls -A "$INSTALL_DIR" 2>/dev/null)" ]]; then
        read -r -p "Preserve the previous scripts? (Y/n) " opt && [[ "${opt,,}" == *"n"* ]] || menu_options+="preserve,"
    fi
    read -r -p "Close the file manager to reload its configurations? (Y/n) " opt && [[ "${opt,,}" == *"n"* ]] || menu_options+="reload,"

    echo
    echo "Starting the installation..."

    # Install basic package dependencies.
    if [[ "$menu_options" == *"dependencies"* ]]; then
        _install_dependencies
    fi

    # Install the scripts.
    _install_scripts "$menu_options"

    echo "Done!"
}

_command_exists() {
    local command_check=$1

    if command -v "$command_check" &>/dev/null; then
        return 0
    fi
    return 1
}

# shellcheck disable=SC2086
_install_dependencies() {
    local common_names="bzip2 foremost ghostscript gzip jpegoptim lame lhasa lzip lzop optipng pandoc perl-base qpdf rhash squashfs-tools tar testdisk wget xclip xorriso zip zstd"

    echo " > Installing dependencies..."

    if _command_exists "sudo"; then
        if _command_exists "apt-get"; then
            sudo apt-get update || true
            # Distro: Ubuntu, Mint, Debian.
            sudo apt-get -y install $common_names gpg imagemagick xz-utils p7zip-full poppler-utils ffmpeg jdupes findimagedupes genisoimage ocrmypdf mp3gain
        elif _command_exists "pacman"; then
            # Distro: Manjaro, Arch Linux.
            # Missing packages: jdupes, findimagedupes, ocrmypdf, mp3gain.
            sudo pacman -Syy || true
            sudo pacman --noconfirm -S $common_names gnupg imagemagick xz p7zip poppler poppler-glib ffmpeg
        elif _command_exists "dnf"; then
            # Distro: Fedora, Red Hat.
            # Missing packages: findimagedupes.
            sudo dnf check-update || true
            sudo dnf -y install $common_names gnupg2 ImageMagick xz p7zip poppler-utils ffmpeg-free jdupes genisoimage ocrmypdf mp3gain
        else
            echo "Error: could not find a package manager!"
            exit 1
        fi
    else
        echo "Error: could not run as administrator!"
        exit 1
    fi
}

_install_scripts() {
    local menu_options=$1
    local tmp_install_dir=""

    # 'Preserve' or 'Remove' previous scripts.
    if [[ "$menu_options" == *"preserve"* ]]; then
        echo " > Preserving previous scripts to a temporary directory..."
        tmp_install_dir=$(mktemp -d)
        mv "$INSTALL_DIR" "$tmp_install_dir" || true
    else
        echo " > Removing previous scripts..."
        rm -rf -- "$INSTALL_DIR"
    fi

    # Install the scripts.
    echo " > Installing new scripts..."
    mkdir --parents "$INSTALL_DIR"
    cp -r . "$INSTALL_DIR"

    # Install the file 'scripts-accels'.
    if [[ "$menu_options" == *"accels"* ]]; then
        if [[ -n "$ACCELS_DIR" ]]; then
            echo " > Installing the file 'scripts-accels'..."
            rm -f -- "$ACCELS_DIR/scripts-accels"
            mkdir --parents "$ACCELS_DIR"
            cp "scripts-accels" "$ACCELS_DIR/scripts-accels"
        fi
    fi

    # Set file permissions.
    echo " > Setting file permissions..."
    find "$INSTALL_DIR" -mindepth 2 -type f ! -path "*.git/*" -exec chmod +x {} \;

    # Restore previous scripts.
    if [[ "$menu_options" == *"preserve"* ]]; then
        echo " > Restoring previous scripts to the install directory..."
        mv "$tmp_install_dir/scripts" "$INSTALL_DIR/User previous scripts"
    fi

    # Close the file manager to reload its configurations.
    if [[ "$menu_options" == *"reload"* ]]; then
        echo " > Closing the file manager to reload its configurations..."
        eval "$FILE_MANAGER -q &>/dev/null" || true
    fi
}

_main "$@"
