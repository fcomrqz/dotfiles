#!/bin/bash

set -euo pipefail

DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DOTFILES_ROOT

case "$(uname -s)" in
  Darwin)
    exec /bin/bash "$DOTFILES_ROOT/install/macos.sh" "$@"
    ;;
  Linux)
    exec /bin/bash "$DOTFILES_ROOT/install/linux.sh" "$@"
    ;;
  *)
    printf 'Unsupported operating system: %s\n' "$(uname -s)" >&2
    exit 1
    ;;
esac
