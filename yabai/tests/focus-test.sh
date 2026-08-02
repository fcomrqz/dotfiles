#!/bin/sh

set -eu

test_dir="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
yabai_dir="$(dirname "$test_dir")"
jq_bin="${JQ_BIN:-/opt/homebrew/bin/jq}"
mock_yabai="$test_dir/mock-yabai.sh"
mock_osascript="$test_dir/mock-osascript.sh"
test_tmp="$(mktemp -d "${TMPDIR:-/tmp}/yabai-focus-tests.XXXXXX")"
state_file="$test_tmp/state.json"
log_file="$test_tmp/yabai.log"
focus_state="$test_tmp/focus-state"
passed=0

trap 'rm -rf "$test_tmp"' EXIT HUP INT TERM

three_display_state='
{
  "displays": [
    {"id": 501, "uuid": "LEFT", "index": 1, "frame": {"x": -100, "y": 0, "w": 100, "h": 100}, "has-focus": true},
    {"id": 502, "uuid": "CENTER", "index": 2, "frame": {"x": 0, "y": 0, "w": 100, "h": 100}, "has-focus": false},
    {"id": 503, "uuid": "RIGHT", "index": 3, "frame": {"x": 100, "y": 0, "w": 100, "h": 100}, "has-focus": false}
  ],
  "spaces": [
    {"id": 601, "index": 1, "label": "aero-1", "display": 1, "has-focus": true, "is-native-fullscreen": false},
    {"id": 602, "index": 2, "label": "aero-3", "display": 2, "has-focus": false, "is-native-fullscreen": false},
    {"id": 603, "index": 3, "label": "aero-2", "display": 3, "has-focus": false, "is-native-fullscreen": false},
    {"id": 604, "index": 4, "label": "", "display": 1, "has-focus": false, "is-native-fullscreen": true}
  ],
  "windows": [
    {"id": 101, "pid": 10, "app": "Zed", "title": "one", "role": "AXWindow", "subrole": "AXStandardWindow", "root-window": true, "display": 1, "space": 1, "frame": {"x": -100, "y": 0, "w": 100, "h": 30}, "has-focus": true, "is-visible": true, "is-minimized": false, "is-hidden": false, "is-floating": false, "is-native-fullscreen": false},
    {"id": 104, "pid": 10, "app": "Zed", "title": "", "role": "AXWindow", "subrole": "AXSystemDialog", "root-window": true, "display": 1, "space": 1, "frame": {"x": -75, "y": 32, "w": 50, "h": 10}, "has-focus": false, "is-visible": true, "is-minimized": false, "is-hidden": false, "is-floating": true, "is-native-fullscreen": false},
    {"id": 102, "pid": 11, "app": "Safari", "title": "two", "role": "AXWindow", "subrole": "AXStandardWindow", "root-window": true, "display": 1, "space": 1, "frame": {"x": -100, "y": 35, "w": 100, "h": 30}, "has-focus": false, "is-visible": true, "is-minimized": false, "is-hidden": false, "is-floating": false, "is-native-fullscreen": false},
    {"id": 103, "pid": 12, "app": "Terminal", "title": "three", "role": "AXWindow", "subrole": "AXStandardWindow", "root-window": true, "display": 1, "space": 1, "frame": {"x": -100, "y": 70, "w": 100, "h": 30}, "has-focus": false, "is-visible": true, "is-minimized": false, "is-hidden": false, "is-floating": false, "is-native-fullscreen": false},
    {"id": 150, "pid": 20, "app": "Safari", "title": "fullscreen", "role": "AXWindow", "subrole": "AXStandardWindow", "root-window": true, "display": 1, "space": 4, "frame": {"x": -100, "y": 0, "w": 100, "h": 100}, "has-focus": false, "is-visible": false, "is-minimized": false, "is-hidden": false, "is-floating": false, "is-native-fullscreen": true},
    {"id": 201, "pid": 30, "app": "Mail", "title": "mail", "role": "AXWindow", "subrole": "AXStandardWindow", "root-window": true, "display": 2, "space": 2, "frame": {"x": 0, "y": 0, "w": 100, "h": 100}, "has-focus": false, "is-visible": true, "is-minimized": false, "is-hidden": false, "is-floating": false, "is-native-fullscreen": false}
  ]
}'

reset_case() {
    printf '%s\n' "$three_display_state" >"$state_file"
    : >"$log_file"
    rm -rf "$focus_state"
    mkdir -p "$focus_state"
}

