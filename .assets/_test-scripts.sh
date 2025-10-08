#!/usr/bin/env bash

set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
ROOT_DIR=$(grep --only-matching "^.*scripts[^/]*" <<<"$SCRIPT_DIR")

# Missing:
#   Compress...
#   Compress to .7z with password (each)

# -----------------------------------------------------------------------------
# CONSTANTS
# -----------------------------------------------------------------------------

_MOCK_DIR_BASE="/tmp"
_MOCK_DIR_TEST="$_MOCK_DIR_BASE/test"
_MOCK_FILE1="$_MOCK_DIR_TEST/file1"
_MOCK_FILE2="$_MOCK_DIR_TEST/file2"
_MOCK_FILE3="$_MOCK_DIR_TEST/file3"
_MOCK_FILE1_CONTENT="File 1 test."
_MOCK_FILE2_CONTENT="File 2 test."
_MOCK_FILE3_CONTENT="File 3 test."

readonly \
    _MOCK_DIR_BASE \
    _MOCK_DIR_TEST \
    _MOCK_FILE1 \
    _MOCK_FILE2 \
    _MOCK_FILE3 \
    _MOCK_FILE1_CONTENT \
    _MOCK_FILE2_CONTENT \
    _MOCK_FILE3_CONTENT

__create_mock_files() {
    rm -rf "$_MOCK_DIR_TEST"
    mkdir -p "$_MOCK_DIR_TEST"
    printf "%s" "$_MOCK_FILE1_CONTENT" >"$_MOCK_FILE1"
    printf "%s" "$_MOCK_FILE2_CONTENT" >"$_MOCK_FILE2"
    printf "%s" "$_MOCK_FILE3_CONTENT" >"$_MOCK_FILE3"
}

__clean_mock_files() {
    rm -rf "$_MOCK_DIR_TEST"
}

unset DISPLAY

_echo_script() {
    echo -e "[\033[36mSCRIPT\033[0m] $1"
}

_main() {
    __create_mock_files

    SCRIPT_TEST="Archive/Compress to .7z (each)"
    _echo_script "$SCRIPT_TEST"
    bash "$ROOT_DIR/$SCRIPT_TEST" "$_MOCK_FILE1"

    SCRIPT_TEST="Archive/Compress to .iso (each)"
    _echo_script "$SCRIPT_TEST"
    bash "$ROOT_DIR/$SCRIPT_TEST" "$_MOCK_DIR_TEST"
    mv "$_MOCK_DIR_BASE/test.iso" "$_MOCK_DIR_TEST"

    SCRIPT_TEST="Archive/Compress to .squashfs (each)"
    _echo_script "$SCRIPT_TEST"
    bash "$ROOT_DIR/$SCRIPT_TEST" "$_MOCK_FILE1"

    SCRIPT_TEST="Archive/Compress to .tar.gz (each)"
    _echo_script "$SCRIPT_TEST"
    bash "$ROOT_DIR/$SCRIPT_TEST" "$_MOCK_FILE1"

    SCRIPT_TEST="Archive/Compress to .tar.xz (each)"
    _echo_script "$SCRIPT_TEST"
    bash "$ROOT_DIR/$SCRIPT_TEST" "$_MOCK_FILE1"

    SCRIPT_TEST="Archive/Compress to .tar.zst (each)"
    _echo_script "$SCRIPT_TEST"
    bash "$ROOT_DIR/$SCRIPT_TEST" "$_MOCK_FILE1"

    SCRIPT_TEST="Archive/Compress to .zip (each)"
    _echo_script "$SCRIPT_TEST"
    bash "$ROOT_DIR/$SCRIPT_TEST" "$_MOCK_FILE1"

    SCRIPT_TEST="Archive/Extract here"
    _echo_script "$SCRIPT_TEST"
    bash "$ROOT_DIR/$SCRIPT_TEST" "$_MOCK_FILE1.zip"

    __clean_mock_files
}

_main "$@"
