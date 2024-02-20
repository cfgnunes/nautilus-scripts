#!/usr/bin/env bash

# Unit test script.

set -eu

_TOTAL_TESTS=0
_TOTAL_FAILED=0

_main() {
    echo "Running the unit tests..."

    _run_source_common_functions
    _run_cleanup_on_exit
    _run_check_dependencies
    _run_check_result
    _run_command_exists
    _run_display_dir_selection_box
    _run_display_file_selection_box
    _run_display_error_box
    _run_display_info_box
    _run_display_password_box
    _run_display_question_box
    _run_display_text_box
    _run_display_result_box
    _run_display_wait_box
    _run_display_wait_box_message
    _run_close_wait_box
    _run_is_wait_box_open
    _run_exit_script
    _run_gdbus_notify
    _run_expand_directory
    _run_has_string_in_list
    _run_install_package
    _run_is_gui_session
    _run_get_distro_name
    _run_get_filename_extension
    _run_get_filename_next_suffix
    _run_get_filemanager_list
    _run_get_files
    _run_get_full_path_dir
    _run_get_full_path_file
    _run_get_max_procs
    _run_get_output_dir
    _run_get_output_file
    _run_get_script_name
    _run_log_compile
    _run_log_write
    _run_move_file
    _run_move_temp_file_to_output
    _run_print_terminal
    _run_read_array_values
    _run_run_task_parallel
    _run_strip_filename_extension
    _run_temp_result_compile
    _run_temp_result_write
    _run_text_remove_empty_lines
    _run_text_remove_home
    _run_text_remove_pwd
    _run_text_sort
    _run_text_uri_decode
    _run_validate_conflict_filenames
    _run_validate_file_extension
    _run_validate_file_mime
    _run_validate_file_mime_parallel
    _run_validate_file_preselect
    _run_validate_file_preselect_parallel
    _run_validate_files_count

    echo "Tests/Failed: $_TOTAL_TESTS/$_TOTAL_FAILED"
    echo "Done!"
}

_test_equal() {
    local description=$1
    local value1=$2
    local value2=$3
    _TOTAL_TESTS=$((_TOTAL_TESTS + 1))

    if [[ "$value1" == "$value2" ]]; then
        echo -n " > [PASS]"
    else
        echo -n " > [FAILED]"
        _TOTAL_FAILED=$((_TOTAL_FAILED + 1))
    fi
    echo -n $'\t'"(${FUNCNAME[1]})"$'\t'
    echo -n "$description" | sed -z "s|\n|\\\n|g" | cat -ETv
    echo
}

_run_source_common_functions() {
    local SCRIPT_DIR=""
    local ROOT_DIR=""

    # Source the script 'common-functions.sh'.
    SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
    ROOT_DIR=$(grep --only-matching "^.*scripts[^/]*" <<<"$SCRIPT_DIR")
    source "$ROOT_DIR/common-functions.sh"

    _test_equal "Check global variables." "$FILENAME_SEPARATOR" $'\r'
}

_run_cleanup_on_exit() {
    # TODO Implement the test: '_run_cleanup_on_exit'.
    :
}

_run_check_dependencies() {
    # TODO Implement the test: '_run_check_dependencies'.
    :
}

_run_check_result() {
    # TODO Implement the test: '_run_check_result'.
    :
}

_run_command_exists() {
    # TODO Implement the test: '_run_command_exists'.
    :
}

_run_display_dir_selection_box() {
    # TODO Implement the test: '_run_display_dir_selection_box'.
    :
}

_run_display_file_selection_box() {
    # TODO Implement the test: '_run_display_file_selection_box'.
    :
}

_run_display_error_box() {
    # TODO Implement the test: '_run_display_error_box'.
    :
}

_run_display_info_box() {
    # TODO Implement the test: '_run_display_info_box'.
    :
}

_run_display_password_box() {
    # TODO Implement the test: '_run_display_password_box'.
    :
}

_run_display_question_box() {
    # TODO Implement the test: '_run_display_question_box'.
    :
}

_run_display_text_box() {
    # TODO Implement the test: '_run_display_text_box'.
    :
}

_run_display_result_box() {
    # TODO Implement the test: '_run_display_result_box'.
    :
}

_run_display_wait_box() {
    # TODO Implement the test: '_run_display_wait_box'.
    :
}

_run_display_wait_box_message() {
    # TODO Implement the test: '_run_display_wait_box_message'.
    :
}

_run_close_wait_box() {
    # TODO Implement the test: '_run_close_wait_box'.
    :
}

_run_is_wait_box_open() {
    # TODO Implement the test: '_run_is_wait_box_open'.
    :
}

