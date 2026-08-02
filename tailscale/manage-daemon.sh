#!/bin/bash

set -euo pipefail

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_ROOT
readonly LABEL="com.tailscale.tailscaled"
readonly TEMPLATE="$SCRIPT_ROOT/tailscale.plist"
readonly DESTINATION="/Library/LaunchDaemons/$LABEL.plist"
readonly LOG_DIRECTORY="/Library/Logs/Tailscale"
readonly LOG_FILE="$LOG_DIRECTORY/tailscaled.log"

usage() {
  cat <<'EOF'
Usage:
  manage-daemon.sh install TAILSCALED
  manage-daemon.sh status
  manage-daemon.sh enable-ssh
  manage-daemon.sh disable-ssh
  manage-daemon.sh uninstall
  manage-daemon.sh render TAILSCALED DESTINATION

The install, enable-ssh, disable-ssh, and uninstall commands require root.
The render command exists for validation and does not change system state.
EOF
}

log_info() {
  printf '• %s\n' "$*"
}

log_success() {
  printf '✓ %s\n' "$*"
}

log_error() {
  printf '✗ %s\n' "$*" >&2
}

require_root() {
  if [[ "$(id -u)" -ne 0 ]]; then
    log_error "This operation must run as root."
    exit 1
  fi
}

