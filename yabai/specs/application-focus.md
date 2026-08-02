# Application focus

Application focus defines shortcuts that cycle an application's windows or
launch it when no matching window exists. The implementation is `../cycle.sh`.

## Bindings

| Shortcut | Application |
| --- | --- |
| `ctrl + opt + o` | Safari |
| `ctrl + opt + z` | Zed |
| `ctrl + opt + t` | Terminal |
| `ctrl + opt + right` | Finder |
| `ctrl + opt + backtick` | Mail |
| `ctrl + opt + a` | Messages |
| `ctrl + opt + q` | WhatsApp |
| `ctrl + opt + tab` | Things |
| `ctrl + opt + x` | Xcode |
| `ctrl + opt + semicolon` | Codex |
| `ctrl + opt + u` | Music |
| `ctrl + opt + g` | Figma |

Punctuation bindings use physical macOS keycodes in `../.skhdrc`.

## Candidates

1. Query all windows known to Yabai.
2. Keep only normal and native-fullscreen windows according to
   [`window-classification.md`](window-classification.md). Normal windows must
   be root `AXStandardWindow` windows at the normal level that can move.
   Native-fullscreen windows remain eligible while non-movable.
3. Exclude notifications, dialogs, sheets, non-normal-level overlays, and
   other auxiliary windows.
4. Match Yabai's `app` field against the shortcut's case-insensitive regular
   expression.
5. Preserve Yabai query order.

The `app` field is a visible application name, not a bundle ID. Bundle IDs are
used only by the launch fallback.

## Cycling

When matching windows exist:

1. Select the next matching window using
   [`focus-cycle.md`](focus-cycle.md).
2. Focus the selected window.
3. Let Yabai's `mouse_follows_focus` setting position the pointer.

If the focused window belongs to another application, the first matching
window is selected. After the final matching window, selection wraps to the
first.

The order is Yabai query order, not MRU order.

The selected window may belong to another native Space, including a
native-fullscreen Space.

## Launch fallback

When there are no matching windows:

1. Launch the application by bundle ID with `open -b`.
2. If that fails and a launch name is configured, retry with `open -a`.
3. Let macOS focus the application as it opens.

The command does not wait for the application to create a window. After Yabai
detects one, the next shortcut invocation cycles it normally.

Application focus does not choose a display or Space independently of its
selected window.
