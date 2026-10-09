#!/usr/bin/env bash

# Source the file '.common-functions.sh'.
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
ROOT_DIR=$(grep --only-matching "^.*scripts[^/]*" <<<"$SCRIPT_DIR")
source "$ROOT_DIR/.common-functions.sh"

# Test all functions defined in the script '.common-functions.sh'.

set -u

# -----------------------------------------------------------------------------
# SECTION: Constants
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
# SECTION: Global variables
# -----------------------------------------------------------------------------

_TOTAL_TESTS=0
_TOTAL_FAILED=0

# -----------------------------------------------------------------------------
# SECTION: Functions
# -----------------------------------------------------------------------------

_main() {
    printf "Running the unit tests...\n"

    __run_source_common_functions

    __run_add_path_env
    __run_check_output
    __run_command_exists
    __run_convert_delimited_string_to_text
    __run_convert_text_to_delimited_string
    __run_deps_get_dependency_value
    __run_directory_push_pop
    __run_escape_single_quotes
    __run_find_filtered_files
    __run_get_available_app
    __run_get_dirname
    __run_get_element
    __run_get_file_encoding
    __run_get_file_mime
    __run_get_filename_extension
    __run_get_filename_full_path
    __run_get_filename_next_suffix
    __run_get_filenames_filemanager
    __run_get_files
    __run_get_items_count
    __run_get_max_procs
    __run_get_output_dir
    __run_get_output_filename
    __run_get_script_name
    __run_get_session_type
    __run_get_working_directory
    __run_i18n
    __run_i18n_initialize
    __run_is_directory_empty
    __run_log_error
    __run_logs_consolidate
    __run_make_temp_dir
    __run_make_temp_dir_local
    __run_make_temp_file
    __run_move_file
    __run_move_file_errors
    __run_run_function_parallel
    __run_run_task_parallel
    __run_session_environment
    __run_storage_text
    __run_storage_text_edge_cases
    __run_str_collapse_char
    __run_str_human_readable_path
    __run_str_sort
    __run_strip_filename_extension
    __run_text_remove_empty_lines
    __run_text_remove_pwd
    __run_text_sort
    __run_text_uri_decode
    __run_translate_to_gvfs_path
    __run_validate_file_mime
    __run_validate_file_mime_parallel
    __run_validate_files_count

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

__save_script_env() {
    local dest=$1
    local var=""

    : >"$dest"
    while IFS= read -r var; do
        declare -p "$var" >>"$dest"
    done < <(compgen -v | grep "_SCRIPT_" || true)
}

__restore_script_env() {
    local dest=$1
    local var=""

    while IFS= read -r var; do
        unset "$var"
    done < <(compgen -v | grep "_SCRIPT_" || true)

    if [[ -s "$dest" ]]; then
        # shellcheck disable=SC1090
        source "$dest"
    fi
}

__invoke_guarded() {
    local message_file=$1
    shift

    (
        # Overridden only for this subshell; ShellCheck cannot see the calls.
        # shellcheck disable=SC2317
        _display_error_box() {
            printf "%s" "$1" >"$message_file"
        }
        # shellcheck disable=SC2317
        _exit_script() {
            exit 2
        }
        "$@"
    )
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

    input="Archive.TAR.GZ"
    expected_output=".TAR.GZ"
    output=$(_get_filename_extension "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="File.a_b-c"
    expected_output=".a_b-c"
    output=$(_get_filename_extension "$input")
    __test_equal "$input" "$expected_output" "$output"

    input="File."
    expected_output="."
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

    rm -f -- "$TEMP_DIR_LOGS/"* 2>/dev/null
    _log_error "message" "input_file" "std_output" "output_file"
    output=$(cat -- "$TEMP_DIR_LOGS/"* 2>/dev/null | tail -n +2)
    expected_output=" > Input file: input_file"$'\n'" > Output file: output_file"$'\n'" > Error: message"$'\n'" > Standard output:"$'\n'"std_output"

    __test_equal "Check the log error content." "$expected_output" "$output"

    rm -f -- "$TEMP_DIR_LOGS/"* 2>/dev/null
    _log_error "only message" "" "" ""
    output=$(cat -- "$TEMP_DIR_LOGS/"* 2>/dev/null | tail -n +2)
    expected_output=" > Error: only message"
    __test_equal "Omit empty log fields." "$expected_output" "$output"
    rm -f -- "$TEMP_DIR_LOGS/"* 2>/dev/null
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

    __create_temp_files
    _move_file "skip" "$_TEMP_FILE1" "$_TEMP_DIR_TEST/moved"
    expected_output=$_TEMP_FILE1_CONTENT
    output=$(<"$_TEMP_DIR_TEST/moved")
    __test_equal "skip moves when destination is free." "$expected_output" "$output"
    __test_path_exists "Source removed after skip move." "false" "$_TEMP_FILE1"
    __clean_temp_files

    __create_temp_files
    _move_file "rename" "$_TEMP_FILE1" "$_TEMP_DIR_TEST/renamed.txt"
    expected_output=$_TEMP_FILE1_CONTENT
    output=$(<"$_TEMP_DIR_TEST/renamed.txt")
    __test_equal "rename to a new name." "$expected_output" "$output"
    __test_path_exists "Source removed after rename." "false" "$_TEMP_FILE1"
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

    input="10"$'\r'"2"$'\r'"2"
    expected_output="2"$'\r'"2"$'\r'"10"
    output=$(_str_sort "$input" "\r" "false")
    __test_equal "Keep duplicates." "$expected_output" "$output"
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

    input="1.10"$'\n'"1.2"
    expected_output="1.2"$'\n'"1.10"
    output=$(_text_sort "$input")
    __test_equal "Version sort." "$expected_output" "$output"

    input="b"$'\n'"a"$'\n'"a"
    expected_output="a"$'\n'"a"$'\n'"b"
    output=$(_text_sort "$input")
    __test_equal "Keep duplicate lines." "$expected_output" "$output"
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

    input="a${FIELD_SEPARATOR}"
    expected_output=2
    output=$(_get_items_count "$input")
    __test_equal "Trailing separator counts as an item." "$expected_output" "$output"
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

    __create_temp_files
    printf "x" >"$_TEMP_DIR_TEST/doc.txt"
    printf "x" >"$_TEMP_DIR_TEST/doc (2).txt"
    input="$_TEMP_DIR_TEST/doc.txt"
    expected_output="$_TEMP_DIR_TEST/doc (3).txt"
    output=$(_get_filename_next_suffix "$input")
    __test_equal "Occupied suffix advances to the next free name." \
        "$expected_output" "$output"
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
    output=$(cat -- "$TEMP_DIR_ITEMS_TO_REMOVE/"* 2>/dev/null)
    __test_equal "Directory is scheduled for removal." "true" \
        "$(grep --quiet --fixed-strings "$temp_dir" <<<"$output" &&
            echo true || echo false)"
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

    printf "x" >"$empty_dir/.hidden"
    __test_exit_code "Hidden file makes the directory non-empty." 1 \
        _is_directory_empty "$empty_dir"
    __test_exit_code "Missing directory is treated as empty." 0 \
        _is_directory_empty "$_TEMP_DIR/missing_dir"

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

    input="a"$'\n'"b${FIELD_SEPARATOR}c"
    expected_output="a'\$'\\n''b"$'\n'"c"
    output=$(_convert_delimited_string_to_text "$input")
    __test_equal "Newline inside an item is escaped." "$expected_output" "$output"
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

    input="a"$'\n'$'\n'"b"$'\n'
    expected_output="a${FIELD_SEPARATOR}b"
    output=$(_convert_text_to_delimited_string "$input")
    __test_equal "Collapse blank lines and a trailing newline." \
        "$expected_output" "$output"
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

    expected_output=""
    output=$(_get_element "a${FIELD_SEPARATOR}${FIELD_SEPARATOR}c" "2")
    __test_equal "Empty field." "$expected_output" "$output"
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

    input=""
    expected_output=""
    output=$(_text_uri_decode "$input")
    __test_equal "Empty URI." "$expected_output" "$output"

    input="file://"
    expected_output=""
    output=$(_text_uri_decode "$input")
    __test_equal "file:// without a path." "$expected_output" "$output"
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

    input="${_TEMP_DIR_TEST}/a ${_TEMP_DIR_TEST}/b"
    expected_output="a b"
    output=$(_text_remove_pwd "$input")
    __test_equal "Replace every working directory prefix." \
        "$expected_output" "$output"

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

    if [[ -n "$HOME" ]]; then
        input="$HOME/Documents/file.txt"
        # shellcheck disable=SC2088
        expected_output="~/Documents/file.txt"
        output=$(_str_human_readable_path "$input")
        __test_equal "Home directory shortened." "$expected_output" "$output"

        input="$HOME"
        expected_output="$HOME"
        output=$(_str_human_readable_path "$input")
        __test_equal "Bare home directory stays absolute." \
            "$expected_output" "$output"
    fi

    input="./file.txt"
    expected_output="file.txt"
    output=$(_str_human_readable_path "$input")
    __test_equal "Leading dot slash is removed." "$expected_output" "$output"

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

    input="ftp://host.example/pub/file"
    expected_output="/run/user/${uid}/gvfs/ftp:host=host.example/pub/file"
    output=$(_translate_to_gvfs_path "$input")
    __test_equal "FTP URI." "$expected_output" "$output"

    input="sftp://host.example"
    expected_output="/run/user/${uid}/gvfs/sftp:host=host.example"
    output=$(_translate_to_gvfs_path "$input")
    __test_equal "Host without a path." "$expected_output" "$output"
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

    printf "upper" >"$_TEMP_DIR_TEST/File.TXT"
    ln -s -- "$txt_file" "$_TEMP_DIR_TEST/link.txt"
    mkdir -p "$_TEMP_DIR_TEST/.git"
    printf "git" >"$_TEMP_DIR_TEST/.git/config"

    output=$(_find_filtered_files "$input" "file" "txt" "" "-maxdepth 1")
    __test_equal "Extension match is case-insensitive." "true" \
        "$(grep --quiet "$_TEMP_DIR_TEST/File.TXT" <<<"$output" && echo true || echo false)"
    __test_equal "Symlink is included for files." "true" \
        "$(grep --quiet "$_TEMP_DIR_TEST/link.txt" <<<"$output" && echo true || echo false)"
    __test_equal "Max depth skips nested files." "false" \
        "$(grep --quiet "$_TEMP_DIR_TEST/subdir/nested.txt" <<<"$output" &&
            echo true || echo false)"

    output=$(_find_filtered_files "$input" "file" "" "" "")
    __test_equal "Paths inside .git are ignored." "false" \
        "$(grep --quiet "$_TEMP_DIR_TEST/.git/config" <<<"$output" &&
            echo true || echo false)"

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

    __test_exit_code "Pop empty directory stack." 1 __pop_empty_stack

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

    mkdir -p "$_TEMP_DIR_TEST/incoming"
    expected_output="$output_dir/incoming"
    output=$(_get_output_filename "$_TEMP_DIR_TEST/incoming" "$output_dir" \
        'par_extension_opt="strip"')
    __test_equal "Directory input." "$expected_output" "$output"

    mkdir -p "$output_dir/new_subdir"
    expected_output="$output_dir/new_subdir (2)"
    output=$(_get_output_filename "$output_dir/new_subdir" "$output_dir" \
        'par_extension_opt="strip"')
    __test_equal "Existing directory gets the next suffix." \
        "$expected_output" "$output"

    expected_output="$output_dir/new_subdir.zip"
    output=$(_get_output_filename "$output_dir/new_subdir" "$output_dir" \
        'par_extension_opt="append"; par_extension="zip"')
    __test_equal "Append extension to a directory." "$expected_output" "$output"

    expected_output="$output_dir/document backup"
    output=$(_get_output_filename "$input_file" "$output_dir" \
        'par_extension_opt="strip"; par_suffix="backup"')
    __test_equal "Suffix with the extension stripped." "$expected_output" "$output"

    touch -- "$output_dir/document.pdf"
    expected_output="$output_dir/document (2).pdf"
    output=$(_get_output_filename "$input_file" "$output_dir" \
        'par_extension_opt="preserve"')
    __test_equal "Existing output file gets the next suffix." \
        "$expected_output" "$output"

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

    output=$(_get_file_mime "$_TEMP_DIR_TEST")
    expected_output="inode/directory"
    __test_equal "Directory MIME type." "$expected_output" "$output"

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

    _validate_file_mime "$_TEMP_FILE1" "text+plain" ""
    output=$(_storage_text_read_all)
    _storage_text_clean
    __test_equal "Plus in a MIME pattern is literal." "" "$output"

    _validate_file_mime "$_TEMP_FILE1" "" "us-ascii"
    output=$(_storage_text_read_all)
    _storage_text_clean
    __test_equal "Matching skip encoding is rejected." "" "$output"

    _validate_file_mime "$_TEMP_FILE1" "" "image/"
    output=$(_storage_text_read_all)
    _storage_text_clean
    __test_equal "Unmatched skip encoding is accepted." "true" \
        "$(grep --quiet "$_TEMP_FILE1" <<<"$output" && echo true || echo false)"

    _validate_file_mime "$_TEMP_FILE1" "" ""
    output=$(_storage_text_read_all)
    _storage_text_clean
    __test_equal "Empty patterns accept the file." "true" \
        "$(grep --quiet "$_TEMP_FILE1" <<<"$output" && echo true || echo false)"

    __clean_temp_files
}

