# Display focus

Display focus defines `cmd + opt + enter/j/k/l`. The implementation is
`../focus-display.sh`.

It uses:

- [`focus-cycle.md`](focus-cycle.md) to select the next window.
- [`focus-memory.md`](focus-memory.md) to restore a display's previous window.
- [`focus-pointer.md`](focus-pointer.md) to position the pointer.

## Bindings

| Shortcut | One display | Three displays |
| --- | --- | --- |
| `cmd + opt + enter` | No action | Left display |
| `cmd + opt + j` | No action | Left display |
| `cmd + opt + k` | Cycle | Center display |
| `cmd + opt + l` | No action | Right display |

The three-display mapping follows Yabai's horizontal display arrangement.

## Candidate order

Each display has one ordered list:

1. Windows in its normal Space, ordered by top position, left position, and
   Yabai window ID.
2. Native-fullscreen windows, ordered by Mission Control Space index.

Minimized and hidden windows are excluded. Floating normal windows are
included when they satisfy
[`window-classification.md`](window-classification.md). Notifications,
dialogs, sheets, non-normal-level overlays, immovable pseudo-windows, and other
auxiliary windows are excluded. Native-fullscreen windows remain candidates
when Yabai reports that they cannot move.

Native-fullscreen windows behave as rows after the normal windows. Cycling
wraps from the final native-fullscreen window to the first normal window. If
the normal Space is empty, the list contains only native-fullscreen windows.

## Selecting another display

Selecting a display that does not currently have focus restores its remembered
window without advancing the cycle:

1. Select the display's last focused candidate.
2. If that window is no longer eligible, select the first candidate.
3. Focus the candidate's Space and window.
4. Confirm focus.
5. Center the pointer on the window.

For example, if the left display had Window 1 focused before switching away,
returning to the left display restores Window 1 rather than selecting Window 2.

## Selecting the focused display

Selecting the display that already has focus advances to its next candidate:

1. Select the next candidate.
2. Focus the candidate's Space and window.
3. Confirm focus.
4. Remember the focused window.
5. Center the pointer on it.

If the only candidate already has focus, do nothing. Do not refocus the window
or move the pointer.

## Native fullscreen

Changing to or from a native-fullscreen window requires a macOS Space
transition. Wait up to two seconds for Yabai to confirm the destination Space
before focusing its window or moving the pointer.

## No candidates

If the display has no normal or native-fullscreen window:

1. Ask Yabai to focus the display, not its normal Space. Focusing the Space by
   Mission Control index can change the active native-fullscreen Space on
   another display.
2. Wait briefly for display focus.
3. Center the pointer on the display.
4. Remember it as the logically selected display.

The logical selection determines whether the next display command restores or
cycles a window. A subsequent real window-focus or display-change event
replaces it.

Genuine keyboard focus of an empty display requires:

- **Show Items On Desktop** enabled.
- **Click wallpaper to reveal Desktop** set to **Only in Stage Manager**.
- `com.apple.Finder CreateDesktop` set to `true`.

Without the Finder desktop, macOS may leave keyboard focus on the previous
display. The logical selection and centered pointer still prevent the next
command from cycling that previous display accidentally.

Window closure and new-window placement are defined in
[`focus-recovery.md`](focus-recovery.md) and
[`window-creation.md`](window-creation.md).
