#!/bin/bash

# Shared installer UI and filesystem helpers. Keep this compatible with the
# Bash 3.2 version shipped by macOS.

readonly COLOR_BLUE=$'\033[34m'
readonly COLOR_GREEN=$'\033[32m'
readonly COLOR_YELLOW=$'\033[33m'
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

log_skip() {
  printf '%s↷%s %s\n' "$COLOR_YELLOW" "$COLOR_RESET" "$*"
}

log_error() {
  printf '%s✗%s %s\n' "$COLOR_RED" "$COLOR_RESET" "$*" >&2
}

is_interactive_terminal() {
  [[ -t 2 \
    && -z "${CI:-}" \
    && "${INSTALL_VERBOSE:-0}" != "1" \
    && "${TERM:-}" != "dumb" ]]
}

format_duration() {
  local elapsed="$1"
  if (( elapsed >= 60 )); then
    printf '%dm %ds' "$(( elapsed / 60 ))" "$(( elapsed % 60 ))"
  else
    printf '%ds' "$elapsed"
  fi
}

step_progress() {
  if [[ -n "${DOTFILES_PROGRESS_FILE:-}" ]]; then
    printf '%s\n' "$*" > "$DOTFILES_PROGRESS_FILE"
  else
    log_info "$*"
  fi
}

run_step() {
  local title="$1"
  shift
  local errexit_was_set=0
  local started_at=$SECONDS
  local elapsed status

  if ! is_interactive_terminal; then
    log_info "$title"
    if [[ "$-" == *e* ]]; then
      errexit_was_set=1
      set +e
    fi
    (
      if [[ "$errexit_was_set" -eq 1 ]]; then
        set -e
      fi
      "$@"
    )
    status=$?
    if [[ "$errexit_was_set" -eq 1 ]]; then
      set -e
    fi
    elapsed=$(( SECONDS - started_at ))
    if [[ "$status" -eq 0 ]]; then
      log_success "$title ($(format_duration "$elapsed"))"
    else
      log_error "$title ($(format_duration "$elapsed"))"
    fi
    return "$status"
  fi

  local log_file progress_file pid frame_index=0 detail message
  local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

  log_file="$(mktemp "${TMPDIR:-/tmp}/dotfiles-install.XXXXXX")"
  progress_file="$(mktemp "${TMPDIR:-/tmp}/dotfiles-progress.XXXXXX")"
  (
    export DOTFILES_PROGRESS_FILE="$progress_file"
    "$@"
  ) >"$log_file" 2>&1 &
  pid=$!

  # shellcheck disable=SC2064
  trap "kill -INT $pid 2>/dev/null || true" INT
  # shellcheck disable=SC2064
  trap "kill -TERM $pid 2>/dev/null || true" TERM

  while kill -0 "$pid" 2>/dev/null; do
    detail=""
    if [[ -s "$progress_file" ]]; then
      IFS= read -r detail < "$progress_file" || true
    fi
    message="$title"
    if [[ -n "$detail" ]]; then
      message="$title · $detail"
    fi
    printf '\r\033[2K%s%s%s %s' \
      "$COLOR_BLUE" "${frames[$frame_index]}" "$COLOR_RESET" "$message" >&2
    frame_index=$(( (frame_index + 1) % ${#frames[@]} ))
    sleep 0.08
  done

  if wait "$pid"; then
    status=0
  else
    status=$?
  fi
  trap - INT TERM

  elapsed=$(( SECONDS - started_at ))
  printf '\r\033[2K' >&2
  if [[ "$status" -eq 0 ]]; then
    log_success "$title ($(format_duration "$elapsed"))"
    rm -f "$log_file"
  else
    log_error "$title ($(format_duration "$elapsed"))"
    if [[ -s "$log_file" ]]; then
      printf '  Last output:\n' >&2
      tail -n "${INSTALL_FAILURE_LINES:-30}" "$log_file" \
        | sed 's/^/    /' >&2
    fi
    printf '  Full log: %s\n' "$log_file" >&2
  fi
  rm -f "$progress_file"
  return "$status"
}

ensure_dir() {
  local directory="$1"
  mkdir -p "$directory"
}

write_launch_agent_plist() {
  local template="$1"
  local destination="$2"
  shift 2
  local edit temporary

  [[ ! -d "$destination" ]] || {
    log_error "Refusing to replace LaunchAgent directory: $destination"
    return 1
  }
  ensure_dir "$(dirname "$destination")"
  temporary="$(
    mktemp "$(dirname "$destination")/.$(basename "$destination").XXXXXX"
  )"

  cp "$template" "$temporary" || {
    rm -f "$temporary"
    return 1
  }
  for edit in "$@"; do
    /usr/libexec/PlistBuddy -c "$edit" "$temporary" || {
      rm -f "$temporary"
      return 1
    }
  done
  plutil -lint "$temporary" >/dev/null || {
    rm -f "$temporary"
    return 1
  }
  chmod 0644 "$temporary"
  mv -f "$temporary" "$destination"
}

install_launch_agent() {
  local label="$1"
  local template="$2"
  local executable="$3"
  local destination="$HOME/Library/LaunchAgents/$label.plist"
  local domain rendered attempt
  domain="gui/$(id -u)"
  rendered="$(mktemp "${TMPDIR:-/tmp}/$label.XXXXXX")"

  write_launch_agent_plist \
    "$template" \
    "$rendered" \
    "Set :ProgramArguments:0 $executable"

  # Preserve a current loaded job instead of restarting it on every install.
  if [[ -f "$destination" ]] && cmp -s "$rendered" "$destination"; then
    rm -f "$rendered"
    if launchctl print "$domain/$label" >/dev/null 2>&1; then
      return
    fi
    launchctl bootstrap "$domain" "$destination"
    return
  fi

  # launchctl bootout may return before launchd finishes removing the job.
  # Wait before replacing and bootstrapping it to avoid error 37 being
  # surfaced by launchctl as the misleading error 5.
  if launchctl print "$domain/$label" >/dev/null 2>&1; then
    launchctl bootout "$domain/$label"
    attempt=0
    while (( attempt < 20 )); do
      if ! launchctl print "$domain/$label" >/dev/null 2>&1; then
        break
      fi
      sleep 0.05
      attempt=$(( attempt + 1 ))
    done
    if launchctl print "$domain/$label" >/dev/null 2>&1; then
      rm -f "$rendered"
      log_error "Timed out while unloading $label."
      return 1
    fi
  fi

  ensure_dir "$HOME/Library/LaunchAgents"
  /usr/bin/install -m 0644 "$rendered" "$destination"
  rm -f "$rendered"

  # A LaunchAgents directory watcher may load the new file first.
  attempt=0
  while (( attempt < 10 )); do
    if launchctl print "$domain/$label" >/dev/null 2>&1; then
      return
    fi
    sleep 0.05
    attempt=$(( attempt + 1 ))
  done
  launchctl bootstrap "$domain" "$destination"
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
