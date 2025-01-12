#!/usr/bin/env bash

# Unit test script.

set -u

# -----------------------------------------------------------------------------
# CONSTANTS
# -----------------------------------------------------------------------------

_TEMP_DIR_TEST="/tmp/unit-test"
_TEMP_FILE1="$_TEMP_DIR_TEST/file1"
_TEMP_FILE2="$_TEMP_DIR_TEST/file2"
_TEMP_FILE3="$_TEMP_DIR_TEST/file3"
_TEMP_FILE1_CONTENT="File 1 test."
_TEMP_FILE2_CONTENT="File 2 test."
_TEMP_FILE3_CONTENT="File 3 test."

readonly \
    _TEMP_DIR_TEST \
    _TEMP_FILE1 \
    _TEMP_FILE2 \
    _TEMP_FILE3 \
    _TEMP_FILE1_CONTENT \
    _TEMP_FILE2_CONTENT \
    _TEMP_FILE3_CONTENT

# -----------------------------------------------------------------------------
# GLOBAL VARIABLES
# -----------------------------------------------------------------------------

_TOTAL_TESTS=0
_TOTAL_FAILED=0

# -----------------------------------------------------------------------------
# FUNCTIONS
# -----------------------------------------------------------------------------

_main() {
    printf "Running the unit tests...\n"

    _run_source_common_functions
    _run_get_filename_extension
    _run_get_script_name
    _run_move_file
    _run_storage_text_read_all
    _run_strip_filename_extension
    _run_text_remove_empty_lines
    _run_text_sort

    printf "\nFinished! "
    printf "Results: %s tests, %s failed.\n" "$_TOTAL_TESTS" "$_TOTAL_FAILED"
}

_files_test_create() {
    rm -rf "$_TEMP_DIR_TEST"
    mkdir -p "$_TEMP_DIR_TEST"
    printf "%s" "$_TEMP_FILE1_CONTENT" >"$_TEMP_FILE1"
    printf "%s" "$_TEMP_FILE2_CONTENT" >"$_TEMP_FILE2"
    printf "%s" "$_TEMP_FILE3_CONTENT" >"$_TEMP_FILE3"
}

_files_test_clean() {
    rm -rf "$_TEMP_DIR_TEST"
}

_test_equal() {
    local description=$1
    local value1=$2
    local value2=$3
    ((_TOTAL_TESTS++))

    if [[ "$value1" == "$value2" ]]; then
        printf " > [PASS]"
    else
        printf " > [FAILED]"
        ((_TOTAL_FAILED++))
    fi
    printf "\t(%s)\t" "${FUNCNAME[1]}"
    printf "%s" "$description" | sed -z "s|\n|\\\n|g" | cat -A
    printf "\n"
}

_test_file() {
    local description=$1
    local file=$2

    ((_TOTAL_TESTS++))

    if [[ -f "$file" ]]; then
        printf " > [PASS]"
    else
        printf " > [FAILED]"
        ((_TOTAL_FAILED++))
    fi
    printf "\t(%s)\t" "${FUNCNAME[1]}"
    printf "%s" "$description" | sed -z "s|\n|\\\n|g" | cat -A
    printf "\n"
}

