#!/bin/sh
# shellcheck disable=SC2016
# shellcheck source-path=SCRIPTDIR

set -u

direction="${1:-}"
script_dir="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"

# shellcheck source=focus-lib.sh
. "$script_dir/focus-lib.sh"

case "$direction" in
    next | prev) ;;
    *)
        printf 'Usage: move-display.sh <next|prev>\n' >&2
        exit 1
        ;;
esac

focus_resolve_tools || exit 1
focus_acquire_lock || exit 0
MOVE_NORMAL_ATTEMPTS="${YABAI_MOVE_NORMAL_ATTEMPTS:-10}"

# shellcheck disable=SC2329 # Invoked indirectly by the EXIT trap.
move_on_exit() {
    move_exit_status=$?
    focus_release_lock
    trap - 0
    exit "$move_exit_status"
}

trap move_on_exit 0
trap 'exit 1' 1 2 15

move_wait_for_normal() {
    move_wait_window="$1"
    move_wait_display="$2"
    move_wait_space="$3"
    move_wait_attempt=0

    while [ "$move_wait_attempt" -lt "$MOVE_NORMAL_ATTEMPTS" ]; do
        move_final_details="$(
            "$FOCUS_YABAI_BIN" -m query --windows --window \
                "$move_wait_window" 2>/dev/null |
                "$FOCUS_JQ_BIN" -r \
                    --argjson display "$move_wait_display" \
                    --argjson space "$move_wait_space" \
                    '[
                        (
                            .display == $display
                            and .space == $space
                            and ."is-native-fullscreen" == false
                        ),
                        (."has-focus" // false),
                        (.frame.x + (.frame.w / 2)),
                        (.frame.y + (.frame.h / 2))
                    ]
                    | @tsv' 2>/dev/null
        )"
        if [ -n "$move_final_details" ]; then
            IFS='	' read -r \
                move_arrived \
                move_has_focus \
                move_center_x \
                move_center_y <<EOF
$move_final_details
EOF
        else
            move_arrived=false
        fi

        if [ "$move_arrived" = true ]; then
            return 0
        fi

        move_wait_attempt=$((move_wait_attempt + 1))
        sleep "$FOCUS_POLL_INTERVAL"
    done

    return 1
}

move_wait_for_focus() {
    move_focus_window="$1"
    move_focus_attempt=0

    while [ "$move_focus_attempt" -lt "$MOVE_NORMAL_ATTEMPTS" ]; do
        move_focus_details="$(
            "$FOCUS_YABAI_BIN" -m query --windows --window \
                "$move_focus_window" 2>/dev/null |
                "$FOCUS_JQ_BIN" -r \
                    '[
                        (."has-focus" // false),
                        (.frame.x + (.frame.w / 2)),
                        (.frame.y + (.frame.h / 2))
                    ]
                    | @tsv' 2>/dev/null
        )"
        if [ -n "$move_focus_details" ]; then
            IFS='	' read -r \
                move_has_focus \
                move_center_x \
                move_center_y <<EOF
$move_focus_details
EOF
            [ "$move_has_focus" = true ] && return 0
        fi

        move_focus_attempt=$((move_focus_attempt + 1))
        sleep "$FOCUS_POLL_INTERVAL"
    done

    return 1
}

move_wait_for_native() {
    move_wait_window="$1"
    move_wait_display="$2"
    move_wait_native="$3"
    move_wait_attempt=0

    while [ "$move_wait_attempt" -lt "$FOCUS_TRANSITION_ATTEMPTS" ]; do
        if "$FOCUS_YABAI_BIN" -m query --windows --window \
            "$move_wait_window" 2>/dev/null |
            "$FOCUS_JQ_BIN" -e \
                --argjson display "$move_wait_display" \
                --argjson native "$move_wait_native" \
                '.display == $display
                and ."is-native-fullscreen" == $native' >/dev/null 2>&1
        then
            return 0
        fi

        move_wait_attempt=$((move_wait_attempt + 1))
        sleep "$FOCUS_POLL_INTERVAL"
    done

    return 1
}

move_restore_native() {
    [ "${restore_native:-false}" = true ] || return 0

    restore_current_display="$(
        "$FOCUS_YABAI_BIN" -m query --windows --window \
            "$window_id" 2>/dev/null |
            "$FOCUS_JQ_BIN" -r '.display // empty' 2>/dev/null
    )"
    if focus_is_number "$restore_current_display"; then
        restore_display="$restore_current_display"
    fi

    "$FOCUS_YABAI_BIN" -m window "$window_id" \
        --toggle native-fullscreen >/dev/null 2>&1 || return 1
    move_wait_for_native "$window_id" "$restore_display" true
}

