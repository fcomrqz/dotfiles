#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly ROOT

temporary="$(mktemp -d)"
trap 'rm -rf "$temporary"' EXIT

secrets_directory="$temporary/home/.config/fcomrqz/secrets"
mkdir -p "$secrets_directory"
chmod 0700 "$temporary/home" "$temporary/home/.config" \
  "$temporary/home/.config/fcomrqz" "$secrets_directory"

cat > "$secrets_directory/example.env" <<'EOF'
EXAMPLE_TOKEN='development-only'
PLAIN_VALUE='available'
EOF
chmod 0600 "$secrets_directory/example.env"

# The quoted expression is evaluated by the child shell after secrets load.
# shellcheck disable=SC2016
HOME="$temporary/home" "$ROOT/bin/with-secrets" example \
  /bin/bash -c \
  '[[ "$EXAMPLE_TOKEN" == development-only && "$PLAIN_VALUE" == available ]]'

if HOME="$temporary/home" "$ROOT/bin/with-secrets" '../example' true \
  >/dev/null 2>&1; then
  printf 'with-secrets accepted an invalid project name\n' >&2
  exit 1
fi

chmod 0644 "$secrets_directory/example.env"
if HOME="$temporary/home" "$ROOT/bin/with-secrets" example true \
  >/dev/null 2>&1; then
  printf 'with-secrets accepted a group-readable secrets file\n' >&2
  exit 1
fi
chmod 0600 "$secrets_directory/example.env"

set +e
HOME="$temporary/home" "$ROOT/bin/with-secrets" example \
  /bin/bash -c 'exit 23'
status=$?
set -e
if [[ "$status" -ne 23 ]]; then
  printf 'with-secrets did not preserve the command status\n' >&2
  exit 1
fi

printf 'ok - project secret launcher\n'
