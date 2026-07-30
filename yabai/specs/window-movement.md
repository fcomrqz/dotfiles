# Cross-display window movement

This feature owns `cmd + opt + comma/period` and is implemented by
`../move-display.sh`.

## Bindings

| Shortcut | Direction |
| --- | --- |
| `cmd + opt + comma` | Previous display |
| `cmd + opt + period` | Next display |

Displays are ordered by their physical horizontal position. Movement wraps
from the first display to the last and from the last to the first. With one
display, both commands do nothing.

## Eligible windows

The command acts on the focused window and keeps its Yabai window ID for the
entire operation.

Normal managed and floating windows are eligible when Yabai reports that they
can move. Focusable dialogs can also move explicitly while remaining floating.
Native-fullscreen windows are eligible even though they are not movable during
their fullscreen transition.

Non-root windows, non-normal-level overlays, immovable normal pseudo-windows,
and other popups from
[`window-classification.md`](window-classification.md) are ignored.

## Destination

Resolve the destination from live Yabai display and Space queries. The target
is the adjacent display's sole normal, non-native-fullscreen Space.

Space labels are not movement targets. Labels can become stale when displays
are disconnected or reordered.

## Activation

Move the window to the target normal Space and request focus as one Yabai
command. First confirm that its display and Space changed and that it is no
longer native fullscreen. Normal movement verification uses a short bounded
wait; native-fullscreen transitions retain the longer transition wait.

Focus confirmation is separate. If the move arrived before focus, request
window focus once more and wait briefly. Only confirmed focus allows:

1. Centering the pointer from the final Yabai-reported frame.
2. Removing stale focus-memory references on the source display.
3. Snapshotting the source and destination normal Spaces.
4. Remembering the window and destination as focused.

If movement fails, do not change pointer or focus memory. Once the destination
is confirmed, the move is committed and must not be rolled back merely because
macOS publishes focus late. In that case, update structural memory without
moving the pointer and report failure.

## Floating windows

Floating windows use the same destination and activation path as managed
windows. Yabai preserves their floating state and translates their frame to
the destination display.

## Native fullscreen

To move a native-fullscreen window:

1. Exit native fullscreen and wait for the normal window.
2. Move and focus it on the destination normal Space.
3. Leave it as a normal window.
4. Center the pointer and update focus memory.

If movement fails after leaving fullscreen, attempt to restore native
fullscreen on the window's current display. Restoring fullscreen is failure
rollback only, not part of a successful move.

## Concurrency

Movement shares the focus-operation lock with display focus and close
recovery while the window is in an intermediate state. Release it after
movement, focus, and pointer placement are confirmed; source and destination
row snapshots may finish after the next focus operation starts.
