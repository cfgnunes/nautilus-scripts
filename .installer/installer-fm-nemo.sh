#!/usr/bin/env bash
# =============================================================================
# Project: Enhanced File Manager Actions
# Description: Installer functions for Nemo.
# Sourced by 'install.sh'. Do not run directly.
# =============================================================================

_close_filemanager_nemo() {
    # This file manager supports the '-q' option to quit gracefully.
    $FILE_MANAGER -q &>/dev/null
}

_install_accels_nemo() {
    _install_accels_gnome2 "$HOME/.gnome2/accels/nemo" "$HOME/.local/share/nemo/scripts"
}

_install_actions_nemo() {
    _create_links "$HOME/.local/share/nemo/scripts"
}
