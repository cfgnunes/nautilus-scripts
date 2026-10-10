#!/usr/bin/env bash

# Source the file '.common-functions.sh'.
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
ROOT_DIR=$(grep --only-matching "^.*scripts[^/]*" <<<"$SCRIPT_DIR")
source "$ROOT_DIR/.common-functions.sh"

# Test all scripts.

# FAIL: (2020) Ubuntu 20.04 - [SCRIPT] Audio and Video/Audio: Effects/Audio: Filter noise
# FAIL: (2020) Ubuntu 20.04 - [SCRIPT] Image/Image: Convert/Image: Convert to JXL
# FAIL: (2021) Debian 11    - [SCRIPT] Image/Image: Convert/Image: Convert to JXL
# FAIL: (2022) Ubuntu 22.04 - [SCRIPT] Image/Image: Convert/Image: Convert to JXL
# PASS: (2023) Debian 12    - All tests passed.
# PASS: (2024) Ubuntu 24.04 - All tests passed.
# PASS: (2025) Debian 13    - All tests passed.
# PASS: (2025) Fedora 42    - All tests passed.
# PASS: (2026) Fedora 43    - All tests passed.
# PASS: (2026) Fedora 44    - All tests passed.
# PASS: (2026) Ubuntu 26.04 - All tests passed.

# Disable GUI for testing on terminal.
unset "DISPLAY"
unset "WAYLAND_DISPLAY"

# Enable automatic 'yes' for testing.
export DEBUG="true"

# -----------------------------------------------------------------------------
# SECTION: Global variables
# -----------------------------------------------------------------------------

_TOTAL_TESTS=0
_TOTAL_FAILED=0

# -----------------------------------------------------------------------------
# SECTION: Test functions
# -----------------------------------------------------------------------------

__check_file_empty() {
    local file=$1

    ((_TOTAL_TESTS++))

    if [[ -f "$file" && ! -s "$file" ]]; then
        printf "\033[90m[ PASS ]\033[0m "
        printf "\033[90mTest file (empty).\033[0m\n"
    else
        printf "\033[91m[ FAIL ]\033[0m "
        printf "\033[91mTest file (empty).\033[0m\n"
        printf "\033[90m[ FILE ]\033[0m "
        printf "\033[90m"
        printf "%s" "$file" | sed -z "s|\n|\\\n|g" | cat -A
        printf "\033[0m\n"
        ((_TOTAL_FAILED++))
    fi
}

__check_file_nonempty() {
    local file=$1

    ((_TOTAL_TESTS++))

    if [[ -f "$file" && -s "$file" ]]; then
        printf "\033[90m[ PASS ]\033[0m "
        printf "\033[90mTest file (non empty).\033[0m\n"
    else
        printf "\033[91m[ FAIL ]\033[0m "
        printf "\033[91mTest file (non empty).\033[0m\n"
        printf "\033[90m[ FILE ]\033[0m "
        printf "\033[90m"
        printf "%s" "$file" | sed -z "s|\n|\\\n|g" | cat -A
        printf "\033[0m\n"
        ((_TOTAL_FAILED++))
    fi
}

