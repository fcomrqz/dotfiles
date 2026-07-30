# Focus pointer

## Display focus

After confirming window and Space focus, move the pointer to the center of the
window. Use its Yabai-reported frame and CoreGraphics for the final movement.
This explicit movement is required when native-fullscreen activation focuses
the window before Yabai can emit `mouse_follows_focus`.

When focusing an empty display, move the pointer to the center of the display.

Do not move the pointer when focus is unchanged or activation fails.

## Application focus

Application shortcuts rely on Yabai's global setting:

```sh
yabai -m config mouse_follows_focus on
```

Yabai moves the pointer after the window receives focus.
