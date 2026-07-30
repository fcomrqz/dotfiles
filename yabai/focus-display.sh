#!/bin/sh
# shellcheck disable=SC2016
# shellcheck source-path=SCRIPTDIR

set -u

requested_display="${1:-}"
script_dir="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"

# shellcheck source=focus-lib.sh
. "$script_dir/focus-lib.sh"

if ! focus_is_number "$requested_display"; then
    printf 'Usage: focus-display.sh <horizontal-display-index>\n' >&2
    exit 1
fi

focus_resolve_tools || exit 1
focus_acquire_lock || exit 0
trap 'focus_release_lock' 0
trap 'exit 1' 1 2 15

displays_json="$("$FOCUS_YABAI_BIN" -m query --displays 2>/dev/null)" ||
    exit 0

active_display_key=0
active_display_index=0
active_display_file="$FOCUS_STATE_DIR/active-display"
active_display_file_exists=false
if [ -f "$active_display_file" ]; then
    active_display_file_exists=true
    IFS='	' read -r \
        remembered_display_key \
        remembered_display_index \
        <"$active_display_file"
    if focus_is_number "$remembered_display_key" &&
        focus_is_number "$remembered_display_index"
    then
        active_display_key="$remembered_display_key"
        active_display_index="$remembered_display_index"
    fi
fi

display_details="$(
    printf '%s\n' "$displays_json" |
        "$FOCUS_JQ_BIN" -r \
            --argjson requested "$requested_display" \
            --argjson active_key "$active_display_key" \
            --argjson active_index "$active_display_index" \
            '
            . as $displays
            | (
                if ($displays | length) == 1 and $requested == 2
                then $displays[0].index
                elif ($displays | length) == 3
                    and any($displays[]; .index == $requested)
                then $requested
                else null
                end
            ) as $target_index
            | select($target_index != null)
            | (
                $displays[]
                | select(.index == $target_index)
            ) as $target
            | (
                any(
                    $displays[];
                    .id == $active_key and .index == $active_index
                )
            ) as $active_valid
            | (
                if $active_valid
                then $active_index
                else (
                    [
                        $displays[]
                        | select(."has-focus" == true)
                        | .index
                    ][0] // 0
                )
                end
            ) as $logical_focus
            | [
                $target.index,
                $target.id,
                ($target.frame.x + ($target.frame.w / 2)),
                ($target.frame.y + ($target.frame.h / 2)),
                $logical_focus,
                $active_valid
            ]
            | @tsv
            '
)"
[ -n "$display_details" ] || exit 0
IFS='	' read -r \
    target_display \
    target_display_key \
    target_center_x \
    target_center_y \
    focused_display \
    active_display_valid <<EOF
$display_details
EOF

if [ "$active_display_file_exists" = true ] &&
    [ "$active_display_valid" != true ]
then
    rm -f "$active_display_file"
fi

spaces_json="$("$FOCUS_YABAI_BIN" -m query --spaces 2>/dev/null)" ||
    exit 0
windows_json="$("$FOCUS_YABAI_BIN" -m query --windows 2>/dev/null)" ||
    exit 0

space_details="$(
    printf '%s\n' "$spaces_json" |
        "$FOCUS_JQ_BIN" -r \
            --argjson display "$target_display" \
            '
            [
                (
                    [
                        .[]
                        | select(
                            .display == $display
                            and ."is-native-fullscreen" == false
                        )
                    ]
                    | sort_by(.index)
                    | .[0].index // 0
                ),
                (
                    [
                        .[]
                        | select(."has-focus" == true)
                        | .index
                    ][0] // 0
                )
            ]
            | @tsv
            '
)"
[ -n "$space_details" ] || exit 0
IFS='	' read -r normal_space focused_space <<EOF
$space_details
EOF

if [ "$focused_display" != "$target_display" ]; then
    switching_display=true
    remembered_window="$(
        focus_display_memory "$target_display_key" candidate \
            2>/dev/null || true
    )"
    focus_is_number "$remembered_window" || remembered_window=0
else
    switching_display=false
    remembered_window=0
fi

selection_details="$(
    printf '%s\n' "$windows_json" |
        "$FOCUS_JQ_BIN" -L "$FOCUS_JQ_LIB" -r \
            --argjson display "$target_display" \
            --argjson normal_space "$normal_space" \
            --argjson switching "$switching_display" \
            --argjson remembered "$remembered_window" \
            'include "focus-window";
            . as $windows
            | [
                $windows[]
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
            ) as $candidates
            | (
                [
                    $windows[]
                    | select(."has-focus" == true)
                    | .id
                ][0] // 0
            ) as $focused
            | ($candidates | length) as $count
            | (
                if $count == 0
                then null
                elif $switching
                then
                    (
                        $candidates
                        | map(.id)
                        | index($remembered)
                    ) as $remembered_position
                    | if $remembered_position == null
                      then $candidates[0]
                      else $candidates[$remembered_position]
                      end
                elif $count == 1 and $focused == $candidates[0].id
                then null
                else
                    (
                        $candidates
                        | map(.id)
                        | index($focused)
                    ) as $focused_position
                    | if $focused_position == null
                      then $candidates[0]
                      else $candidates[
                          (($focused_position + 1) % $count)
                      ]
                      end
                end
            ) as $selected
            | [
                $count,
                ($selected.id // 0),
                ($selected.space // 0),
                ($selected.native // false),
                ($selected.center_x // 0),
                ($selected.center_y // 0)
            ]
            | @tsv
            '
)"
[ -n "$selection_details" ] || exit 0
IFS='	' read -r \
    candidate_count \
    selected_window \
    selected_space \
    selected_native \
    selected_center_x \
    selected_center_y <<EOF
$selection_details
EOF

if [ "$candidate_count" -eq 0 ]; then
    focus_activate_empty_display \
        "$target_display" \
        "$target_center_x" \
        "$target_center_y" || true
    focus_remember_display "$target_display_key" "$target_display" || true
    exit 0
fi

[ "$selected_window" -ne 0 ] || exit 0

if focus_activate_window \
    "$selected_window" \
    "$selected_space" \
    "$focused_space" \
    "$selected_center_x" \
    "$selected_center_y"
then
    focus_remember_candidate \
        "$target_display_key" \
        "$target_display" \
        "$selected_window" \
        "$selected_native" || true
fi
