#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=install/shared.sh
source "$ROOT/install/shared.sh"

temporary="$(mktemp -d)"
trap 'rm -rf "$temporary"' EXIT

CI=1 run_step "successful step" true >/dev/null
if CI=1 run_step "failed step" false >/dev/null 2>&1; then
  printf 'run_step did not preserve a failure status\n' >&2
  exit 1
fi

touch "$temporary/source"
safe_link "$temporary/source" "$temporary/config/link"
[[ -L "$temporary/config/link" ]]
[[ "$(readlink "$temporary/config/link")" == "$temporary/source" ]]

touch "$temporary/real-file"
if safe_link "$temporary/source" "$temporary/real-file" >/dev/null 2>&1; then
  printf 'safe_link replaced a real file\n' >&2
  exit 1
fi

printf 'ok - installer helpers\n'
