#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly ROOT

if [[ "$(uname -s)" != "Darwin" ]]; then
  printf 'ok - Tailscale daemon rendering skipped outside macOS\n'
  exit 0
fi

temporary="$(mktemp -d)"
trap 'rm -rf "$temporary"' EXIT

dummy_tailscaled="$temporary/tailscaled"
rendered="$temporary/com.tailscale.tailscaled.plist"
template_fingerprint="$(shasum -a 256 "$ROOT/tailscale/tailscale.plist")"

touch "$dummy_tailscaled"
chmod 0755 "$dummy_tailscaled"

"$ROOT/tailscale/manage-daemon.sh" \
  render "$dummy_tailscaled" "$rendered"

plutil -lint "$rendered" >/dev/null
[[ "$(
  /usr/libexec/PlistBuddy \
    -c "Print :Label" "$rendered"
)" == "com.tailscale.tailscaled" ]]
[[ "$(
  /usr/libexec/PlistBuddy \
    -c "Print :ProgramArguments:0" "$rendered"
)" == "$dummy_tailscaled" ]]
[[ "$(
  /usr/libexec/PlistBuddy \
    -c "Print :StandardOutPath" "$rendered"
)" == "/Library/Logs/Tailscale/tailscaled.log" ]]
[[ "$(
  /usr/libexec/PlistBuddy \
    -c "Print :StandardErrorPath" "$rendered"
)" == "/Library/Logs/Tailscale/tailscaled.log" ]]
[[ "$(stat -f '%Lp' "$rendered")" == "644" ]]
[[ "$(shasum -a 256 "$ROOT/tailscale/tailscale.plist")" \
  == "$template_fingerprint" ]]

if "$ROOT/tailscale/manage-daemon.sh" \
  render relative/tailscaled "$temporary/relative.plist" \
  >/dev/null 2>&1; then
  printf 'Relative tailscaled path was accepted\n' >&2
  exit 1
fi

touch "$temporary/not-executable"
if "$ROOT/tailscale/manage-daemon.sh" \
  render "$temporary/not-executable" "$temporary/not-executable.plist" \
  >/dev/null 2>&1; then
  printf 'Non-executable tailscaled path was accepted\n' >&2
  exit 1
fi

mkdir "$temporary/destination-directory"
if "$ROOT/tailscale/manage-daemon.sh" \
  render "$dummy_tailscaled" "$temporary/destination-directory" \
  >/dev/null 2>&1; then
  printf 'Directory destination was replaced\n' >&2
  exit 1
fi

printf 'ok - Tailscale daemon rendering\n'
