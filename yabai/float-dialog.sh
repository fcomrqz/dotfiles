#!/bin/sh
# shellcheck source-path=SCRIPTDIR

set -u

window_id="${1:-}"
script_dir="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"

# shellcheck source=focus-lib.sh
. "$script_dir/focus-lib.sh"

focus_is_number "$window_id" || exit 0
focus_resolve_tools || exit 1

window_details="$(
    "$FOCUS_YABAI_BIN" -m query --windows --window \
        "$window_id" 2>/dev/null |
        "$FOCUS_JQ_BIN" -L "$FOCUS_JQ_LIB" -r \
            'include "focus-window";
            [
                (."is-floating" // false),
                yabai_should_float_as_dialog
            ]
            | @tsv' 2>/dev/null
)"
[ -n "$window_details" ] || exit 0
IFS='	' read -r is_floating should_float <<EOF
$window_details
EOF

if [ "$is_floating" != true ] && [ "$should_float" = true ]; then
    "$FOCUS_YABAI_BIN" -m window "$window_id" --toggle float
fi
