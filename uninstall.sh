#!/usr/bin/env bash

set -u

# Use the home directory from the passwd database if '$HOME' is undefined.
HOME=${HOME:-$(eval echo ~)}

INSTALL_NAME_DIR="nautilus-scripts"
INSTALL_PATH=".local/opt/$INSTALL_NAME_DIR"
INSTALL_DIR="$HOME/$INSTALL_PATH"

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

# Desktop shortcuts (application menu).
_uninstall_directory "$HOME/.local/share/applications/$INSTALL_NAME_DIR"

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
find "$dir" -name "$INSTALL_NAME_DIR-*.desktop" -type f -delete 2>/dev/null

# -----------------------------------------------------------------------------
# SECTION: File manager: PCManFM-Qt
# -----------------------------------------------------------------------------

# PCManFM-Qt: File manager actions (context menu).
dir="$HOME/.local/share/file-manager/actions"
find "$dir" -name "$INSTALL_NAME_DIR-*.desktop" -type f -delete 2>/dev/null

# -----------------------------------------------------------------------------
# SECTION: Package manager: pkgx
# -----------------------------------------------------------------------------

_uninstall_directory "$HOME/.local/opt/pkgx"

# -----------------------------------------------------------------------------
# SECTION: GNOME Shell: application folder
# -----------------------------------------------------------------------------

_remove_gnome_application_folder() {
    local folder_name="Scripts"

    # Check gsettings and schema availability.
    if ! command -v gsettings &>/dev/null || ! gsettings list-schemas |
        grep -qxF "org.gnome.desktop.app-folders"; then
        return
    fi

    # Reset all keys for the specific folder
    gsettings reset-recursively \
        org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/$folder_name/ &>/dev/null

    # Remove the folder from GNOME app-folders list.
    local current_folders=""
    current_folders=$(gsettings get org.gnome.desktop.app-folders folder-children)

    # Remove the folder name if it exists.
    if [[ "$current_folders" == *"'$folder_name'"* ]]; then
        local new_list=""
        new_list=$(sed -E \
            "s/'$folder_name'[[:space:]]*,[[:space:]]*//; s/,[[:space:]]*'$folder_name'//; s/'$folder_name'//" \
            <<<"$current_folders")
        new_list=$(sed -E "s/\[[[:space:]]*\]/[]/; s/\[''\]/[]/" <<<"$new_list")
        gsettings set org.gnome.desktop.app-folders folder-children "$new_list" &>/dev/null
    fi
}
_remove_gnome_application_folder

echo "Uninstall complete!"
