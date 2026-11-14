#!/usr/bin/env bash

# Test shell scripts with ShellCheck.

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
ROOT_DIR=$(grep --only-matching "^.*scripts[^/]*" <<<"$SCRIPT_DIR")

# Check for pkgx command or local installation.
if [[ -x "$HOME/.local/opt/pkgx/pkgx" ]]; then
    PKGX="$HOME/.local/opt/pkgx/pkgx"
elif command -v pkgx &>/dev/null; then
    PKGX=$(command -v pkgx)
else
    echo "ERROR: pkgx not found!" >&2
    exit 1
fi

# Find all shell scripts and run ShellCheck on them.
find "$ROOT_DIR" ! -path "*/.git*" -type f \( -iname "*.sh" -o -executable \) \
    -exec "$PKGX" shellcheck -e SC1091 "{}" +
