#!/bin/sh
# shellcheck source-path=SCRIPTDIR

set -u

window_id="${1:-}"
creation_mode="${2:-}"
script_dir="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"

# shellcheck source=focus-lib.sh
. "$script_dir/focus-lib.sh"

focus_is_number "$window_id" || exit 0
focus_resolve_tools || exit 1
focus_ensure_state_dir || exit 1
CREATION_ATTEMPTS="${YABAI_CREATION_ATTEMPTS:-25}"

if [ "$creation_mode" = created ]; then
    # A creation event changes row structure even when no relocation is
    # necessary. Run this once, after any placement or float transition.
    trap '"$script_dir/focus-memory.sh" snapshot-window "$window_id" >/dev/null 2>&1 || true' 0
fi

attempt=0
window_json=""
while [ "$attempt" -lt "$CREATION_ATTEMPTS" ]; do
    window_json="$(
        "$FOCUS_YABAI_BIN" -m query --windows --window \
            "$window_id" 2>/dev/null
    )" && break
    attempt=$((attempt + 1))
    sleep "$FOCUS_POLL_INTERVAL"
done
[ -n "$window_json" ] || exit 0

window_details="$(
    printf '%s\n' "$window_json" |
        "$FOCUS_JQ_BIN" -L "$FOCUS_JQ_LIB" -r \
            'include "focus-window";
            [
                yabai_is_normal_window,
                yabai_should_float_as_dialog,
                (."has-focus" // false),
                .space,
                .display,
                (."is-floating" // false)
            ]
            | @tsv'
)"
[ -n "$window_details" ] || exit 0
IFS='	' read -r \
    is_eligible \
    should_float \
    was_focused \
    current_space \
    window_display \
    is_floating <<EOF
$window_details
EOF

if [ "$creation_mode" = created ] &&
    [ "$is_floating" != true ] &&
    [ "$should_float" = true ]
then
    "$FOCUS_YABAI_BIN" -m window "$window_id" --toggle float \
        >/dev/null 2>&1 || true
fi

[ "$is_eligible" = true ] || exit 0

displays_json="$("$FOCUS_YABAI_BIN" -m query --displays 2>/dev/null)" ||
    exit 0
spaces_json="$("$FOCUS_YABAI_BIN" -m query --spaces 2>/dev/null)" ||
    exit 0

target_display="$(
    focus_active_display_from_json "$displays_json" 2>/dev/null || true
)"
if ! focus_is_number "$target_display"; then
    target_display="$(
        printf '%s\n' "$displays_json" |
            "$FOCUS_JQ_BIN" -r \
                '.[] | select(."has-focus") | .index' |
            head -n 1
    )"
fi
if ! focus_is_number "$target_display"; then
    target_display="$window_display"
fi

target_display_key="$(
    focus_display_key_from_json "$displays_json" "$target_display"
)"
[ -n "$target_display_key" ] || exit 0
target_space="$(
    focus_normal_space_from_json "$spaces_json" "$target_display"
)"
[ -n "$target_space" ] || exit 0
[ "$current_space" != "$target_space" ] || exit 0

"$FOCUS_YABAI_BIN" -m window "$window_id" --space "$target_space" \
    >/dev/null 2>&1 || exit 0

attempt=0
while [ "$attempt" -lt "$CREATION_ATTEMPTS" ]; do
    current_space="$(
        "$FOCUS_YABAI_BIN" -m query --windows --window \
            "$window_id" 2>/dev/null |
            "$FOCUS_JQ_BIN" -r '.space // empty' 2>/dev/null
    )"
    [ "$current_space" = "$target_space" ] && break
    attempt=$((attempt + 1))
    sleep "$FOCUS_POLL_INTERVAL"
done
[ "$current_space" = "$target_space" ] || exit 0

if [ "$was_focused" = true ] &&
    focus_activate_window "$window_id" "$target_space"
then
    focus_remember_candidate \
        "$target_display_key" \
        "$target_display" \
        "$window_id" \
        false || true
fi
