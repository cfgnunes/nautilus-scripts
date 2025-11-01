#!/usr/bin/env bash
# shellcheck disable=SC2034

# This file centralizes dependency definitions for the scripts.

# -----------------------------------------------------------------------------
# SECTION: DEPENDENCIES_MAP ----
# -----------------------------------------------------------------------------
# This array defines the mapping between a dependency key and its corresponding
# package names across different package managers.
#
# Note:
#   - If the package name contains the '~' character, it means that the part
#     before '~' represents the package name used for installation, while the
#     part after '~' represents the package name used for installation
#     verification. This is useful in systems like NixOS, where the installed
#     package name may differ from the one provided during installation.

declare -A DEPENDENCIES_MAP=(
    ["7za"]="
        pkg:    p7zip
        apt:    p7zip-full
        dnf:    p7zip
        pacman: p7zip
        nix:    p7zip
        zypper: 7zip
        guix:   p7zip
        brew:   p7zip
    "

    ["ar"]="
        pkg:    binutils
        apt:    binutils
        dnf:    binutils
        pacman: binutils
        nix:    binutils
        zypper: binutils
        guix:   binutils
        brew:   binutils
    "

    ["axel"]="
        pkg:    axel
        apt:    axel
        dnf:    axel
        pacman: axel
        nix:    axel
        zypper: axel
        guix:   axel
        brew:   axel
    "

    ["baobab"]="
        pkg:    baobab
        apt:    baobab
        dnf:    baobab
        pacman: baobab
        nix:    baobab
        zypper: baobab
        guix:   baobab
        brew:
    "

    ["bsdtar"]="
        pkg:    libarchive
        apt:    libarchive-tools
        dnf:    bsdtar
        pacman: libarchive
        nix:    libarchive
        zypper: bsdtar
        guix:   libarchive
        brew:   libarchive
    "

    ["bzip2"]="
        pkg:    bzip2
        apt:    bzip2
        dnf:    bzip2
        pacman: bzip2
        nix:    bzip2
        zypper: bzip2
        guix:   bzip2
        brew:   bzip2
    "

    ["cabextract"]="
        pkg:    cabextract
        apt:    cabextract
        dnf:    cabextract
        pacman: cabextract
        nix:    cabextract
        zypper: cabextract
        guix:   cabextract
        brew:   cabextract
    "

    ["cjxl"]="
        pkg:    libjxl-tools
        apt:    libjxl-tools
        dnf:    libjxl-utils
        pacman: libjxl
        nix:    libjxl
        zypper: libjxl-tools
        guix:   libjxl
        brew:
    "

    ["clamscan"]="
        pkg:    clamav
        apt:    clamav
        dnf:    clamav
        pacman: clamav
        nix:    clamav
        zypper: clamav
        guix:   clamav
        brew:
    "

    ["compare"]="
        pkg:    imagemagick
        apt:    imagemagick
        dnf:    ImageMagick
        pacman: imagemagick
        nix:    imagemagick
        zypper: ImageMagick
        guix:   imagemagick
        brew:
    "

    ["convert"]="
        pkg:    imagemagick
        apt:    imagemagick
        dnf:    ImageMagick
        pacman: imagemagick
        nix:    imagemagick
        zypper: ImageMagick
        guix:   imagemagick
        brew:
    "

    ["cpio"]="
        pkg:    cpio
        apt:    cpio
        dnf:    cpio
        pacman: cpio
        nix:    cpio
        zypper: cpio
        guix:   cpio
        brew:   cpio
    "

    ["curl"]="
        pkg:    curl
        apt:    curl
        dnf:    curl
        pacman: curl
        nix:    curl
        zypper: curl
        guix:   curl
        brew:
    "

    ["diffpdf"]="
        pkg:
        apt:    diffpdf
        dnf:    diffpdf
        pacman: diffpdf
        nix:    diffpdf
        zypper:
        guix:
        brew:
    "

    ["exiftool"]="
        pkg:    exiftool
        apt:    libimage-exiftool-perl
        dnf:    perl-Image-ExifTool
        pacman: perl-image-exiftool
        nix:    exiftool
        zypper: exiftool
        guix:   perl-image-exiftool
        brew:
    "

    ["ffmpeg"]="
        pkg:    ffmpeg
        apt:    ffmpeg
        dnf:    ffmpeg-free
        pacman: ffmpeg
        nix:    ffmpeg
        zypper: ffmpeg
        guix:   ffmpeg
        brew:
    "

    ["file-roller"]="
        pkg:    file-roller
        apt:    file-roller
        dnf:    file-roller
        pacman: file-roller
        nix:    file-roller
        zypper: file-roller
        guix:   file-roller
        brew:
    "

    ["filelight"]="
        pkg:    filelight
        apt:    filelight
        dnf:    filelight
        pacman: filelight
        nix:    kdePackages.filelight
        zypper: filelight
        guix:   filelight
        brew:
    "

    ["foremost"]="
        pkg:
        apt:    foremost
        dnf:    foremost
        pacman: foremost
        nix:    foremost
        zypper:
        guix:
        brew:   foremost
    "

    ["ghex"]="
        pkg:    ghex
        apt:    ghex
        dnf:    ghex
        pacman: ghex
        nix:    ghex
        zypper: ghex
        guix:   ghex
        brew:
    "

    ["git"]="
        pkg:    git
        apt:    git
        dnf:    git
        pacman: git
        nix:    git
        zypper: git
        guix:   git
        brew:
    "

    ["gpg"]="
        pkg:    gnupg
        apt:    gnupg
        dnf:    gnupg2
        pacman: gnupg
        nix:    gnupg
        zypper: gpg2
        guix:   gnupg
        brew:
    "

    ["gs"]="
        pkg:    ghostscript
        apt:    ghostscript
        dnf:    ghostscript
        pacman: ghostscript
        nix:    ghostscript
        zypper: ghostscript
        guix:   ghostscript
        brew:
    "

    ["gunzip"]="
        pkg:    gzip
        apt:    gzip
        dnf:    gzip
        pacman: gzip
        nix:    gzip
        zypper: gzip
        guix:   gzip
        brew:   gzip
    "

    ["gzip"]="
        pkg:    gzip
        apt:    gzip
        dnf:    gzip
        pacman: gzip
        nix:    gzip
        zypper: gzip
        guix:   gzip
        brew:   gzip
    "

    ["iconv"]="
        pkg:    libiconv
        apt:    libc-bin
        dnf:    glibc-common
        pacman: glibc
        nix:    glibc
        zypper: glibc
        guix:   glibc
        brew:
    "

    ["id3v2"]="
        pkg:    id3v2
        apt:    id3v2
        dnf:    id3v2
        pacman: id3v2
        nix:    id3v2
        zypper: id3v2
        guix:
        brew:   id3v2
    "

    ["inkscape"]="
        pkg:    inkscape
        apt:    inkscape
        dnf:    inkscape
        pacman: inkscape
        nix:    inkscape
        zypper: inkscape
        guix:   inkscape
        brew:
    "

    ["kdiff3"]="
        pkg:
        apt:    kdiff3
        dnf:    kdiff3
        pacman: kdiff3
        nix:    kdiff3
        zypper: kdiff3
        guix:
        brew:
    "

    ["lha"]="
        pkg:    lhasa
        apt:    lhasa
        dnf:    lhasa
        pacman: lhasa
        nix:    lhasa
        zypper: lhasa
        guix:   lhasa
        brew:   lhasa
    "

    ["lp"]="
        pkg:    cups
        apt:    cups-client
        dnf:    cups-client
        pacman: cups
        nix:    cups
        zypper: cups
        guix:   cups
        brew:
    "

    ["lrzip"]="
        pkg:    lrzip
        apt:    lrzip
        dnf:
        pacman: lrzip
        nix:    lrzip
        zypper: lrzip
        guix:   lrzip
        brew:   lrzip
    "

    ["lz4"]="
        pkg:    lz4
        apt:    lz4
        dnf:    lz4
        pacman: lz4
        nix:    lz4
        zypper: lz4
        guix:   lz4
        brew:   lz4
    "

    ["lzip"]="
        pkg:    lzip
        apt:    lzip
        dnf:    lzip
        pacman: lzip
        nix:    lzip
        zypper: lzip
        guix:   lzip
        brew:   lzip
    "

    ["lzma"]="
        pkg:    xz-utils
        apt:    xz-utils
        dnf:    lzma
        pacman: xz
        nix:    xz
        zypper: lzma
        guix:   xz
        brew:   xz
    "

    ["lzop"]="
        pkg:    lzop
        apt:    lzop
        dnf:    lzop
        pacman: lzop
        nix:    lzop
        zypper: lzop
        guix:   lzop
        brew:   lzop
    "

    ["mediainfo"]="
        pkg:    mediainfo
        apt:    mediainfo
        dnf:    mediainfo
        pacman: mediainfo
        nix:    mediainfo
        zypper: mediainfo
        guix:   mediainfo
        brew:
    "

    ["meld"]="
        pkg:    meld
        apt:    meld
        dnf:    meld
        pacman: meld
        nix:    meld
        zypper: meld
        guix:   meld
        brew:
    "

    ["mksquashfs"]="
        pkg:
        apt:    squashfs-tools
        dnf:    squashfs-tools
        pacman: squashfs-tools
        nix:    squashfsTools~squashfs
        zypper: squashfs
        guix:   squashfs-tools
        brew:   squashfs
    "

    ["mp3gain"]="
        pkg:    mp3gain
        apt:    mp3gain
        dnf:    mp3gain
        pacman:
        nix:    mp3gain
        zypper: mp3gain
        guix:
        brew:   mp3gain
    "

    ["mp3val"]="
        pkg:
        apt:    mp3val
        dnf:
        pacman:
        nix:    mp3val
        zypper:
        guix:
        brew:   mp3val
    "

    ["nmap"]="
        pkg:    nmap
        apt:    nmap
        dnf:    nmap
        pacman: nmap
        nix:    nmap
        zypper: nmap
        guix:   nmap
        brew:
    "

    ["okteta"]="
        pkg:
        apt:    okteta
        dnf:    okteta
        pacman: okteta
        nix:    okteta
        zypper: okteta
        guix:   okteta
        brew:
    "

    ["openssl"]="
        pkg:    openssl
        apt:    openssl
        dnf:    openssl
        pacman: openssl
        nix:    openssl
        zypper: openssl
        guix:   openssl
        brew:   openssl
    "

    ["optipng"]="
        pkg:    optipng
        apt:    optipng
        dnf:    optipng
        pacman: optipng
        nix:    optipng
        zypper: optipng
        guix:   optipng
        brew:   optipng
    "

    ["pandoc"]="
        pkg:    pandoc
        apt:    pandoc
        dnf:    pandoc
        pacman: pandoc
        nix:    pandoc
        zypper: pandoc
        guix:   pandoc
        brew:   pandoc
    "

    ["pdfinfo"]="
        pkg:    poppler
        apt:    poppler-utils
        dnf:    poppler-utils
        pacman: poppler
        nix:    poppler-utils
        zypper: poppler-tools
        guix:   poppler
        brew:
    "

    ["perl"]="
        pkg:    perl
        apt:    perl-base
        dnf:    perl-base
        pacman: perl-base
        nix:    perl
        zypper: perl-base
        guix:   perl
        brew:   perl
    "

    ["photorec"]="
        pkg:    testdisk
        apt:    testdisk
        dnf:    testdisk
        pacman: testdisk
        nix:    testdisk
        zypper: photorec
        guix:   testdisk
        brew:   testdisk
    "

    ["ping"]="
        pkg:    inetutils
        apt:    iputils-ping
        dnf:    iputils
        pacman: iputils
        nix:    iputils
        zypper: iputils
        guix:   iputils
        brew:   iputils
    "

    ["qpdf"]="
        pkg:    qpdf
        apt:    qpdf
        dnf:    qpdf
        pacman: qpdf
        nix:    qpdf
        zypper: qpdf
        guix:   qpdf
        brew:   qpdf
    "

    ["rdfind"]="
        pkg:    rdfind
        apt:    rdfind
        dnf:    rdfind
        pacman: rdfind
        nix:    rdfind
        zypper: rdfind
        guix:
        brew:   rdfind
    "

    ["rhash"]="
        pkg:    rhash
        apt:    rhash
        dnf:    rhash
        pacman: rhash
        nix:    rhash
        zypper: rhash
        guix:   rhash
        brew:   rhash
    "

    ["tar"]="
        pkg:    tar
        apt:    tar
        dnf:    tar
        pacman: tar
        nix:    gnutar
        zypper: tar
        guix:   tar
        brew:   gnu-tar
    "

    ["unar"]="
        pkg:    unar
        apt:    unar
        dnf:    unar
        pacman: unarchiver
        nix:    unar
        zypper: unar
        guix:
        brew:   unar
    "

    ["unrar"]="
        pkg:    unrar
        apt:    unrar
        dnf:    unrar
        pacman: unrar
        nix:    unrar
        zypper: unrar
        guix:
        brew:
    "

    ["unsquashfs"]="
        pkg:
        apt:    squashfs-tools
        dnf:    squashfs-tools
        pacman: squashfs-tools
        nix:    squashfsTools~squashfs
        zypper: squashfs
        guix:   squashfs-tools
        brew:   squashfs
    "

    ["unzip"]="
        pkg:    unzip
        apt:    unzip
        dnf:    unzip
        pacman: unzip
        nix:    unzip
        zypper: unzip
        guix:   unzip
        brew:   unzip
    "

    ["wl-paste"]="
        pkg:
        apt:    wl-clipboard
        dnf:    wl-clipboard
        pacman: wl-clipboard
        nix:    wl-clipboard
        zypper: wl-clipboard
        guix:   wl-clipboard
        brew:
    "

    ["xclip"]="
        pkg:    xclip
        apt:    xclip
        dnf:    xclip
        pacman: xclip
        nix:    xclip
        zypper: xclip
        guix:   xclip
        brew:
    "

    ["xorriso"]="
        pkg:    xorriso
        apt:    xorriso
        dnf:    xorriso
        pacman: xorriso
        nix:    xorriso~libisoburn
        zypper: xorriso
        guix:   xorriso
        brew:   xorriso
    "

    ["xxd"]="
        pkg:    xxd
        apt:    xxd
        dnf:    xxd
        pacman: xxd
        nix:    xxd
        zypper: xxd
        guix:   xxd
        brew:
    "

    ["xz"]="
        pkg:    xz-utils
        apt:    xz-utils
        dnf:    xz
        pacman: xz
        nix:    xz
        zypper: xz
        guix:   xz
        brew:   xz
    "

    ["zpaq"]="
        pkg:    zpaq
        apt:    zpaq
        dnf:    zpaq
        pacman:
        nix:    zpaq
        zypper: zpaq
        guix:   zpaq
        brew:   zpaq
    "

    ["zstd"]="
        pkg:    zstd
        apt:    zstd
        dnf:    zstd
        pacman: zstd
        nix:    zstd
        zypper: zstd
        guix:   zstd
        brew:   zstd
    "

    ["latexmk"]="
        pkg:    texlive-bin
        apt:    latexmk
        dnf:    latexmk
        pacman: texlive-binextra
        nix:    texlivePackages.latexmk~latexmk
        zypper: texlive-latexmk
        guix:
        brew:
    "

    ["localc"]="
        pkg:
        apt:    libreoffice-calc
        dnf:    libreoffice-calc
        pacman: libreoffice
        nix:    libreoffice
        zypper: libreoffice-calc
        guix:   libreoffice
        brew:
    "

    ["loimpress"]="
        pkg:
        apt:    libreoffice-impress
        dnf:    libreoffice-impress
        pacman: libreoffice
        nix:    libreoffice
        zypper: libreoffice-impress
        guix:   libreoffice
        brew:
    "

    ["lowriter"]="
        pkg:
        apt:    libreoffice-writer
        dnf:    libreoffice-writer
        pacman: libreoffice
        nix:    libreoffice
        zypper: libreoffice-writer
        guix:   libreoffice
        brew:
    "

    ["ocrmypdf"]="
        pkg:
        apt:    ocrmypdf
        dnf:    ocrmypdf
        pacman:
        nix:    ocrmypdf
        zypper:
        guix:
        brew:
    "

    ["pdfjam"]="
        pkg:    texlive-bin
        apt:    texlive-extra-utils
        dnf:    texlive-pdfjam
        pacman: texlive-basic texlive-binextra texlive-latexextra
        nix:    texliveSmall~texlive texlivePackages.pdfjam~pdfjam
        zypper: texlive-pdfjam-bin
        guix:
        brew:
    "

    ["sox"]="
        pkg:    sox
        apt:    sox libsox-fmt-mp3
        dnf:    sox
        pacman: sox
        nix:    sox
        zypper: sox
        guix:   sox
        brew:   sox
    "

    ["tesseract-lang-$TEMP_DATA_TASK"]="
        pkg:    tesseract
        apt:    tesseract-ocr-$TEMP_DATA_TASK
        dnf:    tesseract-langpack-$TEMP_DATA_TASK
        pacman: tesseract-data-$TEMP_DATA_TASK
        nix:    tesseract
        zypper: tesseract-ocr-traineddata-$TEMP_DATA_TASK
        guix:
        brew:
    "

    ["texlive"]="
        pkg: \
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
        guix:
        brew:
    "
)

# -----------------------------------------------------------------------------
# SECTION: POST_INSTALL ----
# -----------------------------------------------------------------------------
# This array defines commands that need to be executed after a package is
# installed. These commands are usually required for proper initialization,
# configuration, or updates that the package manager alone does not handle.

declare -A POST_INSTALL=(
    ["clamav"]='*:rm -f /var/log/clamav/freshclam.log; sed -i "/^NotifyClamd/d" /etc/clamav/freshclam.conf; freshclam --quiet'

    ["imagemagick"]='*:find /etc -type f -path "/etc/ImageMagick-*/policy.xml" 2>/dev/null -exec sed -i -e "s/rights=\"none\" pattern=\"PDF\"/rights=\"read|write\" pattern=\"PDF\"/g" -e "s/name=\"disk\" value=\".GiB\"/name=\"disk\" value=\"8GiB\"/g" {} +'
)
