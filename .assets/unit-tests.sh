#!/usr/bin/env bash

# Unit test script.

set -u

# -----------------------------------------------------------------------------
# CONSTANTS
# -----------------------------------------------------------------------------

_MOCK_DIR_TEST="/tmp/unit-test"
_MOCK_FILE1="$_MOCK_DIR_TEST/file1"
_MOCK_FILE2="$_MOCK_DIR_TEST/file2"
_MOCK_FILE3="$_MOCK_DIR_TEST/file3"
_MOCK_FILE1_CONTENT="File 1 test."
_MOCK_FILE2_CONTENT="File 2 test."
_MOCK_FILE3_CONTENT="File 3 test."

readonly \
    _MOCK_DIR_TEST \
    _MOCK_FILE1 \
    _MOCK_FILE2 \
    _MOCK_FILE3 \
    _MOCK_FILE1_CONTENT \
    _MOCK_FILE2_CONTENT \
    _MOCK_FILE3_CONTENT

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

    __run_source_common_functions

    __run_check_dependencies
    __run_check_output
    __run_cleanup_on_exit
    __run_close_wait_box
    __run_command_exists
    __run_convert_delimited_string_to_text
    __run_convert_text_to_delimited_string
    __run_directory_pop
    __run_directory_push
    __run_display_dir_selection_box
    __run_display_error_box
    __run_display_file_selection_box
    __run_display_info_box
    __run_display_list_box
    __run_display_password_box
    __run_display_password_box_define
    __run_display_question_box
    __run_display_result_box
    __run_display_text_box
    __run_display_wait_box
    __run_display_wait_box_message
    __run_exit_script
    __run_find_filtered_files
    __run_gdbus_notify
    __run_get_file_encoding
    __run_get_file_mime
    __run_get_filename_dir
    __run_get_filename_extension
    __run_get_filename_full_path
    __run_get_filename_next_suffix
    __run_get_filenames_filemanager
    __run_get_files
    __run_get_items_count
    __run_get_max_procs
    __run_get_output_dir
    __run_get_output_filename
    __run_get_qdbus_command
    __run_get_script_name
    __run_get_temp_dir_local
    __run_get_temp_file
    __run_get_temp_file_dry
    __run_get_working_directory
    __run_is_directory_empty
    __run_is_gui_session
    __run_log_error
    __run_logs_consolidate
    __run_move_file
    __run_move_temp_file_to_output
    __run_open_items_locations
    __run_pkg_get_available_package_manager
    __run_pkg_install_packages
    __run_pkg_is_package_installed
    __run_recent_scripts_add
    __run_recent_scripts_organize
    __run_run_task_parallel
    __run_storage_text
    __run_str_human_readable_path
    __run_str_remove_empty_tokens
    __run_strip_filename_extension
    __run_text_remove_empty_lines
    __run_text_remove_home
    __run_text_remove_pwd
    __run_text_sort
    __run_text_uri_decode
    __run_unset_global_variables_file_manager
    __run_validate_conflict_filenames
    __run_validate_file_mime
    __run_validate_file_mime_parallel
    __run_validate_files_count
    __run_xdg_get_default_app

    printf "\nFinished! "
    printf "Results: %s tests, %s failed.\n" "$_TOTAL_TESTS" "$_TOTAL_FAILED"
}

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

__test_equal() {
    local description=$1
    local expected_output=$2
    local output=$3

    ((_TOTAL_TESTS++))

    if [[ "$expected_output" == "$output" ]]; then
        printf "[\\e[32mPASS\\e[0m] "
    else
        printf "[\\e[31mFAIL\\e[0m] "
        ((_TOTAL_FAILED++))
    fi
    printf "\\e[33mFunction:\\e[0m "
    printf "%s " "${FUNCNAME[1]}"
    printf "\\e[33mDescription:\\e[0m "
    printf "%s" "$description" | sed -z "s|\n|\\\n|g" | cat -A
    printf "\n"

    if [[ "$expected_output" != "$output" ]]; then
        printf "\\e[31mExpected output:\\e[0m "
        printf "%s" "$expected_output" | sed -z "s|\n|\\\n|g" | cat -A
        printf "\n"
        printf "         \\e[31mOutput:\\e[0m "
        printf "%s" "$output" | sed -z "s|\n|\\\n|g" | cat -A
        printf "\n"
    fi
}

__test_file() {
    local description=$1
    local file=$2

    ((_TOTAL_TESTS++))

    if [[ -f "$file" ]]; then
        printf "[\\e[32mPASS\\e[0m] "
    else
        printf "[\\e[31mFAIL\\e[0m] "
        ((_TOTAL_FAILED++))
    fi
    printf "\\e[33mFunction:\\e[0m "
    printf "%s " "${FUNCNAME[1]}"
    printf "\\e[33mDescription:\\e[0m "
    printf "%s" "$description" | sed -z "s|\n|\\\n|g" | cat -A
    printf "\n"
}

