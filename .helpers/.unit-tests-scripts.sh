#!/usr/bin/env bash

# Test all scripts.

# Source the script '.common-functions.sh'.
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
ROOT_DIR=$(grep --only-matching "^.*scripts[^/]*" <<<"$SCRIPT_DIR")
source "$ROOT_DIR/.common-functions.sh"

# Disable GUI for testing on terminal.
unset "DISPLAY"

# Enable automatic 'yes' for testing.
export DEBUG="true"

#------------------------------------------------------------------------------
#region Global variables
#------------------------------------------------------------------------------

_TOTAL_TESTS=0
_TOTAL_FAILED=0

#endregion
#------------------------------------------------------------------------------
#region Test functions
#------------------------------------------------------------------------------

__test_file_empty() {
    local file=$1

    ((_TOTAL_TESTS++))

    if [[ -f "$file" && ! -s "$file" ]]; then
        printf "[\033[32m PASS \033[0m] "
        printf "\033[32mTest file (empty).\033[0m\n"
    else
        printf "[\033[31mFAILED\033[0m] "
        printf "\033[31mTest file (empty).\033[0m\n"
        printf "[\033[31m FILE \033[0m] "
        printf "\033[31m"
        printf "%s" "$file" | sed -z "s|\n|\\\n|g" | cat -A
        printf "\033[0m\n"
        ((_TOTAL_FAILED++))
    fi
}

__test_file_nonempty() {
    local file=$1

    ((_TOTAL_TESTS++))

    if [[ -f "$file" && -s "$file" ]]; then
        printf "[\033[32m PASS \033[0m] "
        printf "\033[32mTest file (non empty).\033[0m\n"
    else
        printf "[\033[31mFAILED\033[0m] "
        printf "\033[31mTest file (non empty).\033[0m\n"
        printf "[\033[31m FILE \033[0m] "
        printf "\033[31m"
        printf "%s" "$file" | sed -z "s|\n|\\\n|g" | cat -A
        printf "\033[0m\n"
        ((_TOTAL_FAILED++))
    fi
}

__echo_script() {
    echo
    echo -e "[\033[36mSCRIPT\033[0m] $1"
}

#endregion
#------------------------------------------------------------------------------
#region Tests
#------------------------------------------------------------------------------

