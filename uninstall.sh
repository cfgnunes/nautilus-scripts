#!/usr/bin/env bash

set -u

INSTALL_NAME_DIR="scripts"

#------------------------------------------------------------------------------
#region Helper functions
#------------------------------------------------------------------------------

_remove_empty_parent_dirs() {
    local path=$1
    local parent_dir=""

    # Remove the directory and parent directories recursively (if empty).
    rmdir -- "$path" 2>/dev/null
    parent_dir=$(dirname -- "$path")
    while [[ "$parent_dir" != "$HOME" ]] && [[ "$parent_dir" != "/" ]]; do
        rmdir -- "$parent_dir" 2>/dev/null || break
        parent_dir=$(dirname -- "$parent_dir")
    done
}

_uninstall_directory() {
    local dir=$1
    rm -rf -- "$dir"
    _remove_empty_parent_dirs "$dir"
}

_uninstall_file() {
    local file=$1
    rm -f -- "$file"

    # Restore the backup (if exists).
    cp -- "$file.bak" "$file" 2>/dev/null
    _remove_empty_parent_dirs "$file"
}

#endregion
#------------------------------------------------------------------------------
#region Close file managers
#------------------------------------------------------------------------------

# Close some file managers to release configuration files.
nemo -q &>/dev/null
caja -q &>/dev/null
thunar -q &>/dev/null

#endregion
#------------------------------------------------------------------------------
#region Common files
#------------------------------------------------------------------------------

# Installed directory.
_uninstall_directory "$HOME/.local/share/$INSTALL_NAME_DIR"

# Desktop shortcuts (application menu).
_uninstall_directory "$HOME/.local/share/applications/$INSTALL_NAME_DIR"

#endregion
#------------------------------------------------------------------------------
#region File manager: Nautilus
#------------------------------------------------------------------------------

# Nautilus: File manager actions (context menu).
find "$HOME/.local/share/nautilus/scripts" -type l -delete 2>/dev/null
find "$HOME/.local/share/nautilus/scripts" -type d -empty -delete 2>/dev/null

# Nautilus: Keyboard accelerators.
_uninstall_file "$HOME/.config/nautilus/scripts-accels"

#endregion
#------------------------------------------------------------------------------
#region File manager: Nemo
#------------------------------------------------------------------------------

# Nemo: File manager actions (context menu).
find "$HOME/.local/share/nemo/scripts" -type l -delete 2>/dev/null
find "$HOME/.local/share/nemo/scripts" -type d -empty -delete 2>/dev/null

# Nemo: Keyboard accelerators.
_uninstall_file "$HOME/.gnome2/accels/nemo"

#endregion
#------------------------------------------------------------------------------
#region File manager: Caja
#------------------------------------------------------------------------------

# Caja: File manager actions (context menu).
find "$HOME/.config/caja/scripts" -type l -delete 2>/dev/null
find "$HOME/.config/caja/scripts" -type d -empty -delete 2>/dev/null

# Caja: Keyboard accelerators.
_uninstall_file "$HOME/.config/caja/accels"

#endregion
#------------------------------------------------------------------------------
#region File manager: Thunar
#------------------------------------------------------------------------------

# Thunar: File manager actions (context menu).
_uninstall_file "$HOME/.config/Thunar/uca.xml"

# Thunar: Keyboard accelerators.
_uninstall_file "$HOME/.config/Thunar/accels.scm"

#endregion
#------------------------------------------------------------------------------
#region File manager: Dolphin
#------------------------------------------------------------------------------

# Dolphin: File manager actions (context menu).
dir="$HOME/.local/share/kio/servicemenus"
find "$dir" -name "$INSTALL_NAME_DIR-*.desktop" -type f -delete 2>/dev/null
_remove_empty_parent_dirs "$dir"

#endregion
#------------------------------------------------------------------------------
#region File manager: PCManFM-Qt
#------------------------------------------------------------------------------

# PCManFM-Qt: File manager actions (context menu).
dir="$HOME/.local/share/file-manager/actions"
find "$dir" -name "$INSTALL_NAME_DIR-*.desktop" -type f -delete 2>/dev/null
_remove_empty_parent_dirs "$dir"

#endregion
#------------------------------------------------------------------------------
#region Package manager: Homebrew
#------------------------------------------------------------------------------

# Homebrew: Installed directory.
_uninstall_directory "$HOME/.local/apps/homebrew"

#endregion
#------------------------------------------------------------------------------
#region GNOME Shell: application folder
#------------------------------------------------------------------------------

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
        new_list=$(sed "s/'$folder_name'//g; s/, ,/,/g; s/ ,/,/g; s/\[,/[ /; s/, \]/]/" <<<"$current_folders" | tr -s ' ')
        gsettings set org.gnome.desktop.app-folders folder-children "$new_list" &>/dev/null
    fi
}
_remove_gnome_application_folder

#endregion

echo "Uninstall complete!"
