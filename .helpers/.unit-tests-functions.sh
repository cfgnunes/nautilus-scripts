#!/usr/bin/env bash

# Source the file '.common-functions.sh'.
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
ROOT_DIR=$(grep --only-matching "^.*scripts[^/]*" <<<"$SCRIPT_DIR")
source "$ROOT_DIR/.common-functions.sh"

# Test all functions defined in the script '.common-functions.sh'.

set -u

#------------------------------------------------------------------------------
#region Constants
#------------------------------------------------------------------------------

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

#endregion
#------------------------------------------------------------------------------
#region Global variables
#------------------------------------------------------------------------------

_TOTAL_TESTS=0
_TOTAL_FAILED=0

#endregion
#------------------------------------------------------------------------------
#region Functions
#------------------------------------------------------------------------------

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

    __run_get_dirname
    __run_get_filename_full_path
    __run_get_filename_next_suffix
    __run_make_temp_dir
    __run_make_temp_dir_local
    __run_make_temp_file
    __run_is_directory_empty
    __run_convert_delimited_string_to_text
    __run_convert_text_to_delimited_string
    __run_get_element
    __run_text_uri_decode
    __run_text_remove_pwd
    __run_str_human_readable_path
    __run_translate_to_gvfs_path
    __run_command_exists
    __run_check_output
    __run_find_filtered_files
    __run_directory_push_pop
    __run_get_output_filename
    __run_get_file_mime
    __run_get_file_encoding
    __run_validate_file_mime
    __run_deps_get_dependency_value
    __run_i18n
    __run_get_max_procs
    __run_logs_consolidate
    __run_get_working_directory
    __run_validate_file_mime_parallel
    __run_run_function_parallel
    __run_move_file_errors
    __run_i18n_initialize
    __run_storage_text_edge_cases

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

__test_exit_code() {
    local description=$1
    local expected_exit_code=$2
    local exit_code=0

    shift 2
    "$@" || exit_code=$?

    ((_TOTAL_TESTS++))

    if ((expected_exit_code == exit_code)); then
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

    if ((expected_exit_code != exit_code)); then
        printf "\\033[31mExpected exit code:\\033[0m %s\n" "$expected_exit_code"
        printf "         \\033[31mExit code:\\033[0m %s\n" "$exit_code"
    fi
}

__test_path_exists() {
    local description=$1
    local expected_exists=$2
    local path=$3
    local exists="false"

    [[ -e "$path" ]] && exists="true"

    __test_equal "$description" "$expected_exists" "$exists"
}

__run_source_common_functions() {
    __test_equal "Check FIELD_SEPARATOR." "$FIELD_SEPARATOR" $'\r'
    __test_equal "Check PREFIX_OUTPUT_DIR." "Output" "$PREFIX_OUTPUT_DIR"
    __test_equal "Check PREFIX_ERROR_LOG_FILE." "Errors" "$PREFIX_ERROR_LOG_FILE"
    __test_equal "Check IGNORE_FIND_PATH." "*.git/*" "$IGNORE_FIND_PATH"
    __test_equal "Check GUI_BOX_HEIGHT." "550" "$GUI_BOX_HEIGHT"
    __test_equal "Check GUI_BOX_WIDTH." "900" "$GUI_BOX_WIDTH"
    __test_equal "Check ACCESSED_RECENTLY_LINKS_TO_KEEP." "15" \
        "$ACCESSED_RECENTLY_LINKS_TO_KEEP"
    # shellcheck disable=SC2153
    __test_path_exists "Check TEMP_DIR exists." "true" "$TEMP_DIR"
    __test_path_exists "Check TEMP_DIR_LOGS exists." "true" "$TEMP_DIR_LOGS"
    __test_path_exists "Check TEMP_DIR_TASK exists." "true" "$TEMP_DIR_TASK"
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

    expected_output=".unit-tests-functions.sh"
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
    local input=""
    local expected_output=""
    local output=""

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

    input="abc"
    expected_output="abc"
    output=$(_str_collapse_char "$input" "x")
    __test_equal "$input" "$expected_output" "$output"

    input="xabcx"
    expected_output="abc"
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
    local input=""
    local expected_output=""
    local output=""

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

    input="single"
    expected_output=1
    output=$(_get_items_count "$input")
    __test_equal "$input" "$expected_output" "$output"
}