__run_source_common_functions() {
    local SCRIPT_DIR=""
    local ROOT_DIR=""

    # Source the script 'common-functions.sh'.
    SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
    ROOT_DIR=$(grep --only-matching "^.*scripts[^/]*" <<<"$SCRIPT_DIR")
    ROOT_DIR=${ROOT_DIR//".assets"/}
    source "$ROOT_DIR/common-functions.sh"

    __test_equal "Check global variables." "$FIELD_SEPARATOR" $'\r'
}

__run_check_dependencies() {
    # TODO: Implement the test.
    printf ""
}

__run_check_output() {
    # TODO: Implement the test.
    printf ""
}

__run_cleanup_on_exit() {
    # TODO: Implement the test.
    printf ""
}

__run_close_wait_box() {
    # TODO: Implement the test.
    printf ""
}

__run_command_exists() {
    # TODO: Implement the test.
    printf ""
}

__run_convert_delimited_string_to_text() {
    # TODO: Implement the test.
    printf ""
}

__run_convert_text_to_delimited_string() {
    # TODO: Implement the test.
    printf ""
}

__run_directory_pop() {
    # TODO: Implement the test.
    printf ""
}

__run_directory_push() {
    # TODO: Implement the test.
    printf ""
}

__run_display_dir_selection_box() {
    # TODO: Implement the test.
    printf ""
}

__run_display_error_box() {
    # TODO: Implement the test.
    printf ""
}

__run_display_file_selection_box() {
    # TODO: Implement the test.
    printf ""
}

__run_display_info_box() {
    # TODO: Implement the test.
    printf ""
}

__run_display_list_box() {
    # TODO: Implement the test.
    printf ""
}

__run_display_password_box() {
    # TODO: Implement the test.
    printf ""
}

__run_display_password_box_define() {
    # TODO: Implement the test.
    printf ""
}

__run_display_question_box() {
    # TODO: Implement the test.
    printf ""
}

__run_display_result_box() {
    # TODO: Implement the test.
    printf ""
}

__run_display_text_box() {
    # TODO: Implement the test.
    printf ""
}

__run_display_wait_box() {
    # TODO: Implement the test.
    printf ""
}

__run_display_wait_box_message() {
    # TODO: Implement the test.
    printf ""
}

__run_exit_script() {
    # TODO: Implement the test.
    printf ""
}

__run_find_filtered_files() {
    # TODO: Implement the test.
    printf ""
}

__run_gdbus_notify() {
    # TODO: Implement the test.
    printf ""
}

__run_get_file_encoding() {
    # TODO: Implement the test.
    printf ""
}

__run_get_file_mime() {
    # TODO: Implement the test.
    printf ""
}

__run_get_filename_dir() {
    # TODO: Implement the test.
    printf ""
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

__run_get_filename_full_path() {
    # TODO: Implement the test.
    printf ""
}

__run_get_filename_next_suffix() {
    # TODO: Implement the test.
    printf ""
}

__run_get_filenames_filemanager() {
    # TODO: Implement the test.
    printf ""
}

__run_get_files() {
    # TODO: Implement the test.
    printf ""
}

__run_get_items_count() {
    # TODO: Implement the test.
    printf ""
}

__run_get_max_procs() {
    # TODO: Implement the test.
    printf ""
}

__run_get_output_dir() {
    # TODO: Implement the test.
    printf ""
}

__run_get_output_filename() {
    # TODO: Implement the test.
    printf ""
}

__run_get_qdbus_command() {
    # TODO: Implement the test.
    printf ""
}

__run_get_script_name() {
    local expected_output=""
    local output=""

    expected_output="unit-tests.sh"
    output=$(_get_script_name)
    __test_equal "$expected_output" "$expected_output" "$output"
}

__run_get_temp_dir_local() {
    # TODO: Implement the test.
    printf ""
}

__run_get_temp_file() {
    # TODO: Implement the test.
    printf ""
}

__run_get_temp_file_dry() {
    # TODO: Implement the test.
    printf ""
}

__run_get_working_directory() {
    # TODO: Implement the test.
    printf ""
}

__run_is_directory_empty() {
    # TODO: Implement the test.
    printf ""
}

__run_is_gui_session() {
    # TODO: Implement the test.
    printf ""
}

__run_log_error() {
    local expected_output=""
    local output=""

    _log_error "message" "input_file" "std_output" "output_file"
    output=$(cat -- "$TEMP_DIR_LOGS/"* 2>/dev/null | tail -n +2)
    expected_output=" > Input file: input_file"$'\n'" > Output file: output_file"$'\n'" > Error: message"$'\n'" > Standard output:"$'\n'"std_output"

    __test_equal "Check the log error content." "$expected_output" "$output"
}

__run_logs_consolidate() {
    # TODO: Implement the test.
    printf ""
}

__run_move_file() {
    local expected_output=""
    local output=""

    __create_mock_files
    _move_file "" "$_MOCK_FILE1" "$_MOCK_FILE2"
    expected_output=$_MOCK_FILE1_CONTENT
    output=$(<"$_MOCK_FILE1")
    __test_equal "" "$expected_output" "$output"
    expected_output=$_MOCK_FILE2_CONTENT
    output=$(<"$_MOCK_FILE2")
    __test_equal "" "$expected_output" "$output"
    __clean_mock_files

    __create_mock_files
    _move_file "rename" "$_MOCK_FILE1" "$_MOCK_FILE1"
    expected_output=$_MOCK_FILE1_CONTENT
    output=$(<"$_MOCK_FILE1")
    __test_equal "skip" "$expected_output" "$output"
    __clean_mock_files

    __create_mock_files
    _move_file "skip" "$_MOCK_FILE1" "$_MOCK_FILE2"
    expected_output=$_MOCK_FILE1_CONTENT
    output=$(<"$_MOCK_FILE1")
    __test_equal "skip" "$expected_output" "$output"
    expected_output=$_MOCK_FILE2_CONTENT
    output=$(<"$_MOCK_FILE2")
    __test_equal "skip" "$expected_output" "$output"
    __clean_mock_files

    __create_mock_files
    _move_file "overwrite" "$_MOCK_FILE1" "$_MOCK_FILE2"
    expected_output=$_MOCK_FILE1_CONTENT
    output=$(<"$_MOCK_FILE2")
    __test_equal "overwrite" "$expected_output" "$output"
    __clean_mock_files

    __create_mock_files
    _move_file "rename" "$_MOCK_FILE1" "$_MOCK_FILE2"
    expected_output=$_MOCK_FILE2_CONTENT
    output=$(<"$_MOCK_FILE2")
    __test_equal "rename" "$expected_output" "$output"
    expected_output=$_MOCK_FILE1_CONTENT
    output=$(<"$_MOCK_FILE2 (1)")
    __test_equal "rename" "$expected_output" "$output"
    __clean_mock_files
}

__run_move_temp_file_to_output() {
    # TODO: Implement the test.
    printf ""
}

__run_open_items_locations() {
    # TODO: Implement the test.
    printf ""
}

__run_pkg_get_available_package_manager() {
    # TODO: Implement the test.
    printf ""
}

__run_pkg_install_packages() {
    # TODO: Implement the test.
    printf ""
}

__run_pkg_is_package_installed() {
    # TODO: Implement the test.
    printf ""
}

__run_recent_scripts_add() {
    # TODO: Implement the test.
    printf ""
}

__run_recent_scripts_organize() {
    # TODO: Implement the test.
    printf ""
}

__run_run_task_parallel() {
    # TODO: Implement the test.
    printf ""
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
    __test_equal "Write and read the compiled temp result." "$expected_output" "$output"

    _storage_text_clean

    _storage_text_write "Line"
    _storage_text_write "Line"
    _storage_text_write "Line"

    expected_output="LineLineLine"
    output=$(_storage_text_read_all)
    __test_equal "Write and read the compiled temp result." "$expected_output" "$output"
}

__run_str_human_readable_path() {
    # TODO: Implement the test.
    printf ""
}

__run_str_remove_empty_tokens() {
    # TODO: Implement the test.
    printf ""
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

__run_text_remove_home() {
    # TODO: Implement the test.
    printf ""
}

__run_text_remove_pwd() {
    # TODO: Implement the test.
    printf ""
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

__run_text_uri_decode() {
    # TODO: Implement the test.
    printf ""
}

__run_unset_global_variables_file_manager() {
    # TODO: Implement the test.
    printf ""
}

__run_validate_conflict_filenames() {
    # TODO: Implement the test.
    printf ""
}

__run_validate_file_mime() {
    # TODO: Implement the test.
    printf ""
}

__run_validate_file_mime_parallel() {
    # TODO: Implement the test.
    printf ""
}

__run_validate_files_count() {
    # TODO: Implement the test.
    printf ""
}

__run_xdg_get_default_app() {
    # TODO: Implement the test.
    printf ""
}

_main "$@"
