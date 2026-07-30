#!/bin/sh
# Shared Yabai focus helpers. This file is sourced by the executable scripts.
# shellcheck disable=SC2016

FOCUS_YABAI_BIN="${YABAI_BIN:-/opt/homebrew/bin/yabai}"
FOCUS_JQ_BIN="${JQ_BIN:-/opt/homebrew/bin/jq}"
FOCUS_OSASCRIPT_BIN="${OSASCRIPT_BIN:-/usr/bin/osascript}"
FOCUS_STATE_DIR="${YABAI_FOCUS_STATE_DIR:-${TMPDIR:-/tmp}/yabai-focus-$(id -u)}"
FOCUS_POINTER_BIN="${YABAI_POINTER_BIN:-$FOCUS_STATE_DIR/warp-pointer}"
FOCUS_POLL_INTERVAL="${YABAI_FOCUS_POLL_INTERVAL:-0.02}"
FOCUS_TRANSITION_ATTEMPTS="${YABAI_FOCUS_TRANSITION_ATTEMPTS:-100}"
FOCUS_JQ_LIB="${YABAI_FOCUS_JQ_LIB:-${script_dir:-.}}"

focus_resolve_tools() {
    if [ ! -x "$FOCUS_YABAI_BIN" ]; then
        FOCUS_YABAI_BIN="$(command -v yabai 2>/dev/null || true)"
    fi
    if [ ! -x "$FOCUS_JQ_BIN" ]; then
        FOCUS_JQ_BIN="$(command -v jq 2>/dev/null || true)"
    fi

    [ -n "$FOCUS_YABAI_BIN" ] && [ -n "$FOCUS_JQ_BIN" ]
}

focus_ensure_state_dir() {
    mkdir -p "$FOCUS_STATE_DIR/displays" "$FOCUS_STATE_DIR/windows"
}

focus_is_number() {
    case "${1:-}" in
        '' | *[!0-9]*) return 1 ;;
        *) return 0 ;;
    esac
}

focus_atomic_write() {
    focus_write_path="$1"
    focus_write_value="${2:-}"
    focus_write_tmp="$(mktemp "${focus_write_path}.tmp.XXXXXX")" || return 1
    printf '%s\n' "$focus_write_value" >"$focus_write_tmp"
    mv -f "$focus_write_tmp" "$focus_write_path"
}

focus_display_key() {
    focus_key_index="$1"
    "$FOCUS_YABAI_BIN" -m query --displays 2>/dev/null |
        "$FOCUS_JQ_BIN" -r --argjson display "$focus_key_index" \
            '.[] | select(.index == $display) | .id' |
        head -n 1
}

focus_display_key_from_json() {
    focus_key_json="$1"
    focus_key_index="$2"
    printf '%s\n' "$focus_key_json" |
        "$FOCUS_JQ_BIN" -r --argjson display "$focus_key_index" \
            '.[] | select(.index == $display) | .id' |
        head -n 1
}

focus_normal_space() {
    focus_normal_display="$1"
    "$FOCUS_YABAI_BIN" -m query --spaces 2>/dev/null |
        "$FOCUS_JQ_BIN" -r --argjson display "$focus_normal_display" \
            '[
                .[]
                | select(
                    .display == $display
                    and ."is-native-fullscreen" == false
                )
            ]
            | sort_by(.index)
            | .[0].index // empty'
}

focus_normal_space_from_json() {
    focus_normal_json="$1"
    focus_normal_display="$2"
    printf '%s\n' "$focus_normal_json" |
        "$FOCUS_JQ_BIN" -r --argjson display "$focus_normal_display" \
            '[
                .[]
                | select(
                    .display == $display
                    and ."is-native-fullscreen" == false
                )
            ]
            | sort_by(.index)
            | .[0].index // empty'
}

focus_display_candidates_from_json() {
    focus_candidates_windows_json="$1"
    focus_candidates_display="$2"
    focus_candidates_normal_space="$3"
    [ -n "$focus_candidates_normal_space" ] ||
        focus_candidates_normal_space=0

    printf '%s\n' "$focus_candidates_windows_json" |
        "$FOCUS_JQ_BIN" -L "$FOCUS_JQ_LIB" -c \
            --argjson display "$focus_candidates_display" \
            --argjson normal_space "$focus_candidates_normal_space" \
            'include "focus-window";
            [
                .[]
                | select(
                    .display == $display
                    and yabai_is_visible_focus_window
                    and (
                        .space == $normal_space
                        or ."is-native-fullscreen" == true
                    )
                )
                | {
                    id,
                    space,
                    native: ."is-native-fullscreen",
                    center_x: (.frame.x + (.frame.w / 2)),
                    center_y: (.frame.y + (.frame.h / 2)),
                    frame
                }
            ]
            | sort_by(
                if .native then 1 else 0 end,
                if .native then .space else .frame.y end,
                if .native then 0 else .frame.x end,
                .id
            )
            | map(del(.frame))'
}

