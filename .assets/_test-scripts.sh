#!/usr/bin/env bash

# Test all scripts.

# Source the script '_common-functions.sh'.
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
ROOT_DIR=$(grep --only-matching "^.*scripts[^/]*" <<<"$SCRIPT_DIR")
source "$ROOT_DIR/_common-functions.sh"

# Disable GUI for testing on terminal.
unset DISPLAY

# -----------------------------------------------------------------------------
# SECTION /// [GLOBAL VARIABLES]
# -----------------------------------------------------------------------------

_TOTAL_TESTS=0
_TOTAL_FAILED=0

# -----------------------------------------------------------------------------
# SECTION /// [TEST FUNCTIONS]
# -----------------------------------------------------------------------------

__test_file_empty() {
    local file=$1

    ((_TOTAL_TESTS++))

    if [[ -f "$file" && ! -s "$file" ]]; then
        printf "[\033[32m PASS \033[0m] "
    else
        printf "[\033[31mFAILED\033[0m] "
        ((_TOTAL_FAILED++))
    fi

    printf "\033[33mTest file (empty):\033[0m "
    printf "%s" "$file" | sed -z "s|\n|\\\n|g" | cat -A
    printf "\n"
}

__test_file_nonempty() {
    local file=$1

    ((_TOTAL_TESTS++))

    if [[ -f "$file" && -s "$file" ]]; then
        printf "[\033[32m PASS \033[0m] "
    else
        printf "[\033[31mFAILED\033[0m] "
        ((_TOTAL_FAILED++))
    fi

    printf "\033[33mTest file (non empty):\033[0m "
    printf "%s" "$file" | sed -z "s|\n|\\\n|g" | cat -A
    printf "\n"
}

__echo_script() {
    echo
    echo -e "[\033[36mSCRIPT\033[0m] $1"
}

# -----------------------------------------------------------------------------
# SECTION /// [MAIN]
# -----------------------------------------------------------------------------

