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
    echo
    echo -e "[\033[36mSCRIPT\033[0m] $1"
}

_main() {
    local script_test=""
    local input_file1=""
    local input_file2=""
    local output_file=""

    __create_temp_files

    input_file1=$_TEMP_FILE1
    output_file=$_TEMP_FILE1

    script_test="Archive/Compress to .7z (each)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1"
    __test_file "$output_file.7z"

    #script_test="Archive/Compress to .7z with password (each)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    script_test="Archive/Compress to .iso (each)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$_TEMP_DIR_TEST"
    mv "$_TEMP_DIR/test.iso" "$_TEMP_DIR_TEST"
    __test_file "$_TEMP_DIR_TEST/test.iso"

    script_test="Archive/Compress to .squashfs (each)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1"
    __test_file "$output_file.squashfs"

    script_test="Archive/Compress to .tar.gz (each)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1"
    __test_file "$output_file.tar.gz"

    script_test="Archive/Compress to .tar.xz (each)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1"
    __test_file "$output_file.tar.xz"

    script_test="Archive/Compress to .tar.zst (each)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1"
    __test_file "$output_file.tar.zst"

    script_test="Archive/Compress to .zip (each)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1"
    __test_file "$output_file.zip"

    #script_test="Archive/Compress..."
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    script_test="Archive/Extract here"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$_TEMP_FILE1.zip"
    __test_file "$output_file (1)"

    #script_test="Archive/Extract here"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Audio: Channels/Audio: Mix channels to mono"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Audio: Channels/Audio: Mix two files (WAV output)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Audio: Convert/Audio: Convert to FLAC"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Audio: Convert/Audio: Convert to MP3 (192 kbps)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Audio: Convert/Audio: Convert to MP3 (320 kbps)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Audio: Convert/Audio: Convert to MP3 (48 kbps, mono)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Audio: Convert/Audio: Convert to OGG (192 kbps)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Audio: Convert/Audio: Convert to OGG (320 kbps)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Audio: Convert/Audio: Convert to OGG (48 kbps, mono)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Audio: Convert/Audio: Convert to OPUS (192 kbps)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Audio: Convert/Audio: Convert to OPUS (320 kbps)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Audio: Convert/Audio: Convert to OPUS (48 kbps, mono)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Audio: Convert/Audio: Convert to WAV"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Audio: Effects/Audio: Fade in"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Audio: Effects/Audio: Fade out"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Audio: Effects/Audio: Normalize"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Audio: Effects/Audio: Remove silent sections (-30 db)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Audio: Effects/Audio: Silence noise (-30 db)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Audio: MP3 files/MP3: List ID3 tags"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Audio: MP3 files/MP3: Maximize gain (recursive)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Audio: MP3 files/MP3: Normalize gain (recursive)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Audio: MP3 files/MP3: Repair (recursive)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Audio: MP3 files/MP3: Show files information"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Audio: MP3 files/MP3: Tag ID3 to name (artist - title)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Audio: MP3 files/MP3: Tag name to ID3 (artist - title)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Audio: Quality/Audio: List quality"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Audio: Quality/Audio: Produce a spectrogram"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Audio: Tools/Audio: Concatenate files"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Audio: Tools/Audio: Remove metadata"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Audio: Tools/Audio: Show files information"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Video: Aspect ratio/Video: Aspect to 1:1"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Video: Aspect ratio/Video: Aspect to 16:10"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Video: Aspect ratio/Video: Aspect to 16:9"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Video: Aspect ratio/Video: Aspect to 2.21:1"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Video: Aspect ratio/Video: Aspect to 2.35:1"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Video: Aspect ratio/Video: Aspect to 2.39:1"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Video: Aspect ratio/Video: Aspect to 4:3"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Video: Aspect ratio/Video: Aspect to 5:4"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Video: Audio track/Video: Extract audio"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Video: Audio track/Video: Remove audio"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Video: Convert/Video: Convert to MKV"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Video: Convert/Video: Convert to MKV (no re-encoding)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Video: Convert/Video: Convert to MP4"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Video: Convert/Video: Convert to MP4 (no re-encoding)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Video: Convert/Video: Export to GIF"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Video: Export frames/Video: Export frames (1 FPS)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Video: Export frames/Video: Export frames (10 FPS)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Video: Export frames/Video: Export frames (5 FPS)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Video: Flip, Rotate/Video: Flip (horizontally)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Video: Flip, Rotate/Video: Flip (vertically)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Video: Flip, Rotate/Video: Rotate (180 deg)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Video: Flip, Rotate/Video: Rotate (270 deg)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Video: Flip, Rotate/Video: Rotate (90 deg)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Video: Frame rate/Video: Frame rate to 30 FPS"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Video: Frame rate/Video: Frame rate to 60 FPS"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Video: Resize/Video: Resize (25 pct)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Video: Resize/Video: Resize (50 pct)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Video: Resize/Video: Resize (75 pct)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Video: Speed factor/Video: Speed factor to 0.5"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Video: Speed factor/Video: Speed factor to 1.5"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Video: Speed factor/Video: Speed factor to 2.0"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Video: Tools/Video: Concatenate files"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Video: Tools/Video: Remove metadata"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Audio and video/Video: Tools/Video: Show files information"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Clipboard operations/Copy filename to clipboard"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Clipboard operations/Copy filename to clipboard (recursive)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Clipboard operations/Copy filepath to clipboard"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Clipboard operations/Copy filepath to clipboard (recursive)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Clipboard operations/Paste clipboard as a file"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Directories and files/Compare items"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Directories and files/Compare items (via Diff)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Directories and files/Find duplicate files"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Directories and files/Find empty directories"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Directories and files/Find hidden items"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Directories and files/Find junk files"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Directories and files/Find recently modified files"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Directories and files/Flatten directory structure"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Directories and files/List largest directories"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Directories and files/List largest files"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Directories and files/List permissions and owners"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Directories and files/Open item location"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Directories and files/Reset permissions (recursive)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Directories and files/Show files information"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Directories and files/Show files metadata"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Directories and files/Show files MIME types"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Directories and files/Show files properties"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/Document: Convert/Document: Convert to DOCX"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/Document: Convert/Document: Convert to EPUB"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/Document: Convert/Document: Convert to FB2"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/Document: Convert/Document: Convert to Markdown"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/Document: Convert/Document: Convert to ODP"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/Document: Convert/Document: Convert to ODS"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/Document: Convert/Document: Convert to ODT"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/Document: Convert/Document: Convert to PDF"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/Document: Convert/Document: Convert to PPTX"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/Document: Convert/Document: Convert to TXT"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/Document: Convert/Document: Convert to XLSX"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/Document: Print/Document: Print (A4)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/Document: Print/Document: Print (US Legal)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/Document: Print/Document: Print (US Letter)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/PDF: Annotations/PDF: Find annotated files"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/PDF: Annotations/PDF: Remove annotations"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/PDF: Combine, Split/PDF: Combine multiple files"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/PDF: Combine, Split/PDF: Split into single-page files"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/PDF: Encrypt, Decrypt/PDF: Decrypt (remove password)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/PDF: Encrypt, Decrypt/PDF: Encrypt (set a password)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/PDF: Encrypt, Decrypt/PDF: Find password-encrypted files"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/PDF: Multiple-page layout/PDF: Layout (landscape, 1x2)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/PDF: Multiple-page layout/PDF: Layout (landscape, 2x1)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/PDF: Multiple-page layout/PDF: Layout (landscape, 2x2)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/PDF: Multiple-page layout/PDF: Layout (landscape, 2x4)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/PDF: Multiple-page layout/PDF: Layout (landscape, 4x2)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/PDF: Multiple-page layout/PDF: Layout (portrait, 1x2)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/PDF: Multiple-page layout/PDF: Layout (portrait, 2x1)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/PDF: Multiple-page layout/PDF: Layout (portrait, 2x2)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/PDF: Multiple-page layout/PDF: Layout (portrait, 2x4)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/PDF: Multiple-page layout/PDF: Layout (portrait, 4x2)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/PDF: Optimize, Reduce/PDF: Find non-linearized files"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/PDF: Optimize, Reduce/PDF: Optimize for web (linearize)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/PDF: Optimize, Reduce/PDF: Reduce (150 dpi, e-book)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/PDF: Optimize, Reduce/PDF: Reduce (300 dpi, printer)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/PDF: Paper size/PDF: Paper size to A3"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/PDF: Paper size/PDF: Paper size to A4"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/PDF: Paper size/PDF: Paper size to A5"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/PDF: Paper size/PDF: Paper size to US Legal"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/PDF: Paper size/PDF: Paper size to US Letter"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/PDF: Rotate/PDF: Rotate (180 deg)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/PDF: Rotate/PDF: Rotate (270 deg)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/PDF: Rotate/PDF: Rotate (90 deg)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/PDF: Signatures/PDF: Find signed files"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/PDF: Signatures/PDF: List signatures"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/PDF: Text recognition (OCR)/PDF: Find non-searchable files"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/PDF: Text recognition (OCR)/PDF: Perform OCR (English)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/PDF: Text recognition (OCR)/PDF: Perform OCR (French)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/PDF: Text recognition (OCR)/PDF: Perform OCR (German)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/PDF: Text recognition (OCR)/PDF: Perform OCR (Italian)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/PDF: Text recognition (OCR)/PDF: Perform OCR (Portuguese)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/PDF: Text recognition (OCR)/PDF: Perform OCR (Russian)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/PDF: Text recognition (OCR)/PDF: Perform OCR (Spanish)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/PDF: Tools/PDF: Convert to PDFA-2b"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/PDF: Tools/PDF: Extract images"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/PDF: Tools/PDF: Remove metadata"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/PDF: Watermark/PDF: Add watermark (overlay)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Document/PDF: Watermark/PDF: Add watermark (underlay)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="File encryption/GPG: Decrypt"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="File encryption/GPG: Encrypt with password"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="File encryption/GPG: Encrypt with password (ASCII)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="File encryption/GPG: Encrypt with public keys"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="File encryption/GPG: Encrypt with public keys (ASCII)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="File encryption/GPG: Import key"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="File encryption/GPG: Sign"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="File encryption/GPG: Sign (ASCII)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="File encryption/GPG: Sign (detached signature)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="File encryption/GPG: Verify signature"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Hash and checksum/Compute all file hashes"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Hash and checksum/Compute CRC32"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Hash and checksum/Compute MD5"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Hash and checksum/Compute SHA1"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Hash and checksum/Compute SHA256"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Hash and checksum/Compute SHA512"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Hash and checksum/Generate MD5 checksum file"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Hash and checksum/Generate SHA1 checksum file"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Hash and checksum/Generate SHA256 checksum file"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Hash and checksum/Generate SHA512 checksum file"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Hash and checksum/Verify MD5 checksum file"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Hash and checksum/Verify SHA1 checksum file"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Hash and checksum/Verify SHA256 checksum file"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Hash and checksum/Verify SHA512 checksum file"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    input_file1="$_TEMP_DIR_TEST/image1.png"
    input_file2="$_TEMP_DIR_TEST/image2.png"
    output_file="$_TEMP_DIR_TEST/image1"

    convert -size 200x100 xc:red "$input_file1"
    convert -size 200x100 xc:blue "$input_file2"

    script_test="Image/Image: Color/Image: Colorspace to gray"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1"
    __test_file "$output_file (grayscale).png"

    script_test="Image/Image: Color/Image: Desaturate"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1"
    __test_file "$output_file (desaturated).png"

    script_test="Image/Image: Color/Image: Generate multiple hues"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1"
    __test_file "$_TEMP_DIR_TEST/Output/image1 (1).png"

    script_test="Image/Image: Combine, Split/Image: Combine into a GIF"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" "$input_file2"
    __test_file "$_TEMP_DIR_TEST/Animated image.gif"

    script_test="Image/Image: Combine, Split/Image: Combine into a PDF"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" "$input_file2"
    __test_file "$_TEMP_DIR_TEST/Combined images.pdf"

    script_test="Image/Image: Combine, Split/Image: Split into 2 (horizontally)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1"
    __test_file "$_TEMP_DIR_TEST/Output (1)/image1-0.png"

    script_test="Image/Image: Combine, Split/Image: Split into 2 (vertically)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1"
    __test_file "$_TEMP_DIR_TEST/Output (2)/image1-0.png"

    script_test="Image/Image: Combine, Split/Image: Split into 4"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1"
    __test_file "$_TEMP_DIR_TEST/Output (3)/image1-0.png"

    script_test="Image/Image: Combine, Split/Image: Stack (horizontally)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" "$input_file2"
    __test_file "$_TEMP_DIR_TEST/Stacked images (horizontal).png"

    script_test="Image/Image: Combine, Split/Image: Stack (vertically)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" "$input_file2"
    __test_file "$_TEMP_DIR_TEST/Stacked images (vertical).png"

    script_test="Image/Image: Convert/Image: Convert to AVIF"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1"
    __test_file "$output_file.avif"

    script_test="Image/Image: Convert/Image: Convert to BMP"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1"
    __test_file "$output_file.bmp"

    script_test="Image/Image: Convert/Image: Convert to GIF"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1"
    __test_file "$output_file.gif"

    script_test="Image/Image: Convert/Image: Convert to JPG"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1"
    __test_file "$output_file.jpg"

    #script_test="Image/Image: Convert/Image: Convert to PNG"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    script_test="Image/Image: Convert/Image: Convert to TIF"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1"
    __test_file "$output_file.tif"

    script_test="Image/Image: Convert/Image: Convert to WEBP"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1"
    __test_file "$output_file.webp"

    script_test="Image/Image: Convert/Image: Export to PDF"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1"
    __test_file "$output_file.pdf"

    script_test="Image/Image: Crop, Resize/Image: Automatic crop"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1"
    __test_file "$output_file (cropped).png"

    script_test="Image/Image: Crop, Resize/Image: Automatic crop (15 pct)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1"
    __test_file "$output_file (cropped) (1).png"

    script_test="Image/Image: Crop, Resize/Image: Resize (25 pct)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1"
    __test_file "$output_file (25 pct).png"

    script_test="Image/Image: Crop, Resize/Image: Resize (50 pct)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1"
    __test_file "$output_file (50 pct).png"

    script_test="Image/Image: Crop, Resize/Image: Resize (75 pct)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1"
    __test_file "$output_file (75 pct).png"

    script_test="Image/Image: Crop, Resize/Image: Resize and crop (1920x1080)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1"
    __test_file "$output_file (1920x1080).png"

    script_test="Image/Image: Flip, Rotate/Image: Flip (horizontally)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1"
    __test_file "$output_file (flipped-h).png"

    script_test="Image/Image: Flip, Rotate/Image: Flip (vertically)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1"
    __test_file "$output_file (flipped-v).png"

    script_test="Image/Image: Flip, Rotate/Image: Rotate (180 deg)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1"
    __test_file "$output_file (180 deg).png"

    script_test="Image/Image: Flip, Rotate/Image: Rotate (270 deg)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1"
    __test_file "$output_file (270 deg).png"

    script_test="Image/Image: Flip, Rotate/Image: Rotate (90 deg)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1"
    __test_file "$output_file (90 deg).png"

    #script_test="Image/Image: Icons/Image: Create PNG icon (128 px)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Image/Image: Icons/Image: Create PNG icon (256 px)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Image/Image: Icons/Image: Create PNG icon (512 px)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Image/Image: Icons/Image: Create PNG icon (64 px)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    script_test="Image/Image: Optimize, Reduce/Image: Optimize PNG"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1"
    __test_file "$output_file (optimized).png"

    #script_test="Image/Image: Optimize, Reduce/Image: Reduce (JPG, 1000kB max)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Image/Image: Optimize, Reduce/Image: Reduce (JPG, 500kB max)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    script_test="Image/Image: Optimize, Reduce/Image: Remove metadata"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1"
    __test_file "$output_file (no metadata).png"

    #script_test="Image/Image: Similarity/Image: Find similar (65 pct)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Image/Image: Similarity/Image: Find similar (75 pct)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Image/Image: Similarity/Image: Find similar (85 pct)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Image/Image: Similarity/Image: Find similar (95 pct)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Image/Image: SVG files/SVG: Compress to SVGZ"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Image/Image: SVG files/SVG: Decompress SVGZ"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Image/Image: SVG files/SVG: Export to EPS"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Image/Image: SVG files/SVG: Export to PDF"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Image/Image: SVG files/SVG: Export to PNG (1024 px)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Image/Image: SVG files/SVG: Export to PNG (256 px)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Image/Image: SVG files/SVG: Export to PNG (512 px)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Image/Image: SVG files/SVG: Replace fonts to 'Charter'"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Image/Image: SVG files/SVG: Replace fonts to 'Helvetica'"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Image/Image: SVG files/SVG: Replace fonts to 'Times'"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Image/Image: Text recognition (OCR)/Image: Perform OCR (English)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Image/Image: Text recognition (OCR)/Image: Perform OCR (French)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Image/Image: Text recognition (OCR)/Image: Perform OCR (German)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Image/Image: Text recognition (OCR)/Image: Perform OCR (Italian)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Image/Image: Text recognition (OCR)/Image: Perform OCR (Portuguese)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Image/Image: Text recognition (OCR)/Image: Perform OCR (Russian)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Image/Image: Text recognition (OCR)/Image: Perform OCR (Spanish)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Image/Image: Transparency/Image: Background to alpha"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Image/Image: Transparency/Image: Background to alpha (15 pct)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Image/Image: Transparency/Image: Color alpha to black"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Image/Image: Transparency/Image: Color alpha to magenta"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Image/Image: Transparency/Image: Color alpha to white"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Image/Image: Transparency/Image: Color black to alpha"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Image/Image: Transparency/Image: Color black to alpha (15 pct)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Image/Image: Transparency/Image: Color magenta to alpha"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Image/Image: Transparency/Image: Color magenta to alpha (15 pct)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Image/Image: Transparency/Image: Color white to alpha"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Image/Image: Transparency/Image: Color white to alpha (15 pct)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Image/Image: Watermark/Image: Add watermark (center)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Image/Image: Watermark/Image: Add watermark (north)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Image/Image: Watermark/Image: Add watermark (northeast)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Image/Image: Watermark/Image: Add watermark (northwest)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Image/Image: Watermark/Image: Add watermark (south)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Image/Image: Watermark/Image: Add watermark (southeast)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Image/Image: Watermark/Image: Add watermark (southwest)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Link operations/Create hard link here"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Link operations/Create hard link to..."
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Link operations/Create symbolic link here"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Link operations/Create symbolic link to Desktop"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Link operations/Create symbolic link to..."
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Link operations/Find broken links"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Link operations/List hard links"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Link operations/List symbolic links"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Link operations/Paste as hard link"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Link operations/Paste as symbolic link"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Network and internet/Git: Clone URLs (clipboard, file)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Network and internet/Git: Open repository website"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Network and internet/Git: Reset and pull"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Network and internet/IP: Ping hosts"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Network and internet/IP: Scan ports"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Network and internet/IP: Test hosts availability"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Network and internet/URL: Check HTTP status"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Network and internet/URL: Check SSL expiry"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Network and internet/URL: Download (clipboard, file)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Network and internet/URL: List HTTP headers"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Open with/Code Editor"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Open with/Disk Usage Analyzer"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Open with/Terminal"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Plain text/Text: Encodings"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Plain text/Text: Encodings/Text: Encode to ISO-8859-1"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Plain text/Text: Encodings/Text: Encode to UTF-8"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Plain text/Text: Encodings/Text: List encodings"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Plain text/Text: Encodings/Text: Transliterate to ASCII"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Plain text/Text: Indentation/Text: Convert '4 spaces' to 'tabs'"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Plain text/Text: Indentation/Text: Convert '8 spaces' to 'tabs'"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Plain text/Text: Indentation/Text: Convert 'tabs' to '4 spaces'"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Plain text/Text: Indentation/Text: Convert 'tabs' to '8 spaces'"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Plain text/Text: Line breaks/Text: Line breaks to CRLF (Windows)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Plain text/Text: Line breaks/Text: Line breaks to LF (Unix)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Plain text/Text: Line breaks/Text: List line breaks"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Plain text/Text: Statistics/Text: List line count"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Plain text/Text: Statistics/Text: List max line length"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Plain text/Text: Statistics/Text: List word count"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Plain text/Text: Tools/Text: Concatenate multiple files"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Plain text/Text: Tools/Text: Convert UTF-8 CRLF (recursive)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Plain text/Text: Tools/Text: Convert UTF-8 LF (recursive)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Plain text/Text: Tools/Text: List file issues"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Plain text/Text: Tools/Text: List files with bad chars"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Plain text/Text: Tools/Text: Remove trailing spaces"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Rename files/Rename: Remove accents (translit.)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Rename files/Rename: Remove brackets"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Rename files/Rename: Replace gaps with dashes"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Rename files/Rename: Replace gaps with spaces"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Rename files/Rename: Replace gaps with underscores"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Rename files/Rename: To lowercase"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Rename files/Rename: To lowercase (recursive)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Rename files/Rename: To sentence case"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Rename files/Rename: To title case"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Rename files/Rename: To uppercase"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Rename files/Rename: To uppercase (recursive)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Security and recovery/File carving (via Foremost)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Security and recovery/File carving (via PhotoRec)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Security and recovery/Scan for malware (via ClamAV)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #script_test="Security and recovery/Shred files (secure delete)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1"
    #__test_file "$output_file"

    #__clean_temp_files

    printf "\nFinished! "
    printf "Results: %s tests, %s failed.\n" "$_TOTAL_TESTS" "$_TOTAL_FAILED"
}

_main "$@"
