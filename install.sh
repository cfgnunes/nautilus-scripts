#!/usr/bin/env bash

# Install the scripts for the GNOME Files (Nautilus), Caja and Nemo file managers.

# shellcheck disable=SC2086

set -eu

_main() {
    local menu_options=""
    local menu_exit=""

    # Show the main menu
    menu_options=$(whiptail --title "Nautilus Scripts Installer" --separate-output --checklist \
        "Installer options:" 11 68 4 \
        "1" "Install basic package dependencies" ON \
        "2" "Install the file 'scripts-accels'" ON \
        "3" "Preserve the previous scripts" OFF \
        "4" "Close the file manager to reload its configurations" ON \
        3>&1 1>&2 2>&3)
    menu_exit=$?

    # Check if the user pressed Cancel or Esc in the menu.
    if [[ $menu_exit != 0 ]]; then
        echo "User cancelled."
        exit 1
    fi

    echo "Starting the installation..."

    # Install basic package dependencies
    if [[ "$menu_options" == *1* ]]; then
        _install_dependencies
    fi

    # Install the scripts
    _install_scripts "$menu_options"

    echo "Done!"
}

_command_exists() {
    local command_check="$1"

    if command -v "$command_check" &>/dev/null; then
        return 0
    fi
    return 1
}

_install_dependencies() {
    local common_names="bzip2 foremost ghostscript gzip jpegoptim lame lzip lzop optipng pandoc perl-base qpdf rhash squashfs-tools tar testdisk unrar wget xclip zip zstd"

    echo " > Installing dependencies..."

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
        echo "Error: could not run as administrator!"
        exit 1
    fi
}

_install_scripts() {
    local menu_options="$1"
    local accels_dir=""
    local file_manager=""
    local install_dir=""
    local tmp_install_dir=""

    # Get the default file manager
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
        echo "Error: could not find any compatible file managers!"
        exit 1
    fi

    # 'Preserve' or 'Remove' previous scripts
    if [[ "$menu_options" == *3* ]]; then
        echo " > Preserving previous scripts to a temporary directory..."
        tmp_install_dir=$(mktemp -d)
        mv "$install_dir/"* "$tmp_install_dir" || true
    else
        echo " > Removing previous scripts..."
        rm -rf "$install_dir"
    fi

    # Install the scripts
    echo " > Installing new scripts..."
    mkdir --parents "$install_dir"
    cp -r ./* "$install_dir/"

    # Restore previous scripts
    if [[ "$menu_options" == *3* ]]; then
        echo " > Restoring previous scripts to the install directory..."
        mv "$tmp_install_dir" "$install_dir/User previous scripts"
    fi

    # Install the file 'scripts-accels'
    if [[ "$menu_options" == *2* ]]; then
        if [[ -n "$accels_dir" ]]; then
            echo " > Installing the file 'scripts-accels'..."
            rm -f "$accels_dir/scripts-accels"
            mkdir --parents "$accels_dir"
            cp "scripts-accels" "$accels_dir/scripts-accels"
        fi
    fi

    # Set file permissions
    echo " > Setting file permissions..."
    find "$install_dir" -mindepth 2 -type f ! -path "*.git/*" -exec chmod +x {} \;

    # Close the file manager to reload its configurations
    if [[ "$menu_options" == *4* ]]; then
        echo " > Closing the file manager to reload its configurations..."
        eval "$file_manager -q &>/dev/null" || true
    fi
}

_main "$@"
