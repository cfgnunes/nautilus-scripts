#!/usr/bin/env bash

# Source the script '.common-functions.sh'.
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
ROOT_DIR=$(grep --only-matching "^.*scripts[^/]*" <<<"$SCRIPT_DIR")
source "$ROOT_DIR/.common-functions.sh"

# Test all functions defined in the script '.common-functions.sh'.

set -u

# -----------------------------------------------------------------------------
# SECTION: Constants ----
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
# SECTION: Global variables ----
# -----------------------------------------------------------------------------

_TOTAL_TESTS=0
_TOTAL_FAILED=0

# -----------------------------------------------------------------------------
# SECTION: Functions ----
# -----------------------------------------------------------------------------

_main() {
    printf "Running the unit tests...\n"

    __run_source_common_functions

    __run_get_filename_extension
    __run_get_script_name
    __run_log_error
    __run_move_file
    __run_storage_text
    __run_str_collapse_char
    __run_str_sort
    __run_get_items_count
    __run_strip_filename_extension
    __run_text_remove_empty_lines
    __run_text_sort

    rm -rf -- "$_TEMP_DIR"

    printf "\nFinished! "
    printf "Results: %s tests, %s failed.\n" "$_TOTAL_TESTS" "$_TOTAL_FAILED"
}

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

__test_equal() {
    local description=$1
    local expected_output=$2
    local output=$3

    ((_TOTAL_TESTS++))

    if [[ "$expected_output" == "$output" ]]; then
        printf "[\\033[32m PASS \\033[0m] "
    else
        printf "[\\033[31mFAILED\\033[0m] "
        ((_TOTAL_FAILED++))
    fi
    printf "\\033[33mFunction:\\033[0m "
    printf "%s" "${FUNCNAME[1]}"
    printf "\n         \\033[33mDescription:\\033[0m "
    printf "%s" "$description" | sed -z "s|\n|\\\n|g" | cat -A
    printf "\n"

    if [[ "$expected_output" != "$output" ]]; then
        printf "\\033[31mExpected output:\\033[0m "
        printf "%s" "$expected_output" | sed -z "s|\n|\\\n|g" | cat -A
        printf "\n"
        printf "         \\033[31mOutput:\\033[0m "
        printf "%s" "$output" | sed -z "s|\n|\\\n|g" | cat -A
        printf "\n"
    fi
}

__run_source_common_functions() {
    __test_equal "Check global variables." "$FIELD_SEPARATOR" $'\r'
}

