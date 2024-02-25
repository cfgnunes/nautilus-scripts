#!/usr/bin/env bash
# shellcheck disable=SC2034

# Install the scripts for the GNOME Files (Nautilus), Caja and Nemo file managers.

set -eu

# Global variables
ASSSETS_DIR=".assets"
ACCELS_FILE=""
FILE_MANAGER=""
INSTALL_DIR=""

_main() {
    local menu_options=""
    local categories_defaults=()
    local categories_dirs=()
    local categories_selected=()
    local menu_defaults=()
    local menu_labels=()
    local menu_selected=()

    _check_default_filemanager

    echo "Scripts installer."
    echo
    echo "Select the options (<SPACE> to select, <UP/DOWN> to choose, <ENTER> to confirm):"

    menu_labels=(
        "Install basic dependencies."
        "Install the keyboard shortcuts."
        "Preserve previous scripts (if any)."
        "Close the file manager to reload its configurations."
        "Choose the script categories to install."
    )
    menu_defaults=(
        "true"
        "true"
        "true"
        "true"
        "false"
    )

    _multiselect_menu menu_selected menu_labels menu_defaults

    [[ ${menu_selected[0]} == "true" ]] && menu_options+="dependencies,"
    [[ ${menu_selected[1]} == "true" ]] && menu_options+="shortcuts,"
    [[ ${menu_selected[2]} == "true" ]] && [[ -n "$(ls -A "$INSTALL_DIR" 2>/dev/null)" ]] && menu_options+="preserve,"
    [[ ${menu_selected[3]} == "true" ]] && menu_options+="reload,"
    [[ ${menu_selected[4]} == "true" ]] && menu_options+="categories,"

    if [[ "$menu_options" == *"categories"* ]]; then
        echo
        echo "Choose the categories (<SPACE> to select, <UP/DOWN> to choose, <ENTER> to confirm):"
        for dirname in ./*/; do
            dirn="${dirname:2}"              # Remove leading path separators './'.
            categories_dirs+=("${dirn::-1}") # Remove trailing path separator '/'.
        done
        _multiselect_menu categories_selected categories_dirs categories_defaults
    fi

    echo
    echo "Starting the installation..."

    # Install basic package dependencies.
    if [[ "$menu_options" == *"dependencies"* ]]; then
        _install_dependencies
    fi

    # Install the scripts.
    _install_scripts "$menu_options" categories_selected categories_dirs

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
            sudo apt-get update
            # Distro: Ubuntu, Mint, Debian.
            sudo apt-get -y install $common_names imagemagick xz-utils p7zip-full poppler-utils ffmpeg findimagedupes genisoimage
        elif _command_exists "pacman"; then
            # Distro: Manjaro, Arch Linux.
            # Missing packages: findimagedupes.
            sudo pacman -Syy
            sudo pacman --noconfirm -S $common_names imagemagick xz p7zip poppler poppler-glib ffmpeg
        elif _command_exists "dnf"; then
            # Distro: Fedora, Red Hat.
            # Missing packages: findimagedupes.
            sudo dnf check-update
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
    local -n _categories_selected=$2
    local -n _categories_dirs=$3
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

    if [[ ${#_categories_selected[@]} == "0" ]]; then # No custom choices, so copy all.
        cp -r . "$INSTALL_DIR"
    else
        index=0
        for option in "${_categories_dirs[@]}"; do
            if [[ "${_categories_selected[index]}" == "true" ]]; then
                cp -r "${option}" "$INSTALL_DIR"
                cp "common-functions.sh" "$INSTALL_DIR"
            fi
            ((index++))
        done
    fi

    # Install the file 'scripts-accels'.
    if [[ "$menu_options" == *"shortcuts"* ]]; then
        echo " > Installing the keyboard shortcuts..."
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

# Menu code based on: https://unix.stackexchange.com/a/673436
_multiselect_menu() {
    local return_value=$1
    local -n options=$2
    local -n defaults=$3

    # Helpers for console print format and control.
    __cursor_blink_on() {
        echo -e -n "\e[?25h"
    }
    __cursor_blink_off() {
        echo -e -n "\e[?25l"
    }
    __cursor_to() {
        local row=$1
        local col=${2:-1}

        echo -e -n "\e[${row};${col}H"
    }
    __get_cursor_row() {
        local row=""
        local col=""

        # shellcheck disable=SC2034
        IFS=';' read -rsdR -p $'\E[6n' row col
        echo "${row#*[}"
    }
    __get_keyboard_key() {
        local key=""

        IFS="" read -rsn1 key &>/dev/null
        if [[ $key = "" ]]; then echo "enter"; fi
        if [[ $key = " " ]]; then echo "space"; fi
        if [[ $key = $'\e' ]]; then
            IFS="" read -rsn2 key &>/dev/null
            if [[ $key = "[A" || $key = "[D" ]]; then echo "up"; fi
            if [[ $key = "[B" || $key = "[C" ]]; then echo "down"; fi
        fi
    }
    __exit_menu() {
        __cursor_to "$last_row"
        __cursor_blink_on
        stty echo
        exit
    }

    # Ensure cursor and input echoing back on upon a ctrl+c during read -s.
    trap "__exit_menu" SIGINT

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

    # Print options by overwriting the last lines.
    __print_options() {
        local index_active=$1
        local index=0
        local option=""

        for option in "${options[@]}"; do
            # Set the prefix " > [ ]" or " > [*]".
            local prefix=" > [ ]"
            if [[ ${selected[index]} == "true" ]]; then
                prefix=" > [\e[1;32m*\e[0m]"
            fi

            # Print the prefix with the option in the menu.
            __cursor_to "$((start_row + index))"
            if [[ "$index" == "$index_active" ]]; then
                # Print the active option.
                echo -e -n "$prefix \e[7m$option\e[27m"
            else
                # Print the inactive option.
                echo -e -n "$prefix $option"
            fi
            # Avoid print chars when press two keys at same time.
            __cursor_to "$start_row"

            index=$((index + 1))
        done
    }

    # Main loop of the menu.
    __cursor_blink_off
    local active=0
    while true; do
        __print_options "$active"

        # User key control.
        case $(__get_keyboard_key) in
        "space")
            # Toggle the option.
            if [[ ${selected[active]} == "true" ]]; then
                selected[active]="false"
            else
                selected[active]="true"
            fi
            ;;
        "enter")
            __print_options -1
            break
            ;;
        "up")
            active=$((active - 1))
            if [[ $active -lt 0 ]]; then
                active=$((${#options[@]} - 1))
            fi
            ;;
        "down")
            active=$((active + 1))
            if [[ $active -ge ${#options[@]} ]]; then
                active=0
            fi
            ;;
        esac
    done

    # Set the cursor position back to normal.
    __cursor_to "$last_row"
    __cursor_blink_on

    eval "$return_value"='("${selected[@]}")'

    # Unset the trap function.
    trap "" SIGINT
}

_main "$@"
