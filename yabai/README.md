# yabai mirror of the AeroSpace setup

This directory mirrors `aerospace/.aerospace.toml` for yabai 7.1.25 or newer.
It intentionally leaves the existing AeroSpace setup untouched so both
configurations can be compared.

## Install

Do not run AeroSpace and skhd with the same shortcuts at the same time.

```sh
brew install asmvik/formulae/yabai asmvik/formulae/skhd jq

ln -sF ~/Developer/fcomrqz/dotfiles/yabai/.yabairc ~/.yabairc
ln -sF ~/Developer/fcomrqz/dotfiles/yabai/.skhdrc ~/.skhdrc

yabai --start-service
skhd --start-service
```

Grant Accessibility permission to both `yabai` and `skhd` when macOS asks.
The base configuration, window movement and fullscreen bindings do not require
disabling System Integrity Protection. The optional yabai scripting addition is
not loaded by this configuration.

## Native Space mapping

yabai cannot reproduce AeroSpace's virtual workspaces. Keep one normal macOS
Space on each display; native-fullscreen applications create the additional
Spaces used by focus cycling.

The bootstrap script discovers each display's normal Space from live Yabai
topology. It does not create or maintain labels. It reapplies BSP layout, gaps,
and padding after display changes, Dock restarts, and wake. The physically
leftmost normal Space receives the 30-point top padding; the others receive 16.

## Mirrored behavior

- BSP corresponds to AeroSpace tiles; stack corresponds to accordion.
- `window_insertion_point focused` plus `window_placement first_child`
  approximates `before-the-mru-window`.
- Inner gaps and outer padding are 16 points; the leftmost display has a
  30-point top padding.
- New top-level windows open in the focused display's normal Space. Window
  rules preserve application floating behavior without assigning displays.
- Cross-display movement wraps by physical horizontal position and targets the
  destination display's live normal Space. Managed, floating, and
  native-fullscreen windows are supported without relying on Space labels.
  Moving a native-fullscreen window exits fullscreen and leaves it as a normal
  window on the destination.
- Display-focus shortcuts cycle rows and then native Spaces on that display,
  including native-fullscreen applications. Returning to a display restores
  its last focused window instead of advancing the cycle.
- Yabai focuses the destination Space and window and supplies its frame.
  Display focus then uses a small compiled CoreGraphics helper for deterministic
  pointer centering because native-fullscreen activation may not trigger
  `mouse_follows_focus`. A delayed retry after Space changes runs in the
  background and does not block the shortcut. Application cycling still relies
  on Yabai's mouse-follow behavior.
- Empty displays are targeted with `display --focus`, never `space --focus`, so
  selecting one cannot switch a native-fullscreen Space on another display.
  A logical display selection preserves correct restore-versus-cycle behavior
  when the Finder desktop is disabled.
- Closing the focused normal window selects its previous row, or its next row
  when the first row closes. Closing native fullscreen restores the display's
  last focused normal window.
- A focused top-level window created over native fullscreen is sent to that
  display's normal Space and followed. Background-created windows move
  silently.
- Application shortcuts cycle existing windows and launch by bundle ID when no
  window exists.
- A shared Yabai-only classifier keeps normal, native-fullscreen, dialog, and
  popup behavior consistent across placement, focus, movement, and memory.
  Dialogs and non-resizable normal windows are floated; non-root,
  non-normal-level, and immovable popup surfaces are ignored.
- `ctrl-alt-f` toggles yabai's instant, same-Space `windowed-fullscreen`.

## Differences that cannot be mirrored exactly

- yabai rules match application names, not bundle IDs. Inspect actual names
  with:

  ```sh
  yabai -m query --windows | jq -r '.[].app' | sort -u
  ```

  Adjust the regular expressions in `.yabairc` if an application reports a
  different name.

- Native Spaces belong to displays. They are not persistent shared workspaces
  that AeroSpace can attach to whichever monitor is available.
- Application-specific workspace assignments are intentionally not mirrored;
  placement follows the focused display instead.
- yabai's built-in and supplemental dialog checks do not inspect the fullscreen
  button, so they remain less comprehensive than AeroSpace's heuristics.
- Toggling BSP/stack changes the entire native Space, whereas AeroSpace can
  change the layout of a container.
- `resize-smart.sh` tries the four resize edges in order; it is an approximation
  of AeroSpace's tree-aware `resize smart`.

## Focus implementation

Focus memory and pre-close row snapshots are kept under
`${TMPDIR}/yabai-focus-<uid>`. The state is rebuilt when `.yabairc` loads and
after display or Dock changes.

Display shortcuts query displays, Spaces, and windows once and parse each
snapshot once for selection, memory lookup, and pointer coordinates.
Application cycling uses one window snapshot. The selected window is
remembered synchronously.

Focus events update only lightweight candidate metadata. Yabai's creation,
destruction, and active-window movement signals maintain the heavier neighbor
snapshots outside the selection path; repeated movement events are coalesced
after layout settles. Space changes do not duplicate focus-memory work.

Focus and movement behavior can be tested without starting yabai or moving
live windows:

```sh
./tests/focus-test.sh
./tests/move-display-test.sh
```
