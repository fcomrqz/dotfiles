#!/bin/sh

set -u

script_dir="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
state_dir="${YABAI_FOCUS_STATE_DIR:-${TMPDIR:-/tmp}/yabai-focus-$(id -u)}"
source_file="$script_dir/warp-pointer.c"
target_file="$state_dir/warp-pointer"

[ -f "$source_file" ] || exit 1
mkdir -p "$state_dir"

if [ -x "$target_file" ] && [ "$target_file" -nt "$source_file" ]; then
    exit 0
fi

temporary_file="$(mktemp "$state_dir/warp-pointer.tmp.XXXXXX")" || exit 1
trap 'rm -f "$temporary_file"' 0
trap 'exit 1' 1 2 15

/usr/bin/xcrun clang \
    -Os \
    -Wall \
    -Wextra \
    -framework ApplicationServices \
    "$source_file" \
    -o "$temporary_file" || exit 1

chmod 755 "$temporary_file"
mv -f "$temporary_file" "$target_file"
trap - 0
