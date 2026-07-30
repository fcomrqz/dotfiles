# New window placement

New top-level windows open in the focused display's normal Space.

## Eligible windows

Placement applies only to normal windows from
[`window-classification.md`](window-classification.md): movable root
`AXStandardWindow` windows at the normal window level that are not native
fullscreen.

Standalone dialogs are floated but not relocated. Attached sheets,
non-normal-level overlays, immovable pseudo-windows, and other popups remain
untouched with their parent application.

## Target display

Use the logically selected display from
[`focus-memory.md`](focus-memory.md). If it is unavailable, use Yabai's focused
display.

Yabai's `window_origin_display focused` setting provides the initial placement.
The creation handler corrects the window when its initial display or Space does
not match the target.

The handler queries the new window once for placement and dialog decisions,
then takes one final structural focus-memory snapshot after any changes.

## Target Space

The destination is the target display's sole normal Space.

This applies when another application opens over a native-fullscreen Space and
when a native-fullscreen application creates another top-level window. The new
window must not remain over native fullscreen.

## Focus

- If the new window had focus when placement began, follow it to the normal
  Space and keep it focused.
- If it was created in the background, move it silently.

Background placement must not change focus or move the pointer.

## Window state

Placement changes only the window's display and Space. Existing managed,
floating, and application-specific rules remain in effect.