focus_display_candidates() {
    focus_candidates_display="$1"
    focus_candidates_normal_space="$(focus_normal_space "$focus_candidates_display")"
    focus_candidates_windows_json="$(
        "$FOCUS_YABAI_BIN" -m query --windows 2>/dev/null
    )" || return 1
    focus_display_candidates_from_json \
        "$focus_candidates_windows_json" \
        "$focus_candidates_display" \
        "$focus_candidates_normal_space"
}

focus_normal_candidates() {
    focus_display_candidates "$1" |
        "$FOCUS_JQ_BIN" -c '[.[] | select(.native == false)]'
}

focus_active_display_from_json() {
    focus_active_displays_json="$1"
    focus_active_file="$FOCUS_STATE_DIR/active-display"
    [ -f "$focus_active_file" ] || return 1

    IFS='	' read -r \
        focus_active_key \
        focus_active_index \
        <"$focus_active_file"
    focus_is_number "$focus_active_key" || return 1
    focus_is_number "$focus_active_index" || return 1

    if printf '%s\n' "$focus_active_displays_json" |
        "$FOCUS_JQ_BIN" -e \
            --argjson key "$focus_active_key" \
            --argjson display "$focus_active_index" \
            'any(.[]; .id == $key and .index == $display)' >/dev/null
    then
        printf '%s\n' "$focus_active_index"
        return 0
    fi

    rm -f "$focus_active_file"
    return 1
}

focus_display_memory() {
    focus_memory_display_key="$1"
    focus_memory_kind="$2"
    case "$focus_memory_kind" in
        candidate | normal) ;;
        *) return 1 ;;
    esac

    focus_memory_file="$FOCUS_STATE_DIR/displays/$focus_memory_display_key.$focus_memory_kind"
    [ -f "$focus_memory_file" ] || return 1
    sed -n '1p' "$focus_memory_file"
}

focus_remember_candidate() {
    focus_remember_display_key="$1"
    focus_remember_display_index="$2"
    focus_remember_window="$3"
    focus_remember_native="$4"

    focus_atomic_write \
        "$FOCUS_STATE_DIR/active-display" \
        "$focus_remember_display_key	$focus_remember_display_index"
    focus_atomic_write \
        "$FOCUS_STATE_DIR/displays/$focus_remember_display_key.candidate" \
        "$focus_remember_window"

    if [ "$focus_remember_native" = false ]; then
        focus_atomic_write \
            "$FOCUS_STATE_DIR/displays/$focus_remember_display_key.normal" \
            "$focus_remember_window"
    fi
}

focus_remember_display() {
    focus_remember_display_key="$1"
    focus_remember_display_index="$2"
    focus_atomic_write \
        "$FOCUS_STATE_DIR/active-display" \
        "$focus_remember_display_key	$focus_remember_display_index"
}

focus_wait_for_space() {
    focus_expected_space="$1"
    focus_wait_attempt=0

    while [ "$focus_wait_attempt" -lt "$FOCUS_TRANSITION_ATTEMPTS" ]; do
        focus_actual_space="$(
            "$FOCUS_YABAI_BIN" -m query --spaces 2>/dev/null |
                "$FOCUS_JQ_BIN" -r \
                    '.[] | select(."has-focus") | .index' |
                head -n 1
        )"
        [ "$focus_actual_space" = "$focus_expected_space" ] && return 0
        focus_wait_attempt=$((focus_wait_attempt + 1))
        sleep "$FOCUS_POLL_INTERVAL"
    done

    return 1
}

focus_wait_for_display() {
    focus_expected_display="$1"
    focus_max_attempts="${2:-$FOCUS_TRANSITION_ATTEMPTS}"
    focus_wait_attempt=0

    while [ "$focus_wait_attempt" -lt "$focus_max_attempts" ]; do
        focus_actual_display="$(
            "$FOCUS_YABAI_BIN" -m query --displays 2>/dev/null |
                "$FOCUS_JQ_BIN" -r \
                    '.[] | select(."has-focus") | .index' |
                head -n 1
        )"
        [ "$focus_actual_display" = "$focus_expected_display" ] && return 0
        focus_wait_attempt=$((focus_wait_attempt + 1))
        sleep "$FOCUS_POLL_INTERVAL"
    done

    return 1
}

