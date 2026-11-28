#!/usr/bin/env bash
# =============================================================================
# Description: Validate the shell scripts with ShellCheck.
# =============================================================================

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
ROOT_DIR=$(grep --only-matching "^.*scripts[^/]*" <<<"$SCRIPT_DIR")

# Find all shell scripts and run ShellCheck on them.
(
    cd -- "$ROOT_DIR/.tests" || exit 1
    find "$ROOT_DIR" ! -path "*/.git*" \
        -type f \( -iname "*.sh" -o -executable \) \
        -exec shellcheck "{}" +
)
