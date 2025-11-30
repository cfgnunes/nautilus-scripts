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
        pkg:    p7zip
        apt:    p7zip-full
        dnf:    p7zip
        pacman: p7zip
        nix:    p7zip
        zypper: 7zip
        guix:   p7zip
        xbps:   p7zip
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
        xbps:   binutils
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
        xbps:   axel
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
        xbps:   baobab
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
        xbps:   bsdtar
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
        xbps:   bzip2
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
        xbps:   cabextract
        brew:   cabextract
    "

    ["cjxl"]="
        pkg:    libjxl-progs
        apt:    libjxl-tools
        dnf:    libjxl-utils
        pacman: libjxl
        nix:    libjxl
        zypper: libjxl-tools
        guix:   libjxl
        xbps:   libjxl-tools
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
        xbps:   clamav
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
        xbps:   ImageMagick
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
        xbps:   ImageMagick
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
        xbps:   cpio
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
        xbps:   curl
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
        xbps:
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
        xbps:   exiftool
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
        xbps:   ffmpeg
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
        xbps:   filelight
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
        xbps:   foremost
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
        xbps:   ghex
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
        xbps:   git
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
        xbps:   gnupg
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
        xbps:   ghostscript
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
        xbps:   gzip
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
        xbps:   gzip
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
        xbps:   glibc
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
        xbps:   id3v2
        brew:   id3v2
    "

    ["inkscape"]="
        pkg:
        apt:    inkscape
        dnf:    inkscape
        pacman: inkscape
        nix:    inkscape
        zypper: inkscape
        guix:   inkscape
        xbps:   inkscape
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
        xbps:   kdiff3
        brew:
    "

    ["lenspect"]="
        pkg:
        apt:
        dnf:
        pacman:
        nix:
        zypper:
        guix:
        brew:
        xbps:
        flatpak: io.github.vmkspv.lenspect
    "

    ["lha"]="
        pkg:    lhasa
        apt:    lhasa
        dnf:    lhasa
        pacman: lhasa
        nix:    lhasa
        zypper: lhasa
        guix:   lhasa
        xbps:   lhasa
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
        xbps:   cups
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
        xbps:   lrzip
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
        xbps:   lz4
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
        xbps:   lzip
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
        xbps:   xz
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
        xbps:   lzop
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
        xbps:   mediainfo
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
        xbps:   meld
        brew:
    "

    ["mp3gain"]="
        pkg:    mp3gain
        apt:    mp3gain
        dnf:    mp3gain
        pacman:
        nix:    mp3gain
        zypper: mp3gain
        guix:
        xbps:
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
        xbps:   mp3val
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
        xbps:   nmap
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
        xbps:   okteta
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
        xbps:   openssl
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
        xbps:   optipng
        brew:   optipng
    "

    ["pandoc"]="
        pkg:    pandoc
        apt:    pandoc
        dnf:    pandoc-cli
        pacman: pandoc
        nix:    pandoc
        zypper: pandoc
        guix:   pandoc
        xbps:   pandoc
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
        xbps:   poppler
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
        xbps:   perl
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
        xbps:   testdisk
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
        xbps:   iputils
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
        xbps:   qpdf
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
        xbps:   rdfind
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
        xbps:   rhash
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
        xbps:   tar
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
        xbps:   unar
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
        xbps:   unrar
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
        xbps:   squashfs-tools
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
        xbps:   unzip
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
        xbps:   wl-clipboard
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
        xbps:   xclip
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
        xbps:   xorriso
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
        xbps:   xxd
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
        xbps:   xz
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
        xbps:   zpaq
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
        xbps:   zstd
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
        xbps:   texlive-latexmk
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
        xbps:   libreoffice-calc
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
        xbps:   libreoffice-impress
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
        xbps:   libreoffice-writer
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
        xbps:   python3-ocrmypdf
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
        xbps:   texlive
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
        xbps:   sox
        brew:   sox
    "

    ["tesseract-lang-$TEMP_DATA_TASK"]="
        pkg:    tesseract
        apt:    tesseract tesseract-ocr-$TEMP_DATA_TASK
        dnf:    tesseract tesseract-langpack-$TEMP_DATA_TASK
        pacman: tesseract tesseract-data-$TEMP_DATA_TASK
        nix:    tesseract
        zypper: tesseract tesseract-ocr-traineddata-$TEMP_DATA_TASK
        guix:
        xbps:   tesseract tesseract-ocr-$TEMP_DAT_TASK
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
        xbps: \
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
