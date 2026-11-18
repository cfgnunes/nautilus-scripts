#!/usr/bin/env bash

# Test shell scripts with ShellCheck.

# Source the file '.common-functions.sh'.
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
ROOT_DIR=$(grep --only-matching "^.*scripts[^/]*" <<<"$SCRIPT_DIR")
source "$ROOT_DIR/.common-functions.sh"

set -a
eval "$(_pkgx_in_sandbox --silent +"shellcheck.net")" &>/dev/null
set +a

# Find all shell scripts.
mapfile -d "" -t FILES < <(
    find "$ROOT_DIR" ! -path "*/.git/*" \
        -type f \( -iname "*.sh" -o -executable \) -print0
)

# Run ShellCheck on them.
_run_in_sandbox "" "true" shellcheck -e SC1091 "${FILES[@]}"
