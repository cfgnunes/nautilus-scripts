#!/usr/bin/env bash
# =============================================================================
# Description: Provide installer functions for Caja.
# Sourced by 'install.sh'. Do not run directly.
#
# Files and directories created:
#   ~/.config/caja/scripts/
#   ~/.config/caja/accels
# =============================================================================

_close_file_manager_caja() {
    # Reload the file manager in background to restore desktop session.
    if [[ -n "${XDG_CURRENT_DESKTOP:-}" ]]; then
        # Only restart if running under MATE.
        if [[ "${XDG_CURRENT_DESKTOP,,}" == *"mate"* ]]; then
            # Close Caja.
            caja -q &>/dev/null
            nohup caja --force-desktop --no-default-window &>/dev/null &
        fi
    fi
}

_install_accels_caja() {
    _install_accels_gnome2 "$HOME/.config/caja/accels" "$HOME/.config/caja/scripts"
}

_install_actions_caja() {
    _create_links "$HOME/.config/caja/scripts"
}
