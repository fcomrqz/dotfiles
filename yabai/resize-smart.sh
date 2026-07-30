#!/bin/sh

set -u

amount="${1:-}"
YABAI_BIN="${YABAI_BIN:-/opt/homebrew/bin/yabai}"

case "$amount" in
    '' | *[!0-9]*)
        printf 'Usage: resize-smart.sh <positive-pixels>\n' >&2
        exit 1
        ;;
esac

if [ ! -x "$YABAI_BIN" ]; then
    YABAI_BIN="$(command -v yabai 2>/dev/null || true)"
fi

[ -n "$YABAI_BIN" ] || exit 1

negative_amount=$((0 - amount))

"$YABAI_BIN" -m window --resize "right:${amount}:0" 2>/dev/null ||
    "$YABAI_BIN" -m window --resize "left:${negative_amount}:0" 2>/dev/null ||
    "$YABAI_BIN" -m window --resize "bottom:0:${amount}" 2>/dev/null ||
    "$YABAI_BIN" -m window --resize "top:0:${negative_amount}" 2>/dev/null ||
    true