focus_wait_for_window() {
    focus_expected_window="$1"
    focus_wait_attempt=0

    while [ "$focus_wait_attempt" -lt "$FOCUS_TRANSITION_ATTEMPTS" ]; do
        focus_has_focus="$(
            "$FOCUS_YABAI_BIN" -m query --windows --window \
                "$focus_expected_window" 2>/dev/null |
                "$FOCUS_JQ_BIN" -r '."has-focus" // false' 2>/dev/null
        )"
        [ "$focus_has_focus" = true ] && return 0
        focus_wait_attempt=$((focus_wait_attempt + 1))
        sleep "$FOCUS_POLL_INTERVAL"
    done

    return 1
}

focus_warp_pointer() {
    focus_warp_x="$1"
    focus_warp_y="$2"

    if [ -x "$FOCUS_POINTER_BIN" ]; then
        "$FOCUS_POINTER_BIN" "$focus_warp_x" "$focus_warp_y"
        return
    fi

    [ -x "$FOCUS_OSASCRIPT_BIN" ] || return 1
    "$FOCUS_OSASCRIPT_BIN" -l JavaScript -e \
        "ObjC.import('CoreGraphics'); $.CGWarpMouseCursorPosition({x: $focus_warp_x, y: $focus_warp_y});" \
        >/dev/null 2>&1
}

focus_center_coordinates() {
    focus_center_x="$1"
    focus_center_y="$2"
    focus_center_token="$3"
    focus_center_retry="${4:-false}"

    focus_atomic_write \
        "$FOCUS_STATE_DIR/pointer-target" \
        "$focus_center_token" || true
    focus_warp_pointer "$focus_center_x" "$focus_center_y" || return 1

    if [ "$focus_center_retry" = true ] && [ -x "$FOCUS_POINTER_BIN" ]; then
        (
            sleep 0.10
            focus_current_token="$(
                sed -n '1p' "$FOCUS_STATE_DIR/pointer-target"
            )"
            if [ "$focus_current_token" = "$focus_center_token" ]; then
                "$FOCUS_POINTER_BIN" "$focus_center_x" "$focus_center_y"
            fi
        ) >/dev/null 2>&1 &
    fi
}

focus_center_window() {
    focus_center_window_id="$1"
    focus_center_retry="${2:-false}"
    focus_center_coordinates="$(
        "$FOCUS_YABAI_BIN" -m query --windows --window \
            "$focus_center_window_id" 2>/dev/null |
            "$FOCUS_JQ_BIN" -r \
                '[
                    .frame.x + (.frame.w / 2),
                    .frame.y + (.frame.h / 2)
                ]
                | @tsv' 2>/dev/null
    )"
    [ -n "$focus_center_coordinates" ] || return 1

    focus_center_x="$(
        printf '%s\n' "$focus_center_coordinates" |
            cut -f 1
    )"
    focus_center_y="$(
        printf '%s\n' "$focus_center_coordinates" |
            cut -f 2
    )"

    focus_center_coordinates \
        "$focus_center_x" \
        "$focus_center_y" \
        "window:$focus_center_window_id" \
        "$focus_center_retry"
}

focus_activate_window() {
    focus_target_window="$1"
    focus_target_space="$2"
    focus_current_space="${3:-}"
    focus_cached_center_x="${4:-}"
    focus_cached_center_y="${5:-}"
    focus_changed_space=false

    if [ -z "$focus_current_space" ]; then
        focus_current_space="$(
            "$FOCUS_YABAI_BIN" -m query --spaces 2>/dev/null |
                "$FOCUS_JQ_BIN" -r \
                    '.[] | select(."has-focus") | .index' |
                head -n 1
        )"
    fi

    if [ "$focus_current_space" != "$focus_target_space" ]; then
        focus_changed_space=true
        "$FOCUS_YABAI_BIN" -m space --focus "$focus_target_space" \
            >/dev/null 2>&1 || return 1
        focus_wait_for_space "$focus_target_space" || return 1
    fi

    "$FOCUS_YABAI_BIN" -m window "$focus_target_window" --focus \
        >/dev/null 2>&1 || return 1
    focus_wait_for_window "$focus_target_window" || return 1

    # Native-fullscreen activation can make the destination window focused
    # before yabai processes window --focus, so mouse_follows_focus may not
    # emit movement. Warp immediately after confirmation and schedule a
    # non-blocking retry when a native Space transition occurred.
    if [ -n "$focus_cached_center_x" ] && [ -n "$focus_cached_center_y" ]; then
        focus_center_coordinates \
            "$focus_cached_center_x" \
            "$focus_cached_center_y" \
            "window:$focus_target_window" \
            "$focus_changed_space" || true
    else
        focus_center_window "$focus_target_window" "$focus_changed_space" ||
            true
    fi
    return 0
}