_run_exit_script() {
    # TODO Implement the test: '_run_exit_script'.
    :
}

_run_gdbus_notify() {
    # TODO Implement the test: '_run_gdbus_notify'.
    :
}

_run_expand_directory() {
    # TODO Implement the test: '_run_expand_directory'.
    :
}

_run_has_string_in_list() {
    # TODO Implement the test: '_run_has_string_in_list'.
    :
}

_run_install_package() {
    # TODO Implement the test: '_run_install_package'.
    :
}

_run_is_gui_session() {
    # TODO Implement the test: '_run_is_gui_session'.
    :
}

_run_get_distro_name() {
    # TODO Implement the test: '_run_get_distro_name'.
    :
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

    input="/tmp/File"
    expected_output=""
    output=$(_get_filename_extension "$input")
    _test_equal "$input" "$output" "$expected_output"

    input="/tmp/File !@#$%&*()_"$'\n'"+.txt"
    expected_output=".txt"
    output=$(_get_filename_extension "$input")
    _test_equal "$input" "$output" "$expected_output"
}

_run_get_filename_next_suffix() {
    # TODO Implement the test: '_run_get_filename_next_suffix'.
    :
}

_run_get_filemanager_list() {
    # TODO Implement the test: '_run_get_filemanager_list'.
    :
}

_run_get_files() {
    # TODO Implement the test: '_run_get_files'.
    :
}

_run_get_full_path_dir() {
    # TODO Implement the test: '_run_get_full_path_dir'.
    :
}

_run_get_full_path_file() {
    # TODO Implement the test: '_run_get_full_path_file'.
    :
}

_run_get_max_procs() {
    # TODO Implement the test: '_run_get_max_procs'.
    :
}

_run_get_output_dir() {
    # TODO Implement the test: '_run_get_output_dir'.
    :
}

_run_get_output_file() {
    # TODO Implement the test: '_run_get_output_file'.
    :
}

_run_get_script_name() {
    # TODO Implement the test: '_run_get_script_name'.
    :
}

_run_log_compile() {
    # TODO Implement the test: '_run_log_compile'.
    :
}

_run_log_write() {
    # TODO Implement the test: '_run_log_write'.
    :
}

_run_move_file() {
    # TODO Implement the test: '_run_move_file'.
    :
}

_run_move_temp_file_to_output() {
    # TODO Implement the test: '_run_move_temp_file_to_output'.
    :
}

_run_print_terminal() {
    # TODO Implement the test: '_run_print_terminal'.
    :
}

_run_read_array_values() {
    # TODO Implement the test: '_run_read_array_values'.
    :
}

_run_run_task_parallel() {
    # TODO Implement the test: '_run_run_task_parallel'.
    :
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

    input="/tmp/File"
    expected_output="/tmp/File"
    output=$(_strip_filename_extension "$input")
    _test_equal "$input" "$output" "$expected_output"

    input="/tmp/File !@#$%&*()_"$'\n'"+.txt"
    expected_output="/tmp/File !@#$%&*()_"$'\n'"+"
    output=$(_strip_filename_extension "$input")
    _test_equal "$input" "$output" "$expected_output"
}

_run_temp_result_compile() {
    local expected_output=""
    local output=""

    _temp_result_write "Line"
    _temp_result_write "Line"

    expected_output="Line"$'\n'"Line"
    output=$(_temp_result_compile)
    _test_equal "Write and read the compiled temp result." "$output" "$expected_output"
}

_run_temp_result_write() {
    # TODO Implement the test: '_run_temp_result_write'.
    :
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
}

_run_text_remove_home() {
    # TODO Implement the test: '_run_text_remove_home'.
    :
}

_run_text_remove_pwd() {
    # TODO Implement the test: '_run_text_remove_pwd'.
    :
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
}

_run_text_uri_decode() {
    # TODO Implement the test: '_run_text_uri_decode'.
    :
}

_run_validate_conflict_filenames() {
    # TODO Implement the test: '_run_validate_conflict_filenames'.
    :
}

_run_validate_file_extension() {
    # TODO Implement the test: '_run_validate_file_extension'.
    :
}

_run_validate_file_mime() {
    # TODO Implement the test: '_run_validate_file_mime'.
    :
}

_run_validate_file_mime_parallel() {
    # TODO Implement the test: '_run_validate_file_mime_parallel'.
    :
}

_run_validate_file_preselect() {
    # TODO Implement the test: '_run_validate_file_preselect'.
    :
}

_run_validate_file_preselect_parallel() {
    # TODO Implement the test: '_run_validate_file_preselect_parallel'.
    :
}

_run_validate_files_count() {
    # TODO Implement the test: '_run_validate_files_count'.
    :
}

_main "$@"
