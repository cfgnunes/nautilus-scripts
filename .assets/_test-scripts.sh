#!/usr/bin/env bash

# Test all scripts.

set -u

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
ROOT_DIR=$(grep --only-matching "^.*scripts[^/]*" <<<"$SCRIPT_DIR")

unset DISPLAY

# Missing:
#   Compress...
#   Compress to .7z with password (each)

# -----------------------------------------------------------------------------
# SECTION /// [CONSTANTS]
# -----------------------------------------------------------------------------

_TEMP_DIR=$(mktemp --directory)
_TEMP_DIR_TEST="$_TEMP_DIR/test"
_TEMP_FILE1="$_TEMP_DIR_TEST/file1"
_TEMP_FILE2="$_TEMP_DIR_TEST/file2"
_TEMP_FILE3="$_TEMP_DIR_TEST/file3"
_TEMP_FILE1_CONTENT="File 1 test."
_TEMP_FILE2_CONTENT="File 2 test."
_TEMP_FILE3_CONTENT="File 3 test."

readonly \
    _TEMP_DIR \
    _TEMP_DIR_TEST \
    _TEMP_FILE1 \
    _TEMP_FILE2 \
    _TEMP_FILE3 \
    _TEMP_FILE1_CONTENT \
    _TEMP_FILE2_CONTENT \
    _TEMP_FILE3_CONTENT

# -----------------------------------------------------------------------------
# SECTION /// [GLOBAL VARIABLES]
# -----------------------------------------------------------------------------

_TOTAL_TESTS=0
_TOTAL_FAILED=0

# -----------------------------------------------------------------------------
# SECTION /// [FUNCTIONS]
# -----------------------------------------------------------------------------

__create_temp_files() {
    rm -rf "$_TEMP_DIR_TEST"
    mkdir -p "$_TEMP_DIR_TEST"
    printf "%s" "$_TEMP_FILE1_CONTENT" >"$_TEMP_FILE1"
    printf "%s" "$_TEMP_FILE2_CONTENT" >"$_TEMP_FILE2"
    printf "%s" "$_TEMP_FILE3_CONTENT" >"$_TEMP_FILE3"
}

__clean_temp_files() {
    rm -rf "$_TEMP_DIR_TEST"
}


__test_file() {
    local file=$1

    ((_TOTAL_TESTS++))

    if [[ -f "$file" ]]; then
        printf "[\\033[32m PASS \\033[0m] "
    else
        printf "[\\033[31mFAILED\\033[0m] "
        ((_TOTAL_FAILED++))
    fi
    printf "\\033[33mTest file:\\033[0m "
    printf "%s" "$file" | sed -z "s|\n|\\\n|g" | cat -A
    printf "\n"
}

__echo_script() {
    echo -e "[\033[36mSCRIPT\033[0m] $1"
}

_main() {
    local script_test=""
    __create_temp_files

    script_test="Archive/Compress to .7z (each)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$_TEMP_FILE1"
    __test_file "$_TEMP_FILE1.7z"

    script_test="Archive/Compress to .iso (each)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$_TEMP_DIR_TEST"
    mv "$_TEMP_DIR/test.iso" "$_TEMP_DIR_TEST"
    __test_file "$_TEMP_DIR_TEST/test.iso"

    script_test="Archive/Compress to .squashfs (each)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$_TEMP_FILE1"
    __test_file "$_TEMP_FILE1.squashfs"

    script_test="Archive/Compress to .tar.gz (each)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$_TEMP_FILE1"
    __test_file "$_TEMP_FILE1.tar.gz"

    script_test="Archive/Compress to .tar.xz (each)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$_TEMP_FILE1"
    __test_file "$_TEMP_FILE1.tar.xz"

    script_test="Archive/Compress to .tar.zst (each)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$_TEMP_FILE1"
    __test_file "$_TEMP_FILE1.tar.zst"

    script_test="Archive/Compress to .zip (each)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$_TEMP_FILE1"
    __test_file "$_TEMP_FILE1.zip"

    script_test="Archive/Extract here"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$_TEMP_FILE1.zip"
    __test_file "$_TEMP_FILE1 (1)"

    __clean_temp_files

    printf "\nFinished! "
    printf "Results: %s tests, %s failed.\n" "$_TOTAL_TESTS" "$_TOTAL_FAILED"
}

_main "$@"
