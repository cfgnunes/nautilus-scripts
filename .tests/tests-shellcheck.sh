#!/usr/bin/env bash
# =============================================================================
# Description: Validate the shell scripts with ShellCheck.
# =============================================================================

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
ROOT_DIR=$(grep --only-matching "^.*scripts[^/]*" <<<"$SCRIPT_DIR")

# Find all shell scripts and run ShellCheck on them.
find "$ROOT_DIR" \
    ! -path "*/.git*" \
    -type f \( -iname "*.sh" -o -executable \) \
    -exec shellcheck -e SC1091 "{}" +
