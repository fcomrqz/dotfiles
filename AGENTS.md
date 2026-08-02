# Keybinding documentation

These instructions apply to the repository. Follow them whenever a task reads
or changes `keybinding/`, `kanata/`, `qmk/unicorne/`, `zed/keymap.json`,
`aerospace/.aerospace.toml`, or `yabai/.skhdrc`.

## Purpose

`keybinding/` is the clean-install shortcut reference used to compare defaults
before changing the user's configuration. Its modifier CSVs document what apps
do by default; they are not a dump of the user's active overrides.

The user uses a 40% keyboard with home-row modifiers, has no dedicated number
or function row, does not use Vim, and prefers to preserve application defaults
where practical.

## Default modifier CSVs

- Use one CSV per modifier combination, named after its modifiers, such as
  `command.csv`, `command-shift.csv`, or `control-option.csv`.
- Keep `Key` as the first column.
- Order applicable app columns as:
  `macOS`, `ChatGPT`, `Zed Editor`, `Zed Agent`, `Zed Terminal`, `Zed Git`,
  `Terminal`, `micro`, `fish`, `Safari`, `Figma`, `Things`, `Mail`,
  `Messages`, `WhatsApp`.
- Omit an app column when that app has no action anywhere in that modifier
  file. In files that contain them, place `micro` and `fish` immediately after
  `Terminal`.
- Treat Zed contexts as separate apps. Do not collapse Zed Editor, Agent,
  Terminal, or Git into one column.
- Put only the action performed in a cell. Do not include usage counts,
  provenance notes, or the user's replacement binding.
- Record clean-install defaults even when the physical keyboard cannot
  currently produce them.
- Never replace a default cell with a value from `zed/keymap.json`, Kanata,
  QMK, AeroSpace, Yabai, `skhd`, or another user configuration.
- For macOS, include only shortcuts that work independently of the foreground
  app. Ordinary shared Cocoa application shortcuts belong in app columns.
- Use the currently installed app or its current shortcut settings as the
  source of truth. For ChatGPT, preserve the latest assigned shortcuts shown
  in its Desktop shortcut settings; do not add rows for unassigned commands.
- Preserve existing key naming within a file and quote CSV fields containing
  commas according to standard CSV rules.

## Custom and derived CSVs

- `space.csv` documents the custom Space layer.
- `hyper.csv` documents the custom modifier-free Hyper/mouse layer.
- `unreachables.csv` is derived from the active keyboard transformations. Its
  columns must remain `Intercepted,Unreachable,Emit,Command`.
- `zed-overrides.csv` is a derived inventory of active entries in
  `zed/keymap.json`. Keep its columns as `Context,Key,Action`; never treat its
  actions as clean-install defaults.
- Do not put window-manager or application overrides into the default modifier
  CSV cells. Compare them against the defaults and update `unreachables.csv`
  only when a default action truly becomes unreachable.
- A shortcut is not unreachable if it can be produced with the other hand
  while the finger responsible for the target key remains free. Account for
  left- and right-side home-row modifiers separately.

## Configuration parity

- Keep Kanata and QMK Unicorne behavior aligned for the base, Space, Hyper,
  home-row modifier, navigation, and shortcut-preservation behavior.
- Escape-hold activates a modifier-free Hyper layer. Mouse actions on that
  layer emit no keyboard modifiers; other reachable keys emit explicit
  Control+Option+Command+Shift chords.
- Mouse buttons are tap-only, not held: `U` left-click, `O` right-click, and
  `H` middle-click. Movement is `I/J/K/L`; scrolling is `N/P`.
- QMK is used with iOS. Do not claim runtime parity unless it has been tested
  on the device.
- Validate Kanata changes with:
  `kanata --check -c kanata/kanata.kbd`.
- Compile QMK changes without flashing when the local toolchain works. Never
  flash unless the user explicitly asks.
- Keep AeroSpace and Yabai/`skhd` global bindings behaviorally aligned where
  both window managers support the same action. Global overrides do not replace
  the defaults documented in `keybinding/`.

## Validation

After editing CSVs, parse every `keybinding/*.csv` and verify that every row in
each file has the same number of fields as its header. Review affected columns
for accidental shifts after inserting or deleting an app column.

After editing configurations, run the relevant syntax or build checks and
report any validation blocked by local dependencies separately from source
errors.
