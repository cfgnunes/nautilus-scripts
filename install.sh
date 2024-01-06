#!/usr/bin/env bash

# Install the scripts for the GNOME Files (Nautilus), Caja and Nemo file managers.

# shellcheck disable=SC2086

set -eu

_command_exists() {
    local command_check="$1"

    if command -v "$command_check" &>/dev/null; then
        return 0
    fi
    return 1
}

_main() {
    echo "Installing the scripts..."
    local install_dir=""
    local accels_dir=""
    local file_manager=""

    if _command_exists "nautilus"; then
        install_dir="$HOME/.local/share/nautilus/scripts"
        accels_dir="$HOME/.config/nautilus"
        file_manager="nautilus"
    elif _command_exists "nemo"; then
        install_dir="$HOME/.local/share/nemo/scripts"
        file_manager="nemo"
    elif _command_exists "caja"; then
        install_dir="$HOME/.config/caja/scripts"
        file_manager="caja"
    else
        echo "Error: not found any compatible file managers!"
        exit 1
    fi

    echo " > Moving previous files to a temporary directory..."
    local tmp_install_dir="$(mktemp -d)"
    mv "$install_dir"/* "$tmp_install_dir" || true

    echo " > Removing previous files..."
    rm -rf "$install_dir"
    rm -f "$accels_dir/scripts-accels"

    echo " > Installing new scripts..."
    mkdir --parents "$install_dir"
    cp -r ./* "$install_dir/"

    echo " > Restoring previous files to the new directory..."
    mv "$tmp_install_dir" "$install_dir/User defined scripts"

    if [[ -n "$accels_dir" ]]; then
        echo " > Installing 'scripts-accels'..."
        mkdir --parents "$accels_dir"
        cp "scripts-accels" "$accels_dir/scripts-accels"
    fi

    echo " > Setting file permissions..."
    find "$install_dir" -mindepth 2 -type f ! -path "*.git/*" -exec chmod +x {} \;

    read -r -p " > Would you like to install some basic dependencies for the scripts now? [Y/n]" answer
    case "${answer,,}" in
    y | yes | "")
        echo " > Installing dependencies..."
        _install_dependencies
        ;;
    *)
        echo " > Skipping installation of dependencies..."
        ;;
    esac

    echo " > Closing the file manager to reload its configurations..."
    eval "$file_manager -q &>/dev/null" || true

    echo "Done!"
}

_install_dependencies() {
    local common_names="bzip2 foremost ghostscript gzip jpegoptim lame lzip lzop optipng pandoc perl-base qpdf rhash squashfs-tools tar testdisk unrar wget xclip zip zstd"

    if _command_exists "sudo"; then
        if _command_exists "apt-get"; then
            sudo apt-get update || true
            # Distro: Debian, Ubuntu, Linux Mint.
            sudo apt-get -y install $common_names gpg imagemagick xz-utils p7zip-full poppler-utils jdupes
        elif _command_exists "pacman"; then
            # Distro: Arch Linux, Manjaro.
            # Missing packages: jdupes
            sudo pacman -Syy || true
            sudo pacman --noconfirm -S $common_names gnupg imagemagick xz p7zip poppler poppler-glib
        elif _command_exists "dnf"; then
            # Distro: Fedora, CentOS, Red Hat.
            sudo dnf check-update || true
            sudo dnf -y install $common_names gnupg ImageMagick xz p7zip poppler poppler-glib jdupes
        else
            echo "Error: could not find a package manager!"
            exit 1
        fi
    else
        echo "Error: could not run the installer as administrator!"
        exit 1
    fi
}

_main "$@"