focus_center_display() {
    focus_center_index="$1"
    [ -x "$FOCUS_OSASCRIPT_BIN" ] || return 1

    focus_center_coordinates="$(
        "$FOCUS_YABAI_BIN" -m query --displays 2>/dev/null |
            "$FOCUS_JQ_BIN" -r --argjson display "$focus_center_index" \
                '.[] | select(.index == $display)
                | [
                    .frame.x + (.frame.w / 2),
                    .frame.y + (.frame.h / 2)
                ]
                | @tsv' |
            head -n 1
    )"
    [ -n "$focus_center_coordinates" ] || return 1

    focus_center_x="$(printf '%s\n' "$focus_center_coordinates" | cut -f 1)"
    focus_center_y="$(printf '%s\n' "$focus_center_coordinates" | cut -f 2)"

    focus_center_coordinates \
        "$focus_center_x" \
        "$focus_center_y" \
        "display:$focus_center_index"
}

focus_activate_empty_display() {
    focus_empty_display="$1"
    focus_empty_center_x="${2:-}"
    focus_empty_center_y="${3:-}"

    # Focusing a normal Space by Mission Control index can change the active
    # native-fullscreen Space on another display. Target the display itself.
    # Finder's desktop may be disabled, so verification is deliberately brief
    # and pointer placement remains the empty-display fallback.
    "$FOCUS_YABAI_BIN" -m display --focus "$focus_empty_display" \
        >/dev/null 2>&1 || true
    focus_wait_for_display "$focus_empty_display" 5 || true

    if [ -n "$focus_empty_center_x" ] && [ -n "$focus_empty_center_y" ]; then
        focus_center_coordinates \
            "$focus_empty_center_x" \
            "$focus_empty_center_y" \
            "display:$focus_empty_display"
    else
        focus_center_display "$focus_empty_display"
    fi
}

focus_acquire_lock() {
    focus_lock_dir="$FOCUS_STATE_DIR/focus.lock"
    focus_lock_attempt=0
    focus_lock_unowned_attempts=0
    focus_ensure_state_dir || return 1

    while ! mkdir "$focus_lock_dir" 2>/dev/null; do
        focus_lock_pid=""
        if [ -f "$focus_lock_dir/pid" ]; then
            focus_lock_pid="$(sed -n '1p' "$focus_lock_dir/pid")"
        fi

        if focus_is_number "$focus_lock_pid"; then
            focus_lock_unowned_attempts=0
        else
            # mkdir publishes the lock before its owner can write pid. Give
            # that short initialization window time to finish instead of
            # deleting a live lock out from under its owner.
            if [ "$focus_lock_unowned_attempts" -lt 5 ]; then
                focus_lock_unowned_attempts=$((focus_lock_unowned_attempts + 1))
                focus_lock_attempt=$((focus_lock_attempt + 1))
                sleep "$FOCUS_POLL_INTERVAL"
                continue
            fi
        fi

        if ! focus_is_number "$focus_lock_pid" ||
            ! kill -0 "$focus_lock_pid" 2>/dev/null
        then
            rm -f "$focus_lock_dir/pid"
            rmdir "$focus_lock_dir" 2>/dev/null || true
            focus_lock_unowned_attempts=0
            continue
        fi

        [ "$focus_lock_attempt" -lt "$FOCUS_TRANSITION_ATTEMPTS" ] || return 1
        focus_lock_attempt=$((focus_lock_attempt + 1))
        sleep "$FOCUS_POLL_INTERVAL"
    done

    if ! printf '%s\n' "$$" >"$focus_lock_dir/pid"; then
        rmdir "$focus_lock_dir" 2>/dev/null || true
        return 1
    fi
    FOCUS_LOCK_DIR="$focus_lock_dir"
}

focus_release_lock() {
    [ -n "${FOCUS_LOCK_DIR:-}" ] || return 0
    rm -f "$FOCUS_LOCK_DIR/pid"
    rmdir "$FOCUS_LOCK_DIR" 2>/dev/null || true
    FOCUS_LOCK_DIR=""
}