move_fail() {
    printf 'move-display: %s\n' "$1" >&2
    move_restore_native || true
    exit 1
}

window_json="$(
    "$FOCUS_YABAI_BIN" -m query --windows --window 2>/dev/null
)" || exit 0
[ -n "$window_json" ] || exit 0

window_details="$(
    printf '%s\n' "$window_json" |
        "$FOCUS_JQ_BIN" -L "$FOCUS_JQ_LIB" -r \
            'include "focus-window";
            [
                .id,
                .display,
                (."is-native-fullscreen" // false),
                yabai_is_move_window
            ]
            | @tsv'
)"
[ -n "$window_details" ] || exit 0
IFS='	' read -r \
    window_id \
    source_display \
    was_native \
    is_move_window <<EOF
$window_details
EOF

focus_is_number "$window_id" || exit 0
focus_is_number "$source_display" || exit 0
if [ "$is_move_window" != true ]; then
    move_fail "focused window $window_id cannot be moved"
fi

displays_json="$(
    "$FOCUS_YABAI_BIN" -m query --displays 2>/dev/null
)" || exit 0
display_count="$(
    printf '%s\n' "$displays_json" |
        "$FOCUS_JQ_BIN" -r 'length'
)"
[ "$display_count" -gt 1 ] || exit 0

target_display="$(
    printf '%s\n' "$displays_json" |
        "$FOCUS_JQ_BIN" -r \
            --argjson current "$source_display" \
            --arg direction "$direction" \
            '
            sort_by(.frame.x, .frame.y, .index)
            | map(.index) as $displays
            | ($displays | index($current)) as $position
            | if $position == null or ($displays | length) < 2
              then empty
              elif $direction == "next"
              then $displays[(($position + 1) % ($displays | length))]
              else $displays[
                  (($position + ($displays | length) - 1)
                   % ($displays | length))
              ]
              end
            '
)"
focus_is_number "$target_display" ||
    move_fail "could not resolve the adjacent display"

spaces_json="$(
    "$FOCUS_YABAI_BIN" -m query --spaces 2>/dev/null
)" || move_fail "could not query Spaces"
target_space="$(
    focus_normal_space_from_json "$spaces_json" "$target_display"
)"
focus_is_number "$target_space" ||
    move_fail "display $target_display has no normal Space"

restore_native=false
restore_display="$source_display"
if [ "$was_native" = true ]; then
    "$FOCUS_YABAI_BIN" -m window "$window_id" \
        --toggle native-fullscreen >/dev/null 2>&1 ||
        move_fail "could not exit native fullscreen"
    move_wait_for_native "$window_id" "$source_display" false ||
        move_fail "timed out while exiting native fullscreen"
    restore_native=true
fi

"$FOCUS_YABAI_BIN" -m window "$window_id" \
    --space "$target_space" --focus >/dev/null 2>&1 ||
    move_fail "could not move window $window_id to display $target_display"
move_wait_for_normal "$window_id" "$target_display" "$target_space" ||
    move_fail "window $window_id did not reach display $target_display"

# Reaching the destination commits the operation. A window that started in
# native fullscreen intentionally remains a normal window there; restoring
# fullscreen is only the rollback for a failed move.
restore_native=false

if [ "$move_has_focus" != true ]; then
    "$FOCUS_YABAI_BIN" -m window "$window_id" --focus >/dev/null 2>&1 ||
        move_fail "window $window_id moved but could not be focused"
    if ! move_wait_for_focus "$window_id"; then
        # The move itself is committed. Do not undo it merely because macOS
        # took too long to publish keyboard focus.
        "$script_dir/focus-memory.sh" relocate \
            "$window_id" \
            "$source_display" >/dev/null 2>&1 || true
        printf '%s\n' \
            "move-display: window $window_id moved but focus was not confirmed" \
            >&2
        exit 1
    fi
fi

# Cross-display Space transitions can beat mouse_follows_focus. Center from
# the final Yabai-reported frame and schedule the helper's guarded retry.
focus_center_coordinates \
    "$move_center_x" \
    "$move_center_y" \
    "window:$window_id" \
    true || true

# The move is no longer in an intermediate state. Let a following focus
# shortcut start while the heavier row snapshots are refreshed.
focus_release_lock

# Remove stale source-display references, snapshot both normal Spaces, and
# record the moved window as the destination display's focused candidate.
"$script_dir/focus-memory.sh" relocate \
    "$window_id" \
    "$source_display" >/dev/null 2>&1 || true

exit 0
