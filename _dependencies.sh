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
        apt-termux: p7zip
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
        apt-termux: libarchive
        apt:    libarchive-tools
        dnf:    bsdtar
        pacman: libarchive
        nix:    libarchive
        zypper: bsdtar
        brew:   libarchive
        guix:   libarchive
    "

    ["clamscan"]="
        *:      clamav
    "

    ["convert"]="
        apt-termux: imagemagick
        apt:    imagemagick
        dnf:    ImageMagick
        pacman: imagemagick
        nix:    imagemagick
        zypper: ImageMagick
        brew:   imagemagick
        guix:   imagemagick
    "

    ["exiftool"]="
        apt-termux: exiftool
        apt:    libimage-exiftool-perl
        dnf:    perl-Image-ExifTool
        pacman: perl-image-exiftool
        nix:    exiftool
        zypper: exiftool
        brew:   exiftool
        guix:   perl-image-exiftool
    "

    ["ffmpeg"]="
        apt-termux: ffmpeg
        apt:    ffmpeg
        dnf:    ffmpeg-free
        pacman: ffmpeg
        nix:    ffmpeg
        zypper: ffmpeg
        brew:   ffmpeg
        guix:   ffmpeg
    "

    ["gpg"]="
        apt-termux: gnupg
        apt:    gnupg
        dnf:    gnupg2
        pacman: gnupg
        nix:    gnupg
        zypper: gpg2
        brew:   gnupg
        guix:   gnupg
    "

    ["gunzip"]="
        *:      gzip
    "

    ["gs"]="
        *:      ghostscript
    "

    ["iconv"]="
        apt-termux: libiconv
        apt:    libc-bin
        dnf:    glibc-common
        pacman: glibc
        nix:    glibc
        zypper: glibc
        brew:   glibc
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
        brew:   libreoffice
        guix:   libreoffice
    "

    ["loimpress"]="
        apt:    libreoffice-impress
        dnf:    libreoffice-impress
        pacman: libreoffice
        nix:    libreoffice
        zypper: libreoffice-impress
        brew:   libreoffice
        guix:   libreoffice
    "

    ["lowriter"]="
        apt:    libreoffice-writer
        dnf:    libreoffice-writer
        pacman: libreoffice
        nix:    libreoffice
        zypper: libreoffice-writer
        brew:   libreoffice
        guix:   libreoffice
    "

    ["lp"]="
        apt-termux: cups
        apt:    cups-client
        dnf:    cups-client
        pacman: cups
        nix:    cups
        zypper: cups
        brew:   cups
        guix:   cups
    "

    ["mksquashfs"]="
        apt-termux: squashfs-tools-ng
        apt:    squashfs-tools
        dnf:    squashfs-tools
        pacman: squashfs-tools
        nix:    squashfsTools~squashfs
        zypper: squashfs
        brew:   squashfs
        guix:   squashfs-tools
    "

    ["perl"]="
        apt-termux: perl
        apt:    perl-base
        dnf:    perl-base
        pacman: perl-base
        nix:    perl
        zypper: perl-base
        brew:   perl
        guix:   perl
    "

    ["photorec"]="
        apt:    testdisk
        dnf:    testdisk
        pacman: testdisk
        nix:    testdisk
        zypper: photorec
        brew:   testdisk
        guix:   testdisk
    "

    ["pdfinfo"]="
        apt-termux: poppler
        apt:    poppler-utils
        dnf:    poppler-utils
        pacman: poppler
        nix:    poppler-utils
        zypper: poppler-tools
        brew:   poppler
        guix:   poppler
    "

    ["ping"]="
        apt-termux: inetutils
        apt:    iputils-ping
        dnf:    iputils
        pacman: iputils
        nix:    iputils
        zypper: iputils
        brew:   iputils
        guix:   iputils
    "

    ["unar"]="
        apt-termux: unar
        apt:    unar
        dnf:    unar
        pacman: unarchiver
        nix:    unar
        zypper: unar
        brew:   unar
    "

    ["unsquashfs"]="
        apt-termux: squashfs-tools-ng
        apt:    squashfs-tools
        dnf:    squashfs-tools
        pacman: squashfs-tools
        nix:    squashfsTools~squashfs
        zypper: squashfs
        brew:   squashfs
        guix:   squashfs-tools
    "

    ["wl-paste"]="
        *:      wl-clipboard
    "

    ["xorriso"]="
        apt-termux: xorriso
        apt:    xorriso
        dnf:    xorriso
        pacman: xorriso
        nix:    xorriso~libisoburn
        zypper: xorriso
        brew:   xorriso
        guix:   xorriso
    "

    ["xz"]="
        apt-termux: xz-utils
        apt:    xz-utils
        dnf:    xz
        pacman: xz
        nix:    xz
        zypper: xz
        brew:   xz
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
        apt-termux: texlive-bin
        apt:    latexmk
        dnf:    latexmk
        pacman: texlive-binextra
        nix:    texlivePackages.latexmk~latexmk
        zypper: texlive-latexmk
    "

    ["pdfjam"]="
        apt-termux: texlive-bin
        apt:    texlive-extra-utils
        dnf:    texlive-pdfjam
        pacman: texlive-basic texlive-binextra texlive-latexextra
        nix:    texliveSmall~texlive texlivePackages.pdfjam~pdfjam
        zypper: texlive-pdfjam-bin
    "

    ["sox-mp3"]="
        apt-termux: sox
        apt:    sox libsox-fmt-mp3
        dnf:    sox
        pacman: sox
        nix:    sox
        zypper: sox
        brew:   sox
        guix:   sox
    "

    ["tesseract-lang-$TEMP_DATA_TASK"]="
        apt-termux: tesseract
        apt:    tesseract-ocr-$TEMP_DATA_TASK
        dnf:    tesseract-langpack-$TEMP_DATA_TASK
        pacman: tesseract-data-$TEMP_DATA_TASK
        nix:    tesseract
        zypper: tesseract-ocr-traineddata-$TEMP_DATA_TASK
    "

    ["texlive"]="
        apt-termux: \
            texlive-bin
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
