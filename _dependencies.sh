#!/usr/bin/env bash
# shellcheck disable=SC2034

# This file centralizes dependency definitions for the scripts.

# -----------------------------------------------------------------------------
# PACKAGE_NAME
# -----------------------------------------------------------------------------
# This associative array defines the mapping between a command name (key) and
# its corresponding package names across different package managers (values).
#
# Note:
#   If the package name is the same as the command name, there is no need to
#   include an entry in this file. Only exceptions or differing names should
#   be explicitly listed.

declare -A PACKAGE_NAME=(
    ["7za"]="
        apt:p7zip-full
        dnf:p7zip
        pacman:p7zip
        nix:p7zip
        zypper:7zip
        brew:p7zip
    "

    ["ar"]="
        *:binutils
    "

    ["bsdtar"]="
        apt:libarchive-tools
        dnf:bsdtar
        pacman:libarchive
        nix:libarchive
        zypper:bsdtar
    "

    ["clamscan"]="
        *:clamav
    "

    ["convert"]="
        apt:imagemagick
        dnf:ImageMagick
        pacman:imagemagick
        nix:imagemagick
        zypper:ImageMagick
    "

    ["exiftool"]="
        apt:libimage-exiftool-perl
        dnf:perl-Image-ExifTool
        pacman:perl-image-exiftool
        nix:exiftool
        zypper:exiftool
    "

    ["ffmpeg"]="
        apt:ffmpeg
        dnf:ffmpeg-free
        pacman:ffmpeg
        nix:ffmpeg
        zypper:ffmpeg
    "

    ["gpg"]="
        apt:gnupg
        dnf:gnupg2
        pacman:gnupg
        nix:gnupg
        zypper:gpg2
    "

    ["gunzip"]="
        *:gzip
    "

    ["gs"]="
        *:ghostscript
    "

    ["iconv"]="
        apt:libc-bin
        dnf:glibc-common
        pacman:glibc
        nix:glibc
        zypper:glibc
    "

    ["lha"]="
        *:lhasa
    "

    ["localc"]="
        apt:libreoffice-calc
        dnf:libreoffice-calc
        pacman:libreoffice
        nix:libreoffice
        zypper:libreoffice-calc
    "

    ["loimpress"]="
        apt:libreoffice-impress
        dnf:libreoffice-impress
        pacman:libreoffice
        nix:libreoffice
        zypper:libreoffice-impress
    "

    ["lowriter"]="
        apt:libreoffice-writer
        dnf:libreoffice-writer
        pacman:libreoffice
        nix:libreoffice
        zypper:libreoffice-writer
    "

    ["lp"]="
        apt:cups-client
        dnf:cups-client
        pacman:cups
        nix:cups
        zypper:cups
    "

    ["mksquashfs"]="
        apt:squashfs-tools
        dnf:squashfs-tools
        pacman:squashfs-tools
        nix:squashfsTools
        zypper:squashfs
    "

    ["perl"]="
        apt:perl-base
        dnf:perl-base
        pacman:perl-base
        nix:perl
        zypper:perl-base
    "

    ["photorec"]="
        apt:testdisk
        dnf:testdisk
        pacman:testdisk
        nix:testdisk
        zypper:photorec
    "

    ["pdfinfo"]="
        apt:poppler-utils
        dnf:poppler-utils
        pacman:poppler
        nix:poppler-utils
        zypper:poppler-tools
    "

    ["ping"]="
        apt:iputils-ping
        dnf:iputils
        pacman:iputils
        nix:iputils
        zypper:iputils
    "

    ["unar"]="
        apt:unar
        dnf:unar
        pacman:unarchiver
        nix:unar
        zypper:unar
    "

    ["unsquashfs"]="
        apt:squashfs-tools
        dnf:squashfs-tools
        pacman:squashfs-tools
        nix:squashfsTools
        zypper:squashfs
    "

    ["wl-paste"]="
        *:wl-clipboard
    "

    ["xz"]="
        apt:xz-utils
        dnf:xz
        pacman:xz
        nix:xz
        zypper:xz
    "
)

# -----------------------------------------------------------------------------
# PACKAGE_NAME_CHECK
# -----------------------------------------------------------------------------
# This associative array defines exceptions for systems where the package name
# used to install differs from the one shown when verifying installation.
#
# Example:
#   - On NixOS, "mksquashfs" is installed via "squashfsTools" but appears as
#     "squashfs" when checked.

declare -A PACKAGE_NAME_CHECK=(
    ["mksquashfs"]="
        nix:squashfs
    "
)

# -----------------------------------------------------------------------------
# POST_INSTALL
# -----------------------------------------------------------------------------
# This associative array defines commands or actions that need to be executed
# after a package is installed. These actions are usually required for proper
# initialization, configuration, or updates that the package manager alone does
# not handle.

declare -A POST_INSTALL=(
    ["clamscan"]="
        *:'sleep 5; rm -f /var/log/clamav/freshclam.log; freshclam --quiet; sleep 5'
    "
)