run_script() {
    YABAI_BIN="$mock_yabai" \
        JQ_BIN="$jq_bin" \
        OSASCRIPT_BIN="$mock_osascript" \
        YABAI_FOCUS_STATE_DIR="$focus_state" \
        MOCK_YABAI_STATE="$state_file" \
        MOCK_YABAI_LOG="$log_file" \
        MOCK_IGNORE_DISPLAY_FOCUS="${MOCK_IGNORE_DISPLAY_FOCUS:-0}" \
        "$@"
}

mock_command() {
    MOCK_YABAI_STATE="$state_file" \
        MOCK_YABAI_LOG="$log_file" \
        JQ_BIN="$jq_bin" \
        "$mock_yabai" -m "$@"
}

mutate_state() {
    mutate_tmp="$(mktemp "${state_file}.tmp.XXXXXX")"
    "$jq_bin" "$1" "$state_file" >"$mutate_tmp"
    mv -f "$mutate_tmp" "$state_file"
}

clear_log() {
    : >"$log_file"
}

assert_log_has() {
    expected="$1"
    if ! grep -Fx -- "$expected" "$log_file" >/dev/null; then
        printf 'FAIL: expected log entry: %s\n' "$expected" >&2
        sed -n '1,240p' "$log_file" >&2
        exit 1
    fi
}

assert_log_lacks_pattern() {
    unexpected="$1"
    if grep -E "$unexpected" "$log_file" >/dev/null; then
        printf 'FAIL: unexpected log pattern: %s\n' "$unexpected" >&2
        sed -n '1,240p' "$log_file" >&2
        exit 1
    fi
}

assert_log_has_pattern() {
    expected="$1"
    if ! grep -E "$expected" "$log_file" >/dev/null; then
        printf 'FAIL: expected log pattern: %s\n' "$expected" >&2
        sed -n '1,240p' "$log_file" >&2
        exit 1
    fi
}

assert_pointer_warp() {
    expected_x="$1"
    expected_y="$2"
    assert_log_has \
        "-l JavaScript -e ObjC.import('CoreGraphics'); $.CGWarpMouseCursorPosition({x: $expected_x, y: $expected_y});"
}

pass() {
    passed=$((passed + 1))
    printf 'ok %s - %s\n' "$passed" "$1"
}

# Returning to a display restores its remembered window instead of cycling.
reset_case
run_script "$yabai_dir/focus-memory.sh" seed
mock_command window 201 --focus >/dev/null
clear_log
run_script "$yabai_dir/focus-display.sh" 1
assert_log_has 'window 101 --focus'
assert_log_lacks_pattern '^window 102 --focus$'
assert_pointer_warp -50 15
pass 'restore per-display focus'

# Selecting the focused display advances through normal rows.
reset_case
run_script "$yabai_dir/focus-display.sh" 1
assert_log_has 'window 102 --focus'
assert_log_lacks_pattern '^window 104 --focus$'
assert_pointer_warp -50 50
queries_before_focus="$(
    awk '
        /^query / { queries += 1 }
        /^window 102 --focus$/ { print queries; exit }
    ' "$log_file"
)"
if [ "$queries_before_focus" -ne 3 ]; then
    printf 'FAIL: expected 3 cached-snapshot queries before focus, got %s\n' \
        "$queries_before_focus" >&2
    exit 1
fi
pass 'cycle normal rows'

# Application cycling, display focus, and memory exclude dialogs, non-normal
# level popups, and nonmovable normal-looking windows.
reset_case
mutate_state '
  .windows += [
    {
      "id": 105,
      "pid": 10,
      "app": "Zed",
      "title": "always-on-top popup",
      "role": "AXWindow",
      "subrole": "AXStandardWindow",
      "root-window": true,
      "display": 1,
      "space": 1,
      "level": 3,
      "can-move": true,
      "can-resize": false,
      "frame": {"x": -80, "y": 20, "w": 40, "h": 20},
      "has-focus": false,
      "is-visible": true,
      "is-minimized": false,
      "is-hidden": false,
      "is-floating": true,
      "is-native-fullscreen": false
    },
    {
      "id": 106,
      "pid": 10,
      "app": "Zed",
      "title": "immovable surface",
      "role": "AXWindow",
      "subrole": "AXStandardWindow",
      "root-window": true,
      "display": 1,
      "space": 1,
      "level": 0,
      "can-move": false,
      "can-resize": false,
      "frame": {"x": -70, "y": 30, "w": 40, "h": 20},
      "has-focus": false,
      "is-visible": true,
      "is-minimized": false,
      "is-hidden": false,
      "is-floating": true,
      "is-native-fullscreen": false
    }
  ]