__run_deps_get_dependency_value() {
    local expected_output=""
    local output=""

    output=$(_deps_get_dependency_value "dig" "dnf" "PKG_MAP")
    expected_output="bind-utils"
    __test_equal "Resolve dnf package for 'dig'." "$expected_output" "$output"

    output=$(_deps_get_dependency_value "dig" "pkgx" "PKG_MAP")
    expected_output="isc.org/bind9"
    __test_equal "Resolve pkgx package for 'dig'." "$expected_output" "$output"

    output=$(_deps_get_dependency_value "nonexistent_key_xyz" "dnf" "PKG_MAP")
    expected_output=""
    __test_equal "Unknown key returns empty." "$expected_output" "$output"

    __test_exit_code "Unknown key returns 0." 0 \
        _deps_get_dependency_value "nonexistent_key_xyz" "dnf" "PKG_MAP"

    output=$(_deps_get_dependency_value "dig" "nix-env" "PKG_MAP")
    expected_output="dnsutils"
    __test_equal "Map nix to nix-env." "$expected_output" "$output"

    output=$(_deps_get_dependency_value "dig" "xbps-install" "PKG_MAP")
    expected_output="bind"
    __test_equal "Map xbps to xbps-install." "$expected_output" "$output"

    output=$(_deps_get_dependency_value "clamav" "dnf" "POST_INSTALL")
    expected_output='rm -f /var/log/clamav/freshclam.log; sed -i "/^NotifyClamd/d" /etc/clamav/freshclam.conf 2>/dev/null; freshclam --quiet'
    __test_equal "Wildcard package manager in POST_INSTALL." \
        "$expected_output" "$output"
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

    cat >"$po_file" <<'EOF'
# comment
msgid "Keep"
msgstr "Sim"

msgid "Drop"
msgstr ""

msgid "Last"
msgstr "Fim"

EOF
    I18N_DATA=()
    _i18n_load_file "$po_file"

    expected_output="Sim"
    output=$(_i18n "Keep")
    __test_equal "Ignore comments." "$expected_output" "$output"

    expected_output="Drop"
    output=$(_i18n "Drop")
    __test_equal "Empty msgstr is ignored." "$expected_output" "$output"

    expected_output="Fim"
    output=$(_i18n "Last")
    __test_equal "Entry after an empty msgstr." "$expected_output" "$output"

    output=$(
        unset I18N_READY
        _i18n "Done!"
    )
    expected_output="Done!"
    __test_equal "Missing I18N_READY returns the msgid." "$expected_output" "$output"

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
    local saved_script_env="$_TEMP_DIR/working_directory_env.sh"

    saved_input_files=$INPUT_FILES
    __save_script_env "$saved_script_env"
    _unset_global_variables_file_manager

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

    NAUTILUS_SCRIPT_CURRENT_URI="trash:///"
    output=$(_get_working_directory)
    __test_equal "Virtual trash:// URI returns empty." "" "$output"

    NAUTILUS_SCRIPT_CURRENT_URI="x-nautilus-search:///query"
    output=$(_get_working_directory)
    __test_equal "Search URI returns empty." "" "$output"

    NAUTILUS_SCRIPT_CURRENT_URI="sftp://host.example/remote/dir"
    expected_output="/run/user/$(id -u)/gvfs/sftp:host=host.example/remote/dir"
    output=$(_get_working_directory)
    __test_equal "Translate a remote current URI." "$expected_output" "$output"

    unset "NAUTILUS_SCRIPT_CURRENT_URI"
    # Read indirectly by '_get_working_directory'.
    # shellcheck disable=SC2034
    NEMO_SCRIPT_CURRENT_URI="file:///tmp/nemo%20dir"
    expected_output="/tmp/nemo dir"
    output=$(_get_working_directory)
    __test_equal "Nemo current URI is decoded." "$expected_output" "$output"

    INPUT_FILES=$saved_input_files
    __restore_script_env "$saved_script_env"
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

    _storage_text_clean
    _storage_text_write "a"
    _storage_text_write "ccc"
    output=$(_storage_text_read_all)
    _storage_text_clean
    __test_equal "Larger chunks are read first." "ccca" "$output"
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

    _storage_text_clean
    _run_function_parallel "__parallel_test_task '{}'" "" "$FIELD_SEPARATOR" "1"
    output=$(_storage_text_read_all)
    _storage_text_clean
    __test_equal "Empty item list runs nothing." "" "$output"
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
    LANG="de_AT.UTF-8"
    _i18n_initialize
    output=$(_i18n "Done!")
    expected_output="Fertig!"
    __test_equal "Unknown region falls back to the base language." \
        "$expected_output" "$output"

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

__run_get_session_type() {
    local output=""

    output=$(XDG_SESSION_TYPE="wayland" _get_session_type)
    __test_equal "Wayland from XDG_SESSION_TYPE." "wayland" "$output"

    output=$(XDG_SESSION_TYPE="x11" _get_session_type)
    __test_equal "X11 from XDG_SESSION_TYPE." "x11" "$output"

    output=$(XDG_SESSION_TYPE="" WAYLAND_DISPLAY="" DISPLAY=":0" _get_session_type)
    __test_equal "X11 fallback from DISPLAY." "x11" "$output"

    output=$(XDG_SESSION_TYPE="" WAYLAND_DISPLAY="wayland-0" DISPLAY="" _get_session_type)
    __test_equal "Wayland fallback from WAYLAND_DISPLAY." "wayland" "$output"

    output=$(XDG_SESSION_TYPE="" WAYLAND_DISPLAY="" DISPLAY="" _get_session_type)
    __test_equal "No display variables returns empty." "" "$output"

    output=$(XDG_SESSION_TYPE="tty" WAYLAND_DISPLAY="wayland-0" DISPLAY=":0" \
        _get_session_type)
    __test_equal "XDG_SESSION_TYPE wins over display variables." "tty" "$output"
}

__pop_empty_stack() {
    (
        dirs -c
        _directory_pop
    )
}

__is_gui_session_with() {
    DISPLAY=$1 WAYLAND_DISPLAY=$2 _is_gui_session
}

__is_qt_desktop_with() {
    XDG_CURRENT_DESKTOP=$1 _is_qt_desktop
}

_main_task() {
    _storage_text_write_ln "$1|$2"
}

__run_escape_single_quotes() {
    local output=""

    output=$(_escape_single_quotes "")
    __test_equal "Empty string." "" "$output"

    output=$(_escape_single_quotes "abc")
    __test_equal "No quotes." "abc" "$output"

    output=$(_escape_single_quotes "it's")
    __test_equal "One quote." "it'\\''s" "$output"

    output=$(_escape_single_quotes "'")
    __test_equal "Quote only." "'\\''" "$output"

    output=$(_escape_single_quotes "a'b'c")
    __test_equal "Several quotes." "a'\\''b'\\''c" "$output"
}

__run_add_path_env() {
    local saved_path=$PATH
    local path_dir="$_TEMP_DIR/binpath"

    mkdir -p "$path_dir"
    __test_exit_code "Add a new directory to PATH." 0 _add_path_env "$path_dir"
    __test_equal "PATH starts with the new directory." "$path_dir" "${PATH%%:*}"
    __test_exit_code "Directory already in PATH." 1 _add_path_env "$path_dir"
    __test_exit_code "Missing directory is rejected." 1 \
        _add_path_env "$_TEMP_DIR/missing_binpath"
    PATH=$saved_path
    rm -rf -- "$path_dir"
}

__run_get_available_app() {
    local output=""
    # Passed by name to '_get_available_app'.
    # shellcheck disable=SC2034
    local apps=("missing_cmd_xyz" "bash")
    # shellcheck disable=SC2034
    local missing=("missing_cmd_a" "missing_cmd_b")

    output=$(_get_available_app "apps")
    __test_equal "Return the first available command." "bash" "$output"
    __test_exit_code "No command from the list exists." 1 \
        _get_available_app "missing"
}

__run_session_environment() {
    local saved_script_env="$_TEMP_DIR/session_env.sh"

    __test_exit_code "DISPLAY marks a GUI session." 0 \
        __is_gui_session_with ":1" ""
    __test_exit_code "WAYLAND_DISPLAY marks a GUI session." 0 \
        __is_gui_session_with "" "wayland-0"
    __test_exit_code "No display is not a GUI session." 1 \
        __is_gui_session_with "" ""

    __test_exit_code "KDE is a Qt desktop." 0 __is_qt_desktop_with "KDE"
    __test_exit_code "LXQt is a Qt desktop." 0 __is_qt_desktop_with "lxqt"
    __test_exit_code "GNOME is not a Qt desktop." 1 __is_qt_desktop_with "GNOME"
    __test_exit_code "Empty desktop is not Qt." 1 __is_qt_desktop_with ""

    __save_script_env "$saved_script_env"
    _unset_global_variables_file_manager
    __test_exit_code "No file manager variables." 1 _is_file_manager_session

    NAUTILUS_SCRIPT_SELECTED_URIS="file:///tmp/a"
    __test_exit_code "Nautilus selection marks a file manager session." 0 \
        _is_file_manager_session

    FOO_SCRIPT_BAR="1"
    __UNIT_TEST_KEEP_VALUE="kept"
    _unset_global_variables_file_manager
    __test_equal "File manager variables are unset." "true" \
        "$([[ -z ${FOO_SCRIPT_BAR:-} && -z ${NAUTILUS_SCRIPT_SELECTED_URIS:-} ]] &&
            echo true || echo false)"
    __test_equal "Unrelated variables stay set." "kept" "$__UNIT_TEST_KEEP_VALUE"
    unset "__UNIT_TEST_KEEP_VALUE"

    __test_exit_code "Session ended after unsetting variables." 1 \
        _is_file_manager_session

    __restore_script_env "$saved_script_env"
}