_main() {
    local script_test=""
    local input_file1=""
    local input_dir1=""
    local input_file2=""
    local output_file=""
    local temp_dir=$TEMP_DIR_TASK

    local std_output="$temp_dir/std_output.txt"
    touch -- "$std_output"

    _check_dependencies "ffmpeg"

    _open_items_locations "$std_output" "true"

    #--------------------------------------------------------------------------
    #region Archive
    #--------------------------------------------------------------------------

    # Create mock files for testing.
    input_dir1="$temp_dir/Test archive"
    mkdir --parents -- "$input_dir1"
    input_file1="$input_dir1/Test archive 1"
    input_file2="$input_dir1/Test archive 2"
    echo "Content of 'Test archive'." >"$input_file1"
    echo "Content of 'Test archive 2'." >"$input_file2"
    output_file=$input_dir1

    script_test="Archive/Compress to '7z'"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_dir1" >"$std_output"
    __test_file_nonempty "$output_file.7z"
    __test_file_empty "$std_output"

    #script_test="Archive/Compress to '7z' with password"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_dir1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    script_test="Archive/Compress to 'tar.gz'"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_dir1" >"$std_output"
    __test_file_nonempty "$output_file.tar.gz"
    __test_file_empty "$std_output"

    script_test="Archive/Compress to 'tar.xz'"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_dir1" >"$std_output"
    __test_file_nonempty "$output_file.tar.xz"
    __test_file_empty "$std_output"

    script_test="Archive/Compress to 'tar.zst'"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_dir1" >"$std_output"
    __test_file_nonempty "$output_file.tar.zst"
    __test_file_empty "$std_output"

    script_test="Archive/Compress to 'zip'"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_dir1" >"$std_output"
    __test_file_nonempty "$output_file.zip"
    __test_file_empty "$std_output"

    script_test="Archive/Extract here"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$output_file.zip" >"$std_output"
    __test_file_nonempty "$output_file (2)/Test archive 1"
    __test_file_empty "$std_output"

    #endregion
    #--------------------------------------------------------------------------
    #region Audio
    #--------------------------------------------------------------------------

    # Create mock files for testing.
    input_file1="$temp_dir/Test audio.mp3"
    input_file2="$temp_dir/Test audio 2.mp3"
    output_file="$temp_dir/Test audio"

    ffmpeg -hide_banner -y \
        -f lavfi -i "sine=frequency=440:duration=5" \
        "$input_file1" &>/dev/null
    cp -- "$input_file1" "$input_file2"

    script_test="Directories and Files/Show media information"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$std_output"

    script_test="Audio and Video/Audio and Video: Tools/Media: Show basic metadata"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$std_output"

    script_test="Audio and Video/Audio and Video: Tools/Media: Concatenate files"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" "$input_file2" >"$std_output"
    __test_file_nonempty "$temp_dir/Concatenated media.mp3"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Audio and Video: Tools/Media: Remove metadata"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (no metadata).mp3"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Audio: Channels/Audio: Mix channels to mono"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (mono).mp3"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Audio: Channels/Audio: Mix two files"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" "$input_file2" >"$std_output"
    __test_file_nonempty "$temp_dir/Mixed audio.wav"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Audio: Convert/Audio: Convert to FLAC"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.flac"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Audio: Convert/Audio: Convert to MP3 (192 kbps)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (2).mp3"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Audio: Convert/Audio: Convert to MP3 (320 kbps)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (3).mp3"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Audio: Convert/Audio: Convert to MP3 (48 kbps)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (4).mp3"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Audio: Convert/Audio: Convert to OGG (192 kbps)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.ogg"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Audio: Convert/Audio: Convert to OGG (320 kbps)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (2).ogg"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Audio: Convert/Audio: Convert to OGG (48 kbps)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (3).ogg"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Audio: Convert/Audio: Convert to OPUS (192 kbps)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.opus"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Audio: Convert/Audio: Convert to OPUS (320 kbps)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (2).opus"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Audio: Convert/Audio: Convert to OPUS (48 kbps)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (3).opus"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Audio: Convert/Audio: Convert to WAV"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.wav"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Audio: Effects/Audio: Fade-in"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (fade-in).mp3"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Audio: Effects/Audio: Fade-out"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (fade-out).mp3"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Audio: Effects/Audio: Volume normalize"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (normalized).mp3"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Audio: Effects/Audio: Remove silence (sections)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (no silence).mp3"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Audio: Effects/Audio: Silence noise"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (noise silenced).mp3"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Audio: Effects/Audio: Remove silence (extremities)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (no silence) (2).mp3"
    __test_file_empty "$std_output"

    #script_test="Audio and Video/Audio: MP3 files/MP3: Maximize gain (recursive)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file.mp3.bak"
    #__test_file_empty "$std_output"

    #script_test="Audio and Video/Audio: MP3 files/MP3: Normalize gain (recursive)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file.mp3.bak"
    #__test_file_empty "$std_output"

    script_test="Audio and Video/Audio: MP3 files/MP3: Show encoding details"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$std_output"

    script_test="Audio and Video/Audio: Quality/Audio: Check quality"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$std_output"

    script_test="Audio and Video/Audio: Quality/Audio: Produce a spectrogram"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.png"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Audio: MP3 files/MP3: (artist - title) Name to ID3"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Audio: MP3 files/MP3: (artist - title) ID3 to Name"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$temp_dir/ - Test audio.mp3"
    __test_file_empty "$std_output"

    #endregion
    #--------------------------------------------------------------------------
    #region Video
    #--------------------------------------------------------------------------

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

    script_test="Audio and Video/Video: Aspect ratio/Video: Aspect to 1:1"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (aspect 1:1).mp4"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Video: Aspect ratio/Video: Aspect to 16:10"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (aspect 16:10).mp4"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Video: Aspect ratio/Video: Aspect to 16:9"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (aspect 16:9).mp4"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Video: Aspect ratio/Video: Aspect to 4:3"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (aspect 4:3).mp4"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Video: Audio track/Video: Extract audio"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.m4a"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Video: Audio track/Video: Remove audio"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (no audio).mp4"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Video: Convert/Video: Convert to MKV"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.mkv"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Video: Convert/Video: Convert to MKV (copy)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (2).mkv"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Video: Convert/Video: Convert to MP4"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (2).mp4"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Video: Convert/Video: Convert to MP4 (copy)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (3).mp4"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Video: Convert/Video: Convert to WebM"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.webm"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Video: Convert/Video: Convert to WebM (copy)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (2).webm"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Video: Convert/Video: Export to GIF (1 FPS)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (1 FPS).gif"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Video: Convert/Video: Export to GIF (5 FPS)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (5 FPS).gif"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Video: Convert/Video: Export to GIF (10 FPS)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (10 FPS).gif"
    __test_file_empty "$std_output"

    rm -rf "$temp_dir/Output"
    script_test="Audio and Video/Video: Export frames/Video: Export frames (1 FPS)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$temp_dir/Output/Test video.mp4_frame_00001.png"
    __test_file_empty "$std_output"

    rm -rf "$temp_dir/Output"
    script_test="Audio and Video/Video: Export frames/Video: Export frames (10 FPS)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$temp_dir/Output/Test video.mp4_frame_00001.png"
    __test_file_empty "$std_output"

    rm -rf "$temp_dir/Output"
    script_test="Audio and Video/Video: Export frames/Video: Export frames (5 FPS)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$temp_dir/Output/Test video.mp4_frame_00001.png"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Video: Flip, Rotate/Video: Flip (horizontal)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (flipped-h).mp4"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Video: Flip, Rotate/Video: Flip (vertical)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (flipped-v).mp4"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Video: Flip, Rotate/Video: Rotate (180 deg)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (180 deg).mp4"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Video: Flip, Rotate/Video: Rotate (270 deg)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (270 deg).mp4"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Video: Flip, Rotate/Video: Rotate (90 deg)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (90 deg).mp4"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Video: Frame rate/Video: Frame rate to 30 FPS"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (30 FPS).mp4"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Video: Frame rate/Video: Frame rate to 60 FPS"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (60 FPS).mp4"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Video: Resize/Video: Resize (25 pct)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (25 pct).mp4"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Video: Resize/Video: Resize (50 pct)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (50 pct).mp4"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Video: Resize/Video: Resize (75 pct)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (75 pct).mp4"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Video: Speed/Video: Speed to 0.5"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (speed 0.5).mp4"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Video: Speed/Video: Speed to 1.5"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (speed 1.5).mp4"
    __test_file_empty "$std_output"

    script_test="Audio and Video/Video: Speed/Video: Speed to 2.0"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (speed 2.0).mp4"
    __test_file_empty "$std_output"

    #endregion
    #--------------------------------------------------------------------------
    #region Clipboard
    #--------------------------------------------------------------------------

    #script_test="Clipboard/Copy file contents"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Clipboard/Copy file names"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Clipboard/Copy file names (recursive)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Clipboard/Copy file paths"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Clipboard/Copy file paths (recursive)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Clipboard/Paste clipboard content"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Directories and Files/Compare items"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #endregion
    #--------------------------------------------------------------------------
    #region Directories and Files
    #--------------------------------------------------------------------------

    script_test="Directories and Files/Compare items (via Diff)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" "$input_file2" >"$std_output"
    __test_file_nonempty "$std_output"

    script_test="Directories and Files/Find duplicate files"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$temp_dir" >"$std_output"
    __test_file_nonempty "$std_output"

    mkdir --parents -- "$temp_dir/Test empty dir"
    script_test="Directories and Files/Find empty directories"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$temp_dir" >"$std_output"
    __test_file_nonempty "$std_output"

    touch -- "$temp_dir/.Test hidden file"
    script_test="Directories and Files/List hidden files"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$temp_dir" >"$std_output"
    __test_file_nonempty "$std_output"

    touch -- "$temp_dir/Test junk file.log"
    script_test="Directories and Files/Find junk files"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$temp_dir" >"$std_output"
    __test_file_nonempty "$std_output"

    script_test="Directories and Files/Find empty files"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$temp_dir" >"$std_output"
    __test_file_nonempty "$std_output"

    script_test="Directories and Files/List recent files"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$temp_dir" >"$std_output"
    __test_file_nonempty "$std_output"

    #script_test="Directories and Files/Flatten directory structure"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    script_test="Directories and Files/List largest directories"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$temp_dir" >"$std_output"
    __test_file_nonempty "$std_output"

    script_test="Directories and Files/List largest files"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$temp_dir" >"$std_output"
    __test_file_nonempty "$std_output"

    script_test="Directories and Files/List permissions and owners"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$temp_dir" >"$std_output"
    __test_file_nonempty "$std_output"

    #script_test="Directories and Files/Open item location"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Directories and Files/Reset permissions (recursive)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$temp_dir" >"$std_output"
    #__test_file_empty "$std_output"

    script_test="Directories and Files/Show files information"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$temp_dir" >"$std_output"
    __test_file_nonempty "$std_output"

    script_test="Directories and Files/Show files metadata"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$temp_dir" >"$std_output"
    __test_file_nonempty "$std_output"

    script_test="Directories and Files/Show files MIME type"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$temp_dir" >"$std_output"
    __test_file_nonempty "$std_output"

    #endregion
    #--------------------------------------------------------------------------
    #region Encryption
    #--------------------------------------------------------------------------

    #script_test="Encryption/Decrypt"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Encryption/Encrypt with password"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Encryption/Encrypt with password (ASCII)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Encryption/Encrypt with keys"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Encryption/Encrypt with keys (ASCII)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Encryption/Import key"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Encryption/Sign"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Encryption/Sign (ASCII)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Encryption/Sign (detached signature)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Encryption/Verify signature"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #endregion
    #--------------------------------------------------------------------------
    #region Checksum
    #--------------------------------------------------------------------------

    # Create mock files for testing.
    input_file1="$temp_dir/Test hash"
    echo "Content of 'Test hash'." >"$input_file1"
    output_file=$input_file1

    script_test="Checksum/Compute all checksums"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file"
    __test_file_nonempty "$std_output"

    script_test="Checksum/Compute MD5"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file"
    __test_file_nonempty "$std_output"

    script_test="Checksum/Compute SHA1"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file"
    __test_file_nonempty "$std_output"

    script_test="Checksum/Compute SHA256"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file"
    __test_file_nonempty "$std_output"

    script_test="Checksum/Compute SHA512"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file"
    __test_file_nonempty "$std_output"

    script_test="Checksum/Generate MD5 file"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.md5"
    __test_file_empty "$std_output"

    script_test="Checksum/Generate SHA1 file"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.sha1"
    __test_file_empty "$std_output"

    script_test="Checksum/Generate SHA256 file"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.sha256"
    __test_file_empty "$std_output"

    script_test="Checksum/Generate SHA512 file"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.sha512"
    __test_file_empty "$std_output"

    script_test="Checksum/Verify MD5 file"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$output_file.md5" >"$std_output"
    __test_file_nonempty "$output_file"

    script_test="Checksum/Verify SHA1 file"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$output_file.sha1" >"$std_output"
    __test_file_nonempty "$output_file"

    script_test="Checksum/Verify SHA256 file"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$output_file.sha256" >"$std_output"
    __test_file_nonempty "$output_file"

    script_test="Checksum/Verify SHA512 file"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$output_file.sha512" >"$std_output"
    __test_file_nonempty "$output_file"

    #endregion
    #--------------------------------------------------------------------------
    #region Image
    #--------------------------------------------------------------------------

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
    script_test="Image/Image: Combine, Split/Image: Split into 2 (horizontal)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$temp_dir/Output/Test image-0.png"
    __test_file_empty "$std_output"

    rm -rf "$temp_dir/Output"
    script_test="Image/Image: Combine, Split/Image: Split into 2 (vertical)"
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

    script_test="Image/Image: Combine, Split/Image: Stack (horizontal)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" "$input_file2" >"$std_output"
    __test_file_nonempty "$temp_dir/Stacked images (horizontal).png"
    __test_file_empty "$std_output"

    script_test="Image/Image: Combine, Split/Image: Stack (vertical)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" "$input_file2" >"$std_output"
    __test_file_nonempty "$temp_dir/Stacked images (vertical).png"
    __test_file_empty "$std_output"

    script_test="Image/Image: Convert/Image: Convert to AVIF"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.avif"
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

    script_test="Image/Image: Convert/Image: Convert to TIFF"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.tif"
    __test_file_empty "$std_output"

    script_test="Image/Image: Convert/Image: Convert to HEIC"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.heic"
    __test_file_empty "$std_output"

    script_test="Image/Image: Convert/Image: Convert to JXL"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.jxl"
    __test_file_empty "$std_output"

    script_test="Image/Image: Convert/Image: Convert to WebP"
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

    script_test="Image/Image: Crop, Resize/Image: Resize (512x512)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (512x512).png"
    __test_file_empty "$std_output"

    script_test="Image/Image: Crop, Resize/Image: Resize (1080x1080)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (1080x1080).png"
    __test_file_empty "$std_output"

    script_test="Image/Image: Crop, Resize/Image: Resize (1920x1080)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (1920x1080).png"
    __test_file_empty "$std_output"

    script_test="Image/Image: Crop, Resize/Image: Resize (2560x1440)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (2560x1440).png"
    __test_file_empty "$std_output"

    script_test="Image/Image: Crop, Resize/Image: Resize (3840x2160)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (3840x2160).png"
    __test_file_empty "$std_output"

    script_test="Image/Image: Flip, Rotate/Image: Flip (horizontal)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (flipped-h).png"
    __test_file_empty "$std_output"

    script_test="Image/Image: Flip, Rotate/Image: Flip (vertical)"
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

    script_test="Image/Image: Metadata, Exif/Image: Remove metadata"
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

    #endregion
    #--------------------------------------------------------------------------
    #region Image: SVG files
    #--------------------------------------------------------------------------

    # Create mock files for testing.
    input_file1="$temp_dir/Test image SVG.svg"
    input_file2="$temp_dir/Test image SVG 2.svg"
    output_file="$temp_dir/Test image SVG"
    cp -- "$ROOT_DIR/screenshot.svg" "$input_file1"
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

    script_test="Image/Image: SVG files/SVG: Replace fonts to Charter"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (font Charter).svg"
    __test_file_empty "$std_output"

    script_test="Image/Image: SVG files/SVG: Replace fonts to Helvetica"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (font Helvetica).svg"
    __test_file_empty "$std_output"

    script_test="Image/Image: SVG files/SVG: Replace fonts to Times"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (font Times).svg"
    __test_file_empty "$std_output"

    #endregion
    #--------------------------------------------------------------------------
    #region Document
    #--------------------------------------------------------------------------

    # Create mock files for testing.
    input_file1="$temp_dir/Test document.txt"
    output_file="$temp_dir/Test document"
    echo "Content of 'Test document'." >"$input_file1"

    script_test="Document/Document: Convert/Document: Convert to ODT"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.odt"
    __test_file_empty "$std_output"

    input_file1="$temp_dir/Test document.odt"

    script_test="Document/Document: Convert/Document: Convert to TXT"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (2).txt"
    __test_file_empty "$std_output"

    script_test="Document/Document: Convert/Document: Convert to EPUB"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.epub"
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

    script_test="Document/Document: Convert/Document: Convert to PDF"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.pdf"
    __test_file_empty "$std_output"

    #script_test="Document/Document: Convert/Document: Convert to ODS"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file.ods"
    #__test_file_empty "$std_output"

    #script_test="Document/Document: Convert/Document: Convert to XLSX"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file.xlsx"
    #__test_file_empty "$std_output"

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

    #endregion
    #--------------------------------------------------------------------------
    #region Document: PDF
    #--------------------------------------------------------------------------

    # Create mock files for testing.
    input_file1="$temp_dir/Test document PDF.pdf"
    input_file2="$temp_dir/Test document PDF 2.pdf"
    output_file="$temp_dir/Test document PDF"
    cp -- "$temp_dir/Combined images.pdf" "$input_file1"
    cp -- "$input_file1" "$input_file2"

    script_test="Document/PDF: Annotations/PDF: Find annotated PDFs"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$temp_dir" >"$std_output"
    __test_file_empty "$std_output"

    script_test="Document/PDF: Annotations/PDF: Remove annotations"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (no annotations).pdf"
    __test_file_empty "$std_output"

    script_test="Document/PDF: Combine, Split/PDF: Combine multiple PDFs"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" "$input_file2" >"$std_output"
    __test_file_nonempty "$temp_dir/Combined documents.pdf"
    __test_file_empty "$std_output"

    rm -rf "$temp_dir/Output"
    script_test="Document/PDF: Combine, Split/PDF: Split into single-page PDFs"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$temp_dir/Output/Test document PDF.0001.pdf"
    __test_file_empty "$std_output"

    #script_test="Document/PDF: Security/PDF: Remove password"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file (decrypted).pdf"
    #__test_file_empty "$std_output"

    #script_test="Document/PDF: Security/PDF: Set a password"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    script_test="Document/PDF: Security/PDF: Find password-protected PDFs"
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

    script_test="Document/PDF: Optimize, Reduce/PDF: Find non-linearized PDFs"
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

    script_test="Document/PDF: Page size/PDF: Set size (A3)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (A3).pdf"
    __test_file_empty "$std_output"

    script_test="Document/PDF: Page size/PDF: Set size (A4)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (A4).pdf"
    __test_file_empty "$std_output"

    script_test="Document/PDF: Page size/PDF: Set size (A5)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (A5).pdf"
    __test_file_empty "$std_output"

    script_test="Document/PDF: Page size/PDF: Set size (US Legal)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (US Legal).pdf"
    __test_file_empty "$std_output"

    script_test="Document/PDF: Page size/PDF: Set size (US Letter)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (US Letter).pdf"
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

    script_test="Document/PDF: Signatures/PDF: Find signed PDFs"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$temp_dir" >"$std_output"
    __test_file_empty "$std_output"

    script_test="Document/PDF: Signatures/PDF: Show signatures"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$temp_dir" >"$std_output"
    __test_file_nonempty "$std_output"

    script_test="Document/PDF: Text recognition (OCR)/PDF: Find non-searchable PDFs"
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
    __test_file_nonempty "$temp_dir/Output/Test document PDF-000.png"
    __test_file_empty "$std_output"

    script_test="Document/PDF: Tools/PDF: Remove metadata"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (no metadata).pdf"
    __test_file_empty "$std_output"

    #script_test="Document/PDF: Watermark/PDF: Add watermark (over)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Document/PDF: Watermark/PDF: Add watermark (under)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #endregion
    #--------------------------------------------------------------------------
    #region Links
    #--------------------------------------------------------------------------

    # Create mock files for testing.
    input_file1="$temp_dir/link"
    echo "Content of 'link'." >"$input_file1"

    script_test="Links/Create hard link here"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$temp_dir/Hard link to link"
    __test_file_empty "$std_output"

    #script_test="Links/Create hard link to..."
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    script_test="Links/Create symbolic link here"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$temp_dir/Link to link"
    __test_file_empty "$std_output"

    #script_test="Links/Create symbolic link to..."
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    script_test="Links/List hard links"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$temp_dir" >"$std_output"
    __test_file_nonempty "$std_output"

    script_test="Links/List symbolic links"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$temp_dir" >"$std_output"
    __test_file_nonempty "$std_output"

    rm -- "$input_file1"
    script_test="Links/Find broken links"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$temp_dir" >"$std_output"
    __test_file_nonempty "$std_output"

    #script_test="Links/Paste as hard link"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Links/Paste as symbolic link"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #endregion
    #--------------------------------------------------------------------------
    #region Network and Internet
    #--------------------------------------------------------------------------

    # Create mock files for testing.
    input_file1="$temp_dir/Test internet.txt"
    echo "https://github.com/cfgnunes/fm-scripts.git" >"$input_file1"

    script_test="Network and Internet/Git: Clone URLs"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$temp_dir/fm-scripts/README.md"
    __test_file_empty "$std_output"

    rm -- "$temp_dir/fm-scripts/README.md"
    script_test="Network and Internet/Git: Reset and pull"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$temp_dir/fm-scripts" >"$std_output"
    __test_file_nonempty "$temp_dir/fm-scripts/README.md"
    __test_file_empty "$std_output"

    #script_test="Network and Internet/Git: Open repository website"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    # Create mock files for testing.
    input_file1="$temp_dir/Test internet.txt"
    echo "127.0.0.1" >"$input_file1"

    script_test="Network and Internet/IP: Scanner"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$std_output"

    # Create mock files for testing.
    input_file1="$temp_dir/Test internet.txt"
    echo "https://github.com/cfgnunes/fm-scripts.git" >"$input_file1"

    script_test="Network and Internet/URL: Check HTTP status"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$std_output"

    # Create mock files for testing.
    input_file1="$temp_dir/Test internet.txt"
    echo "https://www.rfc-editor.org/rfc/rfc2616.txt" >"$input_file1"

    script_test="Network and Internet/URL: Download file"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$temp_dir/rfc2616.txt"
    __test_file_empty "$std_output"

    script_test="Network and Internet/URL: Show HTTP headers"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$std_output"

    #endregion
    #--------------------------------------------------------------------------
    #region Open with
    #--------------------------------------------------------------------------

    #script_test="Open with/Code Editor"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Open with/Disk usage analyzer"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Open with/Terminal"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #endregion
    #--------------------------------------------------------------------------
    #region Plain text
    #--------------------------------------------------------------------------

    # Create mock files for testing.
    input_file1="$temp_dir/Test text.txt"
    input_file2="$temp_dir/Test text 2.txt"
    output_file="$temp_dir/Test text"
    echo "Content of 'Test text'." >"$input_file1"
    echo "Content of 'Test text 2'." >"$input_file2"

    script_test="Plain text/Text: Encode to UTF-8"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (UTF-8).txt"
    __test_file_empty "$std_output"

    script_test="Plain text/Text: Remove accents"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (no accents).txt"
    __test_file_empty "$std_output"

    script_test="Plain text/Text: List encodings"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$std_output"

    script_test="Plain text/Text: Convert tabs to 4 spaces"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (4 spaces).txt"
    __test_file_empty "$std_output"

    script_test="Plain text/Text: List line breaks"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$std_output"

    script_test="Plain text/Text: List line counts"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$std_output"

    script_test="Plain text/Text: List line lengths"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$std_output"

    script_test="Plain text/Text: List word counts"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$std_output"

    script_test="Plain text/Text: Concatenate multiple files"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" "$input_file2" >"$std_output"
    __test_file_nonempty "$temp_dir/Concatenated files.txt"
    __test_file_empty "$std_output"

    # Create mock files for testing.
    input_file1="$temp_dir/Test text.txt"
    output_file="$temp_dir/Test text"
    echo "Content of 'Test text'.(á)" |
        iconv -f UTF-8 -t ISO-8859-1 >"$input_file1"

    script_test="Plain text/Text: Normalize (UTF-8, recursive)"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file.txt.bak"
    __test_file_empty "$std_output"

    script_test="Plain text/Text: List issues"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_empty "$std_output"

    script_test="Plain text/Text: Remove trailing spaces"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file (no trailing).txt"
    __test_file_empty "$std_output"

    #endregion
    #--------------------------------------------------------------------------
    #region Rename files
    #--------------------------------------------------------------------------

    # Create mock files for testing.
    input_file1="$temp_dir/Test réname.txt"
    output_file="$temp_dir/Test rename.txt"
    echo "Content of 'Test'." >"$input_file1"

    script_test="Rename files/Rename: Remove accents"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file"
    __test_file_empty "$std_output"

    # Create mock files for testing.
    input_file1="$temp_dir/Test rename parentheses (suffix 1) (suffix 2).txt"
    output_file="$temp_dir/Test rename parentheses.txt"
    echo "Content of 'Test'." >"$input_file1"

    script_test="Rename files/Rename: Remove parentheses blocks"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file"
    __test_file_empty "$std_output"

    # Create mock files for testing.
    input_file1="$temp_dir/Test rename.txt"
    output_file="$temp_dir/Test-rename.txt"
    echo "Content of 'Test'." >"$input_file1"

    script_test="Rename files/Rename: Change spaces to dashes"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file"
    __test_file_empty "$std_output"

    # Create mock files for testing.
    input_file1="$temp_dir/Test-rename.txt"
    output_file="$temp_dir/Test rename.txt"
    echo "Content of 'Test'." >"$input_file1"

    script_test="Rename files/Rename: Change dashes to spaces"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file"
    __test_file_empty "$std_output"

    # Create mock files for testing.
    input_file1="$temp_dir/Test rename.txt"
    output_file="$temp_dir/Test_rename.txt"
    echo "Content of 'Test'." >"$input_file1"

    # Create mock files for testing.
    input_file1="$temp_dir/Test rename.txt"
    output_file="$temp_dir/test rename.txt"
    echo "Content of 'Test'." >"$input_file1"

    script_test="Rename files/Rename: To lowercase"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file"
    __test_file_empty "$std_output"

    #script_test="Rename files/Rename: To lowercase (recursive)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    # Create mock files for testing.
    input_file1="$temp_dir/test rename.txt"
    output_file="$temp_dir/Test rename.txt"
    echo "Content of 'Test'." >"$input_file1"

    script_test="Rename files/Rename: To sentence case"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file"
    __test_file_empty "$std_output"

    # Create mock files for testing.
    input_file1="$temp_dir/test rename.txt"
    output_file="$temp_dir/Test Rename.txt"
    echo "Content of 'Test'." >"$input_file1"

    script_test="Rename files/Rename: To title case"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file"
    __test_file_empty "$std_output"

    # Create mock files for testing.
    input_file1="$temp_dir/Test rename.txt"
    output_file="$temp_dir/TEST RENAME.TXT"
    echo "Content of 'Test'." >"$input_file1"

    script_test="Rename files/Rename: To uppercase"
    __echo_script "$script_test"
    bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    __test_file_nonempty "$output_file"
    __test_file_empty "$std_output"

    #script_test="Rename files/Rename: To uppercase (recursive)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #endregion
    #--------------------------------------------------------------------------
    #region Security and Recovery
    #--------------------------------------------------------------------------

    #script_test="Security and Recovery/File carving (via Foremost)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Security and Recovery/File carving (via PhotoRec)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #script_test="Security and Recovery/Scan for malware (via ClamAV)"
    #__echo_script "$script_test"
    #bash "$ROOT_DIR/$script_test" "$input_file1" >"$std_output"
    #__test_file_nonempty "$output_file"
    #__test_file_empty "$std_output"

    #endregion

    printf "\nFinished! "
    printf "Results: %s tests, %s failed.\n" "$_TOTAL_TESTS" "$_TOTAL_FAILED"

    read -n1 -rp "Press any key to finish..." </dev/tty
}

#endregion

_main "$@"
