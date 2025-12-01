#!/usr/bin/env bash
# shellcheck disable=SC2034

# This file centralizes dependency definitions for the scripts.

#------------------------------------------------------------------------------
#region DEPENDENCIES_MAP
#------------------------------------------------------------------------------

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
        apt:    p7zip-full
        dnf:    p7zip
        pacman: p7zip
        nix:    p7zip
        zypper: 7zip
        guix:   p7zip
        xbps:   p7zip
        termux: p7zip
        brew:   p7zip
    "

    ["ar"]="
        apt:    binutils
        dnf:    binutils
        pacman: binutils
        nix:    binutils
        zypper: binutils
        guix:   binutils
        xbps:   binutils
        termux: binutils
        brew:   binutils
    "

    ["axel"]="
        apt:    axel
        dnf:    axel
        pacman: axel
        nix:    axel
        zypper: axel
        guix:   axel
        xbps:   axel
        termux: axel
        brew:   axel
    "

    ["baobab"]="
        apt:    baobab
        dnf:    baobab
        pacman: baobab
        nix:    baobab
        zypper: baobab
        guix:   baobab
        xbps:   baobab
        termux: baobab
        brew:
    "

    ["bsdtar"]="
        apt:    libarchive-tools
        dnf:    bsdtar
        pacman: libarchive
        nix:    libarchive
        zypper: bsdtar
        guix:   libarchive
        xbps:   bsdtar
        termux: libarchive
        brew:   libarchive
    "

    ["bzip2"]="
        apt:    bzip2
        dnf:    bzip2
        pacman: bzip2
        nix:    bzip2
        zypper: bzip2
        guix:   bzip2
        xbps:   bzip2
        termux: bzip2
        brew:   bzip2
    "

    ["cabextract"]="
        apt:    cabextract
        dnf:    cabextract
        pacman: cabextract
        nix:    cabextract
        zypper: cabextract
        guix:   cabextract
        xbps:   cabextract
        termux: cabextract
        brew:   cabextract
    "

    ["cjxl"]="
        apt:    libjxl-tools
        dnf:    libjxl-utils
        pacman: libjxl
        nix:    libjxl
        zypper: libjxl-tools
        guix:   libjxl
        xbps:   libjxl-tools
        termux: libjxl-progs
        brew:
    "

    ["clamscan"]="
        apt:    clamav
        dnf:    clamav
        pacman: clamav
        nix:    clamav
        zypper: clamav
        guix:   clamav
        xbps:   clamav
        termux: clamav
        brew:
    "

    ["compare"]="
        apt:    imagemagick
        dnf:    ImageMagick
        pacman: imagemagick
        nix:    imagemagick
        zypper: ImageMagick
        guix:   imagemagick
        xbps:   ImageMagick
        termux: imagemagick
        brew:
    "

    ["convert"]="
        apt:    imagemagick
        dnf:    ImageMagick
        pacman: imagemagick
        nix:    imagemagick
        zypper: ImageMagick
        guix:   imagemagick
        xbps:   ImageMagick
        termux: imagemagick
        brew:
    "

    ["cpio"]="
        apt:    cpio
        dnf:    cpio
        pacman: cpio
        nix:    cpio
        zypper: cpio
        guix:   cpio
        xbps:   cpio
        termux: cpio
        brew:   cpio
    "

    ["curl"]="
        apt:    curl
        dnf:    curl
        pacman: curl
        nix:    curl
        zypper: curl
        guix:   curl
        xbps:   curl
        termux: curl
        brew:
    "

    ["diffpdf"]="
        apt:    diffpdf
        dnf:    diffpdf
        pacman: diffpdf
        nix:    diffpdf
        zypper:
        guix:
        xbps:
        termux:
        brew:
    "

    ["exiftool"]="
        apt:    libimage-exiftool-perl
        dnf:    perl-Image-ExifTool
        pacman: perl-image-exiftool
        nix:    exiftool
        zypper: exiftool
        guix:   perl-image-exiftool
        xbps:   exiftool
        termux: exiftool
        brew:
    "

    ["ffmpeg"]="
        apt:    ffmpeg
        dnf:    ffmpeg-free
        pacman: ffmpeg
        nix:    ffmpeg
        zypper: ffmpeg
        guix:   ffmpeg
        xbps:   ffmpeg
        termux: ffmpeg
        brew:
    "

    ["filelight"]="
        apt:    filelight
        dnf:    filelight
        pacman: filelight
        nix:    kdePackages.filelight
        zypper: filelight
        guix:   filelight
        xbps:   filelight
        termux: filelight
        brew:
    "

    ["foremost"]="
        apt:    foremost
        dnf:    foremost
        pacman: foremost
        nix:    foremost
        zypper:
        guix:
        xbps:   foremost
        termux:
        brew:   foremost
    "

    ["ghex"]="
        apt:    ghex
        dnf:    ghex
        pacman: ghex
        nix:    ghex
        zypper: ghex
        guix:   ghex
        xbps:   ghex
        termux: ghex
        brew:
    "

    ["git"]="
        apt:    git
        dnf:    git
        pacman: git
        nix:    git
        zypper: git
        guix:   git
        xbps:   git
        termux: git
        brew:
    "

    ["gpg"]="
        apt:    gnupg
        dnf:    gnupg2
        pacman: gnupg
        nix:    gnupg
        zypper: gpg2
        guix:   gnupg
        xbps:   gnupg
        termux: gnupg
        brew:
    "

    ["gs"]="
        apt:    ghostscript
        dnf:    ghostscript
        pacman: ghostscript
        nix:    ghostscript
        zypper: ghostscript
        guix:   ghostscript
        xbps:   ghostscript
        termux: ghostscript
        brew:
    "

    ["gunzip"]="
        apt:    gzip
        dnf:    gzip
        pacman: gzip
        nix:    gzip
        zypper: gzip
        guix:   gzip
        xbps:   gzip
        termux: gzip
        brew:   gzip
    "

    ["gzip"]="
        apt:    gzip
        dnf:    gzip
        pacman: gzip
        nix:    gzip
        zypper: gzip
        guix:   gzip
        xbps:   gzip
        termux: gzip
        brew:   gzip
    "

    ["iconv"]="
        apt:    libc-bin
        dnf:    glibc-common
        pacman: glibc
        nix:    glibc
        zypper: glibc
        guix:   glibc
        xbps:   glibc
        termux: libiconv
        brew:
    "

    ["id3v2"]="
        apt:    id3v2
        dnf:    id3v2
        pacman: id3v2
        nix:    id3v2
        zypper: id3v2
        guix:
        xbps:   id3v2
        termux: id3v2
        brew:   id3v2
    "

    ["inkscape"]="
        apt:    inkscape
        dnf:    inkscape
        pacman: inkscape
        nix:    inkscape
        zypper: inkscape
        guix:   inkscape
        xbps:   inkscape
        termux:
        brew:
    "

    ["kdiff3"]="
        apt:    kdiff3
        dnf:    kdiff3
        pacman: kdiff3
        nix:    kdiff3
        zypper: kdiff3
        guix:
        xbps:   kdiff3
        termux:
        brew:
    "

    ["lenspect"]="
        apt:
        dnf:
        pacman:
        nix:
        zypper:
        guix:
        xbps:
        termux:
        brew:
        flatpak: io.github.vmkspv.lenspect
    "

    ["lha"]="
        apt:    lhasa
        dnf:    lhasa
        pacman: lhasa
        nix:    lhasa
        zypper: lhasa
        guix:   lhasa
        xbps:   lhasa
        termux: lhasa
        brew:   lhasa
    "

    ["lp"]="
        apt:    cups-client
        dnf:    cups-client
        pacman: cups
        nix:    cups
        zypper: cups
        guix:   cups
        xbps:   cups
        termux: cups
        brew:
    "

    ["lrzip"]="
        apt:    lrzip
        dnf:
        pacman: lrzip
        nix:    lrzip
        zypper: lrzip
        guix:   lrzip
        xbps:   lrzip
        termux: lrzip
        brew:   lrzip
    "

    ["lz4"]="
        apt:    lz4
        dnf:    lz4
        pacman: lz4
        nix:    lz4
        zypper: lz4
        guix:   lz4
        xbps:   lz4
        termux: lz4
        brew:   lz4
    "

    ["lzip"]="
        apt:    lzip
        dnf:    lzip
        pacman: lzip
        nix:    lzip
        zypper: lzip
        guix:   lzip
        xbps:   lzip
        termux: lzip
        brew:   lzip
    "

    ["lzma"]="
        apt:    xz-utils
        dnf:    lzma
        pacman: xz
        nix:    xz
        zypper: lzma
        guix:   xz
        xbps:   xz
        termux: xz-utils
        brew:   xz
    "

    ["lzop"]="
        apt:    lzop
        dnf:    lzop
        pacman: lzop
        nix:    lzop
        zypper: lzop
        guix:   lzop
        xbps:   lzop
        termux: lzop
        brew:   lzop
    "

    ["mediainfo"]="
        apt:    mediainfo
        dnf:    mediainfo
        pacman: mediainfo
        nix:    mediainfo
        zypper: mediainfo
        guix:   mediainfo
        xbps:   mediainfo
        termux: mediainfo
        brew:
    "

    ["meld"]="
        apt:    meld
        dnf:    meld
        pacman: meld
        nix:    meld
        zypper: meld
        guix:   meld
        xbps:   meld
        termux: meld
        brew:
    "

    ["mp3gain"]="
        apt:    mp3gain
        dnf:    mp3gain
        pacman:
        nix:    mp3gain
        zypper: mp3gain
        guix:
        xbps:
        termux: mp3gain
        brew:   mp3gain
    "

    ["mp3val"]="
        apt:    mp3val
        dnf:
        pacman:
        nix:    mp3val
        zypper:
        guix:
        xbps:   mp3val
        termux:
        brew:   mp3val
    "

    ["nmap"]="
        apt:    nmap
        dnf:    nmap
        pacman: nmap
        nix:    nmap
        zypper: nmap
        guix:   nmap
        xbps:   nmap
        termux: nmap
        brew:
    "

    ["okteta"]="
        apt:    okteta
        dnf:    okteta
        pacman: okteta
        nix:    okteta
        zypper: okteta
        guix:   okteta
        xbps:   okteta
        termux:
        brew:
    "

    ["openssl"]="
        apt:    openssl
        dnf:    openssl
        pacman: openssl
        nix:    openssl
        zypper: openssl
        guix:   openssl
        xbps:   openssl
        termux: openssl
        brew:   openssl
    "

    ["optipng"]="
        apt:    optipng
        dnf:    optipng
        pacman: optipng
        nix:    optipng
        zypper: optipng
        guix:   optipng
        xbps:   optipng
        termux: optipng
        brew:   optipng
    "

    ["pandoc"]="
        apt:    pandoc
        dnf:    pandoc-cli
        pacman: pandoc
        nix:    pandoc
        zypper: pandoc
        guix:   pandoc
        xbps:   pandoc
        termux: pandoc
        brew:   pandoc
    "

    ["pdfinfo"]="
        apt:    poppler-utils
        dnf:    poppler-utils
        pacman: poppler
        nix:    poppler-utils
        zypper: poppler-tools
        guix:   poppler
        xbps:   poppler
        termux: poppler
        brew:
    "

    ["perl"]="
        apt:    perl-base
        dnf:    perl-base
        pacman: perl-base
        nix:    perl
        zypper: perl-base
        guix:   perl
        xbps:   perl
        termux: perl
        brew:   perl
    "

    ["photorec"]="
        apt:    testdisk
        dnf:    testdisk
        pacman: testdisk
        nix:    testdisk
        zypper: photorec
        guix:   testdisk
        xbps:   testdisk
        termux: testdisk
        brew:   testdisk
    "

    ["ping"]="
        apt:    iputils-ping
        dnf:    iputils
        pacman: iputils
        nix:    iputils
        zypper: iputils
        guix:   iputils
        xbps:   iputils
        termux: inetutils
        brew:   iputils
    "

    ["qpdf"]="
        apt:    qpdf
        dnf:    qpdf
        pacman: qpdf
        nix:    qpdf
        zypper: qpdf
        guix:   qpdf
        xbps:   qpdf
        termux: qpdf
        brew:   qpdf
    "

    ["rdfind"]="
        apt:    rdfind
        dnf:    rdfind
        pacman: rdfind
        nix:    rdfind
        zypper: rdfind
        guix:
        xbps:   rdfind
        termux: rdfind
        brew:   rdfind
    "

    ["rhash"]="
        apt:    rhash
        dnf:    rhash
        pacman: rhash
        nix:    rhash
        zypper: rhash
        guix:   rhash
        xbps:   rhash
        termux: rhash
        brew:   rhash
    "

    ["tar"]="
        apt:    tar
        dnf:    tar
        pacman: tar
        nix:    gnutar
        zypper: tar
        guix:   tar
        xbps:   tar
        termux: tar
        brew:   gnu-tar
    "

    ["unar"]="
        apt:    unar
        dnf:    unar
        pacman: unarchiver
        nix:    unar
        zypper: unar
        guix:
        xbps:   unar
        termux: unar
        brew:   unar
    "

    ["unrar"]="
        apt:    unrar
        dnf:    unrar
        pacman: unrar
        nix:    unrar
        zypper: unrar
        guix:
        xbps:   unrar
        termux: unrar
        brew:
    "

    ["unsquashfs"]="
        apt:    squashfs-tools
        dnf:    squashfs-tools
        pacman: squashfs-tools
        nix:    squashfsTools~squashfs
        zypper: squashfs
        guix:   squashfs-tools
        xbps:   squashfs-tools
        termux:
        brew:   squashfs
    "

    ["unzip"]="
        apt:    unzip
        dnf:    unzip
        pacman: unzip
        nix:    unzip
        zypper: unzip
        guix:   unzip
        xbps:   unzip
        termux: unzip
        brew:   unzip
    "

    ["wl-paste"]="
        apt:    wl-clipboard
        dnf:    wl-clipboard
        pacman: wl-clipboard
        nix:    wl-clipboard
        zypper: wl-clipboard
        guix:   wl-clipboard
        xbps:   wl-clipboard
        termux:
        brew:
    "

    ["xclip"]="
        apt:    xclip
        dnf:    xclip
        pacman: xclip
        nix:    xclip
        zypper: xclip
        guix:   xclip
        xbps:   xclip
        termux: xclip
        brew:
    "

    ["xorriso"]="
        apt:    xorriso
        dnf:    xorriso
        pacman: xorriso
        nix:    xorriso~libisoburn
        zypper: xorriso
        guix:   xorriso
        xbps:   xorriso
        termux: xorriso
        brew:   xorriso
    "

    ["xxd"]="
        apt:    xxd
        dnf:    xxd
        pacman: xxd
        nix:    xxd
        zypper: xxd
        guix:   xxd
        xbps:   xxd
        termux: xxd
        brew:
    "

    ["xz"]="
        apt:    xz-utils
        dnf:    xz
        pacman: xz
        nix:    xz
        zypper: xz
        guix:   xz
        xbps:   xz
        termux: xz-utils
        brew:   xz
    "

    ["zpaq"]="
        apt:    zpaq
        dnf:    zpaq
        pacman:
        nix:    zpaq
        zypper: zpaq
        guix:   zpaq
        xbps:   zpaq
        termux: zpaq
        brew:   zpaq
    "

    ["zstd"]="
        apt:    zstd
        dnf:    zstd
        pacman: zstd
        nix:    zstd
        zypper: zstd
        guix:   zstd
        xbps:   zstd
        termux: zstd
        brew:   zstd
    "

    ["latexmk"]="
        apt:    latexmk
        dnf:    latexmk
        pacman: texlive-binextra
        nix:    texlivePackages.latexmk~latexmk
        zypper: texlive-latexmk
        guix:
        xbps:   texlive-latexmk
        termux: texlive-bin
        brew:
    "

    ["localc"]="
        apt:    libreoffice-calc
        dnf:    libreoffice-calc
        pacman: libreoffice
        nix:    libreoffice
        zypper: libreoffice-calc
        guix:   libreoffice
        xbps:   libreoffice-calc
        termux:
        brew:
    "

    ["loimpress"]="
        apt:    libreoffice-impress
        dnf:    libreoffice-impress
        pacman: libreoffice
        nix:    libreoffice
        zypper: libreoffice-impress
        guix:   libreoffice
        xbps:   libreoffice-impress
        termux:
        brew:
    "

    ["lowriter"]="
        apt:    libreoffice-writer
        dnf:    libreoffice-writer
        pacman: libreoffice
        nix:    libreoffice
        zypper: libreoffice-writer
        guix:   libreoffice
        xbps:   libreoffice-writer
        termux:
        brew:
    "

    ["ocrmypdf"]="
        apt:    ocrmypdf
        dnf:    ocrmypdf
        pacman:
        nix:    ocrmypdf
        zypper:
        guix:
        xbps:   python3-ocrmypdf
        termux:
        brew:
    "

    ["pdfjam"]="
        apt:    texlive-extra-utils
        dnf:    texlive-pdfjam
        pacman: texlive-basic texlive-binextra texlive-latexextra
        nix:    texliveSmall~texlive texlivePackages.pdfjam~pdfjam
        zypper: texlive-pdfjam-bin
        guix:
        xbps:   texlive
        termux: texlive-bin
        brew:
    "

    ["sox"]="
        apt:    sox libsox-fmt-mp3
        dnf:    sox
        pacman: sox
        nix:    sox
        zypper: sox
        guix:   sox
        xbps:   sox
        termux: sox
        brew:   sox
    "

    ["tesseract-lang-$TEMP_DATA_TASK"]="
        apt:    tesseract tesseract-ocr-$TEMP_DATA_TASK
        dnf:    tesseract tesseract-langpack-$TEMP_DATA_TASK
        pacman: tesseract tesseract-data-$TEMP_DATA_TASK
        nix:    tesseract
        zypper: tesseract tesseract-ocr-traineddata-$TEMP_DATA_TASK
        guix:
        xbps:   tesseract tesseract-ocr-$TEMP_DATA_TASK
        termux: tesseract
        brew:
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
        guix:
        xbps: \
            texlive-bin
        termux: \
            texlive-bin
        brew:
    "
)

#endregion
#------------------------------------------------------------------------------
#region POST_INSTALL
#------------------------------------------------------------------------------

# This array defines commands that need to be executed after a package is
# installed. These commands are usually required for proper initialization,
# configuration, or updates that the package manager alone does not handle.
declare -A POST_INSTALL=(
    ["clamav"]='*:rm -f /var/log/clamav/freshclam.log; sed -i "/^NotifyClamd/d" /etc/clamav/freshclam.conf 2>/dev/null; freshclam --quiet'

    ["imagemagick"]='*:find /etc -type f -path "/etc/ImageMagick-*/policy.xml" 2>/dev/null -exec sed -i -e "s/rights=\"none\" pattern=\"PDF\"/rights=\"read|write\" pattern=\"PDF\"/g" -e "s/name=\"disk\" value=\".GiB\"/name=\"disk\" value=\"8GiB\"/g" {} +'
)

#endregion