_run_source_common_functions() {
    local SCRIPT_DIR=""
    local ROOT_DIR=""

    # Source the script 'common-functions.sh'.
    SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
    ROOT_DIR=$(grep --only-matching "^.*scripts[^/]*" <<<"$SCRIPT_DIR")
    ROOT_DIR=${ROOT_DIR//".helper-scripts"/}
    source "$ROOT_DIR/common-functions.sh"

    _test_equal "Check global variables." "$FIELD_SEPARATOR" $'\r'
}

_run_get_filename_extension() {
    local input=""
    local expected_output=""
    local output=""

    input=""
    expected_output=""
    output=$(_get_filename_extension "$input")
    _test_equal "$input" "$output" "$expected_output"

    input="File.txt"
    expected_output=".txt"
    output=$(_get_filename_extension "$input")
    _test_equal "$input" "$output" "$expected_output"

    input=".File.txt"
    expected_output=".txt"
    output=$(_get_filename_extension "$input")
    _test_equal "$input" "$output" "$expected_output"

    input="File.tar.gz"
    expected_output=".tar.gz"
    output=$(_get_filename_extension "$input")
    _test_equal "$input" "$output" "$expected_output"

    input="File.txt.tar.gz"
    expected_output=".tar.gz"
    output=$(_get_filename_extension "$input")
    _test_equal "$input" "$output" "$expected_output"

    input="File.txt.gpg"
    expected_output=".gpg"
    output=$(_get_filename_extension "$input")
    _test_equal "$input" "$output" "$expected_output"

    input="File"
    expected_output=""
    output=$(_get_filename_extension "$input")
    _test_equal "$input" "$output" "$expected_output"

    input="/tmp/File.txt"
    expected_output=".txt"
    output=$(_get_filename_extension "$input")
    _test_equal "$input" "$output" "$expected_output"

    input="/tmp/.File.txt"
    expected_output=".txt"
    output=$(_get_filename_extension "$input")
    _test_equal "$input" "$output" "$expected_output"

    input="/tmp/.File"
    expected_output=""
    output=$(_get_filename_extension "$input")
    _test_equal "$input" "$output" "$expected_output"

    input="/tmp/File.thisisnotanextension"
    expected_output=""
    output=$(_get_filename_extension "$input")
    _test_equal "$input" "$output" "$expected_output"

    input="/tmp/File"
    expected_output=""
    output=$(_get_filename_extension "$input")
    _test_equal "$input" "$output" "$expected_output"

    input="/tmp/File !@#$%&*()_"$'\n'"+.txt"
    expected_output=".txt"
    output=$(_get_filename_extension "$input")
    _test_equal "$input" "$output" "$expected_output"
}

_run_get_script_name() {
    local expected_output=""
    local output=""

    expected_output="unit-tests.sh"
    output=$(_get_script_name)
    _test_equal "$expected_output" "$output" "$expected_output"
}

_run_move_file() {
    local expected_output=""
    local output=""

    _files_test_create
    _move_file "" "$_TEMP_FILE1" "$_TEMP_FILE2"
    expected_output=$_TEMP_FILE1_CONTENT
    output=$(<"$_TEMP_FILE1")
    _test_equal "" "$output" "$expected_output"
    expected_output=$_TEMP_FILE2_CONTENT
    output=$(<"$_TEMP_FILE2")
    _test_equal "" "$output" "$expected_output"
    _files_test_clean

    _files_test_create
    _move_file "rename" "$_TEMP_FILE1" "$_TEMP_FILE1"
    expected_output=$_TEMP_FILE1_CONTENT
    output=$(<"$_TEMP_FILE1")
    _test_equal "skip" "$output" "$expected_output"
    _files_test_clean

    _files_test_create
    _move_file "skip" "$_TEMP_FILE1" "$_TEMP_FILE2"
    expected_output=$_TEMP_FILE1_CONTENT
    output=$(<"$_TEMP_FILE1")
    _test_equal "skip" "$output" "$expected_output"
    expected_output=$_TEMP_FILE2_CONTENT
    output=$(<"$_TEMP_FILE2")
    _test_equal "skip" "$output" "$expected_output"
    _files_test_clean

    _files_test_create
    _move_file "overwrite" "$_TEMP_FILE1" "$_TEMP_FILE2"
    expected_output=$_TEMP_FILE1_CONTENT
    output=$(<"$_TEMP_FILE2")
    _test_equal "overwrite" "$output" "$expected_output"
    _files_test_clean

    _files_test_create
    _move_file "rename" "$_TEMP_FILE1" "$_TEMP_FILE2"
    expected_output=$_TEMP_FILE2_CONTENT
    output=$(<"$_TEMP_FILE2")
    _test_equal "rename" "$output" "$expected_output"
    expected_output=$_TEMP_FILE1_CONTENT
    output=$(<"$_TEMP_FILE2 (1)")
    _test_equal "rename" "$output" "$expected_output"
    _files_test_clean

}

_run_storage_text_read_all() {
    local expected_output=""
    local output=""

    _storage_text_write_ln "Line"
    _storage_text_write_ln "Line"

    expected_output="Line"$'\n'"Line"
    output=$(_storage_text_read_all)
    _test_equal "Write and read the compiled temp result." "$output" "$expected_output"
}

_run_strip_filename_extension() {
    local input=""
    local expected_output=""
    local output=""

    input=""
    expected_output=""
    output=$(_strip_filename_extension "$input")
    _test_equal "$input" "$output" "$expected_output"

    input="File.txt"
    expected_output="File"
    output=$(_strip_filename_extension "$input")
    _test_equal "$input" "$output" "$expected_output"

    input=".File.txt"
    expected_output=".File"
    output=$(_strip_filename_extension "$input")
    _test_equal "$input" "$output" "$expected_output"

    input="File.tar.gz"
    expected_output="File"
    output=$(_strip_filename_extension "$input")
    _test_equal "$input" "$output" "$expected_output"

    input="File.txt.tar.gz"
    expected_output="File.txt"
    output=$(_strip_filename_extension "$input")
    _test_equal "$input" "$output" "$expected_output"

    input="File.txt.gpg"
    expected_output="File.txt"
    output=$(_strip_filename_extension "$input")
    _test_equal "$input" "$output" "$expected_output"

    input="File"
    expected_output="File"
    output=$(_strip_filename_extension "$input")
    _test_equal "$input" "$output" "$expected_output"

    input="/tmp/File.txt"
    expected_output="/tmp/File"
    output=$(_strip_filename_extension "$input")
    _test_equal "$input" "$output" "$expected_output"

    input="/tmp/.File.txt"
    expected_output="/tmp/.File"
    output=$(_strip_filename_extension "$input")
    _test_equal "$input" "$output" "$expected_output"

    input="/tmp/.File"
    expected_output="/tmp/.File"
    output=$(_strip_filename_extension "$input")
    _test_equal "$input" "$output" "$expected_output"

    input="/tmp/File.thisisnotanextension"
    expected_output="/tmp/File.thisisnotanextension"
    output=$(_strip_filename_extension "$input")
    _test_equal "$input" "$output" "$expected_output"

    input="/tmp/File"
    expected_output="/tmp/File"
    output=$(_strip_filename_extension "$input")
    _test_equal "$input" "$output" "$expected_output"

    input="/tmp/File !@#$%&*()_"$'\n'"+.txt"
    expected_output="/tmp/File !@#$%&*()_"$'\n'"+"
    output=$(_strip_filename_extension "$input")
    _test_equal "$input" "$output" "$expected_output"
}

_run_text_remove_empty_lines() {
    local input=""
    local expected_output=""
    local output=""

    input=""
    expected_output=""
    output=$(_text_remove_empty_lines "$input")
    _test_equal "$input" "$output" "$expected_output"

    input="Line1"$'\n'"Line2"
    expected_output="Line1"$'\n'"Line2"
    output=$(_text_remove_empty_lines "$input")
    _test_equal "$input" "$output" "$expected_output"

    input="Line1"$'\n'"Line2"$'\n'
    expected_output="Line1"$'\n'"Line2"
    output=$(_text_remove_empty_lines "$input")
    _test_equal "$input" "$output" "$expected_output"

    input="Line1"$'\n'"Line2"$'\n'$'\n'
    expected_output="Line1"$'\n'"Line2"
    output=$(_text_remove_empty_lines "$input")
    _test_equal "$input" "$output" "$expected_output"

    input="Line1"$'\n'$'\n'"Line2"
    expected_output="Line1"$'\n'"Line2"
    output=$(_text_remove_empty_lines "$input")
    _test_equal "$input" "$output" "$expected_output"

    input="Line1"$'\n'"  "$'\n'"Line2"
    expected_output="Line1"$'\n'"Line2"
    output=$(_text_remove_empty_lines "$input")
    _test_equal "$input" "$output" "$expected_output"

    input="Line1"$'\n'" "$'\t'$'\n'"Line2"
    expected_output="Line1"$'\n'"Line2"
    output=$(_text_remove_empty_lines "$input")
    _test_equal "$input" "$output" "$expected_output"

    input="Line1"$'\n'$'\r'$'\n'"Line2"
    expected_output="Line1"$'\n'"Line2"
    output=$(_text_remove_empty_lines "$input")
    _test_equal "$input" "$output" "$expected_output"
}

_run_text_sort() {
    local input=""
    local expected_output=""
    local output=""

    input=""
    expected_output=""
    output=$(_text_sort "$input")
    _test_equal "$input" "$output" "$expected_output"

    input="Line1"$'\n'"Line2"
    expected_output="Line1"$'\n'"Line2"
    output=$(_text_sort "$input")
    _test_equal "$input" "$output" "$expected_output"

    input="Line2"$'\n'"Line1"
    expected_output="Line1"$'\n'"Line2"
    output=$(_text_sort "$input")
    _test_equal "$input" "$output" "$expected_output"

    input="10"$'\n'"2"
    expected_output="2"$'\n'"10"
    output=$(_text_sort "$input")
    _test_equal "$input" "$output" "$expected_output"
}

_main "$@"