'
mkdir -p "$focus_state/displays" "$focus_state/windows"
printf '501\t1\t1\tnormal\n' >"$focus_state/windows/104"
printf '501\t1\t1\tnormal\n' >"$focus_state/windows/105"
printf '501\t1\t1\tnormal\n' >"$focus_state/windows/106"
printf '105\n' >"$focus_state/displays/501.candidate"
run_script "$yabai_dir/focus-memory.sh" seed
for auxiliary_window in 104 105 106; do
    if grep -Fx "$auxiliary_window" \
        "$focus_state/displays/501.order" >/dev/null
    then
        printf 'FAIL: auxiliary window %s was saved in row order\n' \
            "$auxiliary_window" >&2
        exit 1
    fi
    if [ -e "$focus_state/windows/$auxiliary_window" ]; then
        printf 'FAIL: auxiliary window %s received focus metadata\n' \
            "$auxiliary_window" >&2
        exit 1
    fi
done
clear_log
run_script "$yabai_dir/cycle.sh" '^Zed$' dev.zed.Zed Zed
assert_log_has 'window 101 --focus'
assert_log_lacks_pattern '^window (104|105|106) --focus$'
cycle_query_count="$(grep -Ec '^query --windows$' "$log_file")"
if [ "$cycle_query_count" -ne 1 ]; then
    printf 'FAIL: expected one application-cycle snapshot, got %s\n' \
        "$cycle_query_count" >&2
    exit 1
fi
clear_log
run_script "$yabai_dir/focus-display.sh" 1
assert_log_has 'window 102 --focus'
assert_log_lacks_pattern '^window (104|105|106) --focus$'
pass 'exclude auxiliary windows from candidates'

# Native-fullscreen windows follow the final normal row and wrap to the first.
reset_case
mock_command window 103 --focus >/dev/null
clear_log
run_script "$yabai_dir/focus-display.sh" 1
assert_log_has 'space --focus 4'
assert_log_has 'window 150 --focus'
clear_log
run_script "$yabai_dir/focus-display.sh" 1
assert_log_has 'space --focus 1'
assert_log_has 'window 101 --focus'
pass 'cycle native fullscreen and wrap'

# With one display, only the command bound to K (requested index 2) is active.
reset_case
mutate_state '
  .displays = [.displays[0]]
  | .spaces = [.spaces[] | select(.display == 1 and ."is-native-fullscreen" == false)]
  | .windows = [.windows[] | select(.display == 1 and ."is-native-fullscreen" == false)]
'
run_script "$yabai_dir/focus-display.sh" 1
assert_log_lacks_pattern '^window [0-9]+ --focus$'
clear_log
run_script "$yabai_dir/focus-display.sh" 2
assert_log_has 'window 102 --focus'
clear_log
run_script "$yabai_dir/focus-display.sh" 3
assert_log_lacks_pattern '^window [0-9]+ --focus$'
pass 'one-display binding behavior'

# Re-selecting a display with one focused candidate is a complete no-op.
reset_case
mutate_state '.windows = [.windows[] | select(.id == 101)]'
run_script "$yabai_dir/focus-display.sh" 1
assert_log_lacks_pattern '^(window|space|display) .*--focus'
pass 'single candidate does not refocus'

# Closing a focused middle row restores its predecessor.
reset_case
run_script "$yabai_dir/focus-memory.sh" seed
mock_command window 102 --focus >/dev/null
run_script "$yabai_dir/focus-memory.sh" record 102
mutate_state '.windows = [.windows[] | select(.id != 102)]'
# A post-close layout event may refresh the current order before recovery runs.
# The destroyed window's saved neighbors must still preserve the pre-close row.
run_script "$yabai_dir/focus-memory.sh" snapshot-display 1
clear_log
run_script "$yabai_dir/focus-recovery.sh" focused 102
assert_log_has 'window 101 --focus'
pass 'focused close selects predecessor'

# Closing the first row restores its successor.
reset_case
run_script "$yabai_dir/focus-memory.sh" seed
mutate_state '.windows = [.windows[] | select(.id != 101)]'
clear_log
run_script "$yabai_dir/focus-recovery.sh" focused 101
assert_log_has 'window 102 --focus'
pass 'first-row close selects successor'

