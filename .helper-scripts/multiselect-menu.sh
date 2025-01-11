#!/usr/bin/env bash

# Code based on: https://unix.stackexchange.com/a/673436
# Version: 2024-08-21

# Keyboard commands:
#  <enter>: Confirms the current selection of options.
#  <space>: Toggles the selection status of the currently highlighted option.
#  <a>: Toggles all available options.
#  <q> or <ctrl>+<c>: Terminates the process.
#  <up> or <left>: Moves the highlight cursor one option up.
#  <down> or <right>: Moves the highlight cursor one option down.

_multiselect_menu() {
    local return_value=$1
    local -n options=$2
    local -n defaults=$3

    # Turn off echoing of characters typed on the terminal.
    stty -echo

    # Helpers for console print format and control.
    __cursor_blink_on() {
        printf "\e[?25h"
    }
    __cursor_blink_off() {
        printf "\e[?25l"
    }
    __cursor_to() {
        local row=$1
        local col=${2:-1}

        printf "\e[%s;%sH" "$row" "$col"
    }
    __get_cursor_row() {
        local row=""
        local col=""

        IFS=";" read -rs -d "R" -p $'\E[6n' row col
        printf "%s" "${row#*[}"
    }
    __get_keyboard_command() {
        local key=""

        IFS="" read -rs -n 1 key &>/dev/null
        case "$key" in
        "") printf "enter" ;;
        " ") printf "toggle_active" ;;
        "a" | "A") printf "toggle_all" ;;
        "q" | "Q") printf "quit" ;;
        $'\e')
            IFS="" read -rs -n 2 key &>/dev/null
            case "$key" in
            "[A" | "[D") printf "up" ;;
            "[B" | "[C") printf "down" ;;
            esac
            ;;
        esac
    }
    # shellcheck disable=SC2317
    __on_ctrl_c() {
        __cursor_to "$last_row"
        __cursor_blink_on
        stty echo
        exit 1
    }

    # Ensure the cursor is back on upon a ctrl+c during read -s.
    trap "__on_ctrl_c" SIGINT

    # Process the 'defaults' parameter.
    local selected=()
    local i=0
    for i in "${!options[@]}"; do
        if [[ -v "defaults[i]" ]]; then
            if [[ ${defaults[i]} == "false" ]]; then
                selected+=("false")
            else
                selected+=("true")
            fi
        else
            selected+=("true")
        fi
        printf "\n"
    done

    # Determine the current screen position for overwriting the options.
    local start_row=""
    local last_row=""
    last_row=$(__get_cursor_row)
    start_row=$((last_row - ${#options[@]}))

    # Print options by overwriting the last lines.
    __print_options() {
        local index_active=$1

        local i=0
        for i in "${!options[@]}"; do
            # Set the prefix "[ ]" or "[*]".
            local prefix="[ ]"
            if [[ ${selected[i]} == "true" ]]; then
                prefix="[\e[1;32m*\e[0m]"
            fi

            # Print the prefix with the option in the menu.
            __cursor_to "$((start_row + i))"
            local option="${options[i]}"
            if ((i == index_active)); then
                # Print the active option.
                printf "$prefix \e[7m%s\e[27m" "$option"
            else
                # Print the inactive option.
                printf "$prefix %s" "$option"
            fi
        done
    }

    # The menu's main loop.
    __cursor_blink_off
    local active=0
    while true; do
        __print_options "$active"

        # User key control.
        case $(__get_keyboard_command) in
        "enter")
            __print_options -1
            break
            ;;
        "toggle_active")
            if [[ ${selected[active]} == "true" ]]; then
                selected[active]="false"
            else
                selected[active]="true"
            fi
            ;;
        "toggle_all")
            local i=0
            if [[ ${selected[active]} == "true" ]]; then
                for i in "${!selected[@]}"; do
                    selected[i]="false"
                done
            else
                for i in "${!selected[@]}"; do
                    selected[i]="true"
                done
            fi
            ;;
        "quit")
            __on_ctrl_c
            ;;
        "up")
            active=$((active - 1))
            if [[ $active -lt 0 ]]; then
                active=$((${#options[@]} - 1))
            fi
            ;;
        "down")
            active=$((active + 1))
            if [[ $active -ge ${#options[@]} ]]; then
                active=0
            fi
            ;;
        esac
    done

    # Set the cursor position back to normal.
    __cursor_to "$last_row"
    __cursor_blink_on
    stty echo

    eval "$return_value"='("${selected[@]}")'

    # Unset the trap function.
    trap "" SIGINT
}