__run_get_filenames_filemanager() {
    local output=""
    local expected_output=""
    local saved_input_files=$INPUT_FILES
    local saved_script_env="$_TEMP_DIR/filenames_env.sh"
    local uid=""

    uid=$(id -u)
    __save_script_env "$saved_script_env"
    _unset_global_variables_file_manager

    INPUT_FILES="a${FIELD_SEPARATOR}${FIELD_SEPARATOR}b"
    expected_output="a${FIELD_SEPARATOR}b"
    output=$(_get_filenames_filemanager)
    __test_equal "Fallback collapses standard input." "$expected_output" "$output"

    NAUTILUS_SCRIPT_SELECTED_URIS=""
    INPUT_FILES="plain"
    expected_output="plain"
    output=$(_get_filenames_filemanager)
    __test_equal "Empty selection falls back to standard input." \
        "$expected_output" "$output"

    NAUTILUS_SCRIPT_SELECTED_URIS=$'file:///tmp/my%20file.txt\nfile:///tmp/b.txt'
    expected_output=$'/tmp/my file.txt\r/tmp/b.txt'
    output=$(_get_filenames_filemanager)
    __test_equal "Decode file:// selections." "$expected_output" "$output"

    NAUTILUS_SCRIPT_SELECTED_URIS=$'sftp://host.example/one\nsftp://host.example/two'
    expected_output="/run/user/${uid}/gvfs/sftp:host=host.example/one"
    expected_output+="${FIELD_SEPARATOR}"
    expected_output+="/run/user/${uid}/gvfs/sftp:host=host.example/two"
    output=$(_get_filenames_filemanager)
    __test_equal "Translate remote selections." "$expected_output" "$output"

    NAUTILUS_SCRIPT_SELECTED_URIS="smb://server/share/folder/file"
    expected_output="/run/user/${uid}/gvfs/smb-share:server=server,share=share/folder/file"
    output=$(_get_filenames_filemanager)
    __test_equal "Translate an SMB selection." "$expected_output" "$output"

    INPUT_FILES=$saved_input_files
    __restore_script_env "$saved_script_env"
}

