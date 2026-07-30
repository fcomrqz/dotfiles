# Focus specifications

## Scope

The supported setup has either one or three displays. Each display has one
normal macOS Space and may have native-fullscreen Spaces.

Only normal windows and native-fullscreen windows participate. Yabai's
windowed-fullscreen and zoom-fullscreen modes do not.

## Commands

- [`display-focus.md`](display-focus.md) defines display selection and cycling.
- [`application-focus.md`](application-focus.md) defines application cycling
  and launching.
- [`window-movement.md`](window-movement.md) defines cross-display window
  movement.

## Events

- [`focus-recovery.md`](focus-recovery.md) restores focus after a window closes.
- [`window-creation.md`](window-creation.md) places new top-level windows on the
  focused display.

## Shared policies

- [`window-classification.md`](window-classification.md) defines which Yabai
  windows are normal, native fullscreen, dialogs, or popups.
- [`focus-cycle.md`](focus-cycle.md) selects the next window in an ordered list.
- [`focus-memory.md`](focus-memory.md) remembers focus for each display.
- [`focus-pointer.md`](focus-pointer.md) controls pointer movement after focus.

## Invariants

- Confirm the requested focus before moving the pointer.
- Wait for a macOS Space transition to finish before focusing its window.
- A display-focus command that leaves focus unchanged does not move the
  pointer.
- Yabai and skhd must be running with Accessibility permission.
- macOS Secure Input prevents skhd from receiving shortcuts.
- AeroSpace and skhd must not own the same shortcuts simultaneously.
