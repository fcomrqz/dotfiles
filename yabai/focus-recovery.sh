#!/bin/sh
# shellcheck disable=SC2016
# shellcheck source-path=SCRIPTDIR

set -u

close_state="${1:-}"
closed_window="${2:-}"
script_dir="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
memory_script="$script_dir/focus-memory.sh"

# shellcheck source=focus-lib.sh
. "$script_dir/focus-lib.sh"

case "$close_state" in
    focused | background) ;;
    *)
        printf 'Usage: focus-recovery.sh <focused|background> <window-id>\n' \
            >&2
        exit 1
        ;;
esac
focus_is_number "$closed_window" || exit 0
focus_resolve_tools || exit 1
focus_ensure_state_dir || exit 1

metadata="$("$memory_script" metadata "$closed_window" 2>/dev/null || true)"

if [ "$close_state" = background ]; then
    "$memory_script" forget "$closed_window" >/dev/null 2>&1 || true
    if [ -n "$metadata" ]; then
        IFS='	' read -r \
            display_key \
            display_index \
            space_index \
            window_kind <<EOF
$metadata
EOF
        : "$display_key" "$space_index" "$window_kind"
        "$memory_script" snapshot-display "$display_index" \
            >/dev/null 2>&1 || true
    fi
    exit 0
fi

[ -n "$metadata" ] || exit 0
IFS='	' read -r \
    display_key \
    display_index \
    closed_space \
    window_kind <<EOF
$metadata
EOF
: "$closed_space"

focus_acquire_lock || exit 0
trap 'focus_release_lock' 0
trap 'exit 1' 1 2 15

normal_candidates="$(focus_normal_candidates "$display_index")" ||
    normal_candidates='[]'
normal_count="$(
    printf '%s\n' "$normal_candidates" |
        "$FOCUS_JQ_BIN" -r 'length'
)"

recover_window() {
    recover_window_id="$1"
    recover_space="$(
        printf '%s\n' "$normal_candidates" |
            "$FOCUS_JQ_BIN" -r --argjson window "$recover_window_id" \
                '.[] | select(.id == $window) | .space'
    )"
    [ -n "$recover_space" ] || return 1

    if focus_activate_window "$recover_window_id" "$recover_space"; then
        "$memory_script" record "$recover_window_id" >/dev/null 2>&1 || true
        return 0
    fi

    return 1
}

recover_empty_space() {
    focus_activate_empty_display "$display_index" || true
    "$memory_script" set-active-display "$display_index" \
        >/dev/null 2>&1 || true
}

case "$window_kind" in
    normal)
        if [ "$normal_count" -eq 0 ]; then
            recover_empty_space
        else
            neighbors="$(
                "$memory_script" neighbors "$closed_window" \
                    2>/dev/null || true
            )"
            previous_window=""
            next_window=""
            if [ -n "$neighbors" ]; then
                IFS='	' read -r previous_window next_window <<EOF
$neighbors
EOF
            fi

            if focus_is_number "$previous_window" &&
                printf '%s\n' "$normal_candidates" |
                    "$FOCUS_JQ_BIN" -e \
                        --argjson window "$previous_window" \
                        'any(.[]; .id == $window)' >/dev/null
            then
                replacement_window="$previous_window"
            elif focus_is_number "$next_window" &&
                printf '%s\n' "$normal_candidates" |
                    "$FOCUS_JQ_BIN" -e \
                        --argjson window "$next_window" \
                        'any(.[]; .id == $window)' >/dev/null
            then
                replacement_window="$next_window"
            else
                replacement_window="$(
                    printf '%s\n' "$normal_candidates" |
                        "$FOCUS_JQ_BIN" -r '.[0].id'
                )"
            fi

            recover_window "$replacement_window" || true
        fi
        ;;
    native)
        if [ "$normal_count" -eq 0 ]; then
            recover_empty_space
        else
            remembered_normal="$(
                "$memory_script" get "$display_index" normal \
                    2>/dev/null || true
            )"

            if focus_is_number "$remembered_normal" &&
                printf '%s\n' "$normal_candidates" |
                    "$FOCUS_JQ_BIN" -e --argjson window "$remembered_normal" \
                        'any(.[]; .id == $window)' >/dev/null
            then
                recover_window "$remembered_normal" || true
            fi
        fi
        ;;
    other) ;;
esac

"$memory_script" forget "$closed_window" >/dev/null 2>&1 || true
"$memory_script" snapshot-display "$display_index" >/dev/null 2>&1 || true