__run_get_files() {
    local output=""
    local expected_output=""
    local saved_input_files=$INPUT_FILES
    local saved_script_env="$_TEMP_DIR/get_files_env.sh"
    local message_file="$_TEMP_DIR/get_files_message"

    __save_script_env "$saved_script_env"
    _unset_global_variables_file_manager
    __create_temp_files
    printf "upper" >"$_TEMP_DIR_TEST/File.TXT"
    printf "pdf" >"$_TEMP_DIR_TEST/file.pdf"
    printf "x" >"$_TEMP_DIR_TEST/file2.txt"
    printf "x" >"$_TEMP_DIR_TEST/file10.txt"
    mkdir -p "$_TEMP_DIR_TEST/nested"
    printf "nested" >"$_TEMP_DIR_TEST/nested/nested.txt"

    INPUT_FILES="$_TEMP_DIR_TEST/file10.txt${FIELD_SEPARATOR}$_TEMP_DIR_TEST/file2.txt"
    expected_output="$_TEMP_DIR_TEST/file2.txt${FIELD_SEPARATOR}$_TEMP_DIR_TEST/file10.txt"
    output=$(_get_files 'par_type="file"; par_sort_list="true"')
    __test_equal "Sort the selected files." "$expected_output" "$output"

    INPUT_FILES="$_TEMP_DIR_TEST/file2.txt${FIELD_SEPARATOR}$_TEMP_DIR_TEST/file.pdf"
    expected_output="$_TEMP_DIR_TEST/file2.txt"
    output=$(_get_files 'par_type="file"; par_select_extension="txt"')
    __test_equal "Keep only the selected extension." "$expected_output" "$output"

    INPUT_FILES="$_TEMP_DIR_TEST"
    output=$(_get_files \
        'par_type="file"; par_recursive="true"; par_select_extension="txt"')
    __test_equal "Recursive search includes nested files." "true" \
        "$(grep --quiet "$_TEMP_DIR_TEST/nested/nested.txt" <<<"$output" &&
            echo true || echo false)"
    __test_equal "Recursive search drops pdf files." "false" \
        "$(grep --quiet "$_TEMP_DIR_TEST/file.pdf" <<<"$output" &&
            echo true || echo false)"

    INPUT_FILES="$_TEMP_DIR_TEST"
    expected_output="$_TEMP_DIR_TEST"
    output=$(_get_files 'par_type="directory"')
    __test_equal "Non-recursive directory selection." "$expected_output" "$output"

    INPUT_FILES="$_TEMP_FILE1"
    expected_output="$_TEMP_DIR_TEST"
    output=$(_get_files 'par_type="directory"; par_max_items="1"')
    __test_equal "File selection falls back to the working directory." \
        "$expected_output" "$output"

    NAUTILUS_SCRIPT_SELECTED_URIS="file://"
    # Read indirectly by '_get_working_directory'.
    # shellcheck disable=SC2034
    NAUTILUS_SCRIPT_CURRENT_URI="file://${_TEMP_DIR_TEST}"
    INPUT_FILES=""
    expected_output="$_TEMP_DIR_TEST"
    output=$(_get_files 'par_type="directory"')
    __test_equal "Empty file manager selection uses the working directory." \
        "$expected_output" "$output"
    _unset_global_variables_file_manager

    INPUT_FILES="$_TEMP_FILE1${FIELD_SEPARATOR}$_TEMP_FILE2"
    : >"$message_file"
    __test_exit_code "Rejected MIME type stops the script." 2 \
        __invoke_guarded "$message_file" \
        _get_files 'par_type="file"; par_select_mime="image/"'
    output=$(<"$message_file")
    expected_output="$(_i18n "Invalid input file!")"
    __test_equal "Rejected MIME type reports an invalid file." \
        "$expected_output" "$output"

    INPUT_FILES=$saved_input_files
    __restore_script_env "$saved_script_env"
    __clean_temp_files
}

