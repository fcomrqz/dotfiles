#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly ROOT

bash -n \
  "$ROOT/install.sh" \
  "$ROOT/install/shared.sh" \
  "$ROOT/install/macos.sh" \
  "$ROOT/install/linux.sh" \
  "$ROOT/macos/defaults.sh" \
  "$ROOT/orbstack/machine" \
  "$ROOT/bin/with-secrets" \
  "$ROOT/bin/github-app-token-common" \
  "$ROOT/bin/github-token-store" \
  "$ROOT/bin/git-credential-github-app" \
  "$ROOT/bin/gh-github-app" \
  "$ROOT/tests/with-secrets.sh" \
  "$ROOT/tests/install-lib.sh"

while IFS= read -r file; do
  fish --no-execute "$file"
done < <(find "$ROOT/fish" "$ROOT/tests" -type f -name '*.fish' -print)

shellcheck \
  "$ROOT/install.sh" \
  "$ROOT/install/shared.sh" \
  "$ROOT/install/macos.sh" \
  "$ROOT/install/linux.sh" \
  "$ROOT/macos/defaults.sh" \
  "$ROOT/orbstack/machine" \
  "$ROOT/bin/with-secrets" \
  "$ROOT/bin/github-app-token-common" \
  "$ROOT/bin/github-token-store" \
  "$ROOT/bin/git-credential-github-app" \
  "$ROOT/bin/gh-github-app" \
  "$ROOT/tests/with-secrets.sh" \
  "$ROOT/tests/install-lib.sh"

"$ROOT/tests/install-lib.sh"
"$ROOT/tests/with-secrets.sh"
fish "$ROOT/tests/filter-ranking.fish"
fish "$ROOT/tests/open-project.fish"
fish "$ROOT/tests/prompt.fish"

plutil -lint "$ROOT/github/com.fcomrqz.github-token-manager.plist" >/dev/null
if [[ "$(uname -s)" == "Darwin" ]] && command -v swift >/dev/null 2>&1; then
  swift test \
    --package-path "$ROOT/github" \
    --scratch-path "${TMPDIR:-/tmp}/fcomrqz-github-token-manager-tests" \
    --disable-sandbox
fi

if command -v caddy >/dev/null 2>&1; then
  caddy validate --config "$ROOT/caddy/caddy.json"
fi

printf 'All static checks passed.\n'
