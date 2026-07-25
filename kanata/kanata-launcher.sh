#!/bin/bash

set -u

readonly KANATA="/Library/Application Support/com.fcomrqz.kanata/bin/kanata"
readonly CONFIG="/Library/Application Support/com.fcomrqz.kanata/kanata.kbd"
readonly DEVICE_NAME="${KANATA_DEVICE_NAME:-HHKB-Classic}"
readonly FAST_RETRY_SECONDS="${KANATA_FAST_RETRY_SECONDS:-1}"
readonly FAST_WINDOW_SECONDS="${KANATA_FAST_WINDOW_SECONDS:-30}"
readonly IDLE_RETRY_SECONDS="${KANATA_IDLE_RETRY_SECONDS:-600}"

fast_until=$((SECONDS + FAST_WINDOW_SECONDS))

while true; do
  if "$KANATA" --list 2>/dev/null | /usr/bin/grep -Fq "$DEVICE_NAME"; then
    started_at=$SECONDS
    "$KANATA" -q --no-wait -c "$CONFIG"
    if ((SECONDS - started_at >= FAST_WINDOW_SECONDS)); then
      fast_until=$((SECONDS + FAST_WINDOW_SECONDS))
    fi
  fi

  if ((SECONDS < fast_until)); then
    /bin/sleep "$FAST_RETRY_SECONDS"
  else
    /bin/sleep "$IDLE_RETRY_SECONDS"
  fi
done