_main() {
    local script_test=""
    local input_file1=""
    local input_dir1=""
    local input_file2=""
    local output_file=""
    local sample_file=""
    local temp_dir=$TEMP_DIR_TASK

    local std_output="$temp_dir/std_output.txt"
    touch -- "$std_output"

    _dependencies_check_commands "ffmpeg"

    _open_items_locations "$std_output" "true"

    # -------------------------------------------------------------------------
    # SECTION /// [TESTS / Archive]
    # -------------------------------------------------------------------------

    # Create mock files for testing.
    input_dir1="$temp_dir/Test archive"
    mkdir --parents -- "$input_dir1"
    input_file1="$input_dir1/Test archive 1"
    input_file2="$input_dir1/Test archive 2"
    echo "Content of 'Test archive 1'." >"$input_file1"
    echo "Content of 'Test archive 2'." >"$input_file2"
    output_file=$input_dir1

    script_test="Archive/Compress to .7z (each)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_dir1" >"$std_output"
    __test_file_nonempty "$output_file.7z"
    __test_file_empty "$std_output"

    #script_test="Archive/Compress to .7z with password (each)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_dir1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    script_test="Archive/Compress to .iso (each)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_dir1" >"$std_output"
    __test_file_nonempty "$output_file.iso"
    __test_file_empty "$std_output"

    script_test="Archive/Compress to .squashfs (each)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_dir1" >"$std_output"
    __test_file_nonempty "$output_file.squashfs"
    __test_file_empty "$std_output"

    script_test="Archive/Compress to .tar.gz (each)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_dir1" >"$std_output"
    __test_file_nonempty "$output_file.tar.gz"
    __test_file_empty "$std_output"

    script_test="Archive/Compress to .tar.xz (each)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_dir1" >"$std_output"
    __test_file_nonempty "$output_file.tar.xz"
    __test_file_empty "$std_output"

    script_test="Archive/Compress to .tar.zst (each)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_dir1" >"$std_output"
    __test_file_nonempty "$output_file.tar.zst"
    __test_file_empty "$std_output"

    script_test="Archive/Compress to .zip (each)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_dir1" >"$std_output"
    __test_file_nonempty "$output_file.zip"
    __test_file_empty "$std_output"

    #script_test="Archive/Compress..."
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_dir1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    script_test="Archive/Extract here"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$output_file.zip" >"$std_output"
    __test_file_nonempty "$output_file (2)/Test archive 1"
    __test_file_empty "$std_output"

    # -------------------------------------------------------------------------
    # SECTION /// [TESTS / Audio]
    # -------------------------------------------------------------------------

    # Create mock files for testing.
    input_file1="$temp_dir/Test audio.mp3"
    input_file2="$temp_dir/Test audio 2.mp3"
    output_file="$temp_dir/Test audio"

    ffmpeg -hide_banner -y \
        -f lavfi -i "sine=frequency=440:duration=5" \
        "$input_file1" &>/dev/null
    cp -- "$input_file1" "$input_file2"

    script_test="Directories and files/Show media information"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$std_output"

    script_test="Audio and video/Audio and video: Tools/Media: Show basic metadata"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$std_output"

    script_test="Audio and video/Audio and video: Tools/Media: Concatenate files"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" "$input_file2" >"$std_output"
    __test_file_nonempty "$temp_dir/Concatenated media.mp3"
    __test_file_empty "$std_output"

    script_test="Audio and video/Audio and video: Tools/Media: Remove metadata"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (no metadata).mp3"
    __test_file_empty "$std_output"

    script_test="Audio and video/Audio: Channels/Audio: Mix channels to mono"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (mono).mp3"
    __test_file_empty "$std_output"

    script_test="Audio and video/Audio: Channels/Audio: Mix two files (WAV output)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" "$input_file2" >"$std_output"
    __test_file_nonempty "$temp_dir/Mixed audio.wav"
    __test_file_empty "$std_output"

    script_test="Audio and video/Audio: Convert/Audio: Convert to FLAC"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.flac"
    __test_file_empty "$std_output"

    script_test="Audio and video/Audio: Convert/Audio: Convert to MP3 (192 kbps)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (2).mp3"
    __test_file_empty "$std_output"

    script_test="Audio and video/Audio: Convert/Audio: Convert to MP3 (320 kbps)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (3).mp3"
    __test_file_empty "$std_output"

    script_test="Audio and video/Audio: Convert/Audio: Convert to MP3 (48 kbps, mono)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (4).mp3"
    __test_file_empty "$std_output"

    script_test="Audio and video/Audio: Convert/Audio: Convert to OGG (192 kbps)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.ogg"
    __test_file_empty "$std_output"

    script_test="Audio and video/Audio: Convert/Audio: Convert to OGG (320 kbps)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (2).ogg"
    __test_file_empty "$std_output"

    script_test="Audio and video/Audio: Convert/Audio: Convert to OGG (48 kbps, mono)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (3).ogg"
    __test_file_empty "$std_output"

    script_test="Audio and video/Audio: Convert/Audio: Convert to OPUS (192 kbps)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.opus"
    __test_file_empty "$std_output"

    script_test="Audio and video/Audio: Convert/Audio: Convert to OPUS (320 kbps)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (2).opus"
    __test_file_empty "$std_output"

    script_test="Audio and video/Audio: Convert/Audio: Convert to OPUS (48 kbps, mono)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (3).opus"
    __test_file_empty "$std_output"

    script_test="Audio and video/Audio: Convert/Audio: Convert to WAV"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.wav"
    __test_file_empty "$std_output"

    script_test="Audio and video/Audio: Effects/Audio: Fade in"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (fade-in).mp3"
    __test_file_empty "$std_output"

    script_test="Audio and video/Audio: Effects/Audio: Fade out"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (fade-out).mp3"
    __test_file_empty "$std_output"

    script_test="Audio and video/Audio: Effects/Audio: Normalize"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (normalized).mp3"
    __test_file_empty "$std_output"

    script_test="Audio and video/Audio: Effects/Audio: Remove silent sections (-30 db)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (no silence).mp3"
    __test_file_empty "$std_output"

    script_test="Audio and video/Audio: Effects/Audio: Silence noise (-30 db)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (noise gate).mp3"
    __test_file_empty "$std_output"

    #script_test="Audio and video/Audio: MP3 files/MP3: Maximize gain (recursive)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file.mp3.bak"
    #__test_file_empty "$std_output"

    #script_test="Audio and video/Audio: MP3 files/MP3: Normalize gain (recursive)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file.mp3.bak"
    #__test_file_empty "$std_output"

    #script_test="Audio and video/Audio: MP3 files/MP3: Repair (recursive)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file.mp3.bak"
    #__test_file_empty "$std_output"

    script_test="Audio and video/Audio: MP3 files/MP3: Show encoding details"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$std_output"

    script_test="Audio and video/Audio: Quality/Audio: Check quality"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$std_output"

    script_test="Audio and video/Audio: Quality/Audio: Produce a spectrogram"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.png"
    __test_file_empty "$std_output"

    script_test="Audio and video/Audio: MP3 files/MP3: (artist - title) Filename to ID3"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_empty "$std_output"

    script_test="Audio and video/Audio: MP3 files/MP3: (artist - title) ID3 to Filename"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$temp_dir/(Empty) - Test audio.mp3"
    __test_file_empty "$std_output"

    # -------------------------------------------------------------------------
    # SECTION /// [TESTS / Video]
    # -------------------------------------------------------------------------

    # Create mock files for testing.
    input_file1="$temp_dir/Test video.mp4"
    input_file2="$temp_dir/Test video 2.mp4"
    output_file="$temp_dir/Test video"

    # Generate a test video (red background with a 440 Hz sine tone).
    ffmpeg -hide_banner -y \
        -f lavfi -i color=c=red:s=200x100:d=3:r=25 \
        -f lavfi -i "sine=frequency=440:duration=3" \
        -shortest "$input_file1" &>/dev/null
    cp -- "$input_file1" "$input_file2"

    script_test="Audio and video/Video: Aspect ratio/Video: Aspect to 1:1"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (aspect 1:1).mp4"
    __test_file_empty "$std_output"

    script_test="Audio and video/Video: Aspect ratio/Video: Aspect to 16:10"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (aspect 16:10).mp4"
    __test_file_empty "$std_output"

    script_test="Audio and video/Video: Aspect ratio/Video: Aspect to 16:9"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (aspect 16:9).mp4"
    __test_file_empty "$std_output"

    script_test="Audio and video/Video: Aspect ratio/Video: Aspect to 2.21:1"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (aspect 2.21:1).mp4"
    __test_file_empty "$std_output"

    script_test="Audio and video/Video: Aspect ratio/Video: Aspect to 2.35:1"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (aspect 2.35:1).mp4"
    __test_file_empty "$std_output"

    script_test="Audio and video/Video: Aspect ratio/Video: Aspect to 2.39:1"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (aspect 2.39:1).mp4"
    __test_file_empty "$std_output"

    script_test="Audio and video/Video: Aspect ratio/Video: Aspect to 4:3"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (aspect 4:3).mp4"
    __test_file_empty "$std_output"

    script_test="Audio and video/Video: Aspect ratio/Video: Aspect to 5:4"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (aspect 5:4).mp4"
    __test_file_empty "$std_output"

    script_test="Audio and video/Video: Audio track/Video: Extract audio"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.m4a"
    __test_file_empty "$std_output"

    script_test="Audio and video/Video: Audio track/Video: Remove audio"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (no audio).mp4"
    __test_file_empty "$std_output"

    script_test="Audio and video/Video: Convert/Video: Convert to MKV"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.mkv"
    __test_file_empty "$std_output"

    script_test="Audio and video/Video: Convert/Video: Convert to MKV (no re-encoding)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (2).mkv"
    __test_file_empty "$std_output"

    script_test="Audio and video/Video: Convert/Video: Convert to MP4"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (2).mp4"
    __test_file_empty "$std_output"

    script_test="Audio and video/Video: Convert/Video: Convert to MP4 (no re-encoding)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (3).mp4"
    __test_file_empty "$std_output"

    script_test="Audio and video/Video: Convert/Video: Export to GIF"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.gif"
    __test_file_empty "$std_output"

    rm -rf "$temp_dir/Output"
    script_test="Audio and video/Video: Export frames/Video: Export frames (1 FPS)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$temp_dir/Output/Test video.mp4_frame_00001.png"
    __test_file_empty "$std_output"

    rm -rf "$temp_dir/Output"
    script_test="Audio and video/Video: Export frames/Video: Export frames (10 FPS)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$temp_dir/Output/Test video.mp4_frame_00001.png"
    __test_file_empty "$std_output"

    rm -rf "$temp_dir/Output"
    script_test="Audio and video/Video: Export frames/Video: Export frames (5 FPS)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$temp_dir/Output/Test video.mp4_frame_00001.png"
    __test_file_empty "$std_output"

    script_test="Audio and video/Video: Flip, Rotate/Video: Flip (horizontally)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (flipped-h).mp4"
    __test_file_empty "$std_output"

    script_test="Audio and video/Video: Flip, Rotate/Video: Flip (vertically)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (flipped-v).mp4"
    __test_file_empty "$std_output"

    script_test="Audio and video/Video: Flip, Rotate/Video: Rotate (180 deg)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (180 deg).mp4"
    __test_file_empty "$std_output"

    script_test="Audio and video/Video: Flip, Rotate/Video: Rotate (270 deg)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (270 deg).mp4"
    __test_file_empty "$std_output"

    script_test="Audio and video/Video: Flip, Rotate/Video: Rotate (90 deg)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (90 deg).mp4"
    __test_file_empty "$std_output"

    script_test="Audio and video/Video: Frame rate/Video: Frame rate to 30 FPS"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (30 FPS).mp4"
    __test_file_empty "$std_output"

    script_test="Audio and video/Video: Frame rate/Video: Frame rate to 60 FPS"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (60 FPS).mp4"
    __test_file_empty "$std_output"

    script_test="Audio and video/Video: Resize/Video: Resize (25 pct)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (25 pct).mp4"
    __test_file_empty "$std_output"

    script_test="Audio and video/Video: Resize/Video: Resize (50 pct)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (50 pct).mp4"
    __test_file_empty "$std_output"

    script_test="Audio and video/Video: Resize/Video: Resize (75 pct)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (75 pct).mp4"
    __test_file_empty "$std_output"

    script_test="Audio and video/Video: Speed factor/Video: Speed factor to 0.5"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (speed 0.5).mp4"
    __test_file_empty "$std_output"

    script_test="Audio and video/Video: Speed factor/Video: Speed factor to 1.5"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (speed 1.5).mp4"
    __test_file_empty "$std_output"

    script_test="Audio and video/Video: Speed factor/Video: Speed factor to 2.0"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (speed 2.0).mp4"
    __test_file_empty "$std_output"

    # -------------------------------------------------------------------------
    # SECTION /// [TESTS / Clipboard operations/]
    # -------------------------------------------------------------------------

    #script_test="Clipboard operations/Copy file content to clipboard"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Clipboard operations/Copy filename to clipboard"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Clipboard operations/Copy filename to clipboard (recursive)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Clipboard operations/Copy filepath to clipboard"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Clipboard operations/Copy filepath to clipboard (recursive)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Clipboard operations/Paste clipboard as a file"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Directories and files/Compare items"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    # -------------------------------------------------------------------------
    # SECTION /// [TESTS / Directories and files]
    # -------------------------------------------------------------------------

    script_test="Directories and files/Compare items (via Diff)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" "$input_file2" >"$std_output"
    __test_file_nonempty "$std_output"

    script_test="Directories and files/Find duplicate files"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$temp_dir" >"$std_output"
    __test_file_nonempty "$std_output"

    mkdir --parents -- "$temp_dir/Test empty dir"
    script_test="Directories and files/Find empty directories"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$temp_dir" >"$std_output"
    __test_file_nonempty "$std_output"

    touch -- "$temp_dir/.Test hidden file"
    script_test="Directories and files/Find hidden items"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$temp_dir" >"$std_output"
    __test_file_nonempty "$std_output"

    touch -- "$temp_dir/Test junk file.log"
    script_test="Directories and files/Find junk files"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$temp_dir" >"$std_output"
    __test_file_nonempty "$std_output"

    script_test="Directories and files/List recently modified files"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$temp_dir" >"$std_output"
    __test_file_nonempty "$std_output"

    #script_test="Directories and files/Flatten directory structure"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    script_test="Directories and files/List largest directories"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$temp_dir" >"$std_output"
    __test_file_nonempty "$std_output"

    script_test="Directories and files/List largest files"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$temp_dir" >"$std_output"
    __test_file_nonempty "$std_output"

    script_test="Directories and files/List permissions and owners"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$temp_dir" >"$std_output"
    __test_file_nonempty "$std_output"

    #script_test="Directories and files/Open item location"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Directories and files/Reset permissions (recursive)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$temp_dir" >"$std_output"
    #__test_file_empty "$std_output"

    script_test="Directories and files/Show files information"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$temp_dir" >"$std_output"
    __test_file_nonempty "$std_output"

    script_test="Directories and files/Show files metadata"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$temp_dir" >"$std_output"
    __test_file_nonempty "$std_output"

    script_test="Directories and files/Show files MIME types"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$temp_dir" >"$std_output"
    __test_file_nonempty "$std_output"

    # -------------------------------------------------------------------------
    # SECTION /// [TESTS / File encryption]
    # -------------------------------------------------------------------------

    #script_test="File encryption/GPG: Decrypt"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="File encryption/GPG: Encrypt with password"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="File encryption/GPG: Encrypt with password (ASCII)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="File encryption/GPG: Encrypt with public keys"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="File encryption/GPG: Encrypt with public keys (ASCII)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="File encryption/GPG: Import key"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="File encryption/GPG: Sign"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="File encryption/GPG: Sign (ASCII)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="File encryption/GPG: Sign (detached signature)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="File encryption/GPG: Verify signature"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    # -------------------------------------------------------------------------
    # SECTION /// [TESTS / Hash and checksum]
    # -------------------------------------------------------------------------

    # Create mock files for testing.
    input_file1="$temp_dir/Test hash 1"
    echo "Content of 'Test hash 1'." >"$input_file1"
    output_file=$input_file1

    script_test="Hash and checksum/Compute all file hashes"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file"
    __test_file_nonempty "$std_output"

    script_test="Hash and checksum/Compute CRC32"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file"
    __test_file_nonempty "$std_output"

    script_test="Hash and checksum/Compute MD5"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file"
    __test_file_nonempty "$std_output"

    script_test="Hash and checksum/Compute SHA1"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file"
    __test_file_nonempty "$std_output"

    script_test="Hash and checksum/Compute SHA256"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file"
    __test_file_nonempty "$std_output"

    script_test="Hash and checksum/Compute SHA512"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file"
    __test_file_nonempty "$std_output"

    script_test="Hash and checksum/Generate MD5 checksum file"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.md5"
    __test_file_empty "$std_output"

    script_test="Hash and checksum/Generate SHA1 checksum file"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.sha1"
    __test_file_empty "$std_output"

    script_test="Hash and checksum/Generate SHA256 checksum file"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.sha256"
    __test_file_empty "$std_output"

    script_test="Hash and checksum/Generate SHA512 checksum file"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.sha512"
    __test_file_empty "$std_output"

    script_test="Hash and checksum/Verify MD5 checksum file"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$output_file.md5" >"$std_output"
    __test_file_nonempty "$output_file"

    script_test="Hash and checksum/Verify SHA1 checksum file"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$output_file.sha1" >"$std_output"
    __test_file_nonempty "$output_file"

    script_test="Hash and checksum/Verify SHA256 checksum file"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$output_file.sha256" >"$std_output"
    __test_file_nonempty "$output_file"

    script_test="Hash and checksum/Verify SHA512 checksum file"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$output_file.sha512" >"$std_output"
    __test_file_nonempty "$output_file"

    # -------------------------------------------------------------------------
    # SECTION /// [TESTS / Image]
    # -------------------------------------------------------------------------

    # Create mock files for testing.
    input_file1="$temp_dir/Test image.png"
    input_file2="$temp_dir/Test image 2.png"
    output_file="$temp_dir/Test image"

    # Generate a test image.
    ffmpeg -hide_banner -y \
        -f lavfi -i color=c=red:s=200x100 -frames:v 1 \
        -update 1 "$input_file1" &>/dev/null
    cp -- "$input_file1" "$input_file2"

    script_test="Image/Image: Color/Image: Colorspace to gray"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (grayscale).png"
    __test_file_empty "$std_output"

    script_test="Image/Image: Color/Image: Desaturate"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (desaturated).png"
    __test_file_empty "$std_output"

    rm -rf "$temp_dir/Output"
    script_test="Image/Image: Color/Image: Generate multiple hues"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$temp_dir/Output/Test image (2).png"
    __test_file_empty "$std_output"

    script_test="Image/Image: Combine, Split/Image: Combine into a GIF"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" "$input_file2" >"$std_output"
    __test_file_nonempty "$temp_dir/Animated image.gif"
    __test_file_empty "$std_output"

    script_test="Image/Image: Combine, Split/Image: Combine into a PDF"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" "$input_file2" >"$std_output"
    __test_file_nonempty "$temp_dir/Combined images.pdf"
    __test_file_empty "$std_output"

    rm -rf "$temp_dir/Output"
    script_test="Image/Image: Combine, Split/Image: Split into 2 (horizontally)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$temp_dir/Output/Test image-0.png"
    __test_file_empty "$std_output"

    rm -rf "$temp_dir/Output"
    script_test="Image/Image: Combine, Split/Image: Split into 2 (vertically)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$temp_dir/Output/Test image-0.png"
    __test_file_empty "$std_output"

    rm -rf "$temp_dir/Output"
    script_test="Image/Image: Combine, Split/Image: Split into 4"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$temp_dir/Output/Test image-0.png"
    __test_file_empty "$std_output"

    script_test="Image/Image: Combine, Split/Image: Stack (horizontally)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" "$input_file2" >"$std_output"
    __test_file_nonempty "$temp_dir/Stacked images (horizontal).png"
    __test_file_empty "$std_output"

    script_test="Image/Image: Combine, Split/Image: Stack (vertically)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" "$input_file2" >"$std_output"
    __test_file_nonempty "$temp_dir/Stacked images (vertical).png"
    __test_file_empty "$std_output"

    script_test="Image/Image: Convert/Image: Convert to AVIF"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.avif"
    __test_file_empty "$std_output"

    script_test="Image/Image: Convert/Image: Convert to BMP"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.bmp"
    __test_file_empty "$std_output"

    script_test="Image/Image: Convert/Image: Convert to GIF"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.gif"
    __test_file_empty "$std_output"

    script_test="Image/Image: Convert/Image: Convert to JPG"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.jpg"
    __test_file_empty "$std_output"

    script_test="Image/Image: Convert/Image: Convert to PNG"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$output_file.jpg" >"$std_output"
    __test_file_nonempty "$output_file (2).png"
    __test_file_empty "$std_output"

    script_test="Image/Image: Convert/Image: Convert to TIF"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.tif"
    __test_file_empty "$std_output"

    script_test="Image/Image: Convert/Image: Convert to WEBP"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.webp"
    __test_file_empty "$std_output"

    script_test="Image/Image: Convert/Image: Export to PDF"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.pdf"
    __test_file_empty "$std_output"

    script_test="Image/Image: Crop, Resize/Image: Automatic crop"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (cropped).png"
    __test_file_empty "$std_output"

    script_test="Image/Image: Crop, Resize/Image: Automatic crop (15 pct)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (cropped 15 pct).png"
    __test_file_empty "$std_output"

    script_test="Image/Image: Crop, Resize/Image: Resize (25 pct)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (25 pct).png"
    __test_file_empty "$std_output"

    script_test="Image/Image: Crop, Resize/Image: Resize (50 pct)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (50 pct).png"
    __test_file_empty "$std_output"

    script_test="Image/Image: Crop, Resize/Image: Resize (75 pct)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (75 pct).png"
    __test_file_empty "$std_output"

    script_test="Image/Image: Crop, Resize/Image: Resize and crop (1920x1080)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (1920x1080).png"
    __test_file_empty "$std_output"

    script_test="Image/Image: Flip, Rotate/Image: Flip (horizontally)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (flipped-h).png"
    __test_file_empty "$std_output"

    script_test="Image/Image: Flip, Rotate/Image: Flip (vertically)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (flipped-v).png"
    __test_file_empty "$std_output"

    script_test="Image/Image: Flip, Rotate/Image: Rotate (180 deg)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (180 deg).png"
    __test_file_empty "$std_output"

    script_test="Image/Image: Flip, Rotate/Image: Rotate (270 deg)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (270 deg).png"
    __test_file_empty "$std_output"

    script_test="Image/Image: Flip, Rotate/Image: Rotate (90 deg)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (90 deg).png"
    __test_file_empty "$std_output"

    script_test="Image/Image: Icons/Image: Create PNG icon (128 px)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (icon 128 px).png"
    __test_file_empty "$std_output"

    script_test="Image/Image: Icons/Image: Create PNG icon (256 px)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (icon 256 px).png"
    __test_file_empty "$std_output"

    script_test="Image/Image: Icons/Image: Create PNG icon (512 px)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (icon 512 px).png"
    __test_file_empty "$std_output"

    script_test="Image/Image: Icons/Image: Create PNG icon (64 px)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (icon 64 px).png"
    __test_file_empty "$std_output"

    script_test="Image/Image: Optimize, Reduce/Image: Optimize PNG"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (optimized).png"
    __test_file_empty "$std_output"

    script_test="Image/Image: Optimize, Reduce/Image: Reduce (JPG, 1000kB max)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (reduced).jpg"
    __test_file_empty "$std_output"

    script_test="Image/Image: Optimize, Reduce/Image: Reduce (JPG, 500kB max)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (reduced) (2).jpg"
    __test_file_empty "$std_output"

    script_test="Image/Image: Optimize, Reduce/Image: Remove metadata"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (no metadata).png"
    __test_file_empty "$std_output"

    #script_test="Image/Image: Similarity/Image: Find similar (65 pct)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Image/Image: Similarity/Image: Find similar (75 pct)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Image/Image: Similarity/Image: Find similar (85 pct)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Image/Image: Similarity/Image: Find similar (95 pct)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    script_test="Image/Image: Text recognition (OCR)/Image: Perform OCR (English)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_empty "$output_file (OCR eng).txt"
    __test_file_empty "$std_output"

    #script_test="Image/Image: Text recognition (OCR)/Image: Perform OCR (French)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Image/Image: Text recognition (OCR)/Image: Perform OCR (German)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Image/Image: Text recognition (OCR)/Image: Perform OCR (Italian)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Image/Image: Text recognition (OCR)/Image: Perform OCR (Portuguese)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Image/Image: Text recognition (OCR)/Image: Perform OCR (Russian)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Image/Image: Text recognition (OCR)/Image: Perform OCR (Spanish)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    script_test="Image/Image: Transparency/Image: Background to alpha"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (alpha).png"
    __test_file_empty "$std_output"

    script_test="Image/Image: Transparency/Image: Background to alpha (15 pct)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (alpha 15 pct).png"
    __test_file_empty "$std_output"

    script_test="Image/Image: Transparency/Image: Color alpha to black"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (bg black).png"
    __test_file_empty "$std_output"

    script_test="Image/Image: Transparency/Image: Color alpha to magenta"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (bg magenta).png"
    __test_file_empty "$std_output"

    script_test="Image/Image: Transparency/Image: Color alpha to white"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (bg white).png"
    __test_file_empty "$std_output"

    script_test="Image/Image: Transparency/Image: Color black to alpha"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (alpha) (2).png"
    __test_file_empty "$std_output"

    script_test="Image/Image: Transparency/Image: Color black to alpha (15 pct)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (alpha 15 pct) (2).png"
    __test_file_empty "$std_output"

    script_test="Image/Image: Transparency/Image: Color magenta to alpha"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (alpha) (3).png"
    __test_file_empty "$std_output"

    script_test="Image/Image: Transparency/Image: Color magenta to alpha (15 pct)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (alpha 15 pct) (3).png"
    __test_file_empty "$std_output"

    script_test="Image/Image: Transparency/Image: Color white to alpha"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (alpha) (4).png"
    __test_file_empty "$std_output"

    script_test="Image/Image: Transparency/Image: Color white to alpha (15 pct)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (alpha 15 pct) (4).png"
    __test_file_empty "$std_output"

    #script_test="Image/Image: Watermark/Image: Add watermark (center)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Image/Image: Watermark/Image: Add watermark (north)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Image/Image: Watermark/Image: Add watermark (northeast)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Image/Image: Watermark/Image: Add watermark (northwest)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Image/Image: Watermark/Image: Add watermark (south)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Image/Image: Watermark/Image: Add watermark (southeast)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Image/Image: Watermark/Image: Add watermark (southwest)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    # -------------------------------------------------------------------------
    # SECTION /// [TESTS / Image: SVG files]
    # -------------------------------------------------------------------------

    # Create mock files for testing.
    input_file1="$temp_dir/Test image SVG 1.svg"
    input_file2="$temp_dir/Test image SVG 2.svg"
    output_file="$temp_dir/Test image SVG 1"
    cp -- "$ROOT_DIR/.assets/screenshot.svg" "$input_file1"
    cp -- "$input_file1" "$input_file2"

    script_test="Image/Image: SVG files/SVG: Compress to SVGZ"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.svgz"
    __test_file_empty "$std_output"

    script_test="Image/Image: SVG files/SVG: Decompress SVGZ"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$output_file.svgz" >"$std_output"
    __test_file_nonempty "$output_file (2).svg"
    __test_file_empty "$std_output"

    script_test="Image/Image: SVG files/SVG: Export to EPS"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.eps"
    __test_file_empty "$std_output"

    script_test="Image/Image: SVG files/SVG: Export to PDF"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.pdf"
    __test_file_empty "$std_output"

    script_test="Image/Image: SVG files/SVG: Export to PNG (1024 px)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (1024 px).png"
    __test_file_empty "$std_output"

    script_test="Image/Image: SVG files/SVG: Export to PNG (256 px)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (256 px).png"
    __test_file_empty "$std_output"

    script_test="Image/Image: SVG files/SVG: Export to PNG (512 px)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (512 px).png"
    __test_file_empty "$std_output"

    script_test="Image/Image: SVG files/SVG: Replace fonts to 'Charter'"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (font Charter).svg"
    __test_file_empty "$std_output"

    script_test="Image/Image: SVG files/SVG: Replace fonts to 'Helvetica'"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (font Helvetica).svg"
    __test_file_empty "$std_output"

    script_test="Image/Image: SVG files/SVG: Replace fonts to 'Times'"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (font Times).svg"
    __test_file_empty "$std_output"

    # -------------------------------------------------------------------------
    # SECTION /// [TESTS / Document]
    # -------------------------------------------------------------------------

    # Create mock files for testing.
    input_file1="$temp_dir/Test document 1.odt"
    input_file2="$temp_dir/Test document 2.odt"
    output_file="$temp_dir/Test document 1"
    sample_file=$(find / -type f -iname "*.odt" -size -5M -print -quit 2>/dev/null)
    cp -- "$sample_file" "$input_file1"
    cp -- "$input_file1" "$input_file2"

    script_test="Document/Document: Convert/Document: Convert to TXT"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.txt"
    __test_file_empty "$std_output"

    script_test="Document/Document: Convert/Document: Convert to EPUB"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.epub"
    __test_file_empty "$std_output"

    script_test="Document/Document: Convert/Document: Convert to FB2"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.fb2"
    __test_file_empty "$std_output"

    script_test="Document/Document: Convert/Document: Convert to Markdown"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.md"
    __test_file_empty "$std_output"

    script_test="Document/Document: Convert/Document: Convert to DOCX"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.docx"
    __test_file_empty "$std_output"

    input_file1="$temp_dir/Test document 1.docx"
    script_test="Document/Document: Convert/Document: Convert to ODT"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (2).odt"
    __test_file_empty "$std_output"

    script_test="Document/Document: Convert/Document: Convert to ODS"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.ods"
    __test_file_empty "$std_output"

    script_test="Document/Document: Convert/Document: Convert to XLSX"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.xlsx"
    __test_file_empty "$std_output"

    script_test="Document/Document: Convert/Document: Convert to PDF"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.pdf"
    __test_file_empty "$std_output"

    # Create mock files for testing.
    #input_file1="$temp_dir/Test document (presentation) 1.otp"
    #input_file2="$temp_dir/Test document (presentation) 2.otp"
    #output_file="$temp_dir/Test document (presentation) 1"
    #sample_file=$(find / -type f -iname "*.otp" -size -5M -print -quit 2>/dev/null)
    #cp -- "$sample_file" "$input_file1"
    #cp -- "$input_file1" "$input_file2"

    #script_test="Document/Document: Convert/Document: Convert to ODP"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file.odp"
    #__test_file_empty "$std_output"

    #script_test="Document/Document: Convert/Document: Convert to PPTX"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file.pptx"
    #__test_file_empty "$std_output"

    #script_test="Document/Document: Print/Document: Print (A4)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Document/Document: Print/Document: Print (US Legal)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Document/Document: Print/Document: Print (US Letter)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    # -------------------------------------------------------------------------
    # SECTION /// [TESTS / Document: PDF]
    # -------------------------------------------------------------------------

    # Create mock files for testing.
    input_file1="$temp_dir/Test document PDF 1.pdf"
    input_file2="$temp_dir/Test document PDF 2.pdf"
    output_file="$temp_dir/Test document PDF 1"
    cp -- "$temp_dir/Combined images.pdf" "$input_file1"
    cp -- "$input_file1" "$input_file2"

    script_test="Document/PDF: Annotations/PDF: Find annotated files"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$temp_dir" >"$std_output"
    __test_file_empty "$std_output"

    script_test="Document/PDF: Annotations/PDF: Remove annotations"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (no annotations).pdf"
    __test_file_empty "$std_output"

    script_test="Document/PDF: Combine, Split/PDF: Combine multiple files"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" "$input_file2" >"$std_output"
    __test_file_nonempty "$temp_dir/Combined documents.pdf"
    __test_file_empty "$std_output"

    rm -rf "$temp_dir/Output"
    script_test="Document/PDF: Combine, Split/PDF: Split into single-page files"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$temp_dir/Output/Test document PDF 1.0001.pdf"
    __test_file_empty "$std_output"

    #script_test="Document/PDF: Encrypt, Decrypt/PDF: Decrypt (remove password)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file (decrypted).pdf"
    #__test_file_empty "$std_output"

    #script_test="Document/PDF: Encrypt, Decrypt/PDF: Encrypt (set a password)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    script_test="Document/PDF: Encrypt, Decrypt/PDF: Find password-encrypted files"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$temp_dir" >"$std_output"
    __test_file_empty "$std_output"

    script_test="Document/PDF: Multiple-page layout/PDF: Layout (landscape, 1x2)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (landscape, 1x2).pdf"
    __test_file_empty "$std_output"

    script_test="Document/PDF: Multiple-page layout/PDF: Layout (landscape, 2x1)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (landscape, 2x1).pdf"
    __test_file_empty "$std_output"

    script_test="Document/PDF: Multiple-page layout/PDF: Layout (landscape, 2x2)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (landscape, 2x2).pdf"
    __test_file_empty "$std_output"

    script_test="Document/PDF: Multiple-page layout/PDF: Layout (landscape, 2x4)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (landscape, 2x4).pdf"
    __test_file_empty "$std_output"

    script_test="Document/PDF: Multiple-page layout/PDF: Layout (landscape, 4x2)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (landscape, 4x2).pdf"
    __test_file_empty "$std_output"

    script_test="Document/PDF: Multiple-page layout/PDF: Layout (portrait, 1x2)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (portrait, 1x2).pdf"
    __test_file_empty "$std_output"

    script_test="Document/PDF: Multiple-page layout/PDF: Layout (portrait, 2x1)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (portrait, 2x1).pdf"
    __test_file_empty "$std_output"

    script_test="Document/PDF: Multiple-page layout/PDF: Layout (portrait, 2x2)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (portrait, 2x2).pdf"
    __test_file_empty "$std_output"

    script_test="Document/PDF: Multiple-page layout/PDF: Layout (portrait, 2x4)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (portrait, 2x4).pdf"
    __test_file_empty "$std_output"

    script_test="Document/PDF: Multiple-page layout/PDF: Layout (portrait, 4x2)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (portrait, 4x2).pdf"
    __test_file_empty "$std_output"

    script_test="Document/PDF: Optimize, Reduce/PDF: Find non-linearized files"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$temp_dir" >"$std_output"
    __test_file_nonempty "$std_output"

    script_test="Document/PDF: Optimize, Reduce/PDF: Optimize for web (linearize)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (linearized).pdf"
    __test_file_empty "$std_output"

    script_test="Document/PDF: Optimize, Reduce/PDF: Reduce (150 dpi, e-book)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (150 dpi, e-book).pdf"
    __test_file_empty "$std_output"

    script_test="Document/PDF: Optimize, Reduce/PDF: Reduce (300 dpi, printer)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (300 dpi, printer).pdf"
    __test_file_empty "$std_output"

    script_test="Document/PDF: Paper size/PDF: Paper size to A3"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (paper A3).pdf"
    __test_file_empty "$std_output"

    script_test="Document/PDF: Paper size/PDF: Paper size to A4"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (paper A4).pdf"
    __test_file_empty "$std_output"

    script_test="Document/PDF: Paper size/PDF: Paper size to A5"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (paper A5).pdf"
    __test_file_empty "$std_output"

    script_test="Document/PDF: Paper size/PDF: Paper size to US Legal"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (paper US Legal).pdf"
    __test_file_empty "$std_output"

    script_test="Document/PDF: Paper size/PDF: Paper size to US Letter"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (paper US Letter).pdf"
    __test_file_empty "$std_output"

    script_test="Document/PDF: Rotate/PDF: Rotate (180 deg)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (180 deg).pdf"
    __test_file_empty "$std_output"

    script_test="Document/PDF: Rotate/PDF: Rotate (270 deg)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (270 deg).pdf"
    __test_file_empty "$std_output"

    script_test="Document/PDF: Rotate/PDF: Rotate (90 deg)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (90 deg).pdf"
    __test_file_empty "$std_output"

    script_test="Document/PDF: Signatures/PDF: Find signed files"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$temp_dir" >"$std_output"
    __test_file_empty "$std_output"

    script_test="Document/PDF: Signatures/PDF: Show signatures"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$temp_dir" >"$std_output"
    __test_file_nonempty "$std_output"

    script_test="Document/PDF: Text recognition (OCR)/PDF: Find non-searchable files"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$temp_dir" >"$std_output"
    __test_file_nonempty "$std_output"

    #script_test="Document/PDF: Text recognition (OCR)/PDF: Perform OCR (English)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Document/PDF: Text recognition (OCR)/PDF: Perform OCR (French)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Document/PDF: Text recognition (OCR)/PDF: Perform OCR (German)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Document/PDF: Text recognition (OCR)/PDF: Perform OCR (Italian)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Document/PDF: Text recognition (OCR)/PDF: Perform OCR (Portuguese)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Document/PDF: Text recognition (OCR)/PDF: Perform OCR (Russian)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Document/PDF: Text recognition (OCR)/PDF: Perform OCR (Spanish)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    script_test="Document/PDF: Tools/PDF: Convert to PDFA-2b"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (PDFA-2b).pdf"
    __test_file_empty "$std_output"

    rm -rf "$temp_dir/Output"
    script_test="Document/PDF: Tools/PDF: Extract images"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$temp_dir/Output/Test document PDF 1-000.png"
    __test_file_empty "$std_output"

    script_test="Document/PDF: Tools/PDF: Remove metadata"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (no metadata).pdf"
    __test_file_empty "$std_output"

    #script_test="Document/PDF: Watermark/PDF: Add watermark (overlay)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Document/PDF: Watermark/PDF: Add watermark (underlay)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    # -------------------------------------------------------------------------
    # SECTION /// [TESTS / Link operations]
    # -------------------------------------------------------------------------

    # Create mock files for testing.
    input_file1="$temp_dir/link"
    echo "Content of 'link'." >"$input_file1"

    script_test="Link operations/Create hard link here"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$temp_dir/Hard link to link"
    __test_file_empty "$std_output"

    #script_test="Link operations/Create hard link to..."
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    script_test="Link operations/Create symbolic link here"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$temp_dir/Link to link"
    __test_file_empty "$std_output"

    #script_test="Link operations/Create symbolic link to Desktop"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Link operations/Create symbolic link to..."
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    script_test="Link operations/List hard links"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$temp_dir" >"$std_output"
    __test_file_nonempty "$std_output"

    script_test="Link operations/List symbolic links"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$temp_dir" >"$std_output"
    __test_file_nonempty "$std_output"

    rm -- "$input_file1"
    script_test="Link operations/Find broken links"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$temp_dir" >"$std_output"
    __test_file_nonempty "$std_output"

    #script_test="Link operations/Paste as hard link"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Link operations/Paste as symbolic link"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    # -------------------------------------------------------------------------
    # SECTION /// [TESTS / Network and internet]
    # -------------------------------------------------------------------------

    # TODO: Implement this test.
    #script_test="Network and internet/Git: Clone URLs (clipboard, file)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    # TODO: Implement this test.
    #script_test="Network and internet/Git: Open repository website"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    # TODO: Implement this test.
    #script_test="Network and internet/Git: Reset and pull"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    # TODO: Implement this test.
    #script_test="Network and internet/IP: Ping hosts"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    # TODO: Implement this test.
    #script_test="Network and internet/IP: Scan ports"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    # TODO: Implement this test.
    #script_test="Network and internet/IP: Test hosts availability"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    # TODO: Implement this test.
    #script_test="Network and internet/URL: Check HTTP status"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    # TODO: Implement this test.
    #script_test="Network and internet/URL: Check SSL expiry"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    # TODO: Implement this test.
    #script_test="Network and internet/URL: Download (clipboard, file)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    # TODO: Implement this test.
    #script_test="Network and internet/URL: List HTTP headers"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_nonempty "$std_output"

    # -------------------------------------------------------------------------
    # SECTION /// [TESTS / Open with]
    # -------------------------------------------------------------------------

    #script_test="Open with/Code Editor"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Open with/Disk Usage Analyzer"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Open with/Terminal"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    # -------------------------------------------------------------------------
    # SECTION /// [TESTS / Plain text]
    # -------------------------------------------------------------------------

    # Create mock files for testing.
    input_file1="$temp_dir/Test text 1.txt"
    input_file2="$temp_dir/Test text 2.txt"
    output_file="$temp_dir/Test text 1"
    echo "Content of 'Test text 1'." >"$input_file1"
    echo "Content of 'Test text 2'." >"$input_file2"

    script_test="Plain text/Text: Encodings/Text: Encode to ISO-8859-1"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (ISO-8859-1).txt"
    __test_file_empty "$std_output"

    script_test="Plain text/Text: Encodings/Text: Encode to UTF-8"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (UTF-8).txt"
    __test_file_empty "$std_output"

    script_test="Plain text/Text: Encodings/Text: List encodings"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$std_output"

    script_test="Plain text/Text: Indentation/Text: Convert '4 spaces' to 'tabs'"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (tabs).txt"
    __test_file_empty "$std_output"

    script_test="Plain text/Text: Indentation/Text: Convert '8 spaces' to 'tabs'"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (tabs) (2).txt"
    __test_file_empty "$std_output"

    script_test="Plain text/Text: Indentation/Text: Convert 'tabs' to '4 spaces'"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (4 spaces).txt"
    __test_file_empty "$std_output"

    script_test="Plain text/Text: Indentation/Text: Convert 'tabs' to '8 spaces'"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (8 spaces).txt"
    __test_file_empty "$std_output"

    script_test="Plain text/Text: Line breaks/Text: Line breaks to CRLF (Windows)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (CRLF).txt"
    __test_file_empty "$std_output"

    script_test="Plain text/Text: Line breaks/Text: Line breaks to LF (Unix)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (LF).txt"
    __test_file_empty "$std_output"

    script_test="Plain text/Text: Line breaks/Text: List line breaks"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$std_output"

    script_test="Plain text/Text: Statistics/Text: List line count"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$std_output"

    script_test="Plain text/Text: Statistics/Text: List max line length"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$std_output"

    script_test="Plain text/Text: Statistics/Text: List word count"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$std_output"

    script_test="Plain text/Text: Tools/Text: Concatenate multiple files"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" "$input_file2" >"$std_output"
    __test_file_nonempty "$temp_dir/Concatenated files.txt"
    __test_file_empty "$std_output"

    # TODO: Implement this test.
    #script_test="Plain text/Text: Tools/Text: Convert UTF-8 CRLF (recursive)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file.bak"
    #__test_file_empty "$std_output"

    # TODO: Implement this test.
    #script_test="Plain text/Text: Tools/Text: Convert UTF-8 LF (recursive)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file (LF).txt"
    #__test_file_empty "$std_output"

    script_test="Plain text/Text: Tools/Text: List file issues"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_empty "$std_output"

    script_test="Plain text/Text: Tools/Text: List files with bad chars"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_empty "$std_output"

    script_test="Plain text/Text: Tools/Text: Remove trailing spaces"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (no trailing).txt"
    __test_file_empty "$std_output"

    # -------------------------------------------------------------------------
    # SECTION /// [TESTS / Rename files]
    # -------------------------------------------------------------------------

    # TODO: Implement this test.
    #script_test="Rename files/Rename: Remove accents (translit.)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    # TODO: Implement this test.
    #script_test="Rename files/Rename: Remove brackets"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    # TODO: Implement this test.
    #script_test="Rename files/Rename: Replace gaps with dashes"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    # TODO: Implement this test.
    #script_test="Rename files/Rename: Replace gaps with spaces"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    # TODO: Implement this test.
    #script_test="Rename files/Rename: Replace gaps with underscores"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    # TODO: Implement this test.
    #script_test="Rename files/Rename: To lowercase"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    # TODO: Implement this test.
    #script_test="Rename files/Rename: To lowercase (recursive)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    # TODO: Implement this test.
    #script_test="Rename files/Rename: To sentence case"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    # TODO: Implement this test.
    #script_test="Rename files/Rename: To title case"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    # TODO: Implement this test.
    #script_test="Rename files/Rename: To uppercase"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    # TODO: Implement this test.
    #script_test="Rename files/Rename: To uppercase (recursive)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    # -------------------------------------------------------------------------
    # SECTION /// [TESTS / Security and recovery]
    # -------------------------------------------------------------------------

    #script_test="Security and recovery/File carving (via Foremost)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Security and recovery/File carving (via PhotoRec)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Security and recovery/Scan for malware (via ClamAV)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    # TODO: Implement this test.
    #script_test="Security and recovery/Shred files (secure delete)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    printf "\nFinished! "
    printf "Results: %s tests, %s failed.\n" "$_TOTAL_TESTS" "$_TOTAL_FAILED"

    read -n1 -rp "Press any key to finish..." </dev/tty
}

_main "$@"
