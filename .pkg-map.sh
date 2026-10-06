#!/usr/bin/env bash
# shellcheck disable=SC2034

# This file centralizes dependency definitions for the scripts.

# Description:
#   This array defines the mapping between a dependency key and its
#   corresponding package names across different package managers.
#
# Note: If the package name contains the '~' character, it means that the part
# before '~' represents the package name used for installation, while the part
# after '~' represents the package name used for installation verification.
# This is useful in systems like NixOS, where the installed package name may
# differ from the one provided during installation.
declare -A PKG_MAP=(
    ["7za"]="
        termux: p7zip
        apt:    p7zip
        dnf:    p7zip
        pacman: p7zip
        nix:    p7zip
        zypper: 7zip
        guix:   p7zip
        xbps:   p7zip
        pkgx:   github.com/p7zip-project/p7zip
    "

    ["ar"]="
        termux: binutils
        apt:    binutils
        dnf:    binutils
        pacman: binutils
        nix:    binutils
        zypper: binutils
        guix:   binutils
        xbps:   binutils
        pkgx:   gnu.org/binutils
    "

    ["axel"]="
        termux: axel
        apt:    axel
        dnf:    axel
        pacman: axel
        nix:    axel
        zypper: axel
        guix:   axel
        xbps:   axel
        pkgx:
    "

    ["baobab"]="
        termux: baobab
        apt:    baobab
        dnf:    baobab
        pacman: baobab
        nix:    baobab
        zypper: baobab
        guix:   baobab
        xbps:   baobab
        pkgx:
    "

    ["bsdtar"]="
        termux: libarchive
        apt:    libarchive-tools
        dnf:    bsdtar
        pacman: libarchive
        nix:    libarchive
        zypper: bsdtar
        guix:   libarchive
        xbps:   bsdtar
        pkgx:   libarchive.org
    "

    ["bzip2"]="
        termux: bzip2
        apt:    bzip2
        dnf:    bzip2
        pacman: bzip2
        nix:    bzip2
        zypper: bzip2
        guix:   bzip2
        xbps:   bzip2
        pkgx:   sourceware.org/bzip2
    "

    ["bzip3"]="
        termux: bzip3
        apt:    bzip3
        dnf:    bzip3
        pacman: bzip3
        nix:    bzip3
        zypper: bzip3
        guix:
        xbps:   bzip3
        pkgx:
    "

    ["cabextract"]="
        termux: cabextract
        apt:    cabextract
        dnf:    cabextract
        pacman: cabextract
        nix:    cabextract
        zypper: cabextract
        guix:   cabextract
        xbps:   cabextract
        pkgx:
    "

    ["cjxl"]="
        termux: libjxl-progs
        apt:    libjxl-tools
        dnf:    libjxl-utils
        pacman: libjxl
        nix:    libjxl
        zypper: libjxl-tools
        guix:   libjxl
        xbps:   libjxl-tools
        pkgx:   jpeg.org/jpegxl openexr.com@3.4
    "

    ["clamscan"]="
        termux: clamav
        apt:    clamav
        dnf:    clamav
        pacman: clamav
        nix:    clamav
        zypper: clamav
        guix:   clamav
        xbps:   clamav
        pkgx:
    "

    ["compare"]="
        termux: imagemagick
        apt:    imagemagick
        dnf:    ImageMagick
        pacman: imagemagick
        nix:    imagemagick
        zypper: ImageMagick
        guix:   imagemagick
        xbps:   ImageMagick
        pkgx:   imagemagick.org
    "

    ["convert"]="
        termux: imagemagick
        apt:    imagemagick
        dnf:    ImageMagick
        pacman: imagemagick
        nix:    imagemagick
        zypper: ImageMagick
        guix:   imagemagick
        xbps:   ImageMagick
        pkgx:   imagemagick.org
    "

    ["cpio"]="
        termux: cpio
        apt:    cpio
        dnf:    cpio
        pacman: cpio
        nix:    cpio
        zypper: cpio
        guix:   cpio
        xbps:   cpio
        pkgx:
    "

    ["curl"]="
        termux: curl
        apt:    curl
        dnf:    curl
        pacman: curl
        nix:    curl
        zypper: curl
        guix:   curl
        xbps:   curl
        pkgx:   curl.se
    "

    ["dar"]="
        termux: dar
        apt:    dar
        dnf:    dar
        pacman: dar
        nix:    dar
        zypper: dar
        guix:
        xbps:   dar
        pkgx:
    "

    ["diffpdf"]="
        termux:
        apt:    diffpdf
        dnf:    diffpdf
        pacman: diffpdf
        nix:    diffpdf
        zypper:
        guix:
        xbps:
        pkgx:
    "

    ["dig"]="
        termux: dnsutils
        apt:    bind9-dnsutils
        dnf:    bind-utils
        pacman: bind
        nix:    dnsutils
        zypper: bind-utils
        guix:   bind
        xbps:   bind
        pkgx:   isc.org/bind9
    "

    # FIXME: The 'exiftool.org' of pkgx is not working.
    ["exiftool"]="
        termux: exiftool
        apt:    libimage-exiftool-perl
        dnf:    perl-Image-ExifTool
        pacman: perl-image-exiftool
        nix:    exiftool
        zypper: exiftool
        guix:   perl-image-exiftool
        xbps:   exiftool
        pkgx:
    "

    ["ffmpeg"]="
        termux: ffmpeg
        apt:    ffmpeg
        dnf:    ffmpeg-free
        pacman: ffmpeg
        nix:    ffmpeg
        zypper: ffmpeg
        guix:   ffmpeg
        xbps:   ffmpeg
        pkgx:   ffmpeg.org
    "

    ["filelight"]="
        termux: filelight
        apt:    filelight
        dnf:    filelight
        pacman: filelight
        nix:    kdePackages.filelight
        zypper: filelight
        guix:   filelight
        xbps:   filelight
        pkgx:
    "

    ["foremost"]="
        termux:
        apt:    foremost
        dnf:    foremost
        pacman: foremost
        nix:    foremost
        zypper:
        guix:
        xbps:   foremost
        pkgx:
    "

    ["ghex"]="
        termux: ghex
        apt:    ghex
        dnf:    ghex
        pacman: ghex
        nix:    ghex
        zypper: ghex
        guix:   ghex
        xbps:   ghex
        pkgx:
    "

    ["git"]="
        termux: git
        apt:    git
        dnf:    git
        pacman: git
        nix:    git
        zypper: git
        guix:   git
        xbps:   git
        pkgx:   git-scm.org
    "

    ["gpg"]="
        termux: gnupg
        apt:    gnupg
        dnf:    gnupg2
        pacman: gnupg
        nix:    gnupg
        zypper: gpg2
        guix:   gnupg
        xbps:   gnupg
        pkgx:   gnupg.org
    "

    ["gs"]="
        termux: ghostscript
        apt:    ghostscript
        dnf:    ghostscript
        pacman: ghostscript
        nix:    ghostscript
        zypper: ghostscript
        guix:   ghostscript
        xbps:   ghostscript
        pkgx:   ghostscript.com
    "

    ["gunzip"]="
        termux: gzip
        apt:    gzip
        dnf:    gzip
        pacman: gzip
        nix:    gzip
        zypper: gzip
        guix:   gzip
        xbps:   gzip
        pkgx:
    "

    ["gzip"]="
        termux: gzip
        apt:    gzip
        dnf:    gzip
        pacman: gzip
        nix:    gzip
        zypper: gzip
        guix:   gzip
        xbps:   gzip
        pkgx:
    "

    ["iconv"]="
        termux: libiconv
        apt:    libc-bin
        dnf:    glibc-common
        pacman: glibc
        nix:    glibc
        zypper: glibc
        guix:   glibc
        xbps:   glibc
        pkgx:   gnu.org/glibc
    "

    ["id3v2"]="
        termux: id3v2
        apt:    id3v2
        dnf:    id3v2
        pacman: id3v2
        nix:    id3v2
        zypper: id3v2
        guix:
        xbps:   id3v2
        pkgx:
    "

    ["inkscape"]="
        termux:
        apt:    inkscape
        dnf:    inkscape
        pacman: inkscape
        nix:    inkscape
        zypper: inkscape
        guix:   inkscape
        xbps:   inkscape
        pkgx:
    "

    ["kdiff3"]="
        termux:
        apt:    kdiff3
        dnf:    kdiff3
        pacman: kdiff3
        nix:    kdiff3
        zypper: kdiff3
        guix:
        xbps:   kdiff3
        pkgx:
    "

    ["lenspect"]="
        termux:
        apt:
        dnf:
        pacman:
        nix:
        zypper:
        guix:
        xbps:
        pkgx:
        flatpak: io.github.vmkspv.lenspect
    "

    ["lha"]="
        termux: lhasa
        apt:    lhasa
        dnf:    lhasa
        pacman: lhasa
        nix:    lhasa
        zypper: lhasa
        guix:   lhasa
        xbps:   lhasa
        pkgx:
    "

    ["lrzip"]="
        termux: lrzip
        apt:    lrzip
        dnf:
        pacman: lrzip
        nix:    lrzip
        zypper: lrzip
        guix:   lrzip
        xbps:   lrzip
        pkgx:
    "

    ["lz4"]="
        termux: lz4
        apt:    lz4
        dnf:    lz4
        pacman: lz4
        nix:    lz4
        zypper: lz4
        guix:   lz4
        xbps:   lz4
        pkgx:   lz4.org
    "

    ["lzip"]="
        termux: lzip
        apt:    lzip
        dnf:    lzip
        pacman: lzip
        nix:    lzip
        zypper: lzip
        guix:   lzip
        xbps:   lzip
        pkgx:   nongnu.org/lzip
    "

    ["lzma"]="
        termux: xz-utils
        apt:    xz-utils
        dnf:    lzma
        pacman: xz
        nix:    xz
        zypper: lzma
        guix:   xz
        xbps:   xz
        pkgx:   tukaani.org/xz
    "

    ["lzop"]="
        termux: lzop
        apt:    lzop
        dnf:    lzop
        pacman: lzop
        nix:    lzop
        zypper: lzop
        guix:   lzop
        xbps:   lzop
        pkgx:
    "

    ["mediainfo"]="
        termux: mediainfo
        apt:    mediainfo
        dnf:    mediainfo
        pacman: mediainfo
        nix:    mediainfo
        zypper: mediainfo
        guix:   mediainfo
        xbps:   mediainfo
        pkgx:
    "

    ["meld"]="
        termux: meld
        apt:    meld
        dnf:    meld
        pacman: meld
        nix:    meld
        zypper: meld
        guix:   meld
        xbps:   meld
        pkgx:
    "

    ["mp3gain"]="
        termux: mp3gain
        apt:    mp3gain
        dnf:    mp3gain
        pacman:
        nix:    mp3gain
        zypper: mp3gain
        guix:
        xbps:
        pkgx:
    "

    ["nmap"]="
        termux: nmap
        apt:    nmap
        dnf:    nmap
        pacman: nmap
        nix:    nmap
        zypper: nmap
        guix:   nmap
        xbps:   nmap
        pkgx:   nmap.org
    "

    ["okteta"]="
        termux:
        apt:    okteta
        dnf:    okteta
        pacman: okteta
        nix:    okteta
        zypper: okteta
        guix:   okteta
        xbps:   okteta
        pkgx:
    "

    ["openssl"]="
        termux: openssl
        apt:    openssl
        dnf:    openssl
        pacman: openssl
        nix:    openssl
        zypper: openssl
        guix:   openssl
        xbps:   openssl
        pkgx:   openssl.org
    "

    ["optipng"]="
        termux: optipng
        apt:    optipng
        dnf:    optipng
        pacman: optipng
        nix:    optipng
        zypper: optipng
        guix:   optipng
        xbps:   optipng
        pkgx:   sf.net/optipng
    "

    ["pandoc"]="
        termux: pandoc
        apt:    pandoc
        dnf:    pandoc-cli
        pacman: pandoc
        nix:    pandoc
        zypper: pandoc
        guix:   pandoc
        xbps:   pandoc
        pkgx:   pandoc.org
    "

    ["pdfinfo"]="
        termux: poppler
        apt:    poppler-utils
        dnf:    poppler-utils
        pacman: poppler
        nix:    poppler-utils
        zypper: poppler-tools
        guix:   poppler
        xbps:   poppler
        pkgx:   poppler.freedesktop.org
    "

    ["perl"]="
        termux: perl
        apt:    perl-base
        dnf:    perl-base
        pacman: perl-base
        nix:    perl
        zypper: perl-base
        guix:   perl
        xbps:   perl
        pkgx:   perl.org
    "

    ["photorec"]="
        termux: testdisk
        apt:    testdisk
        dnf:    testdisk
        pacman: testdisk
        nix:    testdisk
        zypper: photorec
        guix:   testdisk
        xbps:   testdisk
        pkgx:
    "

    ["ping"]="
        termux: inetutils
        apt:    iputils-ping
        dnf:    iputils
        pacman: iputils
        nix:    iputils
        zypper: iputils
        guix:   iputils
        xbps:   iputils
        pkgx:   gnu.org/inetutils
    "

    ["qpdf"]="
        termux: qpdf
        apt:    qpdf
        dnf:    qpdf
        pacman: qpdf
        nix:    qpdf
        zypper: qpdf
        guix:   qpdf
        xbps:   qpdf
        pkgx:   qpdf.sourceforge.io
    "

    ["rdfind"]="
        termux: rdfind
        apt:    rdfind
        dnf:    rdfind
        pacman: rdfind
        nix:    rdfind
        zypper: rdfind
        guix:
        xbps:   rdfind
        pkgx:
    "

    ["rhash"]="
        termux: rhash
        apt:    rhash
        dnf:    rhash
        pacman: rhash
        nix:    rhash
        zypper: rhash
        guix:   rhash
        xbps:   rhash
        pkgx:   rhash.sourceforge.net
    "

    ["rsync"]="
        termux: rsync
        apt:    rsync
        dnf:    rsync
        pacman: rsync
        nix:    rsync
        zypper: rsync
        guix:   rsync
        xbps:   rsync
        pkgx:   rsync.samba.org
    "

    ["tar"]="
        termux: tar
        apt:    tar
        dnf:    tar
        pacman: tar
        nix:    gnutar
        zypper: tar
        guix:   tar
        xbps:   tar
        pkgx:   gnu.org/tar
    "

    ["unar"]="
        termux: unar
        apt:    unar
        dnf:    unar
        pacman: unarchiver
        nix:    unar
        zypper: unar
        guix:
        xbps:   unar
        pkgx:
    "

    ["unrar"]="
        termux: unrar
        apt:    unrar
        dnf:    unrar
        pacman: unrar
        nix:    unrar
        zypper: unrar
        guix:
        xbps:   unrar
        pkgx:   rarlab.com
    "

    ["unsquashfs"]="
        termux:
        apt:    squashfs-tools
        dnf:    squashfs-tools
        pacman: squashfs-tools
        nix:    squashfsTools~squashfs
        zypper: squashfs
        guix:   squashfs-tools
        xbps:   squashfs-tools
        pkgx:   github.com/plougher/squashfs-tools
    "

    ["unzip"]="
        termux: unzip
        apt:    unzip
        dnf:    unzip
        pacman: unzip
        nix:    unzip
        zypper: unzip
        guix:   unzip
        xbps:   unzip
        pkgx:   info-zip.org/unzip
    "

    ["wl-paste"]="
        termux:
        apt:    wl-clipboard
        dnf:    wl-clipboard
        pacman: wl-clipboard
        nix:    wl-clipboard
        zypper: wl-clipboard
        guix:   wl-clipboard
        xbps:   wl-clipboard
        pkgx:
    "

    ["xclip"]="
        termux: xclip
        apt:    xclip
        dnf:    xclip
        pacman: xclip
        nix:    xclip
        zypper: xclip
        guix:   xclip
        xbps:   xclip
        pkgx:
    "

    ["xorriso"]="
        termux: xorriso
        apt:    xorriso
        dnf:    xorriso
        pacman: xorriso
        nix:    xorriso~libisoburn
        zypper: xorriso
        guix:   xorriso
        xbps:   xorriso
        pkgx:
    "

    ["xxd"]="
        termux: xxd
        apt:    xxd
        dnf:    xxd
        pacman: xxd
        nix:    xxd
        zypper: xxd
        guix:   xxd
        xbps:   xxd
        pkgx:
    "

    ["xz"]="
        termux: xz-utils
        apt:    xz-utils
        dnf:    xz
        pacman: xz
        nix:    xz
        zypper: xz
        guix:   xz
        xbps:   xz
        pkgx:   tukaani.org/xz
    "

    ["zpaq"]="
        termux: zpaq
        apt:    zpaq
        dnf:    zpaq
        pacman:
        nix:    zpaq
        zypper: zpaq
        guix:   zpaq
        xbps:   zpaq
        pkgx:
    "

    ["zstd"]="
        termux: zstd
        apt:    zstd
        dnf:    zstd
        pacman: zstd
        nix:    zstd
        zypper: zstd
        guix:   zstd
        xbps:   zstd
        pkgx:   facebook.com/zstd
    "

    ["latexmk"]="
        termux: texlive-bin
        apt:    latexmk
        dnf:    latexmk
        pacman: texlive-binextra
        nix:    texlivePackages.latexmk~latexmk
        zypper: texlive-latexmk
        guix:   texlive-bin
        xbps:   texlive-latexmk
        pkgx:
    "

    ["localc"]="
        termux:
        apt:    libreoffice-calc
        dnf:    libreoffice-calc
        pacman: libreoffice
        nix:    libreoffice
        zypper: libreoffice-calc
        guix:   libreoffice
        xbps:   libreoffice-calc
        pkgx:
    "

    ["loimpress"]="
        termux:
        apt:    libreoffice-impress
        dnf:    libreoffice-impress
        pacman: libreoffice
        nix:    libreoffice
        zypper: libreoffice-impress
        guix:   libreoffice
        xbps:   libreoffice-impress
        pkgx:
    "

    ["lowriter"]="
        termux:
        apt:    libreoffice-writer
        dnf:    libreoffice-writer
        pacman: libreoffice
        nix:    libreoffice
        zypper: libreoffice-writer
        guix:   libreoffice
        xbps:   libreoffice-writer
        pkgx:
    "

    ["ocrmypdf"]="
        termux:
        apt:    ocrmypdf
        dnf:    ocrmypdf
        pacman:
        nix:    ocrmypdf
        zypper:
        guix:
        xbps:   python3-ocrmypdf
        pkgx:   github.com/ocrmypdf/OCRmyPDF
    "

    ["pdfjam"]="
        termux: texlive-bin
        apt:    texlive-extra-utils
        dnf:    texlive-pdfjam
        pacman: texlive-basic texlive-binextra texlive-latexextra
        nix:    texliveSmall~texlive texlivePackages.pdfjam~pdfjam
        zypper: texlive-pdfjam-bin
        guix:   texlive-bin
        xbps:   texlive
        pkgx:
    "

    ["scour"]="
        termux:
        apt:    scour
        dnf:    python3-scour
        pacman: scour
        nix:    scour
        zypper: python3-scour~scour
        guix:   python-scour
        xbps:   python3-scour
        pkgx:
    "

    ["sox"]="
        termux: sox
        apt:    sox libsox-fmt-mp3
        dnf:    sox
        pacman: sox
        nix:    sox
        zypper: sox
        guix:   sox
        xbps:   sox
        pkgx:
    "

    ["tesseract-lang-${TASK_LANG:-}"]="
        termux: tesseract
        apt:    tesseract-ocr tesseract-ocr-${TASK_LANG:-}
        dnf:    tesseract tesseract-langpack-${TASK_LANG:-}
        pacman: tesseract tesseract-data-${TASK_LANG:-}
        nix:    tesseract
        zypper: tesseract tesseract-ocr-traineddata-${TASK_LANG:-}
        guix:   tesseract-ocr
        xbps:   tesseract-ocr tesseract-ocr-${TASK_LANG:-}
        pkgx:
    "

    ["texlive"]="
        termux: texlive-bin
        apt:    texlive \
                texlive-fonts-extra \
                texlive-latex-extra \
                texlive-publishers \
                texlive-science \
                texlive-xetex
        dnf:    texlive-base \
                texlive-collection-fontsextra \
                texlive-collection-latexextra \
                texlive-collection-publishers \
                texlive-collection-mathscience \
                texlive-collection-xetex
        pacman: texlive-basic \
                texlive-fontsextra \
                texlive-latexextra \
                texlive-publishers \
                texlive-mathscience \
                texlive-xetex
        nix:    texliveFull~texlive
        zypper: texlive-collection-basic \
                texlive-collection-fontsextra \
                texlive-collection-latexextra \
                texlive-collection-publishers \
                texlive-collection-mathscience \
                texlive-collection-xetex
        guix:   texlive
        xbps:   texlive-bin
        pkgx:
    "

    ["tmux"]="
        termux: tmux
        apt:    tmux
        dnf:    tmux
        pacman: tmux
        nix:    tmux
        zypper: tmux
        guix:   tmux
        xbps:   tmux
        pkgx:   github.com/tmux/tmux
    "
)

# Description:
#   This array defines commands that need to be executed after a package is
#   installed. These commands are usually required for proper initialization,
#   configuration, or updates that the package manager alone does not handle.
declare -A POST_INSTALL=(
    ["clamav"]='*:rm -f /var/log/clamav/freshclam.log; sed -i "/^NotifyClamd/d" /etc/clamav/freshclam.conf 2>/dev/null; freshclam --quiet'

    ["imagemagick"]='*:find /etc -type f -path "/etc/ImageMagick-*/policy.xml" 2>/dev/null -exec sed -i -e "s/rights=\"none\" pattern=\"PDF\"/rights=\"read|write\" pattern=\"PDF\"/g" -e "s/name=\"disk\" value=\".GiB\"/name=\"disk\" value=\"8GiB\"/g" {} +'
)