__run_get_output_dir() {
    local output=""
    local expected_output=""
    local saved_input_files=$INPUT_FILES
    local saved_script_env="$_TEMP_DIR/output_dir_env.sh"

    __save_script_env "$saved_script_env"
    _unset_global_variables_file_manager
    __create_temp_files
    INPUT_FILES="$_TEMP_FILE1"
    rm -f -- "$TEMP_CONTROL_BATCH_ENABLED"

    expected_output="$_TEMP_DIR_TEST"
    output=$(_get_output_dir 'par_use_same_dir="true"')
    __test_equal "Use the working directory." "$expected_output" "$output"

    touch -- "$TEMP_CONTROL_BATCH_ENABLED"
    expected_output="$_TEMP_DIR_TEST/$PREFIX_OUTPUT_DIR"
    output=$(_get_output_dir 'par_use_same_dir="true"')
    __test_equal "Batch mode creates an output directory." \
        "$expected_output" "$output"
    __test_path_exists "Output directory exists." "true" "$output"
    rm -f -- "$TEMP_CONTROL_BATCH_ENABLED"

    expected_output="$_TEMP_DIR_TEST/$PREFIX_OUTPUT_DIR (2)"
    output=$(_get_output_dir 'par_use_same_dir="false"')
    __test_equal "Existing output directory gets the next suffix." \
        "$expected_output" "$output"

    INPUT_FILES=$saved_input_files
    __restore_script_env "$saved_script_env"
    rm -f -- "$TEMP_CONTROL_BATCH_ENABLED"
    __clean_temp_files
}

