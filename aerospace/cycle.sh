#!/bin/bash

# Usage: cycle.sh <app-bundle-id> [app-name]
# Example: cycle.sh dev.zed.Zed Zed

if [ $# -eq 0 ]; then
  echo "Usage: cycle.sh <app-bundle-id> [app-name]"
  echo "Example: cycle.sh dev.zed.Zed Zed"
  exit 1
fi

app_bundle_id="$1"
app_name="${2:-$(echo "$app_bundle_id" | awk -F. '{print $NF}')}"

current=$(aerospace list-windows --focused --format '%{window-id}')
app_windows=$(aerospace list-windows --all --format '%{window-id},%{app-bundle-id}' | awk -F, -v bid="$app_bundle_id" '$2 == bid {print $1}')

if [ -z "$app_windows" ]; then
  open -a "$app_name"
  exit 0
fi

next=$(echo "$app_windows" | grep -A1 "^$current$" | tail -1)

if [ "$next" = "$current" ] || [ -z "$next" ]; then
  next=$(echo "$app_windows" | head -1)
fi

aerospace focus --window-id "$next"
