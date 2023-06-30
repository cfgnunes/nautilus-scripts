#!/usr/bin/env bash

# Install the scripts for the GNOME Files (Nautilus), Caja and Nemo file managers.

set -eu

_main() {
    echo "Installing the scripts..."
    local INSTALL_DIR=""
    local ACCELS_DIR=""
    local FILE_MANAGER=""

    if hash nautilus &>/dev/null; then
        INSTALL_DIR="$HOME/.local/share/nautilus/scripts"
        ACCELS_DIR="$HOME/.config/nautilus"
        FILE_MANAGER="nautilus"
    elif hash nemo &>/dev/null; then
        INSTALL_DIR="$HOME/.local/share/nemo/scripts"
        FILE_MANAGER="nemo"
    elif hash caja &>/dev/null; then
        INSTALL_DIR="$HOME/.config/caja/scripts"
        FILE_MANAGER="caja"
    else
        echo "Error: not found any compatible file managers!"
        return 1
    fi

    echo " > Removing previous files..."
    rm -rf "$INSTALL_DIR"
    rm -f "$ACCELS_DIR/scripts-accels"

    echo " > Installing new scripts..."
    mkdir --parents "$INSTALL_DIR"
    cp -r ./* "$INSTALL_DIR/"

    if [[ -n "$ACCELS_DIR" ]]; then
        echo " > Installing 'scripts-accels'..."
        mkdir --parents "$ACCELS_DIR"
        cp "scripts-accels" "$ACCELS_DIR/scripts-accels"
    fi

    echo " > Setting file permissions..."
    find -L "$INSTALL_DIR" -mindepth 2 -type f ! -path "*.git/*" -exec chmod +x {} \;
    find -L "$INSTALL_DIR" -maxdepth 1 -type f ! -path "*.git/*" -exec chmod -x {} \;

    echo " > Closing the file manager to reload its configurations..."
    eval "$FILE_MANAGER -q &>/dev/null" || true

    echo "Done!"
}

_main "$@"
