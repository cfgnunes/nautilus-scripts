#!/usr/bin/env bash

# Install the scripts for the GNOME Files (Nautilus), Caja and Nemo file managers.

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
        return 1
    fi

    echo " > Removing previous files..."
    rm -rf "$install_dir"
    rm -f "$accels_dir/scripts-accels"

    echo " > Installing new scripts..."
    mkdir --parents "$install_dir"
    cp -r ./* "$install_dir/"

    if [[ -n "$accels_dir" ]]; then
        echo " > Installing 'scripts-accels'..."
        mkdir --parents "$accels_dir"
        cp "scripts-accels" "$accels_dir/scripts-accels"
    fi

    echo " > Setting file permissions..."
    find -L "$install_dir" -mindepth 2 -type f ! -path "*.git/*" -exec chmod +x {} \;
    find -L "$install_dir" -maxdepth 1 -type f ! -path "*.git/*" -exec chmod -x {} \;

    echo " > Closing the file manager to reload its configurations..."
    eval "$file_manager -q &>/dev/null" || true

    echo "Done!"
}

_main "$@"