# Closing the final normal window keeps the normal Space instead of cycling
# into an existing native-fullscreen candidate.
reset_case
mutate_state '.windows = [.windows[] | select(.id == 101 or .id == 150)]'
run_script "$yabai_dir/focus-memory.sh" seed
mutate_state '.windows = [.windows[] | select(.id != 101)]'
clear_log
run_script "$yabai_dir/focus-recovery.sh" focused 101
assert_log_has 'display --focus 1'
assert_log_lacks_pattern '^window 150 --focus$'
pass 'last normal close stays on empty normal Space'

# Closing a background window never activates a Space or window.
reset_case
run_script "$yabai_dir/focus-memory.sh" seed
mutate_state '.windows = [.windows[] | select(.id != 102)]'
clear_log
run_script "$yabai_dir/focus-recovery.sh" background 102
assert_log_lacks_pattern '^(window|space|display) .*--focus'
pass 'background close leaves focus untouched'

# Closing native fullscreen restores the last focused normal window.
reset_case
run_script "$yabai_dir/focus-memory.sh" seed
mock_command window 150 --focus >/dev/null
run_script "$yabai_dir/focus-memory.sh" record 150
mutate_state '
  .windows = [.windows[] | select(.id != 150)]
  | .spaces = [.spaces[] | select(.index != 4)]
'
clear_log
run_script "$yabai_dir/focus-recovery.sh" focused 150
assert_log_has 'space --focus 1'
assert_log_has 'window 101 --focus'
pass 'native-fullscreen close restores normal focus'

# A focused window follows the logical display even if it initially appears on
# another display and its window-focused signal runs before placement.
reset_case
run_script "$yabai_dir/focus-memory.sh" seed
mutate_state '
  .displays |= map(."has-focus" = (.index == 3))
  | .spaces |= map(."has-focus" = (.index == 3))
  | .windows |= map(."has-focus" = false)
  | .windows += [{
    "id": 170,
    "pid": 40,
    "app": "Terminal",
    "title": "new",
    "role": "AXWindow",
    "subrole": "AXStandardWindow",
    "root-window": true,
    "display": 3,
    "space": 3,
    "frame": {"x": 100, "y": 0, "w": 100, "h": 100},
    "has-focus": true,
    "is-visible": true,
    "is-minimized": false,
    "is-hidden": false,
    "is-floating": false,
    "is-native-fullscreen": false
  }]
'
run_script "$yabai_dir/focus-memory.sh" record 170
clear_log
run_script "$yabai_dir/place-new-window.sh" 170
assert_log_has 'window 170 --space 1'
assert_log_has 'space --focus 1'
assert_log_has 'window 170 --focus'
pass 'foreground window follows logical display'

# A background window moves silently and preserves its floating state.
reset_case
mock_command window 201 --focus >/dev/null
run_script "$yabai_dir/focus-memory.sh" seed
mutate_state '
  .windows += [{
    "id": 171,
    "pid": 41,
    "app": "Things",
    "title": "background",
    "role": "AXWindow",
    "subrole": "AXStandardWindow",
    "root-window": true,
    "display": 1,
    "space": 1,
    "frame": {"x": -100, "y": 0, "w": 80, "h": 80},
    "has-focus": false,
    "is-visible": true,
    "is-minimized": false,
    "is-hidden": false,
    "is-floating": true,
    "is-native-fullscreen": false
  }]
'
clear_log
run_script "$yabai_dir/place-new-window.sh" 171
assert_log_has 'window 171 --space 2'
assert_log_lacks_pattern '^(window|space|display) .*--focus'
if [ "$("$jq_bin" -r '.windows[] | select(.id == 171) | ."is-floating"' "$state_file")" != true ]; then
    printf 'FAIL: background placement changed floating state\n' >&2
    exit 1
fi
pass 'background window moves silently'

# A new top-level window from a fullscreen app is routed to its normal Space.
reset_case
run_script "$yabai_dir/focus-memory.sh" seed
mutate_state '
  .windows += [{
    "id": 160,
    "pid": 20,
    "app": "Safari",
    "title": "new",
    "role": "AXWindow",
    "subrole": "AXStandardWindow",
    "root-window": true,
    "display": 1,
    "space": 4,
    "frame": {"x": -90, "y": 10, "w": 80, "h": 80},
    "has-focus": false,
    "is-visible": true,
    "is-minimized": false,
    "is-hidden": false,
    "is-floating": true,
    "is-native-fullscreen": false
  }]
