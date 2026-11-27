#!/usr/bin/env bash
# =============================================================================
# Description: Display an interactive menu in the terminal.
#
# Keyboard commands:
#                       <enter>: Confirms the current selection.
#                       <space>: Toggles the selected option.
#             <a> or <ctrl>+<a>: Toggles all options.
#                  <q> or <esc>: Exits the menu.
#                    <ctrl>+<c>: Exits the menu (interrupt signal).
# <up>, <left> or <shift>+<tab>: Moves the cursor up one option.
#      <down>, <right> or <tab>: Moves the cursor down one option.
#                        <home>: Moves the cursor to the first option.
#                         <end>: Moves the cursor to the last option.
#
# Returns:
#   0   if the selection was confirmed.
#   1   if the user quits with <q> or <esc>.
#   2   if the terminal is not interactive or input cannot be read.
#   129 on SIGHUP.
#   130 on <ctrl>+<c> (SIGINT).
#   143 on SIGTERM.
#
# Example of usage:
#   source "multiselect-menu.sh"
#   labels=("Option A" "Option B")
#   initial_values=("true" "false")
#   _multiselect_menu labels initial_values checked_values || return 1
#   echo "Option A: ${checked_values[0]}"
#   echo "Option B: ${checked_values[1]}"
# =============================================================================

_multiselect_menu() {
    local -n _labels=$1
    local -n _initial_values=$2
    local -n _checked_values=$3
    local labels_count=${#_labels[@]}

    # Ensure that the terminal is interactive.
    [[ -t 0 ]] || return 2

    # Helper functions.
    __abort() {
        __cursor_to "$last_row"
        __finish
        exit "$1"
    }
    __finish() {
        __restore_terminal
        trap - EXIT TERM HUP INT
        eval "$old_traps"
    }
    __restore_terminal() {
        printf "\033[?25h" # Show the cursor.
        stty "$old_stty" 2>/dev/null
    }
    __cursor_to() {
        printf "\033[%s;%sH" "$1" "${2:-1}"
    }
    __get_cursor_row() {
        local row=""

        IFS=";" read -rs -d "R" -p $'\E[6n' row _ || return 1
        printf "%s" "${row#*[}"
    }
    __get_key_cmd() {
        local key=""

        IFS="" read -rs -n 1 key &>/dev/null || return 1
        case "$key" in
        "") printf "confirm" ;;                     # <enter>
        " ") printf "toggle_opt" ;;                 # <space>
        $'\t') printf "down" ;;                     # <tab>
        "a" | "A" | $'\x01') printf "toggle_all" ;; # <a> or <ctrl>+<a>
        "q" | "Q") printf "quit" ;;                 # <q>
        $'\033')                                    # <esc>
            key=""
            IFS="" read -rs -n 2 -t 0.05 key &>/dev/null
            case "$key" in
            "") printf "quit" ;;               # <esc>
            "[A" | "[D" | "[Z") printf "up" ;; # <up>, <left> or <shift>+<tab>
            "[B" | "[C") printf "down" ;;      # <down> or <right>
            "[H") printf "home" ;;             # <home>
            "[F") printf "end" ;;              # <end>
            esac
            ;;
        esac
    }
    __print_menu() {
        local i_cursor=$1
        local prefix=""

        local i
        for i in "${!_labels[@]}"; do
            prefix="[ ]"
            [[ ${values[i]} == "true" ]] && prefix=$'[\033[0;32m*\033[0m]'

            __cursor_to "$((start_row + i))"
            if ((i == i_cursor)); then
                printf "%s \033[7m%s\033[27m" "$prefix" "${_labels[i]}"
            else
                printf "%s %s" "$prefix" "${_labels[i]}"
            fi
        done
    }

    # Save the original terminal state to restore later.
    local old_stty=""
    local old_traps=""
    old_stty=$(stty -g)
    old_traps=$(trap -p EXIT TERM HUP INT)

    # Turn off echoing of characters typed on the terminal.
    stty -echo

    local last_row=""
    local start_row=""

    # Ensure the terminal is restored on ctrl+c, kill, hangup or any exit.
    trap "__abort 130" INT
    trap "__abort 143" TERM
    trap "__abort 129" HUP
    trap "__restore_terminal" EXIT

    # Process the 'initial_values' parameter.
    local -a values=()
    local i=""
    for i in "${!_labels[@]}"; do
        values+=("${_initial_values[i]:-false}")
        printf "\n"
    done

    # Determine the current screen position for overwriting the options.
    printf '\033[6n'
    if ! last_row=$(__get_cursor_row); then
        __finish
        return 1
    fi
    start_row=$((last_row - labels_count))

    # Main loop of the menu.
    i=0
    local key_cmd=""
    printf "\033[?25l" # Hide the cursor.
    while true; do
        __print_menu "$i"

        if ! key_cmd=$(__get_key_cmd); then
            __cursor_to "$last_row"
            __finish
            return 1
        fi

        case $key_cmd in
        "confirm")
            __print_menu -1
            break
            ;;
        "toggle_opt")
            if [[ ${values[i]} == "true" ]]; then
                values[i]="false"
            else
                values[i]="true"
            fi
            ;;
        "toggle_all")
            if [[ ${values[i]} == "true" ]]; then
                values=("${values[@]/*/false}")
            else
                values=("${values[@]/*/true}")
            fi
            ;;
        "quit") __abort 1 ;;
        "up") i=$(((i - 1 + labels_count) % labels_count)) ;;
        "down") i=$(((i + 1) % labels_count)) ;;
        "home") i=0 ;;
        "end") i=$((labels_count - 1)) ;;
        esac
    done

    # Set the cursor position back to normal.
    __cursor_to "$last_row"
    __finish

    _checked_values=("${values[@]}")
}
