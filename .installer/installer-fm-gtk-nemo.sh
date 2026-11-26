#!/usr/bin/env bash
# =============================================================================
# Description: Provide installer functions for Nemo.
# Sourced by 'install.sh'. Do not run directly.
#
# Files and directories created:
#   ~/.local/share/nemo/scripts/
#   ~/.gnome2/accels/nemo
# =============================================================================

_close_file_manager_nemo() {
    nemo -q &>/dev/null
}

_install_accels_nemo() {
    _install_accels_gnome2 "$HOME/.gnome2/accels/nemo" "$HOME/.local/share/nemo/scripts"
}

_install_actions_nemo() {
    _create_links "$HOME/.local/share/nemo/scripts"
}
