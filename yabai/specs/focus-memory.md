# Focus memory

Store two values for each display:

- **Last candidate:** the last focused normal or native-fullscreen window. Use
  it when returning to the display.
- **Last normal window:** the last focused window in the normal Space. Use it
  when native fullscreen closes.

Also remember the logically selected display. This can differ from Yabai's
focused display when the target is empty and the Finder desktop is disabled.
Use it to decide whether a display shortcut is switching displays or cycling
the selected display.

Update these values after every confirmed focus change, including changes made
outside the display-focus shortcuts. Recording focus updates only focus
metadata; it does not rebuild row order because focus does not change layout.

Rebuild normal-Space row order after structural changes: window creation,
window destruction, and movement. Repeated `window_moved` events for the active
window are coalesced so an auto-balance reflow produces one final snapshot.
Space changes do not need a separate memory update: `window_focused` records
the candidate and `display_changed` records the logical display.

Only normal and native-fullscreen windows from
[`window-classification.md`](window-classification.md) are eligible for focus
memory. Normal-Space row snapshots contain only visible normal windows.
Notifications, dialogs, sheets, non-normal-level overlays, immovable
pseudo-windows, and other auxiliary windows must not become candidates or row
neighbors.

Before restoring a window, verify that it still exists, is eligible, and
belongs to the display. Discard stale values and let the caller choose a
fallback.

Identify displays by a stable Yabai display ID or UUID and windows by Yabai
window ID. Arrangement indices are shortcut targets, not memory keys.
