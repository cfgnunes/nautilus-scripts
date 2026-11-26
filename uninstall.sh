#!/usr/bin/env bash
# =============================================================================
# Description: Uninstall the Enhanced File Manager Actions.
#
# Usage:
#   bash uninstall.sh
# =============================================================================

set -u

# Use the home directory from the passwd database if '$HOME' is undefined.
HOME=${HOME:-$(eval echo ~)}

APP_NAME="nautilus-scripts"
USER_OPT_DIR="$HOME/.local/opt"
INSTALL_DIR="$USER_OPT_DIR/$APP_NAME"

# -----------------------------------------------------------------------------
# SECTION: Helper functions
# -----------------------------------------------------------------------------

_uninstall_directory() {
    local dir=$1
    rm -rf -- "$dir"
}

_uninstall_file() {
    local file=$1
    rm -f -- "$file"

    # Restore the backup (if exists).
    cp -- "$file.bak" "$file" 2>/dev/null
}

# -----------------------------------------------------------------------------
# SECTION: Close file managers
# -----------------------------------------------------------------------------

# Close some file managers to release configuration files.
caja -q &>/dev/null
nautilus -q &>/dev/null
nemo -q &>/dev/null
thunar -q &>/dev/null

# -----------------------------------------------------------------------------
# SECTION: Common files
# -----------------------------------------------------------------------------

# Installed directory.
_uninstall_directory "$INSTALL_DIR"

# -----------------------------------------------------------------------------
# SECTION: File manager: Nautilus
# -----------------------------------------------------------------------------

# Nautilus: File manager actions (context menu).
find "$HOME/.local/share/nautilus/scripts" -type l -lname "$INSTALL_DIR/*" -delete 2>/dev/null
find "$HOME/.local/share/nautilus/scripts" -type d -empty -delete 2>/dev/null

# Nautilus: Keyboard accelerators.
_uninstall_file "$HOME/.config/nautilus/scripts-accels"

# -----------------------------------------------------------------------------
# SECTION: File manager: Nemo
# -----------------------------------------------------------------------------

# Nemo: File manager actions (context menu).
find "$HOME/.local/share/nemo/scripts" -type l -lname "$INSTALL_DIR/*" -delete 2>/dev/null
find "$HOME/.local/share/nemo/scripts" -type d -empty -delete 2>/dev/null

# Nemo: Keyboard accelerators.
_uninstall_file "$HOME/.gnome2/accels/nemo"

# -----------------------------------------------------------------------------
# SECTION: File manager: Caja
# -----------------------------------------------------------------------------

# Caja: File manager actions (context menu).
find "$HOME/.config/caja/scripts" -type l -lname "$INSTALL_DIR/*" -delete 2>/dev/null
find "$HOME/.config/caja/scripts" -type d -empty -delete 2>/dev/null

# Caja: Keyboard accelerators.
_uninstall_file "$HOME/.config/caja/accels"

# -----------------------------------------------------------------------------
# SECTION: File manager: Thunar
# -----------------------------------------------------------------------------

# Thunar: File manager actions (context menu).
_uninstall_file "$HOME/.config/Thunar/uca.xml"

# Thunar: Keyboard accelerators.
_uninstall_file "$HOME/.config/Thunar/accels.scm"

# -----------------------------------------------------------------------------
# SECTION: File manager: Dolphin
# -----------------------------------------------------------------------------

# Dolphin: File manager actions (context menu).
dir="$HOME/.local/share/kio/servicemenus"
find "$dir" -name "$APP_NAME-*.desktop" -type f -delete 2>/dev/null

# -----------------------------------------------------------------------------
# SECTION: File manager: PCManFM-Qt
# -----------------------------------------------------------------------------

# PCManFM-Qt: File manager actions (context menu).
dir="$HOME/.local/share/file-manager/actions"
find "$dir" -name "$APP_NAME-*.desktop" -type f -delete 2>/dev/null

# -----------------------------------------------------------------------------
# SECTION: Package manager: pkgx
# -----------------------------------------------------------------------------

_uninstall_directory "$HOME/.local/opt/pkgx"

echo "Uninstall complete!"
