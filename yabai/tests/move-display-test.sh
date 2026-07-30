#!/bin/sh

set -eu

test_dir="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
yabai_dir="$(dirname "$test_dir")"
jq_bin="${JQ_BIN:-/opt/homebrew/bin/jq}"
mock_yabai="$test_dir/mock-yabai.sh"
mock_osascript="$test_dir/mock-osascript.sh"
test_tmp="$(mktemp -d "${TMPDIR:-/tmp}/yabai-move-tests.XXXXXX")"
state_file="$test_tmp/state.json"
log_file="$test_tmp/yabai.log"
focus_state="$test_tmp/focus-state"
passed=0

trap 'rm -rf "$test_tmp"' EXIT HUP INT TERM

movement_state='
{
  "displays": [
    {"id": 501, "uuid": "RIGHT", "index": 1, "frame": {"x": 200, "y": 0, "w": 100, "h": 100}, "has-focus": false},
    {"id": 502, "uuid": "CENTER", "index": 2, "frame": {"x": 100, "y": 0, "w": 100, "h": 100}, "has-focus": true},
    {"id": 503, "uuid": "LEFT", "index": 3, "frame": {"x": 0, "y": 0, "w": 100, "h": 100}, "has-focus": false}
  ],
  "spaces": [
    {"id": 611, "index": 11, "label": "aero-2", "display": 1, "has-focus": false, "is-native-fullscreen": false},
    {"id": 612, "index": 12, "label": "aero-3", "display": 2, "has-focus": true, "is-native-fullscreen": false},
    {"id": 613, "index": 13, "label": "", "display": 3, "has-focus": false, "is-native-fullscreen": false}
  ],
  "windows": [
    {"id": 101, "pid": 10, "app": "Zed", "title": "move me", "role": "AXWindow", "subrole": "AXStandardWindow", "root-window": true, "display": 2, "space": 12, "frame": {"x": 100, "y": 35, "w": 100, "h": 30}, "has-focus": true, "is-visible": true, "is-minimized": false, "is-hidden": false, "is-floating": false, "is-native-fullscreen": false, "can-move": true},
    {"id": 201, "pid": 20, "app": "Mail", "title": "right", "role": "AXWindow", "subrole": "AXStandardWindow", "root-window": true, "display": 1, "space": 11, "frame": {"x": 200, "y": 0, "w": 100, "h": 30}, "has-focus": false, "is-visible": true, "is-minimized": false, "is-hidden": false, "is-floating": false, "is-native-fullscreen": false, "can-move": true},
    {"id": 301, "pid": 30, "app": "Safari", "title": "left", "role": "AXWindow", "subrole": "AXStandardWindow", "root-window": true, "display": 3, "space": 13, "frame": {"x": 0, "y": 0, "w": 100, "h": 30}, "has-focus": false, "is-visible": true, "is-minimized": false, "is-hidden": false, "is-floating": false, "is-native-fullscreen": false, "can-move": true}
  ]
}'

reset_case() {
    printf '%s\n' "$movement_state" >"$state_file"
    : >"$log_file"
    rm -rf "$focus_state"
    mkdir -p "$focus_state"
}

run_script() {
    YABAI_BIN="$mock_yabai" \
        JQ_BIN="$jq_bin" \
        OSASCRIPT_BIN="$mock_osascript" \
        YABAI_FOCUS_STATE_DIR="$focus_state" \
        YABAI_FOCUS_POLL_INTERVAL=0 \
        MOCK_YABAI_STATE="$state_file" \
        MOCK_YABAI_LOG="$log_file" \
        MOCK_FAIL_WINDOW_SPACE="${MOCK_FAIL_WINDOW_SPACE:-0}" \
        "$@"
}

mutate_state() {
    mutate_tmp="$(mktemp "${state_file}.tmp.XXXXXX")"
    "$jq_bin" "$1" "$state_file" >"$mutate_tmp"
    mv -f "$mutate_tmp" "$state_file"
}

assert_log_has() {
    expected="$1"
    if ! grep -Fx "$expected" "$log_file" >/dev/null; then
        printf 'FAIL: expected log entry: %s\n' "$expected" >&2
        sed -n '1,260p' "$log_file" >&2
        exit 1
    fi
}

assert_log_lacks_pattern() {
    unexpected="$1"
    if grep -E "$unexpected" "$log_file" >/dev/null; then
        printf 'FAIL: unexpected log pattern: %s\n' "$unexpected" >&2
        sed -n '1,260p' "$log_file" >&2
        exit 1
    fi
}

assert_state() {
    filter="$1"
    description="$2"
    if ! "$jq_bin" -e "$filter" "$state_file" >/dev/null; then
        printf 'FAIL: %s\n' "$description" >&2
        "$jq_bin" . "$state_file" >&2
        exit 1
    fi
}

pass() {
    passed=$((passed + 1))
    printf 'ok %s - %s\n' "$passed" "$1"
}

# Physical position, rather than display index or stale label, selects right.
reset_case
run_script "$yabai_dir/focus-memory.sh" seed
: >"$log_file"
run_script "$yabai_dir/move-display.sh" next
assert_log_has 'window 101 --space 11 --focus'
assert_log_lacks_pattern 'aero-[123]'
assert_log_has_pattern='CGWarpMouseCursorPosition'
if ! grep -F "$assert_log_has_pattern" "$log_file" >/dev/null; then
    printf 'FAIL: pointer was not centered after movement\n' >&2
    exit 1
fi
assert_state \
    '.windows[] | select(.id == 101) | .display == 1 and .space == 11 and ."has-focus" == true' \
    'managed window did not move right'
if grep -Fx 101 "$focus_state/displays/502.order" >/dev/null; then
    printf 'FAIL: source display order still contains the moved window\n' >&2
    exit 1
