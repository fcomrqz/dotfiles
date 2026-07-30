# Window classification

All focus, placement, movement, and memory features use the shared jq policy in
`../focus-window.jq`. Classification uses only fields reported by Yabai.

## Normal window

A normal window:

- Has role `AXWindow` and subrole `AXStandardWindow`.
- Is a root window.
- Has window level `0`, the normal macOS window level.
- Is not native fullscreen.
- Can move.

Normal windows may be managed or floating. They participate in display focus,
application focus, placement, focus memory, close recovery, and explicit
cross-display movement.

## Native-fullscreen window

A native-fullscreen window has the same role, root, and level requirements as
a normal window and reports native fullscreen. It remains eligible for focus
and movement when Yabai reports `can-move=false`; leaving native fullscreen is
what makes cross-display movement possible.

## Dialog

A dialog is a root `AXWindow` at the normal window level with a subrole other
than `AXStandardWindow`.

Dialogs are floated by the creation handler and may be moved explicitly when
Yabai reports that they can move. They do not participate in display focus,
application focus, focus memory, or normal-Space row order.

A movable normal window that cannot resize is also floated as a supplemental
dialog heuristic. It remains a normal focus candidate because `can-resize` is
not equivalent to macOS fullscreen-button availability.

## Popup or ineligible window

All remaining objects are ineligible. This includes:

- Non-root windows such as attached sheets.
- Non-normal-level overlays and always-on-top utility surfaces.
- Standard-looking normal-level windows that cannot move.
- Accessibility objects that are not windows.

Do not relocate, cycle, remember, recover, or explicitly move these objects.

## Limit

Yabai does not expose fullscreen, minimize, close, and zoom button metadata or
AX identifiers. Therefore this policy cannot reproduce AeroSpace's complete
dialog heuristic without a separate macOS Accessibility helper.