'
run_script "$yabai_dir/place-new-window.sh" 160
assert_log_has 'window 160 --space 1'
if [ "$("$jq_bin" -r '.windows[] | select(.id == 160) | ."is-floating"' "$state_file")" != true ]; then
    printf 'FAIL: routing changed the window floating state\n' >&2
    exit 1
fi
pass 'route fullscreen-created top-level window'

# A focused window opened over another application's fullscreen Space is moved
# to the normal Space and followed.
reset_case
mock_command window 150 --focus >/dev/null
run_script "$yabai_dir/focus-memory.sh" seed
mutate_state '
  .windows |= map(."has-focus" = false)
  | .windows += [{
    "id": 172,
    "pid": 42,
    "app": "Terminal",
    "title": "over fullscreen",
    "role": "AXWindow",
    "subrole": "AXStandardWindow",
    "root-window": true,
    "display": 1,
    "space": 4,
    "frame": {"x": -100, "y": 0, "w": 100, "h": 100},
    "has-focus": true,
    "is-visible": true,
    "is-minimized": false,
    "is-hidden": false,
    "is-floating": false,
    "is-native-fullscreen": false
  }]
'
clear_log
run_script "$yabai_dir/place-new-window.sh" 172
assert_log_has 'window 172 --space 1'
assert_log_has 'space --focus 1'
assert_log_has 'window 172 --focus'
pass 'foreground window leaves native fullscreen'

# Attached sheets remain with their native-fullscreen parent.
reset_case
mutate_state '
  .windows += [{
    "id": 161,
    "pid": 20,
    "app": "Safari",
    "title": "sheet",
    "role": "AXWindow",
    "subrole": "AXSheet",
    "root-window": false,
    "display": 1,
    "space": 4,
    "frame": {"x": -90, "y": 10, "w": 80, "h": 40},
    "has-focus": false,
    "is-visible": true,
    "is-minimized": false,
    "is-hidden": false,
    "is-floating": true,
    "is-native-fullscreen": false
  }]
'
run_script "$yabai_dir/place-new-window.sh" 161
assert_log_lacks_pattern '^window 161 --space'
pass 'leave attached sheet with fullscreen parent'

# A root AXStandardWindow at a non-normal level is an app-owned popup. The
# creation handler must neither relocate it nor toggle its state.
reset_case
mutate_state '
  .windows += [{
    "id": 162,
    "pid": 50,
    "app": "Codex",
    "title": "pet",
    "role": "AXWindow",
    "subrole": "AXStandardWindow",
    "root-window": true,
    "display": 1,
    "space": 4,
    "level": 3,
    "can-move": true,
    "can-resize": false,
    "frame": {"x": -90, "y": 10, "w": 40, "h": 40},
    "has-focus": false,
    "is-visible": true,
    "is-minimized": false,
    "is-hidden": false,
    "is-floating": false,
    "is-native-fullscreen": false
  }]
'
run_script "$yabai_dir/handle-window-created.sh" 162
assert_log_lacks_pattern '^window 162 --(space|toggle)'
if [ -e "$focus_state/windows/162" ]; then
    printf 'FAIL: popup received focus metadata\n' >&2
    exit 1
fi
pass 'ignore non-normal-level popup creation'

# A root nonstandard window at the normal level remains a dialog. Float it,
# but do not relocate or add it to focus memory.
reset_case
mutate_state '
  .windows += [{
    "id": 163,
    "pid": 51,
    "app": "Xcode",
    "title": "Settings",
    "role": "AXWindow",
    "subrole": "AXDialog",
    "root-window": true,
    "display": 1,
    "space": 1,
    "level": 0,
    "can-move": true,
    "can-resize": false,
    "frame": {"x": -90, "y": 10, "w": 60, "h": 60},
    "has-focus": false,
    "is-visible": true,
    "is-minimized": false,
    "is-hidden": false,
    "is-floating": false,
    "is-native-fullscreen": false
  }]
'
run_script "$yabai_dir/handle-window-created.sh" 163
assert_log_has 'window 163 --toggle float'
assert_log_lacks_pattern '^window 163 --space'
if [ -e "$focus_state/windows/163" ]; then
    printf 'FAIL: dialog received focus metadata\n' >&2
    exit 1
fi
pass 'float dialog without relocating it'

