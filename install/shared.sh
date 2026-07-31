#!/bin/bash

# Shared installer UI and filesystem helpers. Keep this compatible with the
# Bash 3.2 version shipped by macOS.

readonly COLOR_BLUE=$'\033[34m'
readonly COLOR_GREEN=$'\033[32m'
readonly COLOR_RED=$'\033[31m'
readonly COLOR_RESET=$'\033[0m'

log_section() {
  printf '\n%s%s%s\n' "$COLOR_BLUE" "$*" "$COLOR_RESET"
}

log_info() {
  printf '%s•%s %s\n' "$COLOR_BLUE" "$COLOR_RESET" "$*"
}

log_success() {
  printf '%s✓%s %s\n' "$COLOR_GREEN" "$COLOR_RESET" "$*"
}

log_error() {
  printf '%s✗%s %s\n' "$COLOR_RED" "$COLOR_RESET" "$*" >&2
}

is_interactive_terminal() {
  [[ -t 2 && -z "${CI:-}" && "${TERM:-}" != "dumb" ]]
}

run_step() {
  local title="$1"
  shift

  if ! is_interactive_terminal; then
    log_info "$title"
    "$@"
    return
  fi

  local log_file pid frame_index=0 status
  local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  if [[ "${LC_ALL:-${LANG:-}}" != *UTF-8* && "${LC_ALL:-${LANG:-}}" != *utf8* ]]; then
    frames=('|' '/' '-' "\\")
  fi

  log_file="$(mktemp "${TMPDIR:-/tmp}/dotfiles-install.XXXXXX")"
  "$@" >"$log_file" 2>&1 &
  pid=$!

  # shellcheck disable=SC2064
  trap "kill -INT $pid 2>/dev/null || true" INT
  # shellcheck disable=SC2064
  trap "kill -TERM $pid 2>/dev/null || true" TERM

  while kill -0 "$pid" 2>/dev/null; do
    printf '\r\033[2K%s%s%s %s' \
      "$COLOR_BLUE" "${frames[$frame_index]}" "$COLOR_RESET" "$title" >&2
    frame_index=$(( (frame_index + 1) % ${#frames[@]} ))
    sleep 0.08
  done

  if wait "$pid"; then
    status=0
  else
    status=$?
  fi
  trap - INT TERM

  printf '\r\033[2K' >&2
  if [[ "$status" -eq 0 ]]; then
    log_success "$title"
  else
    log_error "$title"
    if [[ -s "$log_file" ]]; then
      sed 's/^/  /' "$log_file" >&2
    fi
  fi
  rm -f "$log_file"
  return "$status"
}

ensure_dir() {
  local directory="$1"
  mkdir -p "$directory"
}

safe_link() {
  local source="$1"
  local destination="$2"

  ensure_dir "$(dirname "$destination")"
  if [[ -L "$destination" ]]; then
    if [[ "$(readlink "$destination")" == "$source" ]]; then
      return 0
    fi
    rm "$destination"
  elif [[ -e "$destination" ]]; then
    log_error "Refusing to replace non-symlink: $destination"
    return 1
  fi
  ln -s "$source" "$destination"
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

require_root() {
  if [[ "$(id -u)" -ne 0 ]]; then
    log_error "This operation must run as root."
    exit 1
  fi
}

require_non_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    log_error "This operation must run as the development user."
    exit 1
  fi
}

download() {
  local url="$1"
  local destination="$2"
  curl --fail --silent --show-error --location "$url" --output "$destination"
}
