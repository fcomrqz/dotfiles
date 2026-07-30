#!/bin/sh

set -u

YABAI_BIN="${YABAI_BIN:-/opt/homebrew/bin/yabai}"
JQ_BIN="${JQ_BIN:-/opt/homebrew/bin/jq}"

if [ ! -x "$YABAI_BIN" ]; then
    YABAI_BIN="$(command -v yabai 2>/dev/null || true)"
fi
if [ ! -x "$JQ_BIN" ]; then
    JQ_BIN="$(command -v jq 2>/dev/null || true)"
fi

if [ -z "$YABAI_BIN" ] || [ -z "$JQ_BIN" ]; then
    exit 1
fi

layout="$(
    "$YABAI_BIN" -m query --spaces --space |
        "$JQ_BIN" -r '.type'
)"

if [ "$layout" = bsp ]; then
    "$YABAI_BIN" -m space --layout stack
else
    "$YABAI_BIN" -m space --layout bsp
fi
