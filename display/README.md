# Display

`display` is a small macOS command-line tool for this three-monitor setup. It
controls display availability, brightness, and orientation without a
third-party runtime dependency.

## Commands

```sh
display list
display main
display fitness
display reset

display brightness
display brightness up
display brightness down
display brightness 0.5

display orientation main 90
display orientation fitness 0
display orientation UUID 0
```

`list` reports contextual IDs, persistent UUIDs, enabled state, orientation,
and brightness.

The two single-display presets use physical UUIDs rather than contextual IDs:

```text
main:    1E1520FE-94BE-4EC7-BE8D-3F6DF7F99049 at 90°
fitness: 57977437-1296-43A8-9836-89A69038CBBC at 0°
```

The fitness UUID currently corresponds to contextual CoreGraphics ID `3`.
Contextual IDs and the display macOS designates as main can change when
displays reconnect. UUID-based presets remain deterministic across those
changes. A UUID is normally stable for the same physical display and EDID,
although changing ports, adapters, or display metadata can occasionally
regenerate it.

`brightness up` and `brightness down` preserve the existing `0.0225` step and
set enabled side displays `0.02625` below the main display. The F14 and F15
AeroSpace bindings invoke these commands directly. A numeric value sets the
main display directly and applies the same side-display offset.

Orientation accepts `main`, `fitness`, or any display UUID and one of `0`, `90`,
`180`, or `270` degrees. A target must be enabled before it can be rotated.

Before leaving the full setup, the tool records contextual IDs, UUIDs, and
orientations in `/tmp/display-UID.state`. This allows direct switching between
the `main` and `fitness` presets even though disabled displays may disappear
from CoreGraphics' online-display list. `reset` reconnects all three displays,
restores the saved orientations, and clears the state file. Without saved
state, it uses the normal setup rotations: main 90°, left 90°, fitness 270°.

## Build and install

The Xcode Command Line Tools are the only build dependency:

```sh
make -C display
ln -sF "$PWD/display/display" /opt/homebrew/bin/display
```

The repository's `install.sh` performs both commands during a fresh macOS
setup. Build products are ignored by Git.

## Private APIs

The implementation dynamically loads these private macOS APIs:

- `CGSConfigureDisplayEnabled` to enable and disable displays.
- `DisplayServices` brightness functions.
- `CoreDisplay` display metadata.
- MonitorPanel's `MPDisplay` class to change orientation.

No private framework is linked into the executable, and no private headers are
required. Foundation, CoreGraphics, and CoreFoundation are system frameworks
supplied by macOS.

Apple can change or remove the private APIs in any macOS update. Disabling a
display removes it from the active desktop and makes it black. Some
display/port combinations may not reconnect through the same private API; if
that happens, unplug and reconnect the missing displays. The configuration is
scoped to the current login session, so restarting macOS remains a final
recovery path.
