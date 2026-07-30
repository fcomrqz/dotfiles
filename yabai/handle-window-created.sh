#!/bin/sh

set -u

window_id="${1:-}"
script_dir="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"

case "$window_id" in
    '' | *[!0-9]*) exit 0 ;;
esac

# Creation placement owns the initial query, dialog heuristic, and final
# structural snapshot so the same window is not queried by three scripts.
"$script_dir/place-new-window.sh" "$window_id" created