__run_validate_files_count() {
    local message_file="$_TEMP_DIR/validate_count_message"
    local items="a${FIELD_SEPARATOR}b"
    local output=""

    __test_exit_code "Count within the default limits." 0 \
        _validate_files_count "$items" "file" "" "" "" "" ""
    __test_exit_code "Count equal to the minimum." 0 \
        _validate_files_count "$items" "file" "" "" "2" "" ""
    __test_exit_code "Count equal to the maximum." 0 \
        _validate_files_count "$items" "file" "" "" "" "2" ""

    : >"$message_file"
    __test_exit_code "No files exits." 2 \
        __invoke_guarded "$message_file" \
        _validate_files_count "" "file" "" "" "" "" ""
    output=$(<"$message_file")
    __test_equal "No files message." \
        "$(_i18n "You must select") $(_i18n "files")!" "$output"

    __test_exit_code "No directories exits." 2 \
        __invoke_guarded "$message_file" \
        _validate_files_count "" "directory" "" "" "" "" ""
    output=$(<"$message_file")
    __test_equal "No directories message." \
        "$(_i18n "You must select") $(_i18n "directories")!" "$output"

    __test_exit_code "No files or directories exits." 2 \
        __invoke_guarded "$message_file" \
        _validate_files_count "" "all" "" "" "" "" ""
    output=$(<"$message_file")
    __test_equal "No files or directories message." \
        "$(_i18n "You must select") $(_i18n "files or directories")!" "$output"

    __test_exit_code "Empty type exits." 2 \
        __invoke_guarded "$message_file" \
        _validate_files_count "" "" "" "" "" "" ""
    output=$(<"$message_file")
    __test_equal "Empty type message." \
        "$(_i18n "Invalid input file!")" "$output"

    __test_exit_code "MIME filter with no matches exits." 2 \
        __invoke_guarded "$message_file" \
        _validate_files_count "" "file" "" "text/" "" "" ""
    output=$(<"$message_file")
    __test_equal "MIME filter message." \
        "$(_i18n "Invalid input file!")" "$output"

    __test_exit_code "Extension filter with no matches exits." 2 \
        __invoke_guarded "$message_file" \
        _validate_files_count "" "file" "txt|pdf" "" "" "" ""
    output=$(<"$message_file")
    __test_equal "Extension filter message." \
        "$(_i18n "You must select files with the extension:") '.txt' or '.pdf'!" \
        "$output"

    __test_exit_code "Below the minimum exits." 2 \
        __invoke_guarded "$message_file" \
        _validate_files_count "$items" "file" "" "" "3" "" ""
    output=$(<"$message_file")
    __test_equal "Minimum message." \
        "$(_i18n "You must select at least") 3 $(_i18n "files")!" "$output"

    items="a${FIELD_SEPARATOR}b${FIELD_SEPARATOR}c"
    __test_exit_code "Above the maximum exits." 2 \
        __invoke_guarded "$message_file" \
        _validate_files_count "$items" "file" "" "" "" "1" ""
    output=$(<"$message_file")
    __test_equal "Maximum message." \
        "$(_i18n "You must select up to") 1 $(_i18n "files")!" "$output"
}

__run_run_task_parallel() {
    local output=""

    _storage_text_clean
    export -f _main_task
    _run_task_parallel "" "$_TEMP_DIR/out" "1"
    output=$(_storage_text_read_all)
    __test_equal "Empty task list runs nothing." "" "$output"

    _storage_text_clean
    _run_task_parallel \
        "alpha${FIELD_SEPARATOR}beta" \
        "$_TEMP_DIR/o'ut" \
        "2"
    output=$(_storage_text_read_all)
    _storage_text_clean
    __test_equal "Parallel task receives the first item." "true" \
        "$(grep --quiet "alpha|$_TEMP_DIR/o'ut" <<<"$output" &&
            echo true || echo false)"
    __test_equal "Parallel task receives the second item." "true" \
        "$(grep --quiet "beta|$_TEMP_DIR/o'ut" <<<"$output" &&
            echo true || echo false)"
}

_main "$@"