__run_get_filename_extension() {
    local input=""
    local expected_output=""
    local output=""

    input=""
    expected_output=""
    output=$(_get_filename_extension "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="File.txt"
    expected_output=".txt"
    output=$(_get_filename_extension "$input")
    __test_equal "$input" "$expected_output" "$output"

    input=".File.txt"
    expected_output=".txt"
    output=$(_get_filename_extension "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="File.tar.gz"
    expected_output=".tar.gz"
    output=$(_get_filename_extension "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="File.txt.tar.gz"
    expected_output=".tar.gz"
    output=$(_get_filename_extension "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="File.txt.gpg"
    expected_output=".gpg"
    output=$(_get_filename_extension "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="File"
    expected_output=""
    output=$(_get_filename_extension "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="/tmp/File.txt"
    expected_output=".txt"
    output=$(_get_filename_extension "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="/tmp/.File.txt"
    expected_output=".txt"
    output=$(_get_filename_extension "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="/tmp/.File"
    expected_output=""
    output=$(_get_filename_extension "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="/tmp/File.thisisnotanextension"
    expected_output=""
    output=$(_get_filename_extension "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="/tmp/File"
    expected_output=""
    output=$(_get_filename_extension "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="/tmp/File !@#$%&*()_"$'\n'"+.txt"
    expected_output=".txt"
    output=$(_get_filename_extension "$input")
    __test_equal "$input" "$expected_output" "$output"
}

__run_get_script_name() {
    local expected_output=""
    local output=""

    expected_output=".test-functions.sh"
    output=$(_get_script_name)
    __test_equal "$expected_output" "$expected_output" "$output"
}

__run_log_error() {
    local expected_output=""
    local output=""

    _log_error "message" "input_file" "std_output" "output_file"
    output=$(cat -- "$TEMP_DIR_LOGS/"* 2>/dev/null | tail -n +2)
    expected_output=" > Input file: input_file"$'\n'" > Output file: output_file"$'\n'" > Error: message"$'\n'" > Standard output:"$'\n'"std_output"

    __test_equal "Check the log error content." "$expected_output" "$output"
}

__run_move_file() {
    local expected_output=""
    local output=""

    __create_temp_files
    _move_file "" "$_TEMP_FILE1" "$_TEMP_FILE2"
    expected_output=$_TEMP_FILE1_CONTENT
    output=$(<"$_TEMP_FILE1")
    __test_equal "" "$expected_output" "$output"
    expected_output=$_TEMP_FILE2_CONTENT
    output=$(<"$_TEMP_FILE2")
    __test_equal "" "$expected_output" "$output"
    __clean_temp_files

    __create_temp_files
    _move_file "rename" "$_TEMP_FILE1" "$_TEMP_FILE1"
    expected_output=$_TEMP_FILE1_CONTENT
    output=$(<"$_TEMP_FILE1")
    __test_equal "skip" "$expected_output" "$output"
    __clean_temp_files

    __create_temp_files
    _move_file "skip" "$_TEMP_FILE1" "$_TEMP_FILE2"
    expected_output=$_TEMP_FILE1_CONTENT
    output=$(<"$_TEMP_FILE1")
    __test_equal "skip" "$expected_output" "$output"
    expected_output=$_TEMP_FILE2_CONTENT
    output=$(<"$_TEMP_FILE2")
    __test_equal "skip" "$expected_output" "$output"
    __clean_temp_files

    __create_temp_files
    _move_file "safe_overwrite" "$_TEMP_FILE1" "$_TEMP_FILE2"
    expected_output=$_TEMP_FILE1_CONTENT
    output=$(<"$_TEMP_FILE2")
    __test_equal "safe_overwrite" "$expected_output" "$output"
    __clean_temp_files

    __create_temp_files
    _move_file "rename" "$_TEMP_FILE1" "$_TEMP_FILE2"
    expected_output=$_TEMP_FILE2_CONTENT
    output=$(<"$_TEMP_FILE2")
    __test_equal "rename" "$expected_output" "$output"
    expected_output=$_TEMP_FILE1_CONTENT
    output=$(<"$_TEMP_FILE2 (2)")
    __test_equal "rename" "$expected_output" "$output"
    __clean_temp_files
}

__run_storage_text() {
    # Test all functions related to the storage text feature:
    # '_storage_text_clean'
    # '_storage_text_read_all'
    # '_storage_text_write_ln'
    # '_storage_text_write'

    local expected_output=""
    local output=""

    _storage_text_write_ln "Line"
    _storage_text_write_ln "Line"
    _storage_text_write_ln "Line"

    expected_output="Line"$'\n'"Line"$'\n'"Line"
    output=$(_storage_text_read_all)
    _storage_text_clean

    __test_equal "Write/read the compiled result." "$expected_output" "$output"

    _storage_text_write "Line"
    _storage_text_write "Line"
    _storage_text_write "Line"

    expected_output="LineLineLine"
    output=$(_storage_text_read_all)
    __test_equal "Write/read the compiled result." "$expected_output" "$output"
}

__run_strip_filename_extension() {
    local input=""
    local expected_output=""
    local output=""

    input=""
    expected_output=""
    output=$(_strip_filename_extension "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="File.txt"
    expected_output="File"
    output=$(_strip_filename_extension "$input")
    __test_equal "$input" "$expected_output" "$output"

    input=".File.txt"
    expected_output=".File"
    output=$(_strip_filename_extension "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="File.tar.gz"
    expected_output="File"
    output=$(_strip_filename_extension "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="File.txt.tar.gz"
    expected_output="File.txt"
    output=$(_strip_filename_extension "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="File.txt.gpg"
    expected_output="File.txt"
    output=$(_strip_filename_extension "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="File"
    expected_output="File"
    output=$(_strip_filename_extension "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="/tmp/File.txt"
    expected_output="/tmp/File"
    output=$(_strip_filename_extension "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="/tmp/.File.txt"
    expected_output="/tmp/.File"
    output=$(_strip_filename_extension "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="/tmp/.File"
    expected_output="/tmp/.File"
    output=$(_strip_filename_extension "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="/tmp/File.thisisnotanextension"
    expected_output="/tmp/File.thisisnotanextension"
    output=$(_strip_filename_extension "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="/tmp/File"
    expected_output="/tmp/File"
    output=$(_strip_filename_extension "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="/tmp/File !@#$%&*()_"$'\n'"+.txt"
    expected_output="/tmp/File !@#$%&*()_"$'\n'"+"
    output=$(_strip_filename_extension "$input")
    __test_equal "$input" "$expected_output" "$output"
}

__run_text_remove_empty_lines() {
    local input=""
    local expected_output=""
    local output=""

    input=""
    expected_output=""
    output=$(_text_remove_empty_lines "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="Line1"$'\n'"Line2"
    expected_output="Line1"$'\n'"Line2"
    output=$(_text_remove_empty_lines "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="Line1"$'\n'"Line2"$'\n'
    expected_output="Line1"$'\n'"Line2"
    output=$(_text_remove_empty_lines "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="Line1"$'\n'"Line2"$'\n'$'\n'
    expected_output="Line1"$'\n'"Line2"
    output=$(_text_remove_empty_lines "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="Line1"$'\n'$'\n'"Line2"
    expected_output="Line1"$'\n'"Line2"
    output=$(_text_remove_empty_lines "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="Line1"$'\n'"  "$'\n'"Line2"
    expected_output="Line1"$'\n'"Line2"
    output=$(_text_remove_empty_lines "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="Line1"$'\n'" "$'\t'$'\n'"Line2"
    expected_output="Line1"$'\n'"Line2"
    output=$(_text_remove_empty_lines "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="Line1"$'\n'$'\r'$'\n'"Line2"
    expected_output="Line1"$'\n'"Line2"
    output=$(_text_remove_empty_lines "$input")
    __test_equal "$input" "$expected_output" "$output"
}

__run_str_sort() {
    local input=""
    local expected_output=""
    local output=""

    input=""
    expected_output=""
    output=$(_str_sort "$input" "\r" "false")
    __test_equal "$input" "$expected_output" "$output"

    input="Line1"$'\r'"Line2"
    expected_output="Line1"$'\r'"Line2"
    output=$(_str_sort "$input" "\r" "false")
    __test_equal "$input" "$expected_output" "$output"

    input="Line2"$'\r'"Line1"
    expected_output="Line1"$'\r'"Line2"
    output=$(_str_sort "$input" "\r" "false")
    __test_equal "$input" "$expected_output" "$output"

    input="10"$'\r'"2"
    expected_output="2"$'\r'"10"
    output=$(_str_sort "$input" "\r" "false")
    __test_equal "$input" "$expected_output" "$output"

    input="10"$'\r'"2"$'\r'"2"
    expected_output="2"$'\r'"10"
    output=$(_str_sort "$input" "\r" "true")
    __test_equal "$input" "$expected_output" "$output"
}

__run_str_collapse_char() {
    input=""
    expected_output=""
    output=$(_str_collapse_char "$input" "x")
    __test_equal "$input" "$expected_output" "$output"

    input="x123xx123x"
    expected_output="123x123"
    output=$(_str_collapse_char "$input" "x")
    __test_equal "$input" "$expected_output" "$output"

    input="xxx"
    expected_output=""
    output=$(_str_collapse_char "$input" "x")
    __test_equal "$input" "$expected_output" "$output"
}

__run_text_sort() {
    local input=""
    local expected_output=""
    local output=""

    input=""
    expected_output=""
    output=$(_text_sort "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="Line1"$'\n'"Line2"
    expected_output="Line1"$'\n'"Line2"
    output=$(_text_sort "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="Line2"$'\n'"Line1"
    expected_output="Line1"$'\n'"Line2"
    output=$(_text_sort "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="10"$'\n'"2"
    expected_output="2"$'\n'"10"
    output=$(_text_sort "$input")
    __test_equal "$input" "$expected_output" "$output"
}

__run_get_items_count() {
    input=""
    expected_output=0
    output=$(_get_items_count "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="${FIELD_SEPARATOR}${FIELD_SEPARATOR}"
    expected_output=3
    output=$(_get_items_count "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="10${FIELD_SEPARATOR}2"
    expected_output=2
    output=$(_get_items_count "$input")
    __test_equal "$input" "$expected_output" "$output"
}

_main "$@"
