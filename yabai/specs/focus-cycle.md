# Focus cycle

The cycle policy receives an ordered list of windows and the currently focused
window:

1. If the list is empty, return no window.
2. If the focused window is not in the list, return the first window.
3. Otherwise, return the next window.
4. After the final window, wrap to the first.

The caller owns membership and ordering. This policy does not query Yabai,
change focus, move the pointer, or launch an application.
