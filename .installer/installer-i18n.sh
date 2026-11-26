#!/usr/bin/env bash
# =============================================================================
# Description: Provide internationalization (i18n) functions for the installer.
# Sourced by 'install.sh'. Do not run directly.
# =============================================================================

I18N_DIR="$SCRIPT_DIR/.po"
I18N_FILE="" # Current translation file being used.
readonly I18N_DIR

_i18n() {
    local msgid=$1

    _i18n_get_translation "$I18N_FILE" "$msgid"
}

_i18n_get_translation() {
    local po_file=$1
    local msgid=$2
    local msgstr=""
    msgstr=$(grep -A1 "msgid *\"$msgid\"" "$po_file" 2>/dev/null |
        grep -o -P -m1 "msgstr\s+\"\K[^\"]+" 2>/dev/null)

    if [[ -n "$msgstr" ]]; then
        printf "%s" "$msgstr"
    else
        printf "%s" "$msgid"
    fi
}

_i18n_initialize() {
    # LANG not set: nothing to load
    if [[ -z "${LANG:-}" ]]; then
        return
    fi

    local lang_full="${LANG%%.*}"      # e.g. 'pt_BR.UTF-8' to 'pt_BR'.
    local lang_base="${lang_full%%_*}" # e.g. 'pt_BR' to 'pt'.
    local po_file=""

    # Try full locale first (e.g. pt_BR.po).
    po_file="$I18N_DIR/$lang_full.po"
    if [[ -f "$po_file" ]]; then
        I18N_FILE="$po_file"
        return
    fi

    # Fallback to base language (e.g. pt.po).
    po_file="$I18N_DIR/$lang_base.po"
    if [[ -f "$po_file" ]]; then
        I18N_FILE="$po_file"
    fi
}

_i18n_print_desktop_name() {
    local prefix=$1
    local name=$2

    local po_file=""
    while IFS= read -r -d $'\0' po_file; do
        local msg=""
        msg=$(_i18n_get_translation "$I18N_DIR/$po_file" "$name")
        printf "%s\n" "${prefix}[${po_file%.po}]=${msg}"
    done < <(_list_traslation_files)
}

# Translate each directory component in the path.
_i18n_translate_path() {
    local path=$1
    local IFS='/'

    # shellcheck disable=SC2206
    local -a components=($path)
    local -a translated_components=()
    local translated_path=""

    local component=""
    for component in "${components[@]}"; do
        translated_components+=("$(_i18n "$component")")
    done

    translated_path=$(
        IFS='/'
        echo "${translated_components[*]}"
    )
    printf "%s" "$translated_path"
}

_list_traslation_files() {
    find -L "$I18N_DIR" -name "*.po" -type f \
        -printf "%f\0" 2>/dev/null | sort --zero-terminated
}
