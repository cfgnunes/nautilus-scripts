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
#   - If the package name is the same as the command name, there is no need to
#     include an entry in this file. Only exceptions or differing names should
#     be explicitly listed.
#   - If the package name contains the '~' character, it means that the part
#     before '~' represents the package name used for installation, while the
#     part after '~' represents the package name used for installation
#     verification. This is useful in systems like NixOS, where the installed
#     package name may differ from the one provided during installation.

declare -A PACKAGE_NAME=(
    ["7za"]="
        apt:    p7zip-full
        dnf:    p7zip
        pacman: p7zip
        nix:    p7zip
        zypper: 7zip
        brew:   p7zip
        guix:   p7zip
    "

    ["ar"]="
        *:      binutils
    "

    ["bsdtar"]="
        apt:    libarchive-tools
        dnf:    bsdtar
        pacman: libarchive
        nix:    libarchive
        zypper: bsdtar
        guix:   libarchive
    "

    ["clamscan"]="
        *:      clamav
    "

    ["convert"]="
        apt:    imagemagick
        dnf:    ImageMagick
        pacman: imagemagick
        nix:    imagemagick
        zypper: ImageMagick
        guix:   imagemagick
    "

    ["exiftool"]="
        apt:    libimage-exiftool-perl
        dnf:    perl-Image-ExifTool
        pacman: perl-image-exiftool
        nix:    exiftool
        zypper: exiftool
        guix:   perl-image-exiftool
    "

    ["ffmpeg"]="
        apt:    ffmpeg
        dnf:    ffmpeg-free
        pacman: ffmpeg
        nix:    ffmpeg
        zypper: ffmpeg
        guix:   ffmpeg
    "

    ["gpg"]="
        apt:    gnupg
        dnf:    gnupg2
        pacman: gnupg
        nix:    gnupg
        zypper: gpg2
        guix:   gnupg
    "

    ["gunzip"]="
        *:      gzip
    "

    ["gs"]="
        *:      ghostscript
    "

    ["iconv"]="
        apt:    libc-bin
        dnf:    glibc-common
        pacman: glibc
        nix:    glibc
        zypper: glibc
        guix:   glibc
    "

    ["lha"]="
        *:      lhasa
    "

    ["localc"]="
        apt:    libreoffice-calc
        dnf:    libreoffice-calc
        pacman: libreoffice
        nix:    libreoffice
        zypper: libreoffice-calc
        guix:   libreoffice
    "

    ["loimpress"]="
        apt:    libreoffice-impress
        dnf:    libreoffice-impress
        pacman: libreoffice
        nix:    libreoffice
        zypper: libreoffice-impress
        guix:   libreoffice
    "

    ["lowriter"]="
        apt:    libreoffice-writer
        dnf:    libreoffice-writer
        pacman: libreoffice
        nix:    libreoffice
        zypper: libreoffice-writer
        guix:   libreoffice
    "

    ["lp"]="
        apt:    cups-client
        dnf:    cups-client
        pacman: cups
        nix:    cups
        zypper: cups
        guix:   cups
    "

    ["mksquashfs"]="
        apt:    squashfs-tools
        dnf:    squashfs-tools
        pacman: squashfs-tools
        nix:    squashfsTools~squashfs
        zypper: squashfs
        guix:   squashfs-tools
    "

    ["perl"]="
        apt:    perl-base
        dnf:    perl-base
        pacman: perl-base
        nix:    perl
        zypper: perl-base
        guix:   perl
    "

    ["photorec"]="
        apt:    testdisk
        dnf:    testdisk
        pacman: testdisk
        nix:    testdisk
        zypper: photorec
        guix:   testdisk
    "

    ["pdfinfo"]="
        apt:    poppler-utils
        dnf:    poppler-utils
        pacman: poppler
        nix:    poppler-utils
        zypper: poppler-tools
        guix:   poppler
    "

    ["ping"]="
        apt:    iputils-ping
        dnf:    iputils
        pacman: iputils
        nix:    iputils
        zypper: iputils
        guix:   iputils
    "

    ["unar"]="
        apt:    unar
        dnf:    unar
        pacman: unarchiver
        nix:    unar
        zypper: unar
    "

    ["unsquashfs"]="
        apt:    squashfs-tools
        dnf:    squashfs-tools
        pacman: squashfs-tools
        nix:    squashfsTools
        zypper: squashfs
    "

    ["wl-paste"]="
        *:      wl-clipboard
    "

    ["xorriso"]="
        apt:    xorriso
        dnf:    xorriso
        pacman: xorriso
        nix:    xorriso~libisoburn
        zypper: xorriso
        guix:   xorriso
    "

    ["xz"]="
        apt:    xz-utils
        dnf:    xz
        pacman: xz
        nix:    xz
        zypper: xz
        guix:   xz
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
        *:sleep 5; rm -f /var/log/clamav/freshclam.log; \
            freshclam --quiet; sleep 5
    "
)

# -----------------------------------------------------------------------------
# META_PACKAGES
# -----------------------------------------------------------------------------
# This associative array defines grouped or composite packages that must be
# installed together to provide complete functionality for a given name.

declare -A META_PACKAGES=(
    ["latexmk"]="
        apt:    latexmk
        dnf:    latexmk
        pacman: texlive-binextra
        nix:    texlivePackages.latexmk~latexmk
        zypper: texlive-latexmk
    "

    ["pdfjam"]="
        apt:    texlive-extra-utils
        dnf:    texlive-pdfjam
        pacman: texlive-basic texlive-binextra texlive-latexextra
        nix:    texliveSmall~texlive texlivePackages.pdfjam~pdfjam
        zypper: texlive-pdfjam-bin
    "

    ["sox-mp3"]="
        apt:    sox libsox-fmt-mp3
        dnf:    sox
        pacman: sox
        nix:    sox
        zypper: sox
        guix:   sox
    "

    ["tesseract-lang-$TEMP_DATA_TASK"]="
        apt:    tesseract-ocr-$TEMP_DATA_TASK
        dnf:    tesseract-langpack-$TEMP_DATA_TASK
        pacman: tesseract-data-$TEMP_DATA_TASK
        nix:    tesseract
        zypper: tesseract-ocr-traineddata-$TEMP_DATA_TASK
    "

    ["texlive"]="
        apt: \
            texlive \
            texlive-fonts-extra \
            texlive-latex-extra \
            texlive-publishers \
            texlive-science \
            texlive-xetex
        dnf: \
            texlive-base \
            texlive-collection-fontsextra \
            texlive-collection-latexextra \
            texlive-collection-publishers \
            texlive-collection-mathscience \
            texlive-collection-xetex
        pacman: \
            texlive-basic \
            texlive-fontsextra \
            texlive-latexextra \
            texlive-publishers \
            texlive-mathscience \
            texlive-xetex
        nix: \
            texliveFull~texlive
        zypper: \
            texlive-collection-basic \
            texlive-collection-fontsextra \
            texlive-collection-latexextra \
            texlive-collection-publishers \
            texlive-collection-mathscience \
            texlive-collection-xetex
    "
)
