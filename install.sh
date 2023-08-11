#!/usr/bin/env bash

# Install the scripts for the GNOME Files (Nautilus), Caja and Nemo file managers.

set -eu

_command_exists() {
    local command_check="$1"

    if command -v "$command_check" &>/dev/null; then
        return 0
    fi
    return 1
}

_main() {
    echo "Installing the scripts..."
    local install_dir=""
    local accels_dir=""
    local file_manager=""

    if _command_exists "nautilus"; then
        install_dir="$HOME/.local/share/nautilus/scripts"
        accels_dir="$HOME/.config/nautilus"
        file_manager="nautilus"
    elif _command_exists "nemo"; then
        install_dir="$HOME/.local/share/nemo/scripts"
        file_manager="nemo"
    elif _command_exists "caja"; then
        install_dir="$HOME/.config/caja/scripts"
        file_manager="caja"
    else
        echo "Error: not found any compatible file managers!"
        return 1
    fi

    echo " > Removing previous files..."
    rm -rf "$install_dir"
    rm -f "$accels_dir/scripts-accels"

    echo " > Installing new scripts..."
    mkdir --parents "$install_dir"
    cp -r ./* "$install_dir/"

    if [[ -n "$accels_dir" ]]; then
        echo " > Installing 'scripts-accels'..."
        mkdir --parents "$accels_dir"
        cp "scripts-accels" "$accels_dir/scripts-accels"
    fi

    echo " > Setting file permissions..."
    find -L "$install_dir" -mindepth 2 -type f ! -path "*.git/*" -exec chmod +x {} \;
    find -L "$install_dir" -maxdepth 1 -type f ! -path "*.git/*" -exec chmod -x {} \;

    echo " > Closing the file manager to reload its configurations..."
    eval "$file_manager -q &>/dev/null" || true

    read -r -p " > Would you like to install all dependencies for the scripts now? [Y/n]" answer
    case "${answer,,}" in
    y | yes | "")
        echo "> Installing dependencies..."
        _install_dependencies
        ;;
    *)
        echo "> Skipping installation of dependencies..."
        ;;
    esac

    echo "Done!"
}

_install_dependencies() {

    if _command_exists "sudo"; then
        if _command_exists "apt-get"; then
            sudo apt-get update
            sudo apt-get -y install \
                sudo apt-get install \
                baobab \
                binutils \
                bzip2 \
                coreutils \
                cups-bsd \
                eog \
                ffmpeg \
                file-roller \
                findimagedupes \
                foremost \
                ghostscript \
                git \
                gpg \
                gzip \
                imagemagick \
                inkscape \
                jdupes \
                jpegoptim \
                lame \
                lhasa \
                libc-bin \
                lzip \
                lzop \
                meld \
                mp3gain \
                mp3val \
                ocrmypdf \
                optipng \
                p7zip-full \
                pandoc \
                perl-base \
                poppler-utils \
                qpdf \
                rhash \
                squashfs-tools \
                tar \
                testdisk \
                unrar \
                xclip \
                xz-utils \
                zip \
                zstd
        elif _command_exists "pacman"; then
            sudo pacman -Syy
            sudo pacman --noconfirm -S \
                baobab \
                binutils \
                bzip2 \
                coreutils \
                cups-bsd \
                eog \
                ffmpeg \
                file-roller \
                findimagedupes \
                foremost \
                ghostscript \
                git \
                gpg \
                gzip \
                imagemagick \
                inkscape \
                jdupes \
                jpegoptim \
                lame \
                lhasa \
                libc-bin \
                lzip \
                lzop \
                meld \
                mp3gain \
                mp3val \
                ocrmypdf \
                optipng \
                p7zip-full \
                pandoc \
                perl-base \
                poppler-utils \
                qpdf \
                rhash \
                squashfs-tools \
                tar \
                testdisk \
                unrar \
                xclip \
                xz-utils \
                zip \
                zstd
        elif _command_exists "dnf"; then
            sudo dnf check-update
            sudo dnf -y install \
                baobab \
                binutils \
                bzip2 \
                coreutils \
                cups-bsd \
                eog \
                ffmpeg \
                file-roller \
                findimagedupes \
                foremost \
                ghostscript \
                git \
                gpg \
                gzip \
                imagemagick \
                inkscape \
                jdupes \
                jpegoptim \
                lame \
                lhasa \
                libc-bin \
                lzip \
                lzop \
                meld \
                mp3gain \
                mp3val \
                ocrmypdf \
                optipng \
                p7zip-full \
                pandoc \
                perl-base \
                poppler-utils \
                qpdf \
                rhash \
                squashfs-tools \
                tar \
                testdisk \
                unrar \
                xclip \
                xz-utils \
                zip \
                zstd
        elif _command_exists "yum"; then
            sudo yum check-update
            sudo yum -y install \
                baobab \
                binutils \
                bzip2 \
                coreutils \
                cups-bsd \
                eog \
                ffmpeg \
                file-roller \
                findimagedupes \
                foremost \
                ghostscript \
                git \
                gpg \
                gzip \
                imagemagick \
                inkscape \
                jdupes \
                jpegoptim \
                lame \
                lhasa \
                libc-bin \
                lzip \
                lzop \
                meld \
                mp3gain \
                mp3val \
                ocrmypdf \
                optipng \
                p7zip-full \
                pandoc \
                perl-base \
                poppler-utils \
                qpdf \
                rhash \
                squashfs-tools \
                tar \
                testdisk \
                unrar \
                xclip \
                xz-utils \
                zip \
                zstd
        else
            echo "Error: could not find a package manager!"
            return 1
        fi
    else
        echo "Error: could not run the installer as administrator!"
        return 1
    fi
}

_main "$@"