validate_tailscaled() {
  local binary="$1"

  [[ "$binary" == /* ]] || {
    log_error "tailscaled must be an absolute path: $binary"
    return 2
  }
  [[ -f "$binary" && -x "$binary" ]] || {
    log_error "tailscaled is not an executable file: $binary"
    return 2
  }
}

render_plist() {
  local binary="$1"
  local destination="$2"
  local temporary

  validate_tailscaled "$binary"
  [[ ! -d "$destination" ]] || {
    log_error "Refusing to replace a directory: $destination"
    return 1
  }
  mkdir -p "$(dirname "$destination")"
  temporary="$(
    mktemp "$(dirname "$destination")/.$(basename "$destination").XXXXXX"
  )"
  cp "$TEMPLATE" "$temporary"
  /usr/libexec/PlistBuddy \
    -c "Set :ProgramArguments:0 $binary" \
    -c "Set :StandardOutPath $LOG_FILE" \
    -c "Set :StandardErrorPath $LOG_FILE" \
    "$temporary" >/dev/null
  plutil -lint "$temporary" >/dev/null
  chmod 0644 "$temporary"
  mv -f "$temporary" "$destination"
}

service_loaded() {
  launchctl print "system/$LABEL" >/dev/null 2>&1
}

service_running() {
  launchctl print "system/$LABEL" 2>/dev/null \
    | grep -Fq "state = running"
}

wait_for_service_removal() {
  local attempt=0

  while (( attempt < 30 )); do
    if ! service_loaded; then
      return 0
    fi
    sleep 0.1
    attempt=$(( attempt + 1 ))
  done
  log_error "Timed out while unloading $LABEL."
  return 1
}

wait_for_service_start() {
  local attempt=0

  while (( attempt < 50 )); do
    if service_running; then
      return 0
    fi
    sleep 0.1
    attempt=$(( attempt + 1 ))
  done
  log_error "Timed out while starting $LABEL."
  return 1
}

unload_service() {
  if service_loaded; then
    launchctl bootout "system/$LABEL"
    wait_for_service_removal
  fi
}

bootstrap_service() {
  launchctl bootstrap system "$DESTINATION"
  wait_for_service_start
}

install_daemon() {
  local binary="$1"
  local rendered backup="" had_previous=false

  require_root
  validate_tailscaled "$binary"
  install -d -o root -g wheel -m 0750 "$LOG_DIRECTORY"
  rendered="$(mktemp "${TMPDIR:-/tmp}/$LABEL.XXXXXX")"
  render_plist "$binary" "$rendered"

  if [[ -f "$DESTINATION" ]] && cmp -s "$rendered" "$DESTINATION"; then
    rm -f "$rendered"
    if service_running; then
      log_success "Tailscale system daemon is already current"
      return
    fi
    if service_loaded; then
      launchctl kickstart -k "system/$LABEL"
      wait_for_service_start
    else
      bootstrap_service
    fi
    log_success "Tailscale system daemon is running"
    return
  fi

  if [[ -f "$DESTINATION" ]]; then
    had_previous=true
    backup="$(mktemp "${TMPDIR:-/tmp}/$LABEL.backup.XXXXXX")"
    cp -p "$DESTINATION" "$backup"
  fi

  install -o root -g wheel -m 0644 "$rendered" "$DESTINATION"
  rm -f "$rendered"
  unload_service

  if bootstrap_service; then
    [[ -z "$backup" ]] || rm -f "$backup"
    log_success "Tailscale system daemon is installed and running"
    return
  fi

  log_error "The new daemon failed to start; restoring the previous service."
  unload_service || true
  if [[ "$had_previous" == "true" ]]; then
    install -o root -g wheel -m 0644 "$backup" "$DESTINATION"
    rm -f "$backup"
    bootstrap_service || {
      log_error "The previous Tailscale service could not be restored."
      return 1
    }
  else
    rm -f "$DESTINATION"
  fi
  return 1
}

installed_tailscaled() {
  [[ -f "$DESTINATION" ]] || {
    log_error "The Tailscale LaunchDaemon is not installed."
    return 1
  }
  /usr/libexec/PlistBuddy \
    -c "Print :ProgramArguments:0" \
    "$DESTINATION"
}

tailscale_client() {
  local daemon directory client

  daemon="$(installed_tailscaled)"
  directory="$(dirname "$daemon")"
  client="$directory/tailscale"
  [[ -f "$client" && -x "$client" ]] || {
    log_error "Could not find the Tailscale CLI next to $daemon."
    return 1
  }
  printf '%s\n' "$client"
}

enable_ssh() {
  local client

  require_root
  service_running || {
    log_error "The Tailscale system daemon is not running."
    return 1
  }
  client="$(tailscale_client)"
  if "$client" status >/dev/null 2>&1; then
    "$client" set --ssh
  else
    "$client" up --ssh
  fi
  log_success "Tailscale SSH is enabled"
}

disable_ssh() {
  local client

  require_root
  service_running || {
    log_error "The Tailscale system daemon is not running."
    return 1
  }
  client="$(tailscale_client)"
  "$client" set --ssh=false
  log_success "Tailscale SSH is disabled"
}

status_daemon() {
  local client

  if ! service_running; then
    log_error "Tailscale system daemon is not running."
    return 1
  fi
  log_success "Tailscale system daemon is running"
  client="$(tailscale_client)"
  "$client" status
}

uninstall_daemon() {
  require_root
  unload_service
  rm -f "$DESTINATION"
  log_success "Tailscale system daemon was removed"
  log_info "Tailscale authentication state and logs were preserved."
}

command_name="${1:-}"
case "$command_name" in
  install)
    [[ -n "${2:-}" && -z "${3:-}" ]] || {
      usage >&2
      exit 2
    }
    install_daemon "$2"
    ;;
  status)
    [[ -z "${2:-}" ]] || {
      usage >&2
      exit 2
    }
    status_daemon
    ;;
  enable-ssh)
    [[ -z "${2:-}" ]] || {
      usage >&2
      exit 2
    }
    enable_ssh
    ;;
  disable-ssh)
    [[ -z "${2:-}" ]] || {
      usage >&2
      exit 2
    }
    disable_ssh
    ;;
  uninstall)
    [[ -z "${2:-}" ]] || {
      usage >&2
      exit 2
    }
    uninstall_daemon
    ;;
  render)
    [[ -n "${2:-}" && -n "${3:-}" && -z "${4:-}" ]] || {
      usage >&2
      exit 2
    }
    render_plist "$2" "$3"
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
