# Focus recovery after window closure

Window-close recovery is event-driven and separate from display-focus cycling.

Normal windows use the same order as display focus: top position, left
position, and Yabai window ID. Only visible normal windows from
[`window-classification.md`](window-classification.md) participate;
notifications and other auxiliary windows are excluded.

## Focused normal window

When the focused normal window closes:

1. Focus its immediate predecessor in the pre-close order.
2. If the first window closed, focus its immediate successor instead.
3. Confirm focus, center the pointer on the replacement, and remember it.
4. If no normal window remains, keep the normal Space active and center the
   pointer on the display. Do not enter native fullscreen.

## Nonfocused window

When a nonfocused window closes, leave focus and the pointer unchanged. Remove
any focus-memory entry that refers to the closed window.

## Native-fullscreen window

When a native-fullscreen window closes:

1. Restore the display's last focused normal window.
2. Confirm focus and center the pointer on that window.
3. If the normal Space is empty, keep it active and center the pointer on the
   display.

If normal windows exist but the remembered normal window is unavailable, the
fallback window is not yet specified.
