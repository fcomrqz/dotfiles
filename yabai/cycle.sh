#!/bin/sh
# shellcheck disable=SC2016 # jq variables are intentionally single-quoted.

set -u

if [ "$#" -lt 2 ]; then
    printf 'Usage: cycle.sh <yabai-app-regex> <bundle-id> [launch-name]\n' >&2
    exit 1
fi

app_pattern="$1"
bundle_id="$2"
launch_name="${3:-}"
script_dir="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
YABAI_BIN="${YABAI_BIN:-/opt/homebrew/bin/yabai}"
JQ_BIN="${JQ_BIN:-/opt/homebrew/bin/jq}"

if [ ! -x "$YABAI_BIN" ]; then
    YABAI_BIN="$(command -v yabai 2>/dev/null || true)"
fi
if [ ! -x "$JQ_BIN" ]; then
    JQ_BIN="$(command -v jq 2>/dev/null || true)"
fi

if [ -z "$YABAI_BIN" ] || [ -z "$JQ_BIN" ]; then
    printf 'cycle: yabai and jq are required\n' >&2
    exit 1
fi

windows_json="$("$YABAI_BIN" -m query --windows 2>/dev/null)" ||
    windows_json='[]'
next_id="$(
    printf '%s\n' "$windows_json" |
        "$JQ_BIN" -L "$script_dir" -r --arg pattern "$app_pattern" \
            'include "focus-window";
            . as $windows
            | [
                $windows[]
                | select(
                    (.app | test($pattern; "i"))
                    and yabai_is_focus_window
                )
            ] as $candidates
            | (
                [
                    $windows[]
                    | select(."has-focus" == true)
                    | .id
                ][0] // null
            ) as $current
            | if ($candidates | length) == 0
              then empty
              else
                  ($candidates | map(.id)) as $ids
                  | ($ids | index($current)) as $position
                  | if $position == null
                    then $ids[0]
                    else $ids[(($position + 1) % ($ids | length))]
                    end
              end
            '
)"

if [ -z "$next_id" ]; then
    if ! open -b "$bundle_id" 2>/dev/null && [ -n "$launch_name" ]; then
        open -a "$launch_name"
    fi
    exit 0
fi

"$YABAI_BIN" -m window "$next_id" --focus
