#!/usr/bin/env bash

# Install the scripts for the GNOME Files (Nautilus), Caja and Nemo file managers.

set -u

# Global variables
ASSSETS_DIR=".assets"
ACCELS_FILE=""
FILE_MANAGER=""
INSTALL_DIR=""

_main() {
    local ans=""
    local menu_options=""
    local defaults_categories=()
    local opt_categories=()
    local script_dirs=()

    _check_default_filemanager

    echo "Scripts installer."

    # Show the main options
    read -r -p " > Would you like to install basic dependencies? (Y/n) " ans && [[ "${ans,,}" == *"n"* ]] || menu_options+="dependencies,"
    read -r -p " > Would you like to install the keyboard shortcuts? (Y/n) " ans && [[ "${ans,,}" == *"n"* ]] || menu_options+="accels,"
    if [[ -n "$(ls -A "$INSTALL_DIR" 2>/dev/null)" ]]; then
        read -r -p " > Would you like to preserve the previous scripts? (Y/n) " ans && [[ "${ans,,}" == *"n"* ]] || menu_options+="preserve,"
    fi
    read -r -p " > Would you like to close the file manager to reload its configurations? (Y/n) " ans && [[ "${ans,,}" == *"n"* ]] || menu_options+="reload,"
    read -r -p " > Would you like to choose the script categories to install? (y/N) " ans
    if [[ "${ans,,}" == *"y"* ]]; then
        echo " > Choose the categories (<SPACE> to select, <UP/DOWN> to choose, <ENTER> to confirm):"
        for dirname in ./*/; do
            dirn="${dirname:2}"          # Remove leading path separators './'.
            script_dirs+=("${dirn::-1}") # Remove trailing path separator '/'.
        done
        _multiselect_menu opt_categories script_dirs defaults_categories
    fi

    echo
    echo "Starting the installation..."

    # Install basic package dependencies.
    if [[ "$menu_options" == *"dependencies"* ]]; then
        _install_dependencies
    fi

    # Install the scripts.
    _install_scripts "$menu_options" opt_categories script_dirs

    echo "Done!"
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
        echo "Error: could not find any compatible file managers!"
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
_install_dependencies() {
    local common_names="bzip2 foremost ghostscript gzip jpegoptim lame lhasa lzip lzop optipng pandoc perl-base qpdf rdfind rhash squashfs-tools tar testdisk unzip wget xclip xorriso zip zstd"

    echo " > Installing dependencies..."

    if _command_exists "sudo"; then
        if _command_exists "apt-get"; then
            sudo apt-get update || true
            # Distro: Ubuntu, Mint, Debian.
            sudo apt-get -y install $common_names imagemagick xz-utils p7zip-full poppler-utils ffmpeg findimagedupes genisoimage
        elif _command_exists "pacman"; then
            # Distro: Manjaro, Arch Linux.
            # Missing packages: findimagedupes.
            sudo pacman -Syy || true
            sudo pacman --noconfirm -S $common_names imagemagick xz p7zip poppler poppler-glib ffmpeg
        elif _command_exists "dnf"; then
            # Distro: Fedora, Red Hat.
            # Missing packages: findimagedupes.
            sudo dnf check-update || true
            sudo dnf -y install $common_names ImageMagick xz p7zip poppler-utils ffmpeg-free genisoimage
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
    local -n _opt_categories=$2
    local -n _script_dirs=$3
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

    if [ ${#_opt_categories[@]} -eq 0 ]; then # No custom choices, so copy all.
        cp -r . "$INSTALL_DIR"
    else
        index=0
        for option in "${_script_dirs[@]}"; do
            if [ "${_opt_categories[index]}" == "true" ]; then
                cp -r "${option}" "$INSTALL_DIR"
                cp "common-functions.sh" "$INSTALL_DIR"
            fi
            ((index++))
        done
    fi

    # Install the file 'scripts-accels'.
    if [[ "$menu_options" == *"accels"* ]]; then
        echo " > Installing the file 'scripts-accels'..."
        mkdir --parents "$(dirname -- "$ACCELS_FILE")"
        mv "$ACCELS_FILE" "$ACCELS_FILE.bak" 2>/dev/null || true

        case "$FILE_MANAGER" in
        "nautilus")
            cp "$ASSSETS_DIR/scripts-accels" "$ACCELS_FILE"
            ;;
        "nemo")
            cp "$ASSSETS_DIR/accels-gtk2" "$ACCELS_FILE"
            sed -i "s|USER|$USER|g" "$ACCELS_FILE"
            sed -i "s|ACCELS_PATH|local\\\\\\\\sshare\\\\\\\\snemo|g" "$ACCELS_FILE"
            ;;
        "caja")
            cp "$ASSSETS_DIR/accels-gtk2" "$ACCELS_FILE"
            sed -i "s|USER|$USER|g" "$ACCELS_FILE"
            sed -i "s|ACCELS_PATH|config\\\\\\\\scaja|g" "$ACCELS_FILE"
            ;;
        esac
    fi

    # Set file permissions.
    echo " > Setting file permissions..."
    find "$INSTALL_DIR" -mindepth 2 -type f ! -path "*.git/*" ! -path "*$ASSSETS_DIR/*" -exec chmod +x {} \;

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

# Menu code based on:
# https://unix.stackexchange.com/a/673436
_multiselect_menu() {
    local return_value=$1
    local -n options=$2
    local -n defaults=$3

    # Helpers for console print format and control.
    __cursor_blink_on() {
        echo -e -n "\033[?25h"
    }
    __cursor_blink_off() {
        echo -e -n "\033[?25l"
    }
    __cursor_to() {
        echo -e -n "\033[$1;${2:-1}H"
    }
    __print_inactive() {
        echo -e -n "  > $2 $1 "
    }
    __print_active() {
        echo -e -n "  > $2\033[7m $1 \033[27m"
    }
    __get_cursor_row() {
        IFS=';' read -sdRr -p $'\E[6n' ROW COL
        echo "${ROW#*[}"
    }

    # Proccess the 'defaults' parameter.
    local selected=()
    for ((i = 0; i < ${#options[@]}; i++)); do
        if [[ -v "defaults[i]" ]]; then
            if [[ ${defaults[i]} = "false" ]]; then
                selected+=("false")
            else
                selected+=("true")
            fi
        else
            selected+=("true")
        fi
        echo
    done

    # Determine current screen position for overwriting the options.
    local start_row=""
    local last_row=""
    last_row=$(__get_cursor_row)
    start_row=$((last_row - ${#options[@]}))

    # Ensure cursor and input echoing back on upon a ctrl+c during read -s.
    trap "__cursor_blink_on; stty echo; echo; exit" 2
    __cursor_blink_off

    # Local functions to use in the menu.
    __get_keyboard_key() {
        local key=""

        IFS="" read -rsn1 key 2>/dev/null >&2
        if [[ $key = "" ]]; then echo "enter"; fi
        if [[ $key = $'\x20' ]]; then echo "space"; fi
        if [[ $key = $'\x1b' ]]; then
            read -rsn2 key
            if [[ $key = "[A" || $key = "[D" ]]; then echo "up"; fi
            if [[ $key = "[B" || $key = "[C" ]]; then echo "down"; fi
        fi
    }

    __toggle_option() {
        local option=$1

        if [[ ${selected[option]} == true ]]; then
            selected[option]=false
        else
            selected[option]=true
        fi
    }

    # Print options by overwriting the last lines.
    __print_options() {
        local index=0

        for option in "${options[@]}"; do
            local prefix="[ ]"
            if [[ ${selected[index]} == true ]]; then
                prefix="[\e[38;5;46m*\e[0m]"
            fi

            __cursor_to $((start_row + index))
            if [ $index -eq "$1" ]; then
                __print_active "$option" "$prefix"
            else
                __print_inactive "$option" "$prefix"
            fi
            ((index++))
        done
    }

    # Print the menu.
    local active=0
    while true; do
        __print_options $active

        # User key control.
        case $(__get_keyboard_key) in
        "space")
            __toggle_option $active
            ;;
        "enter")
            __print_options -1
            break
            ;;
        "up")
            ((active--))
            if [ $active -lt 0 ]; then
                active=$((${#options[@]} - 1))
            fi
            ;;
        "down")
            ((active++))
            if [ $active -ge ${#options[@]} ]; then
                active=0
            fi
            ;;
        esac
    done

    # Cursor position back to normal.
    __cursor_to "$last_row"
    __cursor_blink_on

    eval "$return_value"='("${selected[@]}")'
}

_main "$@"