__test_begin() {
    temp_dir=$(mktemp --directory --tmpdir="$TEMP_DIR_TASK" "test.XXXX")

    local item=""
    local source=""
    local dest_name=""
    for item in "$@"; do
        source=${item%%::*}
        dest_name=${item#*::}
        cp -a -- "$source" "$temp_dir/$dest_name"
    done
}

__run_script() {
    local script=$1
    shift

    local output=""

    printf '%s\n' "$script" >"$temp_dir/script_name.txt"
    echo
    echo -e "\033[90m[SCRIPT] $script\033[0m"
    # The sentinel keeps trailing newlines, which command substitution removes.
    output=$(
        bash "$ROOT_DIR/$script" "$@"
        printf x
    )
    output=${output%x}
    printf '%s' "$output" >"$temp_dir/std_output.txt"
    std_output="$temp_dir/std_output.txt"
}

__test_script() {
    local script=$1
    local stdout_mode=$2
    local expected_rel=$3
    shift 3

    __run_script "$script" "$@"

    if [[ -n "$expected_rel" ]]; then
        __check_file_nonempty "$temp_dir/$expected_rel"
    fi

    if [[ "$stdout_mode" == "empty" ]]; then
        __check_file_empty "$std_output"
    else
        __check_file_nonempty "$std_output"
    fi
}

__test_scripts_file() {
    local fixture=$1
    local input_name=$2
    local stdout_mode=$3
    shift 3

    local spec=""
    local script=""
    local expected=""
    for spec in "$@"; do
        script=${spec%%|*}
        expected=${spec#*|}
        __test_begin "$fixture::$input_name"
        __test_script "$script" "$stdout_mode" "$expected" \
            "$temp_dir/$input_name"
    done
}

__test_scripts_stdout() {
    local fixture=$1
    local input_name=$2
    shift 2

    local script=""
    for script in "$@"; do
        __test_begin "$fixture::$input_name"
        __test_script "$script" "text" "" "$temp_dir/$input_name"
    done
}

# -----------------------------------------------------------------------------
# SECTION: Functions for generating fixtures
# -----------------------------------------------------------------------------

__generate_fixture_audio() {
    local dest=$1

    ffmpeg -hide_banner -y \
        -f lavfi -i "sine=frequency=440:duration=5" \
        "$dest" &>/dev/null
}

__generate_fixture_video() {
    local dest=$1

    ffmpeg -hide_banner -y \
        -f lavfi -i color=c=red:s=200x100:d=3:r=25 \
        -f lavfi -i "sine=frequency=440:duration=3" \
        -shortest "$dest" &>/dev/null
}

__generate_fixture_image() {
    local dest=$1

    ffmpeg -hide_banner -y \
        -f lavfi -i color=c=red:s=200x100 -frames:v 1 \
        -update 1 "$dest" &>/dev/null
}

__generate_fixture_targz() {
    local dest=$1
    local side=""

    side=$(mktemp --directory --tmpdir="$TEMP_DIR_TASK" "fixture.XXXX")
    echo "Content of 'Test archive'." >"$side/Test archive 1"
    echo "Content of 'Test archive 2'." >"$side/Test archive 2"
    (
        cd -- "$side" || exit 1
        tar --create --gzip --file="$dest" -- \
            "Test archive 1" "Test archive 2"
    )
    rm -rf -- "$side"
}

__generate_fixture_audio_tag() {
    local dest=$1
    local side=""

    side=$(mktemp --directory --tmpdir="$TEMP_DIR_TASK" "fixture.XXXX")
    ffmpeg -hide_banner -y \
        -f lavfi -i "sine=frequency=440:duration=5" \
        "$side/artist - title.mp3" &>/dev/null
    bash "$ROOT_DIR/Audio and Video/Audio: MP3 files/MP3: (artist - title) Name to ID3" \
        "$side/artist - title.mp3" >/dev/null
    cp -- "$side/artist - title.mp3" "$dest"
    rm -rf -- "$side"
}

__generate_fixture_text() {
    local dest=$1

    echo "Content of 'Test text'." >"$dest"
}

__generate_fixture_archive_dir() {
    mkdir -p -- "$temp_dir/Test archive"
    echo "Content of 'Test archive'." >"$temp_dir/Test archive/Test archive 1"
    echo "Content of 'Test archive 2'." >"$temp_dir/Test archive/Test archive 2"
}

__download_file() {
    local url=$1
    local output_file=$2

    if _command_exists "wget"; then
        wget -q -O "$output_file" -- "$url"
    elif _command_exists "curl"; then
        curl -fsSL -o "$output_file" -- "$url"
    else
        echo "Error: Neither wget nor curl is installed."
        return 1
    fi
}

# -----------------------------------------------------------------------------
# SECTION: Tests
# -----------------------------------------------------------------------------

_main() {
    local temp_dir=""
    local std_output=""
    local fixtures_dir="$ROOT_DIR/test"
    local fixture_jpg="$fixtures_dir/Test image.jpg"
    local fixture_mp3="$fixtures_dir/Test audio.mp3"
    local fixture_mp3_tag="$fixtures_dir/Test audio id3.mp3"
    local fixture_mp4="$fixtures_dir/Test video.mp4"
    local fixture_odt="$fixtures_dir/Test document.odt"
    local fixture_pdf="$fixtures_dir/Test document PDF.pdf"
    local fixture_png="$fixtures_dir/Test image.png"
    local fixture_svg=""
    local fixture_svgz=""
    local fixture_tgz="$fixtures_dir/Test archive.tar.gz"
    local fixture_txt="$fixtures_dir/Test text.txt"
    local checksum=""
    local font_file=""

    _check_dependencies "ffmpeg git gzip"

    _open_items_locations "$TEMP_DIR_TASK/task" "true"

    # Generate the fixtures.
    mkdir -p -- "$fixtures_dir"
    [[ ! -f "$fixture_jpg" ]] && __generate_fixture_image "$fixture_jpg"
    [[ ! -f "$fixture_mp3" ]] && __generate_fixture_audio "$fixture_mp3"
    [[ ! -f "$fixture_mp3_tag" ]] && __generate_fixture_audio_tag "$fixture_mp3_tag"
    [[ ! -f "$fixture_mp4" ]] && __generate_fixture_video "$fixture_mp4"
    [[ ! -f "$fixture_png" ]] && __generate_fixture_image "$fixture_png"
    [[ ! -f "$fixture_tgz" ]] && __generate_fixture_targz "$fixture_tgz"
    [[ ! -f "$fixture_txt" ]] && __generate_fixture_text "$fixture_txt"
    [[ ! -f "$fixture_odt" ]] && __download_file "https://freetestdata.com/wp-content/uploads/2021/09/Free_Test_Data_100KB_ODT.odt" "$fixture_odt"
    [[ ! -f "$fixture_pdf" ]] && __download_file "https://freetestdata.com/wp-content/uploads/2021/09/Free_Test_Data_100KB_PDF.pdf" "$fixture_pdf"

    # -------------------------------------------------------------------------
    # SECTION: Archive
    # -------------------------------------------------------------------------

    # IGNORED: Archive/Compress to '7z' with password
    # IGNORED: Archive/Compress to 'zip' with password

    __test_begin
    __generate_fixture_archive_dir
    __test_script "Archive/Compress to '7z'" "empty" "Test archive.7z" \
        "$temp_dir/Test archive"

    __test_begin
    __generate_fixture_archive_dir
    __test_script "Archive/Compress to 'tar.gz'" "empty" "Test archive.tar.gz" \
        "$temp_dir/Test archive"

    __test_begin
    __generate_fixture_archive_dir
    __test_script "Archive/Compress to 'tar.xz'" "empty" "Test archive.tar.xz" \
        "$temp_dir/Test archive"

    __test_begin
    __generate_fixture_archive_dir
    __test_script "Archive/Compress to 'tar.zst'" "empty" \
        "Test archive.tar.zst" "$temp_dir/Test archive"

    __test_begin
    __generate_fixture_archive_dir
    __test_script "Archive/Compress to 'zip'" "empty" "Test archive.zip" \
        "$temp_dir/Test archive"

    __test_begin "$fixture_tgz::Test archive.tar.gz"
    __test_script "Archive/Extract here" "empty" \
        "Test archive/Test archive 1" \
        "$temp_dir/Test archive.tar.gz"

    # -------------------------------------------------------------------------
    # SECTION: Audio
    # -------------------------------------------------------------------------

    # IGNORED: Audio and Video/Audio: MP3 files/MP3: Maximize volume (recursive)
    # IGNORED: Audio and Video/Audio: MP3 files/MP3: Normalize volume (recursive)

    __test_scripts_stdout "$fixture_mp3" "Test audio.mp3" \
        "Audio and Video/Audio and Video: Tools/Media: Show information" \
        "Audio and Video/Audio and Video: Tools/Media: Show basic metadata"

    __test_begin \
        "$fixture_mp3::Test audio.mp3" \
        "$fixture_mp3::Test audio 2.mp3"
    __test_script \
        "Audio and Video/Audio and Video: Tools/Media: Concatenate files" \
        "empty" "Concatenated media.mp3" \
        "$temp_dir/Test audio.mp3" "$temp_dir/Test audio 2.mp3"

    __test_scripts_file "$fixture_mp3" "Test audio.mp3" "empty" \
        "Audio and Video/Audio and Video: Tools/Media: Remove metadata|Test audio (no metadata).mp3" \
        "Audio and Video/Audio: Channels/Audio: Mix channels to mono|Test audio (mono).mp3" \
        "Audio and Video/Audio: Convert/Audio: Convert to FLAC|Test audio.flac" \
        "Audio and Video/Audio: Convert/Audio: Convert to MP3 (192 kbps)|Test audio (2).mp3" \
        "Audio and Video/Audio: Convert/Audio: Convert to MP3 (320 kbps)|Test audio (2).mp3" \
        "Audio and Video/Audio: Convert/Audio: Convert to MP3 (48 kbps)|Test audio (2).mp3" \
        "Audio and Video/Audio: Convert/Audio: Convert to OPUS (192 kbps)|Test audio.opus" \
        "Audio and Video/Audio: Convert/Audio: Convert to OPUS (320 kbps)|Test audio.opus" \
        "Audio and Video/Audio: Convert/Audio: Convert to OPUS (48 kbps)|Test audio.opus" \
        "Audio and Video/Audio: Convert/Audio: Convert to WAV|Test audio.wav" \
        "Audio and Video/Audio: Effects/Audio: Fade-in|Test audio (fade-in).mp3" \
        "Audio and Video/Audio: Effects/Audio: Fade-out|Test audio (fade-out).mp3" \
        "Audio and Video/Audio: Effects/Audio: Normalize volume|Test audio (normalized).mp3" \
        "Audio and Video/Audio: Effects/Audio: Remove silence (sections)|Test audio (no silence).mp3" \
        "Audio and Video/Audio: Effects/Audio: Filter noise|Test audio (noise filtered).mp3" \
        "Audio and Video/Audio: Effects/Audio: Remove silence (extremities)|Test audio (no silence).mp3"

    __test_begin \
        "$fixture_mp3::Test audio.mp3" \
        "$fixture_mp3::Test audio 2.mp3"
    __test_script "Audio and Video/Audio: Channels/Audio: Mix two files" \
        "empty" "Mixed audio.wav" \
        "$temp_dir/Test audio.mp3" "$temp_dir/Test audio 2.mp3"

    __test_scripts_stdout "$fixture_mp3" "Test audio.mp3" \
        "Audio and Video/Audio: MP3 files/MP3: Show encoding details" \
        "Audio and Video/Audio: Quality/Audio: Check quality"

    __test_scripts_file "$fixture_mp3" "Test audio.mp3" "empty" \
        "Audio and Video/Audio: Quality/Audio: Produce spectrogram|Test audio.png"

    __test_begin "$fixture_mp3::Test audio.mp3"
    __test_script \
        "Audio and Video/Audio: MP3 files/MP3: (artist - title) Name to ID3" \
        "empty" "" "$temp_dir/Test audio.mp3"

    __test_begin "$fixture_mp3_tag::Test audio.mp3"
    __test_script \
        "Audio and Video/Audio: MP3 files/MP3: (artist - title) ID3 to Name" \
        "empty" "artist - title.mp3" "$temp_dir/Test audio.mp3"

    # -------------------------------------------------------------------------
    # SECTION: Video
    # -------------------------------------------------------------------------

    # IGNORED: Audio and Video/Video: Convert/Video: Convert to WebM (copy)

    __test_scripts_file "$fixture_mp4" "Test video.mp4" "empty" \
        "Audio and Video/Video: Aspect ratio/Video: Aspect to 1:1|Test video (aspect 1:1).mp4" \
        "Audio and Video/Video: Aspect ratio/Video: Aspect to 16:10|Test video (aspect 16:10).mp4" \
        "Audio and Video/Video: Aspect ratio/Video: Aspect to 16:9|Test video (aspect 16:9).mp4" \
        "Audio and Video/Video: Aspect ratio/Video: Aspect to 4:3|Test video (aspect 4:3).mp4" \
        "Audio and Video/Video: Audio track/Video: Extract audio|Test video.m4a" \
        "Audio and Video/Video: Audio track/Video: Remove audio|Test video (no audio).mp4" \
        "Audio and Video/Video: Convert/Video: Convert to MKV|Test video.mkv" \
        "Audio and Video/Video: Convert/Video: Convert to MP4|Test video (2).mp4" \
        "Audio and Video/Video: Convert/Video: Convert to WebM|Test video.webm" \
        "Audio and Video/Video: Convert/Video: Convert to MKV (copy)|Test video.mkv" \
        "Audio and Video/Video: Convert/Video: Convert to MP4 (copy)|Test video (2).mp4" \
        "Audio and Video/Video: Convert/Video: Export to GIF (1 FPS)|Test video (1 FPS).gif" \
        "Audio and Video/Video: Convert/Video: Export to GIF (5 FPS)|Test video (5 FPS).gif" \
        "Audio and Video/Video: Convert/Video: Export to GIF (10 FPS)|Test video (10 FPS).gif" \
        "Audio and Video/Video: Export frames/Video: Export frames (1 FPS)|Output/Test video.mp4_frame_00001.png" \
        "Audio and Video/Video: Export frames/Video: Export frames (10 FPS)|Output/Test video.mp4_frame_00001.png" \
        "Audio and Video/Video: Export frames/Video: Export frames (5 FPS)|Output/Test video.mp4_frame_00001.png" \
        "Audio and Video/Video: Flip, Rotate/Video: Flip (horizontal)|Test video (flipped-h).mp4" \
        "Audio and Video/Video: Flip, Rotate/Video: Flip (vertical)|Test video (flipped-v).mp4" \
        "Audio and Video/Video: Flip, Rotate/Video: Rotate (180 deg)|Test video (180 deg).mp4" \
        "Audio and Video/Video: Flip, Rotate/Video: Rotate (270 deg)|Test video (270 deg).mp4" \
        "Audio and Video/Video: Flip, Rotate/Video: Rotate (90 deg)|Test video (90 deg).mp4" \
        "Audio and Video/Video: Frame rate/Video: Frame rate to 30 FPS|Test video (30 FPS).mp4" \
        "Audio and Video/Video: Frame rate/Video: Frame rate to 60 FPS|Test video (60 FPS).mp4" \
        "Audio and Video/Video: Resize/Video: Resize (25 pct)|Test video (25 pct).mp4" \
        "Audio and Video/Video: Resize/Video: Resize (50 pct)|Test video (50 pct).mp4" \
        "Audio and Video/Video: Resize/Video: Resize (75 pct)|Test video (75 pct).mp4" \
        "Audio and Video/Video: Speed/Video: Speed to 0.5|Test video (speed 0.5).mp4" \
        "Audio and Video/Video: Speed/Video: Speed to 1.5|Test video (speed 1.5).mp4" \
        "Audio and Video/Video: Speed/Video: Speed to 2.0|Test video (speed 2.0).mp4"

    # -------------------------------------------------------------------------
    # SECTION: Directories and Files
    # -------------------------------------------------------------------------

    # IGNORED: Directories and Files/Flatten directory structure
    # IGNORED: Directories and Files/Open item location
    # IGNORED: Directories and Files/Reset permissions (recursive)
    # IGNORED: Clipboard/Copy file contents
    # IGNORED: Clipboard/Copy file names
    # IGNORED: Clipboard/Copy file names (recursive)
    # IGNORED: Clipboard/Copy file paths
    # IGNORED: Clipboard/Copy file paths (recursive)
    # IGNORED: Clipboard/Paste clipboard contents
    # IGNORED: Directories and Files/Compare items

    __test_begin
    echo "one" >"$temp_dir/file1.txt"
    echo "two" >"$temp_dir/file2.txt"
    __test_script "Directories and Files/Compare items (via Diff)" "text" "" \
        "$temp_dir/file1.txt" "$temp_dir/file2.txt"

    __test_begin
    echo "same" >"$temp_dir/a.txt"
    cp -- "$temp_dir/a.txt" "$temp_dir/b.txt"
    __test_script "Directories and Files/Find duplicate files" "text" "" \
        "$temp_dir"

    __test_begin
    mkdir -p -- "$temp_dir/Test empty dir"
    __test_script "Directories and Files/Find empty directories" "text" "" \
        "$temp_dir"

    __test_begin
    touch -- "$temp_dir/.Test hidden file"
    __test_script "Directories and Files/List hidden files" "text" "" \
        "$temp_dir"

    __test_begin
    touch -- "$temp_dir/Test junk file.log"
    __test_script "Directories and Files/Find junk files" "text" "" \
        "$temp_dir"

    __test_begin
    touch -- "$temp_dir/Test empty file"
    __test_script "Directories and Files/Find empty files" "text" "" \
        "$temp_dir"

    local dir_script=""
    for dir_script in \
        "Directories and Files/List recent files" \
        "Directories and Files/List largest files" \
        "Directories and Files/List permissions and owners" \
        "Directories and Files/Show file information" \
        "Directories and Files/Show file metadata" \
        "Directories and Files/Show file MIME type"; do
        __test_begin
        __generate_fixture_text "$temp_dir/Test file.txt"
        __test_script "$dir_script" "text" "" "$temp_dir"
    done

    # -------------------------------------------------------------------------
    # SECTION: Image
    # -------------------------------------------------------------------------

    # IGNORED: Image/Image: Metadata, Exif/Image: Rename from metadata
    # IGNORED: Image/Image: Similarity/Image: Find similar (65 pct)
    # IGNORED: Image/Image: Similarity/Image: Find similar (75 pct)
    # IGNORED: Image/Image: Similarity/Image: Find similar (85 pct)
    # IGNORED: Image/Image: Similarity/Image: Find similar (95 pct)
    # IGNORED: Image/Image: Text recognition (OCR)/Image: Perform OCR (French)
    # IGNORED: Image/Image: Text recognition (OCR)/Image: Perform OCR (German)
    # IGNORED: Image/Image: Text recognition (OCR)/Image: Perform OCR (Italian)
    # IGNORED: Image/Image: Text recognition (OCR)/Image: Perform OCR (Portuguese)
    # IGNORED: Image/Image: Text recognition (OCR)/Image: Perform OCR (Russian)
    # IGNORED: Image/Image: Text recognition (OCR)/Image: Perform OCR (Spanish)
    # IGNORED: Image/Image: Watermark/Image: Add watermark (center)
    # IGNORED: Image/Image: Watermark/Image: Add watermark (north)
    # IGNORED: Image/Image: Watermark/Image: Add watermark (northeast)
    # IGNORED: Image/Image: Watermark/Image: Add watermark (northwest)
    # IGNORED: Image/Image: Watermark/Image: Add watermark (south)
    # IGNORED: Image/Image: Watermark/Image: Add watermark (southeast)
    # IGNORED: Image/Image: Watermark/Image: Add watermark (southwest)

    __test_scripts_file "$fixture_png" "Test image.png" "empty" \
        "Image/Image: Color/Image: Colorspace to gray|Test image (grayscale).png" \
        "Image/Image: Color/Image: Desaturate|Test image (desaturated).png" \
        "Image/Image: Color/Image: Generate multiple hues|Output/Test image (2).png"

    __test_begin \
        "$fixture_png::Test image.png" \
        "$fixture_png::Test image 2.png"
    __test_script "Image/Image: Combine, Split/Image: Combine into GIF" \
        "empty" "Animated image.gif" \
        "$temp_dir/Test image.png" "$temp_dir/Test image 2.png"

    __test_begin \
        "$fixture_png::Test image.png" \
        "$fixture_png::Test image 2.png"
    __test_script "Image/Image: Combine, Split/Image: Combine into PDF" \
        "empty" "Combined images.pdf" \
        "$temp_dir/Test image.png" "$temp_dir/Test image 2.png"

    __test_scripts_file "$fixture_png" "Test image.png" "empty" \
        "Image/Image: Combine, Split/Image: Split into 2 (horizontal)|Output/Test image-0.png" \
        "Image/Image: Combine, Split/Image: Split into 2 (vertical)|Output/Test image-0.png" \
        "Image/Image: Combine, Split/Image: Split into 4|Output/Test image-0.png"

    __test_begin \
        "$fixture_png::Test image.png" \
        "$fixture_png::Test image 2.png"
    __test_script "Image/Image: Combine, Split/Image: Stack (horizontal)" \
        "empty" "Stacked images (horizontal).png" \
        "$temp_dir/Test image.png" "$temp_dir/Test image 2.png"

    __test_begin \
        "$fixture_png::Test image.png" \
        "$fixture_png::Test image 2.png"
    __test_script "Image/Image: Combine, Split/Image: Stack (vertical)" \
        "empty" "Stacked images (vertical).png" \
        "$temp_dir/Test image.png" "$temp_dir/Test image 2.png"

    __test_scripts_file "$fixture_png" "Test image.png" "empty" \
        "Image/Image: Convert/Image: Convert to AVIF|Test image.avif" \
        "Image/Image: Convert/Image: Convert to GIF|Test image.gif" \
        "Image/Image: Convert/Image: Convert to JPG|Test image.jpg"

    __test_scripts_file "$fixture_jpg" "Test image.jpg" "empty" \
        "Image/Image: Convert/Image: Convert to PNG|Test image.png"

    __test_scripts_file "$fixture_png" "Test image.png" "empty" \
        "Image/Image: Convert/Image: Convert to TIFF|Test image.tif" \
        "Image/Image: Convert/Image: Convert to HEIC|Test image.heic" \
        "Image/Image: Convert/Image: Convert to JXL|Test image.jxl" \
        "Image/Image: Convert/Image: Convert to WebP|Test image.webp" \
        "Image/Image: Convert/Image: Export to PDF|Test image.pdf" \
        "Image/Image: Crop, Resize/Image: Automatic crop|Test image (cropped).png" \
        "Image/Image: Crop, Resize/Image: Automatic crop (15 pct)|Test image (cropped 15 pct).png" \
        "Image/Image: Crop, Resize/Image: Resize (25 pct)|Test image (25 pct).png" \
        "Image/Image: Crop, Resize/Image: Resize (50 pct)|Test image (50 pct).png" \
        "Image/Image: Crop, Resize/Image: Resize (75 pct)|Test image (75 pct).png" \
        "Image/Image: Crop, Resize/Image: Resize (1920x1080)|Test image (1920x1080).png" \
        "Image/Image: Crop, Resize/Image: Resize (2560x1440)|Test image (2560x1440).png" \
        "Image/Image: Crop, Resize/Image: Resize (3840x2160)|Test image (3840x2160).png" \
        "Image/Image: Flip, Rotate/Image: Flip (horizontal)|Test image (flipped-h).png" \
        "Image/Image: Flip, Rotate/Image: Flip (vertical)|Test image (flipped-v).png" \
        "Image/Image: Flip, Rotate/Image: Rotate (180 deg)|Test image (180 deg).png" \
        "Image/Image: Flip, Rotate/Image: Rotate (270 deg)|Test image (270 deg).png" \
        "Image/Image: Flip, Rotate/Image: Rotate (90 deg)|Test image (90 deg).png" \
        "Image/Image: Icons/Image: Create PNG icon (128 px)|Test image (icon 128 px).png" \
        "Image/Image: Icons/Image: Create PNG icon (256 px)|Test image (icon 256 px).png" \
        "Image/Image: Icons/Image: Create PNG icon (512 px)|Test image (icon 512 px).png" \
        "Image/Image: Optimize, Reduce/Image: Optimize PNG|Test image (optimized).png" \
        "Image/Image: Optimize, Reduce/Image: Reduce (JPG, 1000kB max)|Test image (reduced).jpg" \
        "Image/Image: Optimize, Reduce/Image: Reduce (JPG, 500kB max)|Test image (reduced).jpg" \
        "Image/Image: Metadata, Exif/Image: Remove metadata|Test image (no metadata).png"

    __test_begin
    font_file=$(fc-match -f '%{file}' sans 2>/dev/null || true)
    if [[ ! -f "$font_file" || "${font_file##*/}" != *[Ss][Aa][Nn][Ss]* ]]; then
        font_file=$(find /usr/share/fonts /usr/local/share/fonts \
            "${XDG_DATA_HOME:-$HOME/.local/share}/fonts" \
            -type f \( -iname '*sans*.ttf' -o -iname '*sans*.otf' \) \
            -print -quit 2>/dev/null || true)
    fi
    ffmpeg -hide_banner -y \
        -f lavfi -i color=c=white:s=900x240 \
        -vf "drawtext=fontfile='${font_file}':text='HELLO':fontcolor=black:fontsize=140:x=(w-text_w)/2:y=(h-text_h)/2" \
        -frames:v 1 -update 1 "$temp_dir/Test image OCR.png" &>/dev/null
    __test_script \
        "Image/Image: Text recognition (OCR)/Image: Perform OCR (English)" \
        "empty" "Test image OCR (OCR eng).txt" \
        "$temp_dir/Test image OCR.png"

    __test_scripts_file "$fixture_png" "Test image.png" "empty" \
        "Image/Image: Transparency/Image: Background to alpha|Test image (alpha).png" \
        "Image/Image: Transparency/Image: Background to alpha (15 pct)|Test image (alpha 15 pct).png" \
        "Image/Image: Transparency/Image: Color alpha to black|Test image (bg black).png" \
        "Image/Image: Transparency/Image: Color alpha to magenta|Test image (bg magenta).png" \
        "Image/Image: Transparency/Image: Color alpha to white|Test image (bg white).png" \
        "Image/Image: Transparency/Image: Color black to alpha|Test image (alpha).png" \
        "Image/Image: Transparency/Image: Color black to alpha (15 pct)|Test image (alpha 15 pct).png" \
        "Image/Image: Transparency/Image: Color magenta to alpha|Test image (alpha).png" \
        "Image/Image: Transparency/Image: Color magenta to alpha (15 pct)|Test image (alpha 15 pct).png" \
        "Image/Image: Transparency/Image: Color white to alpha|Test image (alpha).png" \
        "Image/Image: Transparency/Image: Color white to alpha (15 pct)|Test image (alpha 15 pct).png"

    # -------------------------------------------------------------------------
    # SECTION: Image: SVG files
    # -------------------------------------------------------------------------

    fixture_svg="$fixtures_dir/Test image SVG.svg"
    fixture_svgz="$fixtures_dir/Test image SVG.svgz"
    cp -- "$ROOT_DIR/screenshot.svg" "$fixture_svg"
    gzip --no-name -c "$fixture_svg" >"$fixture_svgz"

    __test_scripts_file "$fixture_svg" "Test image SVG.svg" "empty" \
        "Image/Image: SVG files/SVG: Compress to SVGZ|Test image SVG.svgz" \
        "Image/Image: SVG files/SVG: Export to PDF|Test image SVG.pdf" \
        "Image/Image: SVG files/SVG: Export to PNG (256 px)|Test image SVG (256 px).png" \
        "Image/Image: SVG files/SVG: Export to PNG (512 px)|Test image SVG (512 px).png" \
        "Image/Image: SVG files/SVG: Export to PNG (1024 px)|Test image SVG (1024 px).png" \
        "Image/Image: SVG files/SVG: Replace fonts with Charter|Test image SVG (font Charter).svg" \
        "Image/Image: SVG files/SVG: Replace fonts with Helvetica|Test image SVG (font Helvetica).svg" \
        "Image/Image: SVG files/SVG: Replace fonts with Times|Test image SVG (font Times).svg"

    __test_scripts_file "$fixture_svgz" "Test image SVG.svgz" "empty" \
        "Image/Image: SVG files/SVG: Decompress SVGZ|Test image SVG.svg"

    # -------------------------------------------------------------------------
    # SECTION: Document
    # -------------------------------------------------------------------------

    # IGNORED: Document/Document: Convert/Document: Convert to ODS
    # IGNORED: Document/Document: Convert/Document: Convert to XLSX
    # IGNORED: Document/Document: Convert/Document: Convert to ODP
    # IGNORED: Document/Document: Convert/Document: Convert to PPTX

    __test_begin
    echo "Content of 'Test document'." >"$temp_dir/Test document.txt"
    __test_script "Document/Document: Convert/Document: Convert to ODT" \
        "empty" "Test document.odt" "$temp_dir/Test document.txt"

    __test_scripts_file "$fixture_odt" "Test document.odt" "empty" \
        "Document/Document: Convert/Document: Convert to TXT|Test document.txt" \
        "Document/Document: Convert/Document: Convert to EPUB|Test document.epub" \
        "Document/Document: Convert/Document: Convert to Markdown|Test document.md" \
        "Document/Document: Convert/Document: Convert to DOCX|Test document.docx" \
        "Document/Document: Convert/Document: Convert to PDF|Test document.pdf" \
        "Document/Document: Convert/Document: Convert to PDF (landscape)|Test document (landscape).pdf"

    # -------------------------------------------------------------------------
    # SECTION: Document: PDF
    # -------------------------------------------------------------------------

    # IGNORED: Document/PDF: Security/PDF: Remove password
    # IGNORED: Document/PDF: Security/PDF: Set password
    # IGNORED: Document/PDF: Text recognition (OCR)/PDF: Perform OCR (English)
    # IGNORED: Document/PDF: Text recognition (OCR)/PDF: Perform OCR (French)
    # IGNORED: Document/PDF: Text recognition (OCR)/PDF: Perform OCR (German)
    # IGNORED: Document/PDF: Text recognition (OCR)/PDF: Perform OCR (Italian)
    # IGNORED: Document/PDF: Text recognition (OCR)/PDF: Perform OCR (Portuguese)
    # IGNORED: Document/PDF: Text recognition (OCR)/PDF: Perform OCR (Russian)
    # IGNORED: Document/PDF: Text recognition (OCR)/PDF: Perform OCR (Spanish)
    # IGNORED: Document/PDF: Watermark/PDF: Add watermark (over)
    # IGNORED: Document/PDF: Watermark/PDF: Add watermark (under)

    __test_begin "$fixture_pdf::Test document PDF.pdf"
    __test_script "Document/PDF: Annotations/PDF: Find annotated PDFs" \
        "empty" "" "$temp_dir"

    __test_scripts_file "$fixture_pdf" "Test document PDF.pdf" "empty" \
        "Document/PDF: Annotations/PDF: Remove annotations|Test document PDF (no annotations).pdf"

    __test_begin \
        "$fixture_pdf::Test document PDF.pdf" \
        "$fixture_pdf::Test document PDF 2.pdf"
    __test_script "Document/PDF: Combine, Split/PDF: Combine multiple PDFs" \
        "empty" "Combined documents.pdf" \
        "$temp_dir/Test document PDF.pdf" \
        "$temp_dir/Test document PDF 2.pdf"

    __test_scripts_file "$fixture_pdf" "Test document PDF.pdf" "empty" \
        "Document/PDF: Combine, Split/PDF: Split into single-page PDFs|Output/Test document PDF.0001.pdf"

    __test_begin "$fixture_pdf::Test document PDF.pdf"
    __test_script "Document/PDF: Security/PDF: Find password-protected PDFs" \
        "empty" "" "$temp_dir"

    __test_scripts_file "$fixture_pdf" "Test document PDF.pdf" "empty" \
        "Document/PDF: Multi-page layout/PDF: Layout (landscape, 1x2)|Test document PDF (landscape, 1x2).pdf" \
        "Document/PDF: Multi-page layout/PDF: Layout (landscape, 2x1)|Test document PDF (landscape, 2x1).pdf" \
        "Document/PDF: Multi-page layout/PDF: Layout (landscape, 2x2)|Test document PDF (landscape, 2x2).pdf" \
        "Document/PDF: Multi-page layout/PDF: Layout (landscape, 2x4)|Test document PDF (landscape, 2x4).pdf" \
        "Document/PDF: Multi-page layout/PDF: Layout (landscape, 4x2)|Test document PDF (landscape, 4x2).pdf" \
        "Document/PDF: Multi-page layout/PDF: Layout (portrait, 1x2)|Test document PDF (portrait, 1x2).pdf" \
        "Document/PDF: Multi-page layout/PDF: Layout (portrait, 2x1)|Test document PDF (portrait, 2x1).pdf" \
        "Document/PDF: Multi-page layout/PDF: Layout (portrait, 2x2)|Test document PDF (portrait, 2x2).pdf" \
        "Document/PDF: Multi-page layout/PDF: Layout (portrait, 2x4)|Test document PDF (portrait, 2x4).pdf" \
        "Document/PDF: Multi-page layout/PDF: Layout (portrait, 4x2)|Test document PDF (portrait, 4x2).pdf"

    __test_begin "$fixture_pdf::Test document PDF.pdf"
    __test_script "Document/PDF: Optimize, Reduce/PDF: Find non-linearized PDFs" \
        "text" "" "$temp_dir"

    __test_scripts_file "$fixture_pdf" "Test document PDF.pdf" "empty" \
        "Document/PDF: Optimize, Reduce/PDF: Optimize for web (linearize)|Test document PDF (linearized).pdf" \
        "Document/PDF: Optimize, Reduce/PDF: Reduce (150 dpi, e-book)|Test document PDF (150 dpi, e-book).pdf" \
        "Document/PDF: Optimize, Reduce/PDF: Reduce (300 dpi, printer)|Test document PDF (300 dpi, printer).pdf" \
        "Document/PDF: Page size/PDF: Set size (A3)|Test document PDF (A3).pdf" \
        "Document/PDF: Page size/PDF: Set size (A4)|Test document PDF (A4).pdf" \
        "Document/PDF: Page size/PDF: Set size (A5)|Test document PDF (A5).pdf" \
        "Document/PDF: Page size/PDF: Set size (US Legal)|Test document PDF (US Legal).pdf" \
        "Document/PDF: Page size/PDF: Set size (US Letter)|Test document PDF (US Letter).pdf" \
        "Document/PDF: Rotate/PDF: Rotate (180 deg)|Test document PDF (180 deg).pdf" \
        "Document/PDF: Rotate/PDF: Rotate (270 deg)|Test document PDF (270 deg).pdf" \
        "Document/PDF: Rotate/PDF: Rotate (90 deg)|Test document PDF (90 deg).pdf"

    __test_begin "$fixture_pdf::Test document PDF.pdf"
    __test_script "Document/PDF: Signatures/PDF: Find signed PDFs" \
        "empty" "" "$temp_dir"

    __test_begin "$fixture_pdf::Test document PDF.pdf"
    __test_script "Document/PDF: Signatures/PDF: Show signatures" \
        "text" "" "$temp_dir"

    __test_begin "$fixture_pdf::Test document PDF.pdf"
    __test_script \
        "Document/PDF: Text recognition (OCR)/PDF: Find non-searchable PDFs" \
        "empty" "" "$temp_dir"

    __test_scripts_file "$fixture_pdf" "Test document PDF.pdf" "empty" \
        "Document/PDF: Tools/PDF: Convert to grayscale|Test document PDF (grayscale).pdf" \
        "Document/PDF: Tools/PDF: Convert to PDFA-2b|Test document PDF (PDFA-2b).pdf" \
        "Document/PDF: Tools/PDF: Extract images|Output/Test document PDF-000.jpg" \
        "Document/PDF: Tools/PDF: Remove metadata|Test document PDF (no metadata).pdf"

    # -------------------------------------------------------------------------
    # SECTION: Links
    # -------------------------------------------------------------------------

    # IGNORED: Links/Create hard link to...
    # IGNORED: Links/Create symbolic link to...
    # IGNORED: Links/Paste as hard link
    # IGNORED: Links/Paste as symbolic link

    __test_begin
    echo "Content of 'link'." >"$temp_dir/link"
    __test_script "Links/Create hard link here" "empty" "Hard link to link" \
        "$temp_dir/link"

    __test_begin
    echo "Content of 'link'." >"$temp_dir/link"
    __test_script "Links/Create symbolic link here" "empty" "Link to link" \
        "$temp_dir/link"

    __test_begin
    echo "Content of 'link'." >"$temp_dir/link"
    ln -- "$temp_dir/link" "$temp_dir/link-hard"
    __test_script "Links/List hard links" "text" "" "$temp_dir"

    __test_begin
    echo "Content of 'link'." >"$temp_dir/link"
    ln -s -- "$temp_dir/link" "$temp_dir/link-sym"
    __test_script "Links/List symbolic links" "text" "" "$temp_dir"

    __test_begin
    echo "Content of 'link'." >"$temp_dir/link"
    ln -s -- "$temp_dir/link" "$temp_dir/link-sym"
    rm -- "$temp_dir/link"
    __test_script "Links/Find broken links" "text" "" "$temp_dir"

    # -------------------------------------------------------------------------
    # SECTION: Network and Internet
    # -------------------------------------------------------------------------

    # IGNORED: Network and Internet/Git: Open repository website

    __test_begin
    echo "https://github.com/cfgnunes/nautilus-scripts.git" \
        >"$temp_dir/Test internet.txt"
    __test_script "Network and Internet/Git: Clone URLs" "empty" \
        "nautilus-scripts/README.md" "$temp_dir/Test internet.txt"

    __test_begin
    git clone --quiet "https://github.com/cfgnunes/nautilus-scripts.git" \
        "$temp_dir/nautilus-scripts"
    rm -- "$temp_dir/nautilus-scripts/README.md"
    __test_script "Network and Internet/Git: Reset and pull" "empty" \
        "nautilus-scripts/README.md" "$temp_dir/nautilus-scripts"

    __test_begin
    echo "127.0.0.1" >"$temp_dir/Test internet.txt"
    __test_script "Network and Internet/IP: Scan hosts" "text" "" \
        "$temp_dir/Test internet.txt"

    __test_begin
    echo "https://github.com/cfgnunes/nautilus-scripts.git" \
        >"$temp_dir/Test internet.txt"
    __test_script "Network and Internet/URL: Check HTTP status" "text" "" \
        "$temp_dir/Test internet.txt"

    __test_begin
    echo "https://www.rfc-editor.org/rfc/rfc2616.txt" \
        >"$temp_dir/Test internet.txt"
    __test_script "Network and Internet/URL: Download file" "empty" \
        "rfc2616.txt" "$temp_dir/Test internet.txt"

    __test_begin
    echo "https://www.rfc-editor.org/rfc/rfc2616.txt" \
        >"$temp_dir/Test internet.txt"
    __test_script "Network and Internet/URL: Show HTTP headers" "text" "" \
        "$temp_dir/Test internet.txt"

    # -------------------------------------------------------------------------
    # SECTION: Plain text
    # -------------------------------------------------------------------------

    __test_scripts_file "$fixture_txt" "Test text.txt" "empty" \
        "Plain text/Text: Encode to UTF-8|Test text (UTF-8).txt" \
        "Plain text/Text: Remove accents|Test text (no accents).txt" \
        "Plain text/Text: Convert tabs to 4 spaces|Test text (4 spaces).txt"

    __test_scripts_stdout "$fixture_txt" "Test text.txt" \
        "Plain text/Text: List encodings" \
        "Plain text/Text: List line breaks" \
        "Plain text/Text: List line counts" \
        "Plain text/Text: List line lengths" \
        "Plain text/Text: List word counts"

    __test_begin \
        "$fixture_txt::Test text.txt" \
        "$fixture_txt::Test text 2.txt"
    echo "Content of 'Test text 2'." >"$temp_dir/Test text 2.txt"
    __test_script "Plain text/Text: Concatenate multiple files" "empty" \
        "Concatenated files.txt" \
        "$temp_dir/Test text.txt" "$temp_dir/Test text 2.txt"

    __test_begin
    echo "Content of 'Test text'.(á)" |
        piconv -f UTF-8 -t ISO-8859-1 >"$temp_dir/Test text.txt"
    __test_script "Plain text/Text: Normalize (UTF-8, recursive)" "empty" \
        "Test text.txt.bak" "$temp_dir/Test text.txt"

    __test_begin "$fixture_txt::Test text.txt"
    __test_script "Plain text/Text: List issues" "empty" "" \
        "$temp_dir/Test text.txt"

    __test_scripts_file "$fixture_txt" "Test text.txt" "empty" \
        "Plain text/Text: Remove trailing spaces|Test text (no trailing).txt"

    # -------------------------------------------------------------------------
    # SECTION: Rename files
    # -------------------------------------------------------------------------

    # IGNORED: Rename files/Rename: To lowercase (recursive)
    # IGNORED: Rename files/Rename: To uppercase (recursive)

    __test_begin
    echo "Content of 'Test'." >"$temp_dir/Test réname accents.txt"
    __test_script "Rename files/Rename: Remove accents" "empty" \
        "Test rename accents.txt" "$temp_dir/Test réname accents.txt"

    __test_begin
    echo "Content of 'Test'." >"$temp_dir/Test rename suffixes extra.txt"
    __test_script "Rename files/Rename: Remove suffixes" "empty" \
        "Test rename suffixes.txt" \
        "$temp_dir/Test rename suffixes extra.txt"

    __test_begin
    echo "Content of 'Test'." \
        >"$temp_dir/Test rename suffixes2 (suffix extra).txt"
    __test_script "Rename files/Rename: Remove suffixes" "empty" \
        "Test rename suffixes2.txt" \
        "$temp_dir/Test rename suffixes2 (suffix extra).txt"

    __test_begin
    echo "Content of 'Test'." >"$temp_dir/Extra Test rename prefixes.txt"
    __test_script "Rename files/Rename: Remove prefixes" "empty" \
        "Test rename prefixes.txt" \
        "$temp_dir/Extra Test rename prefixes.txt"

    __test_begin
    echo "Content of 'Test'." \
        >"$temp_dir/(prefix extra) Test rename prefixes2.txt"
    __test_script "Rename files/Rename: Remove prefixes" "empty" \
        "Test rename prefixes2.txt" \
        "$temp_dir/(prefix extra) Test rename prefixes2.txt"

    __test_begin
    echo "Content of 'Test'." >"$temp_dir/Test rename.txt"
    __test_script "Rename files/Rename: Change spaces to dashes" "empty" \
        "Test-rename.txt" "$temp_dir/Test rename.txt"

    __test_begin
    echo "Content of 'Test'." >"$temp_dir/Test-rename.txt"
    __test_script "Rename files/Rename: Change dashes to spaces" "empty" \
        "Test rename.txt" "$temp_dir/Test-rename.txt"

    __test_begin
    echo "Content of 'Test'." >"$temp_dir/Test rename.txt"
    __test_script "Rename files/Rename: To lowercase" "empty" \
        "test rename.txt" "$temp_dir/Test rename.txt"

    __test_begin
    echo "Content of 'Test'." >"$temp_dir/test rename.txt"
    __test_script "Rename files/Rename: To sentence case" "empty" \
        "Test rename.txt" "$temp_dir/test rename.txt"

    __test_begin
    echo "Content of 'Test'." >"$temp_dir/test rename.txt"
    __test_script "Rename files/Rename: To title case" "empty" \
        "Test Rename.txt" "$temp_dir/test rename.txt"

    __test_begin
    echo "Content of 'Test'." >"$temp_dir/Test rename.txt"
    __test_script "Rename files/Rename: To uppercase" "empty" \
        "TEST RENAME.TXT" "$temp_dir/Test rename.txt"

    __test_begin
    echo "Content of 'Test'." >"$temp_dir/Test md5 prefix.txt"
    checksum=$(md5sum -- "$temp_dir/Test md5 prefix.txt")
    checksum=${checksum%%[$'\t ']*}
    checksum=${checksum:0:4}
    __test_script "Rename files/Rename: Add MD5 prefix" "empty" \
        "($checksum) Test md5 prefix.txt" \
        "$temp_dir/Test md5 prefix.txt"

    # -------------------------------------------------------------------------
    # SECTION: Checksum
    # -------------------------------------------------------------------------

    # IGNORED: Checksum/Generate MD5 file
    # IGNORED: Checksum/Generate SHA1 file
    # IGNORED: Checksum/Generate SHA256 file
    # IGNORED: Checksum/Generate SHA512 file

    local hash_script=""
    for hash_script in \
        "Checksum/Compute all checksums" \
        "Checksum/Compute MD5" \
        "Checksum/Compute SHA1" \
        "Checksum/Compute SHA256" \
        "Checksum/Compute SHA512"; do
        __test_begin
        echo "Content of 'Test hash'." >"$temp_dir/Test hash"
        __run_script "$hash_script" "$temp_dir/Test hash"
        __check_file_nonempty "$temp_dir/Test hash"
        __check_file_nonempty "$std_output"
    done

    __test_begin
    echo "Content of 'Test hash'." >"$temp_dir/Test hash"
    md5sum -- "$temp_dir/Test hash" >"$temp_dir/Test hash.md5"
    __run_script "Checksum/Verify MD5 file" "$temp_dir/Test hash.md5"
    __check_file_nonempty "$temp_dir/Test hash"

    __test_begin
    echo "Content of 'Test hash'." >"$temp_dir/Test hash"
    sha1sum -- "$temp_dir/Test hash" >"$temp_dir/Test hash.sha1"
    __run_script "Checksum/Verify SHA1 file" "$temp_dir/Test hash.sha1"
    __check_file_nonempty "$temp_dir/Test hash"

    __test_begin
    echo "Content of 'Test hash'." >"$temp_dir/Test hash"
    sha256sum -- "$temp_dir/Test hash" >"$temp_dir/Test hash.sha256"
    __run_script "Checksum/Verify SHA256 file" "$temp_dir/Test hash.sha256"
    __check_file_nonempty "$temp_dir/Test hash"

    __test_begin
    echo "Content of 'Test hash'." >"$temp_dir/Test hash"
    sha512sum -- "$temp_dir/Test hash" >"$temp_dir/Test hash.sha512"
    __run_script "Checksum/Verify SHA512 file" "$temp_dir/Test hash.sha512"
    __check_file_nonempty "$temp_dir/Test hash"

    printf "\nFinished! "
    printf "Results: %s tests, %s failed.\n" "$_TOTAL_TESTS" "$_TOTAL_FAILED"

    read -n1 -rp "Press any key to finish..." </dev/tty
}

_main "$@"