# When macOS refuses genuine empty-display focus, logical display memory keeps
# returning to a fullscreen display from advancing its fullscreen cycle.
reset_case
mutate_state '
  .displays |= map(."has-focus" = (.index == 2))
  | .spaces = [
      {
        "id": 601,
        "index": 1,
        "label": "aero-1",
        "display": 1,
        "has-focus": false,
        "is-native-fullscreen": false
      },
      {
        "id": 602,
        "index": 2,
        "label": "aero-3",
        "display": 2,
        "has-focus": false,
        "is-native-fullscreen": false
      },
      {
        "id": 604,
        "index": 4,
        "label": "",
        "display": 2,
        "has-focus": true,
        "is-native-fullscreen": true
      },
      {
        "id": 606,
        "index": 6,
        "label": "",
        "display": 2,
        "has-focus": false,
        "is-native-fullscreen": true
      }
    ]
  | .windows = [
      (
        .windows[]
        | select(.id == 150)
        | .display = 2
        | .space = 4
        | .frame.x = 0
        | ."has-focus" = true
      ),
      (
        .windows[]
        | select(.id == 150)
        | .id = 151
        | .display = 2
        | .space = 6
        | .frame.x = 0
        | ."has-focus" = false
      )
    ]
'
run_script "$yabai_dir/focus-memory.sh" seed
clear_log
MOCK_IGNORE_DISPLAY_FOCUS=1 run_script "$yabai_dir/focus-display.sh" 1
assert_log_has 'display --focus 1'
assert_log_lacks_pattern '^space --focus 1$'
clear_log
MOCK_IGNORE_DISPLAY_FOCUS=1 run_script "$yabai_dir/focus-display.sh" 2
assert_log_has 'window 150 --focus'
assert_log_lacks_pattern '^window 151 --focus$'
assert_pointer_warp 50 50
pass 'empty display does not advance fullscreen elsewhere'

# The complete configuration registers all focus signals successfully.
reset_case
YABAI_BIN="$mock_yabai" \
    JQ_BIN="$jq_bin" \
    OSASCRIPT_BIN="$mock_osascript" \
    YABAI_CONFIG_DIR="$yabai_dir" \
    YABAI_FOCUS_STATE_DIR="$focus_state" \
    MOCK_YABAI_STATE="$state_file" \
    MOCK_YABAI_LOG="$log_file" \
    /bin/sh "$yabai_dir/.yabairc"
if ! grep -F \
    'signal --add label=focus-memory-window-focused event=window_focused' \
    "$log_file" >/dev/null
then
    printf 'FAIL: focus-memory signal was not registered\n' >&2
    exit 1
fi
if ! grep -F \
    'signal --add label=focus-recovery-window-focused event=window_destroyed active=yes' \
    "$log_file" >/dev/null
then
    printf 'FAIL: focused-close recovery signal was not registered\n' >&2
    exit 1
fi
if ! grep -F \
    'signal --add label=mirror-window-created event=window_created' \
    "$log_file" >/dev/null
then
    printf 'FAIL: window-created handler signal was not registered\n' >&2
    exit 1
fi
if ! grep -F \
    'signal --add label=focus-memory-display-changed event=display_changed' \
    "$log_file" >/dev/null
then
    printf 'FAIL: display-memory signal was not registered\n' >&2
    exit 1
fi
if ! grep -F \
    'signal --add label=focus-memory-window-moved event=window_moved active=yes' \
    "$log_file" >/dev/null
then
    printf 'FAIL: active-window move coalescing was not registered\n' >&2
    exit 1
fi
if grep -F \
    'signal --add label=focus-memory-space-changed event=space_changed' \
    "$log_file" >/dev/null
then
    printf 'FAIL: duplicate Space-change memory signal was registered\n' >&2
    exit 1
fi
if grep -E '^space .*--label' "$log_file" >/dev/null; then
    printf 'FAIL: bootstrap still maintains obsolete Space labels\n' >&2
    exit 1
fi
if grep -E '^rule --add .*space=' "$log_file" >/dev/null; then
    printf 'FAIL: application rule still contains a fixed Space\n' >&2
    exit 1
fi
assert_log_has 'space 1 --padding abs:16:16:16:16'
assert_log_has 'space 2 --padding abs:30:16:16:16'
assert_log_has 'space 3 --padding abs:16:16:16:16'
pass 'register focus signals'

printf '1..%s\n' "$passed"
