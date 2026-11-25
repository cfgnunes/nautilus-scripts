#!/usr/bin/env bash

# =============================================================================
# Description: Dependency check and package installation functions.
# Sourced by 'install.sh'. Do not run directly.
# =============================================================================

_check_dependencies() {
    _echo ""
    _echo_info "$(_i18n 'Checking for basic dependencies:')"

    local packages=""

    # Basic packages to run the script '.common-functions.sh'.
    _command_exists "basename" || packages+="coreutils "
    _command_exists "pstree" || packages+="psmisc "
    _command_exists "xdg-open" || packages+="xdg-utils "

    local is_termux="false"
    if [[ "$HOME" == *"com.termux"* && "$(uname -o)" == "Android" ]]; then
        is_termux="true"
    fi

    # Skip Bubblewrap installation on Termux.
    if [[ "$is_termux" == "false" ]]; then
        # Bubblewrap is used for running commands inside a sandbox.
        _command_exists "bwrap" || packages+="bubblewrap "
    fi

    # HACK: Workaround for Termux (Android).
    # Check if the 'file' command is available and functional. Some minimal
    # GNU/Linux distributions (such as Termux) may have a non-functional 'file'
    # command, which can cause issues when running the scripts.
    if ! _command_exists "file" ||
        ! file --brief --mime-type /dev/null >/dev/null 2>&1; then
        packages+="file "
    fi

    # Packages for dialogs.
    if [[ -n "${XDG_CURRENT_DESKTOP:-}" ]]; then
        if ! _command_exists "zenity" && ! _command_exists "yad"; then
            if [[ "${XDG_CURRENT_DESKTOP,,}" == *"gnome"* ||
                "${XDG_CURRENT_DESKTOP,,}" == *"cosmic"* ]]; then
                packages+="zenity "
            else
                packages+="yad "
            fi
        fi
    fi

    if _command_exists "nix-env"; then
        # Package manager 'nix-env': For Nix-based systems.
        _command_exists "pgrep" || packages+="procps "
        _install_packages "nix-env" "$packages"
    elif _command_exists "apt-get"; then
        # Package manager 'apt-get': For Debian/Ubuntu systems.
        _command_exists "pgrep" || packages+="procps "
        _install_packages "apt-get" "$packages"
    elif _command_exists "rpm-ostree"; then
        # Package manager 'rpm-ostree': For Fedora/RHEL atomic systems.
        _command_exists "pgrep" || packages+="procps-ng "
        _install_packages "rpm-ostree" "$packages"
    elif _command_exists "dnf"; then
        # Package manager 'dnf': For Fedora/RHEL systems.
        _command_exists "pgrep" || packages+="procps-ng "
        _install_packages "dnf" "$packages"
    elif _command_exists "pacman"; then
        # Package manager 'pacman': For Arch Linux systems.
        _command_exists "pgrep" || packages+="procps "
        _install_packages "pacman" "$packages"
    elif _command_exists "zypper"; then
        # Package manager 'zypper': For openSUSE systems.
        _command_exists "pgrep" || packages+="procps-ng "
        _install_packages "zypper" "$packages"
    elif _command_exists "guix"; then
        # Package manager 'guix': For GNU Guix systems.
        _command_exists "pgrep" || packages+="procps "
        _install_packages "guix" "$packages"
    elif _command_exists "xbps-install"; then
        # Package manager 'xbps': For Void Linux systems.
        _command_exists "pgrep" || packages+="procps-ng "
        _install_packages "xbps-install" "$packages"
    else
        if [[ -n "$packages" ]]; then
            _log "[ERR] Missing package manager."
            _echo_error "$(_i18n 'Could not find a package manager!')"
            exit 1
        fi
    fi

    if [[ -z "$packages" ]]; then
        _echo_info "> $(_i18n 'All dependencies are already satisfied.')"
    fi
    _echo_info "> $(_i18n 'Done!')"
}

_install_packages() {
    local pkg_manager=$1
    local packages=$2
    local cmd_admin=""
    local cmd_admin_available=""
    local cmd_inst=""

    # Remove the last space char.
    packages=${packages% }

    _log "[INF] Package manager: $pkg_manager"

    [[ -z "$packages" ]] && return

    _echo_info "> $(_i18n 'The following packages are missing:') $packages"

    _command_exists "sudo" && cmd_admin_available="sudo"

    cmd_inst=""
    cmd_admin="$cmd_admin_available"

    case "$pkg_manager" in
    "apt-get")
        cmd_inst+="apt-get update;"
        cmd_inst+="apt-get -y install $packages"
        ;;
    "dnf")
        cmd_inst+="dnf check-update;"
        cmd_inst+="dnf -y install $packages"
        ;;
    "guix")
        cmd_inst="guix package -i $packages"
        ;;
    "nix-env")
        local nix_channel="nixpkgs"
        if grep --quiet "ID=nixos" /etc/os-release 2>/dev/null; then
            nix_channel="nixos"
        fi
        local pkg=""
        for pkg in $packages; do
            nix-env -iA "$nix_channel.$pkg"
        done
        ;;
    "pacman")
        cmd_inst+="pacman -Syy;"
        cmd_inst+="pacman --noconfirm -S $packages"
        ;;
    "rpm-ostree")
        cmd_inst+="rpm-ostree install $packages"
        ;;
    "xbps-install")
        cmd_inst+="xbps-install -S;"
        cmd_inst+="xbps-install -y -u xbps;"
        cmd_inst+="xbps-install -y $packages"
        ;;
    "zypper")
        cmd_inst+="zypper refresh;"
        cmd_inst+="zypper --non-interactive install $packages"
        ;;
    esac

    # Execute installation.
    if [[ -n "$cmd_inst" ]]; then
        _echo_info "> $(_i18n 'Installing the packages. Please wait...')"
        # If root privileges are required, prepend with 'sudo'.
        $cmd_admin bash -c "$cmd_inst"
    fi
}