__run_get_dirname() {
    local input=""
    local expected_output=""
    local output=""

    input="$_TEMP_FILE1"
    expected_output=$(dirname -- "$_TEMP_FILE1")
    expected_output=$(cd -- "$expected_output" &>/dev/null && pwd)
    output=$(_get_dirname "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="/tmp"
    expected_output="/"
    output=$(_get_dirname "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="/"
    expected_output="/"
    output=$(_get_dirname "$input")
    __test_equal "$input" "$expected_output" "$output"
}

__run_get_filename_full_path() {
    local input=""
    local expected_output=""
    local output=""

    input="$_TEMP_FILE1"
    expected_output="$_TEMP_FILE1"
    output=$(_get_filename_full_path "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="/tmp/test.txt"
    expected_output="/tmp/test.txt"
    output=$(_get_filename_full_path "$input")
    __test_equal "$input" "$expected_output" "$output"

    __create_temp_files
    pushd "$_TEMP_DIR_TEST" &>/dev/null || return 1
    input="file1"
    expected_output="$_TEMP_DIR_TEST/file1"
    output=$(_get_filename_full_path "$input")
    __test_equal "$input" "$expected_output" "$output"
    popd &>/dev/null || return 1
    __clean_temp_files
}

__run_get_filename_next_suffix() {
    local input=""
    local expected_output=""
    local output=""

    __create_temp_files
    input="$_TEMP_DIR_TEST/new_file.txt"
    expected_output="$_TEMP_DIR_TEST/new_file.txt"
    output=$(_get_filename_next_suffix "$input")
    __test_equal "New file without conflict." "$expected_output" "$output"

    input="$_TEMP_FILE1"
    expected_output="$_TEMP_DIR_TEST/file1 (2)"
    output=$(_get_filename_next_suffix "$input")
    __test_equal "Existing file adds suffix." "$expected_output" "$output"
    __clean_temp_files

    __create_temp_files
    mkdir -p "$_TEMP_DIR_TEST/existing_dir"
    input="$_TEMP_DIR_TEST/existing_dir"
    expected_output="$_TEMP_DIR_TEST/existing_dir (2)"
    output=$(_get_filename_next_suffix "$input")
    __test_equal "Existing directory adds suffix." "$expected_output" "$output"
    __clean_temp_files
}

__run_make_temp_dir() {
    local temp_dir=""
    local output=""

    temp_dir=$(_make_temp_dir)
    __test_path_exists "Create temporary directory." "true" "$temp_dir"
    output=$(basename -- "$temp_dir")
    __test_equal "Directory is under TEMP_DIR_TASK." \
        "$TEMP_DIR_TASK" "$(dirname -- "$temp_dir")"
    rm -rf -- "$temp_dir"
}

__run_make_temp_dir_local() {
    local temp_dir=""
    local output=""

    __create_temp_files
    temp_dir=$(_make_temp_dir_local "$_TEMP_DIR_TEST" "local_test")
    __test_path_exists "Create local temporary directory." "true" "$temp_dir"
    output=$(basename -- "$temp_dir")
    __test_equal "Directory uses custom prefix." "local_test." \
        "${output:0:11}"
    rm -rf -- "$temp_dir"
    __clean_temp_files
}

__run_make_temp_file() {
    local temp_file=""

    temp_file=$(_make_temp_file)
    __test_path_exists "Create temporary file." "true" "$temp_file"
    __test_equal "File is under TEMP_DIR_TASK." \
        "$TEMP_DIR_TASK" "$(dirname -- "$temp_file")"
    rm -f -- "$temp_file"
}

__run_is_directory_empty() {
    local empty_dir="$_TEMP_DIR/empty_dir"
    local non_empty_dir="$_TEMP_DIR/non_empty_dir"

    mkdir -p "$empty_dir" "$non_empty_dir"
    printf "x" >"$non_empty_dir/file"

    __test_exit_code "Empty directory returns 0." 0 _is_directory_empty "$empty_dir"
    __test_exit_code "Non-empty directory returns 1." 1 \
        _is_directory_empty "$non_empty_dir"

    rm -rf -- "$empty_dir" "$non_empty_dir"
}

__run_convert_delimited_string_to_text() {
    local input=""
    local expected_output=""
    local output=""

    input=""
    expected_output=""
    output=$(_convert_delimited_string_to_text "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="a${FIELD_SEPARATOR}b${FIELD_SEPARATOR}c"
    expected_output="a"$'\n'"b"$'\n'"c"
    output=$(_convert_delimited_string_to_text "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="only"
    expected_output="only"
    output=$(_convert_delimited_string_to_text "$input")
    __test_equal "$input" "$expected_output" "$output"
}

__run_convert_text_to_delimited_string() {
    local input=""
    local expected_output=""
    local output=""

    input=""
    expected_output=""
    output=$(_convert_text_to_delimited_string "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="a"$'\n'"b"$'\n'"c"
    expected_output="a${FIELD_SEPARATOR}b${FIELD_SEPARATOR}c"
    output=$(_convert_text_to_delimited_string "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="only"
    expected_output="only"
    output=$(_convert_text_to_delimited_string "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="a${FIELD_SEPARATOR}${FIELD_SEPARATOR}b"
    expected_output="a${FIELD_SEPARATOR}b"
    output=$(_convert_text_to_delimited_string "$input")
    __test_equal "Collapse duplicate separators." "$expected_output" "$output"
}

__run_get_element() {
    local input=""
    local expected_output=""
    local output=""

    input="a${FIELD_SEPARATOR}b${FIELD_SEPARATOR}c"
    expected_output="a"
    output=$(_get_element "$input" "1")
    __test_equal "First element." "$expected_output" "$output"

    expected_output="b"
    output=$(_get_element "$input" "2")
    __test_equal "Second element." "$expected_output" "$output"

    expected_output="c"
    output=$(_get_element "$input" "3")
    __test_equal "Third element." "$expected_output" "$output"

    expected_output=""
    output=$(_get_element "$input" "4")
    __test_equal "Missing element." "$expected_output" "$output"

    expected_output="single"
    output=$(_get_element "single" "1")
    __test_equal "Single element." "$expected_output" "$output"
}

__run_text_uri_decode() {
    local input=""
    local expected_output=""
    local output=""

    input="file:///home/user%20name/file%20name.txt"
    expected_output="/home/user name/file name.txt"
    output=$(_text_uri_decode "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="file:///tmp/test.txt"
    expected_output="/tmp/test.txt"
    output=$(_text_uri_decode "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="/plain/path"
    expected_output="/plain/path"
    output=$(_text_uri_decode "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="file:///tmp/50%25.pdf"
    expected_output="/tmp/50%.pdf"
    output=$(_text_uri_decode "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="file:///tmp/100%25%20complete.txt"
    expected_output="/tmp/100% complete.txt"
    output=$(_text_uri_decode "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="file:///tmp/report%25s.txt"
    expected_output="/tmp/report%s.txt"
    output=$(_text_uri_decode "$input")
    __test_equal "$input" "$expected_output" "$output"
}

__run_text_remove_pwd() {
    local input=""
    local expected_output=""
    local output=""
    local saved_input_files=""

    __create_temp_files
    saved_input_files=$INPUT_FILES
    INPUT_FILES="$_TEMP_FILE1"

    input="$_TEMP_FILE1"
    expected_output="file1"
    output=$(_text_remove_pwd "$input")
    __test_equal "Replace working directory prefix." "$expected_output" "$output"

    input="/other/path/file.txt"
    expected_output="/other/path/file.txt"
    output=$(_text_remove_pwd "$input")
    __test_equal "Unrelated path unchanged." "$expected_output" "$output"

    INPUT_FILES=$saved_input_files
    __clean_temp_files
}

__run_str_human_readable_path() {
    local input=""
    local expected_output=""
    local output=""
    local saved_input_files=""

    __create_temp_files
    saved_input_files=$INPUT_FILES
    INPUT_FILES="$_TEMP_FILE1"

    input="$_TEMP_FILE1"
    expected_output="file1"
    output=$(_str_human_readable_path "$input")
    __test_equal "Relative path in working directory." "$expected_output" "$output"

    if [[ -n "${HOME:-}" ]]; then
        input="$HOME/Documents/file.txt"
        # shellcheck disable=SC2088
        expected_output="~/Documents/file.txt"
        output=$(_str_human_readable_path "$input")
        __test_equal "Home directory shortened." "$expected_output" "$output"
    fi

    INPUT_FILES=$saved_input_files
    __clean_temp_files
}

__run_translate_to_gvfs_path() {
    local input=""
    local expected_output=""
    local output=""
    local uid=""

    uid=$(id -u)

    input="sftp://host.example/path/to/file"
    expected_output="/run/user/${uid}/gvfs/sftp:host=host.example/path/to/file"
    output=$(_translate_to_gvfs_path "$input")
    __test_equal "SFTP URI." "$expected_output" "$output"

    input="smb://server/share/folder/file"
    expected_output="/run/user/${uid}/gvfs/smb-share:server=server,share=share/folder/file"
    output=$(_translate_to_gvfs_path "$input")
    __test_equal "SMB URI." "$expected_output" "$output"

    input="smb://server/share"
    expected_output="/run/user/${uid}/gvfs/smb-share:server=server,share=share"
    output=$(_translate_to_gvfs_path "$input")
    __test_equal "SMB URI without path." "$expected_output" "$output"

    input="sftp://host.example/tmp/50%25.pdf"
    expected_output="/run/user/${uid}/gvfs/sftp:host=host.example/tmp/50%.pdf"
    output=$(_translate_to_gvfs_path "$input")
    __test_equal "SFTP URI with percent in filename." "$expected_output" "$output"
}

__run_command_exists() {
    __test_exit_code "Existing command 'bash'." 0 _command_exists "bash"
    __test_exit_code "Existing command 'test'." 0 _command_exists "test"
    __test_exit_code "Non-existent command." 1 \
        _command_exists "__nonexistent_command_xyz__"
}

__run_check_output() {
    local temp_output="$_TEMP_DIR/check_output.txt"

    rm -f -- "$TEMP_DIR_LOGS/"* 2>/dev/null
    __create_temp_files
    printf "content" >"$temp_output"

    __test_exit_code "Success with existing output file." 0 \
        _check_output "0" "" "$_TEMP_FILE1" "$temp_output"

    __test_exit_code "Failure on non-zero exit code." 1 \
        _check_output "1" "error output" "$_TEMP_FILE1" "$temp_output"

    __test_exit_code "Failure when output file is missing." 1 \
        _check_output "0" "" "$_TEMP_FILE1" "$_TEMP_DIR/missing.txt"

    __test_exit_code "Success without output file check." 0 \
        _check_output "0" "" "$_TEMP_FILE1" ""

    rm -f -- "$TEMP_DIR_LOGS/"* 2>/dev/null
    __clean_temp_files
}

__run_find_filtered_files() {
    local input=""
    local expected_output=""
    local output=""
    local txt_file=""
    local pdf_file=""

    __create_temp_files
    txt_file="$_TEMP_DIR_TEST/file.txt"
    pdf_file="$_TEMP_DIR_TEST/file.pdf"
    printf "text" >"$txt_file"
    printf "pdf" >"$pdf_file"
    mkdir -p "$_TEMP_DIR_TEST/subdir"
    printf "nested" >"$_TEMP_DIR_TEST/subdir/nested.txt"

    input="$_TEMP_DIR_TEST"
    output=$(_find_filtered_files "$input" "file" "txt" "" "")
    __test_equal "Filter by txt extension." "true" \
        "$(grep --quiet "$txt_file" <<<"$output" && echo true || echo false)"
    __test_equal "Exclude pdf when selecting txt." "false" \
        "$(grep --quiet "$pdf_file" <<<"$output" && echo true || echo false)"

    output=$(_find_filtered_files "$input" "file" "" "pdf" "")
    __test_equal "Skip pdf extension." "true" \
        "$(grep --quiet "$txt_file" <<<"$output" && echo true || echo false)"
    __test_equal "Skipped pdf file." "false" \
        "$(grep --quiet "$pdf_file" <<<"$output" && echo true || echo false)"

    output=$(_find_filtered_files "$input" "directory" "" "" "")
    __test_equal "Find directories." "true" \
        "$(grep --quiet "$_TEMP_DIR_TEST/subdir" <<<"$output" && echo true || echo false)"

    __clean_temp_files
}

__run_directory_push_pop() {
    local original_dir=""
    local output=""

    __create_temp_files
    original_dir=$(pwd)

    __test_exit_code "Push valid directory." 0 _directory_push "$_TEMP_DIR_TEST"
    output=$(pwd)
    __test_equal "Current directory after push." "$_TEMP_DIR_TEST" "$output"

    __test_exit_code "Pop directory." 0 _directory_pop
    output=$(pwd)
    __test_equal "Current directory after pop." "$original_dir" "$output"

    __test_exit_code "Push invalid directory." 1 \
        _directory_push "$_TEMP_DIR/nonexistent_dir"

    __clean_temp_files
}

__run_get_output_filename() {
    local input_file=""
    local output_dir=""
    local expected_output=""
    local output=""

    __create_temp_files
    output_dir="$_TEMP_DIR_TEST/output"
    mkdir -p "$output_dir"
    input_file="$_TEMP_DIR_TEST/document.pdf"

    expected_output="$output_dir/document.pdf"
    output=$(_get_output_filename "$input_file" "$output_dir" \
        'par_extension_opt="preserve"')
    __test_equal "Preserve extension." "$expected_output" "$output"

    expected_output="$output_dir/document"
    output=$(_get_output_filename "$input_file" "$output_dir" \
        'par_extension_opt="strip"')
    __test_equal "Strip extension." "$expected_output" "$output"

    expected_output="$output_dir/document.txt"
    output=$(_get_output_filename "$input_file" "$output_dir" \
        'par_extension_opt="replace"; par_extension="txt"')
    __test_equal "Replace extension." "$expected_output" "$output"

    expected_output="$output_dir/document.pdf.zip"
    output=$(_get_output_filename "$input_file" "$output_dir" \
        'par_extension_opt="append"; par_extension="zip"')
    __test_equal "Append extension." "$expected_output" "$output"

    expected_output="$output_dir/prefix document backup.pdf"
    output=$(_get_output_filename "$input_file" "$output_dir" \
        'par_extension_opt="preserve"; par_prefix="prefix"; par_suffix="backup"')
    __test_equal "Prefix and suffix." "$expected_output" "$output"

    expected_output="$output_dir/new_subdir"
    output=$(_get_output_filename "$output_dir/new_subdir" "$output_dir" \
        'par_extension_opt="strip"')
    __test_equal "Directory input." "$expected_output" "$output"

    __clean_temp_files
}

__run_get_file_mime() {
    local expected_output=""
    local output=""

    __create_temp_files
    output=$(_get_file_mime "$_TEMP_FILE1")
    __test_equal "MIME type is not empty." "false" "$([[ -z "$output" ]] && echo true || echo false)"
    __test_equal "MIME type contains text." "true" \
        "$(grep --quiet "text" <<<"$output" && echo true || echo false)"

    output=$(_get_file_mime "$_TEMP_DIR/nonexistent_file")
    expected_output=""
    __test_equal "Non-existent file returns empty." "$expected_output" "$output"

    __clean_temp_files
}

__run_get_file_encoding() {
    local expected_output=""
    local output=""

    __create_temp_files
    output=$(_get_file_encoding "$_TEMP_FILE1")
    __test_equal "Encoding is not empty." "false" \
        "$([[ -z "$output" ]] && echo true || echo false)"

    output=$(_get_file_encoding "$_TEMP_DIR/nonexistent_file")
    expected_output=""
    __test_equal "Non-existent file returns empty." "$expected_output" "$output"

    __clean_temp_files
}

__run_validate_file_mime() {
    local output=""

    _storage_text_clean
    __create_temp_files

    _validate_file_mime "$_TEMP_FILE1" "text/" ""
    output=$(_storage_text_read_all)
    _storage_text_clean
    __test_equal "Valid text file passes MIME check." "true" \
        "$(grep --quiet "$_TEMP_FILE1" <<<"$output" && echo true || echo false)"

    _validate_file_mime "$_TEMP_FILE1" "image/" ""
    output=$(_storage_text_read_all)
    _storage_text_clean
    __test_equal "Invalid MIME type is rejected." "" "$output"

    __clean_temp_files
}

__run_deps_get_dependency_value() {
    local expected_output=""
    local output=""

    output=$(_deps_get_dependency_value "7za" "apt-get" "PKG_MAP")
    expected_output="p7zip"
    __test_equal "Resolve apt-get package for 7za." "$expected_output" "$output"

    output=$(_deps_get_dependency_value "7za" "brew" "PKG_MAP")
    expected_output="p7zip"
    __test_equal "Resolve brew package for 7za." "$expected_output" "$output"

    output=$(_deps_get_dependency_value "nonexistent_key_xyz" "apt-get" "PKG_MAP")
    expected_output=""
    __test_equal "Unknown key returns empty." "$expected_output" "$output"

    __test_exit_code "Unknown package manager returns 1." 1 \
        _deps_get_dependency_value "7za" "unknown-pm" "PKG_MAP"
}

__run_i18n() {
    local expected_output=""
    local output=""
    local po_file="$_TEMP_DIR/test.po"
    declare -A saved_i18n_data=()

    # Backup and reset I18N_DATA.
    local key=""
    for key in "${!I18N_DATA[@]}"; do
        saved_i18n_data["$key"]="${I18N_DATA[$key]}"
    done
    I18N_DATA=()

    cat >"$po_file" <<'EOF'
msgid "Hello"
msgstr "Olá"

msgid "World"
msgstr "Mundo"

EOF

    _i18n_load_file "$po_file"

    expected_output="Olá"
    output=$(_i18n "Hello")
    __test_equal "Translated string." "$expected_output" "$output"

    expected_output="Untranslated"
    output=$(_i18n "Untranslated")
    __test_equal "Fallback to original." "$expected_output" "$output"

    expected_output=""
    output=$(_i18n "")
    __test_equal "Empty msgid." "$expected_output" "$output"

    # Restore I18N_DATA.
    I18N_DATA=()
    for key in "${!saved_i18n_data[@]}"; do
        I18N_DATA["$key"]="${saved_i18n_data[$key]}"
    done
}

__run_get_max_procs() {
    local output=""
    local expected_min=1
    local result="false"

    output=$(_get_max_procs)
    ((output >= expected_min)) && result="true"
    __test_equal "Returns a positive integer." "true" "$result"
}

__run_logs_consolidate() {
    rm -f -- "$TEMP_DIR_LOGS/"* 2>/dev/null
    __test_exit_code "No logs to consolidate." 0 _logs_consolidate ""
}

__run_get_working_directory() {
    local expected_output=""
    local output=""
    local saved_input_files=""
    local saved_current_uri="${NAUTILUS_SCRIPT_CURRENT_URI:-}"

    saved_input_files=$INPUT_FILES

    __create_temp_files
    INPUT_FILES="$_TEMP_FILE1"
    expected_output=$(dirname -- "$_TEMP_FILE1")
    expected_output=$(cd -- "$expected_output" &>/dev/null && pwd)
    output=$(_get_working_directory)
    __test_equal "Working dir from first input file." "$expected_output" "$output"
    __clean_temp_files

    INPUT_FILES=""
    unset "NAUTILUS_SCRIPT_CURRENT_URI"
    output=$(_get_working_directory)
    __test_equal "Empty input files returns empty." "" "$output"

    NAUTILUS_SCRIPT_CURRENT_URI="file:///tmp/test%20dir"
    expected_output="/tmp/test dir"
    output=$(_get_working_directory)
    __test_equal "Decode file:// URI." "$expected_output" "$output"

    NAUTILUS_SCRIPT_CURRENT_URI="recent:///"
    output=$(_get_working_directory)
    __test_equal "Virtual recent:// URI returns empty." "" "$output"

    INPUT_FILES=$saved_input_files
    if [[ -n "$saved_current_uri" ]]; then
        NAUTILUS_SCRIPT_CURRENT_URI=$saved_current_uri
    else
        unset "NAUTILUS_SCRIPT_CURRENT_URI"
    fi
}

__run_storage_text_edge_cases() {
    local output=""
    local file_count=0

    _storage_text_clean
    _storage_text_write ""
    _storage_text_write $'\n'
    file_count=$(find "$TEMP_DIR_STORAGE_TEXT" -type f 2>/dev/null | wc -l)
    __test_equal "Empty write creates no files." "0" "$file_count"

    _storage_text_write_ln ""
    file_count=$(find "$TEMP_DIR_STORAGE_TEXT" -type f 2>/dev/null | wc -l)
    __test_equal "Empty write_ln creates no files." "0" "$file_count"

    _storage_text_write "alpha"
    _storage_text_clean
    output=$(_storage_text_read_all)
    __test_equal "Clean removes stored text." "" "$output"
}

__parallel_test_task() {
    _storage_text_write "$1"
}

__run_validate_file_mime_parallel() {
    local output=""

    _storage_text_clean
    __create_temp_files

    output=$(_validate_file_mime_parallel \
        "$_TEMP_FILE1${FIELD_SEPARATOR}$_TEMP_FILE2" "text/" "")
    _storage_text_clean

    __test_equal "Parallel MIME validation keeps text files." "2" \
        "$(_get_items_count "$output")"
    __test_equal "First file is valid." "true" \
        "$(grep --quiet "$_TEMP_FILE1" <<<"$output" && echo true || echo false)"
    __test_equal "Second file is valid." "true" \
        "$(grep --quiet "$_TEMP_FILE2" <<<"$output" && echo true || echo false)"

    _storage_text_clean
    output=$(_validate_file_mime_parallel \
        "$_TEMP_FILE1${FIELD_SEPARATOR}$_TEMP_FILE2" "image/" "")
    _storage_text_clean
    __test_equal "Parallel MIME validation rejects non-images." "" "$output"

    __clean_temp_files
}

__run_run_function_parallel() {
    local output=""

    _storage_text_clean
    export -f __parallel_test_task _storage_text_write
    _run_function_parallel "__parallel_test_task '{}'" \
        "alpha${FIELD_SEPARATOR}beta" "$FIELD_SEPARATOR" "2"
    output=$(_storage_text_read_all)
    _storage_text_clean

    __test_equal "Parallel task writes first item." "true" \
        "$(grep --quiet "alpha" <<<"$output" && echo true || echo false)"
    __test_equal "Parallel task writes second item." "true" \
        "$(grep --quiet "beta" <<<"$output" && echo true || echo false)"
}

__run_move_file_errors() {
    __test_exit_code "Missing source and destination." 1 _move_file "skip" "" ""
    __test_exit_code "Non-existent source file." 1 \
        _move_file "skip" "$_TEMP_DIR/missing_src" "$_TEMP_DIR/missing_dst"

    __create_temp_files
    cp -- "$_TEMP_FILE1" "$_TEMP_FILE2"
    __test_exit_code "Safe overwrite with identical files." 1 \
        _move_file "safe_overwrite" "$_TEMP_FILE1" "$_TEMP_FILE2"
    : >"$_TEMP_FILE1"
    __test_exit_code "Safe overwrite with zero-byte source." 1 \
        _move_file "safe_overwrite" "$_TEMP_FILE1" "$_TEMP_FILE2"
    __clean_temp_files
}

__run_i18n_initialize() {
    local expected_output=""
    local output=""
    declare -A saved_i18n_data=()
    local saved_lang="${LANG:-}"
    local key=""

    for key in "${!I18N_DATA[@]}"; do
        saved_i18n_data["$key"]="${I18N_DATA[$key]}"
    done

    I18N_DATA=()
    LANG="pt_BR.UTF-8"
    _i18n_initialize

    output=$(_i18n "Done!")
    expected_output="Concluído!"
    __test_equal "Load translation from locale file." "$expected_output" "$output"

    I18N_DATA=()
    LANG="xx_YY.UTF-8"
    _i18n_initialize
    output=$(_i18n "Done!")
    expected_output="Done!"
    __test_equal "Unknown locale falls back to msgid." "$expected_output" "$output"

    I18N_DATA=()
    unset "LANG"
    _i18n_initialize
    output=$(_i18n "Done!")
    expected_output="Done!"
    __test_equal "Unset LANG keeps msgid." "$expected_output" "$output"

    I18N_DATA=()
    for key in "${!saved_i18n_data[@]}"; do
        I18N_DATA["$key"]="${saved_i18n_data[$key]}"
    done
    if [[ -n "$saved_lang" ]]; then
        LANG=$saved_lang
    else
        unset "LANG"
    fi
}

#endregion

_main "$@"
