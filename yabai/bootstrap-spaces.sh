#!/bin/sh
# shellcheck disable=SC2016 # jq variables are intentionally single-quoted.

set -u

YABAI_BIN="${YABAI_BIN:-/opt/homebrew/bin/yabai}"
JQ_BIN="${JQ_BIN:-/opt/homebrew/bin/jq}"

if [ ! -x "$YABAI_BIN" ]; then
    YABAI_BIN="$(command -v yabai 2>/dev/null || true)"
fi
if [ ! -x "$JQ_BIN" ]; then
    JQ_BIN="$(command -v jq 2>/dev/null || true)"
fi

if [ -z "$YABAI_BIN" ] || [ -z "$JQ_BIN" ]; then
    printf 'bootstrap-spaces: yabai and jq are required\n' >&2
    exit 1
fi

displays_json="$("$YABAI_BIN" -m query --displays 2>/dev/null)" || exit 0
spaces_json="$("$YABAI_BIN" -m query --spaces 2>/dev/null)" || exit 0

# Space labels are deliberately unnecessary. Select each display's sole normal
# Space from the live topology, ordered by physical display position.
normal_spaces="$(
    "$JQ_BIN" -nr \
        --argjson displays "$displays_json" \
        --argjson spaces "$spaces_json" \
        '
        $displays
        | sort_by(.frame.x, .frame.y, .index)
        | to_entries[]
        | .key as $position
        | .value.index as $display
        | (
            [
                $spaces[]
                | select(
                    .display == $display
                    and ."is-native-fullscreen" == false
                )
            ]
            | sort_by(.index)
            | .[0].index // 0
        ) as $space
        | [
            $display,
            $space,
            (if $position == 0 then 30 else 16 end)
        ]
        | @tsv
        '
)"

printf '%s\n' "$normal_spaces" |
    while IFS='	' read -r display_index space_index top_padding; do
        [ -n "$display_index" ] || continue
        if [ "$space_index" = 0 ]; then
            printf 'bootstrap-spaces: display %s has no normal Space\n' \
                "$display_index" >&2
            continue
        fi

        "$YABAI_BIN" -m space "$space_index" --layout bsp
        "$YABAI_BIN" -m space "$space_index" \
            --padding "abs:${top_padding}:16:16:16"
        "$YABAI_BIN" -m space "$space_index" --gap abs:16
    done
