#!/usr/bin/env bash
# =============================================================================
# Description: Provide the installer function for pkgx.
# Sourced by 'install.sh'. Do not run directly.
# =============================================================================

_install_pkgx() {
    local pkgx_dir="$USER_OPT_DIR/pkgx"
    local pkgx_cmd="$pkgx_dir/pkgx"
    local pkgx_cmd_tmp="$TEMP_DIR/pkgx"
    local pkgx_url="https://api.github.com/repos/pkgxdev/pkgx/releases/latest"

    _echo ""
    _echo_info "$(_i18n 'Installing pkgx:')"

    # Check if pkgx is already installed.
    if [[ -x "$pkgx_cmd" ]]; then
        _echo_info "> $(_i18n 'pkgx is already installed.')"
        _echo_info "> $(_i18n 'Done!')"
        return
    fi

    local tarball_regex=""
    local arch=""
    arch=$(uname -m)
    case "$arch" in
    "x86_64") tarball_regex="https.*/pkgx.*linux.*86.64\.tar\.gz" ;;
    "aarch64") tarball_regex="https.*/pkgx.*linux.*aarch64\.tar\.gz" ;;
    *)
        _echo_error "> Unsupported architecture: $arch"
        return 1
        ;;
    esac

    _echo_info "> $(_i18n 'Downloading the package...')"

    # Download and extract pkgx.
    if _command_exists "curl"; then
        {
            curl -fsL "$pkgx_url" 2>/dev/null |
                grep --ignore-case --only-matching -m1 "$tarball_regex" |
                xargs curl -fsL | tar xz -C "$TEMP_DIR"
        } 2>/dev/null
    else
        {
            wget -qO- "$pkgx_url" 2>/dev/null |
                grep --ignore-case --only-matching -m1 "$tarball_regex" |
                xargs wget -qO- | tar xz -C "$TEMP_DIR"
        } 2>/dev/null
    fi

    # Verify installation.
    if [[ ! -f "$pkgx_cmd_tmp" ]]; then
        _echo_error "> $(_i18n 'pkgx installation failed!')"
        return 1
    fi

    chmod +x -- "$pkgx_cmd_tmp"

    # Check if pkgx can run.
    if ! bwrap --ro-bind / / --unshare-all "$pkgx_cmd_tmp" -v 2>&1 |
        grep -q "pkgx [0-9]"; then
        _echo_error "> $(_i18n 'pkgx cannot run on your system!')"
        return 1
    fi

    _echo_info "> $(_i18n 'Installing pkgx to:') $pkgx_dir"

    mkdir --parents -- "$pkgx_dir"
    mv -- "$pkgx_cmd_tmp" "$pkgx_cmd"

    _echo_info "> $(_i18n 'Done!')"
}