fi
if [ "$(sed -n '1p' "$focus_state/active-display")" != '501	1' ]; then
    printf 'FAIL: destination display was not remembered\n' >&2
    exit 1
fi
pass 'managed window follows physical next display'

# Previous from the center means the physically left display and wraps.
reset_case
run_script "$yabai_dir/move-display.sh" prev
assert_log_has 'window 101 --space 13 --focus'
assert_state \
    '.windows[] | select(.id == 101) | .display == 3 and .space == 13' \
    'window did not move to the physical previous display'
: >"$log_file"
run_script "$yabai_dir/move-display.sh" prev
assert_log_has 'window 101 --space 11 --focus'
pass 'movement wraps in physical order'

# Floating windows take the same path and remain floating.
reset_case
mutate_state '
  .windows |= map(
    if .id == 101
    then ."is-floating" = true | .app = "Things"
    else .
    end
  )
'
run_script "$yabai_dir/move-display.sh" next
assert_log_has 'window 101 --space 11 --focus'
assert_state \
    '.windows[] | select(.id == 101) | .display == 1 and ."is-floating" == true' \
    'floating state was lost during movement'
pass 'floating window moves and stays floating'

# Focusable dialogs can be moved explicitly and retain their floating state.
reset_case
mutate_state '
  .windows |= map(
    if .id == 101
    then .subrole = "AXDialog"
        | ."is-floating" = true
        | .app = "Xcode"
        | .level = 0
    else .
    end
  )
'
run_script "$yabai_dir/move-display.sh" next
assert_log_has 'window 101 --space 11 --focus'
assert_state \
    '.windows[] | select(.id == 101) | .display == 1 and ."is-floating" == true' \
    'dialog floating state was lost during movement'
pass 'dialog moves and stays floating'

# Native fullscreen exits and remains a normal window on the target Space.
reset_case
mutate_state '
  .spaces |= map(."has-focus" = false)
  | .spaces += [{
      "id": 614,
      "index": 14,
      "label": "",
      "display": 2,
      "has-focus": true,
      "is-native-fullscreen": true
    }]
  | .windows |= map(
      if .id == 101
      then .space = 14
          | ."is-native-fullscreen" = true
          | ."can-move" = false
      else .
      end
    )
'
run_script "$yabai_dir/move-display.sh" next
toggle_count="$(
    grep -Fc 'window 101 --toggle native-fullscreen' "$log_file"
)"
if [ "$toggle_count" -ne 1 ]; then
    printf 'FAIL: expected one fullscreen toggle, got %s\n' \
        "$toggle_count" >&2
    exit 1
fi
assert_log_has 'window 101 --space 11 --focus'
assert_state \
    '.windows[] | select(.id == 101) | .display == 1 and .space == 11 and ."is-native-fullscreen" == false and ."has-focus" == true' \
    'native fullscreen did not become a normal destination window'
pass 'native fullscreen exits into destination normal Space'

# A nonmovable normal window fails without moving focus or the pointer.
reset_case
mutate_state '
  .windows |= map(
    if .id == 101 then ."can-move" = false else . end
  )
'
if run_script "$yabai_dir/move-display.sh" next 2>/dev/null; then
    printf 'FAIL: nonmovable window unexpectedly succeeded\n' >&2
    exit 1
fi
assert_log_lacks_pattern '^window 101 --space'
assert_log_lacks_pattern 'CGWarpMouseCursorPosition'
assert_state \
    '.windows[] | select(.id == 101) | .display == 2 and ."has-focus" == true' \
    'nonmovable window state changed'
pass 'nonmovable window leaves state untouched'

# Non-normal-level popups are app-owned surfaces, not movable user windows.
reset_case
mutate_state '
  .windows |= map(
    if .id == 101
    then .level = 3
        | ."can-move" = true
        | ."is-floating" = true
    else .
    end
  )
'
if run_script "$yabai_dir/move-display.sh" next 2>/dev/null; then
    printf 'FAIL: popup unexpectedly moved\n' >&2
    exit 1
fi
assert_log_lacks_pattern '^window 101 --space'
assert_log_lacks_pattern 'CGWarpMouseCursorPosition'
pass 'popup movement is ignored'

# A failed Yabai move does not center the pointer or update focus memory.
reset_case
run_script "$yabai_dir/focus-memory.sh" seed
active_before="$(sed -n '1p' "$focus_state/active-display")"
: >"$log_file"
if MOCK_FAIL_WINDOW_SPACE=1 \
    run_script "$yabai_dir/move-display.sh" next 2>/dev/null
then
    printf 'FAIL: failed Yabai movement unexpectedly succeeded\n' >&2
    exit 1
fi
assert_log_has 'window 101 --space 11 --focus'
assert_log_lacks_pattern 'CGWarpMouseCursorPosition'
assert_state \
    '.windows[] | select(.id == 101) | .display == 2 and ."has-focus" == true' \
    'failed movement changed the window'
if [ "$(sed -n '1p' "$focus_state/active-display")" != "$active_before" ]; then
    printf 'FAIL: failed movement changed display memory\n' >&2
    exit 1
fi
pass 'failed movement leaves pointer and memory untouched'

# One display is an intentional no-op.
reset_case
mutate_state '
  .displays = [.displays[] | select(.index == 2)]
  | .spaces = [.spaces[] | select(.display == 2)]
  | .windows = [.windows[] | select(.display == 2)]
'
run_script "$yabai_dir/move-display.sh" next
assert_log_lacks_pattern '^window 101 --space'
assert_log_lacks_pattern 'CGWarpMouseCursorPosition'
pass 'one display does nothing'

printf '1..%s\n' "$passed"
