#!/bin/bash

set -euo pipefail

readonly SUPPORT_DIR="/Library/Application Support/com.fcomrqz.kanata"
readonly BIN_DIR="$SUPPORT_DIR/bin"
readonly LOG_DIR="/Library/Logs/Kanata"
readonly DEPLOYMENT_BACKUPS="$SUPPORT_DIR/deployment-backups"
readonly PREVIOUS_DEPLOYMENT="$SUPPORT_DIR/previous-deployment"
readonly STAGED_ROLLBACK="$SUPPORT_DIR/staged-rollback"
readonly KANATA_DEST="$BIN_DIR/kanata"
readonly LAUNCHER_DEST="$BIN_DIR/kanata-launcher"
readonly CONFIG_DEST="$SUPPORT_DIR/kanata.kbd"
readonly KANATA_PLIST="/Library/LaunchDaemons/com.fcomrqz.kanata.plist"
readonly KARABINER_PLIST="/Library/LaunchDaemons/com.fcomrqz.karabiner.plist"
readonly KANATA_LABEL="com.fcomrqz.kanata"
readonly KARABINER_LABEL="com.fcomrqz.karabiner"
readonly DEVICE_NAME="HHKB-Classic"
readonly KARABINER_DAEMON="/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_DIR
readonly SOURCE_LAUNCHER="$SCRIPT_DIR/kanata-launcher.sh"
readonly SOURCE_KANATA_PLIST="$SCRIPT_DIR/com.fcomrqz.kanata.plist"
readonly SOURCE_KARABINER_PLIST="$SCRIPT_DIR/com.fcomrqz.karabiner.plist"

usage() {
  echo "Usage:"
  echo "  sudo /bin/bash $0 install <kanata-binary> <kanata-config> <user-uid> <user-home>"
  echo "  sudo /bin/bash $0 stage <kanata-binary> <kanata-config>"
  echo "  sudo /bin/bash $0 activate-staged <user-uid> <user-home>"
  echo "  sudo /bin/bash $0 abort-staged"
  echo "  sudo /bin/bash $0 rollback"
}

require_root() {
  if [[ "$(id -u)" -ne 0 ]]; then
    echo "This command must run as root." >&2
    exit 1
  fi
}

job_exists() {
  /bin/launchctl print "$1" >/dev/null 2>&1
}

bootout_if_loaded() {
  local domain="$1"
  if job_exists "$domain"; then
    /bin/launchctl bootout "$domain"
  fi
}

stop_system_jobs() {
  bootout_if_loaded "system/$KANATA_LABEL"
  bootout_if_loaded "system/$KARABINER_LABEL"
}

suspend_system_jobs() {
  stop_system_jobs
  /bin/launchctl disable "system/$KANATA_LABEL"
  /bin/launchctl disable "system/$KARABINER_LABEL"
}

wait_for_running() {
  local domain="$1"
  local _

  for _ in {1..10}; do
    if /bin/launchctl print "$domain" 2>/dev/null | /usr/bin/grep -q "state = running"; then
      return 0
    fi
    /bin/sleep 1
  done
  return 1
}

device_is_present() {
  "$KANATA_DEST" --list 2>/dev/null | /usr/bin/grep -Fq "$DEVICE_NAME"
}

deployed_job_uses_launcher() {
  /usr/bin/plutil -extract ProgramArguments.0 raw "$KANATA_PLIST" 2>/dev/null \
    | /usr/bin/grep -Fq "$LAUNCHER_DEST"
}

kanata_child_is_running() {
  local launcher_pid
  launcher_pid="$(/bin/launchctl print "system/$KANATA_LABEL" 2>/dev/null \
    | /usr/bin/awk '/^[[:space:]]*pid = / { print $3; exit }')"
  [[ -n "$launcher_pid" ]] && /usr/bin/pgrep -P "$launcher_pid" -x kanata >/dev/null 2>&1
}

wait_for_kanata_child_if_required() {
  local _

  # Avoid probing devices while the running Kanata child has them open. On
  # macOS, a concurrent `kanata --list` can abort when the HID device is
  # already held exclusively by the remapping process.
  if ! deployed_job_uses_launcher || kanata_child_is_running || ! device_is_present; then
    return 0
  fi
  for _ in {1..10}; do
    if kanata_child_is_running; then
      return 0
    fi
    /bin/sleep 1
  done
  return 1
}

wait_for_stable_jobs() {
  local _

  for _ in {1..12}; do
    /bin/launchctl print "system/$KARABINER_LABEL" 2>/dev/null \
      | /usr/bin/grep -q "state = running" || return 1
    /bin/launchctl print "system/$KANATA_LABEL" 2>/dev/null \
      | /usr/bin/grep -q "state = running" || return 1
    # Check for the child before enumerating devices for the same reason as
    # wait_for_kanata_child_if_required above. Shell conditions short-circuit
    # from left to right.
    if deployed_job_uses_launcher && ! kanata_child_is_running && device_is_present; then
      return 1
    fi
    /bin/sleep 1
  done
  return 0
}

start_system_jobs() {
  /bin/launchctl enable "system/$KARABINER_LABEL" || return 1
  /bin/launchctl bootstrap system "$KARABINER_PLIST" || return 1
  /bin/sleep 1
  /bin/launchctl enable "system/$KANATA_LABEL" || return 1
  /bin/launchctl bootstrap system "$KANATA_PLIST" || return 1

  wait_for_running "system/$KARABINER_LABEL" \
    && wait_for_running "system/$KANATA_LABEL" \
    && wait_for_kanata_child_if_required \
    && wait_for_stable_jobs
}

snapshot_is_complete() {
  local snapshot="$1"
  [[ -d "$snapshot" \
    && -x "$snapshot/kanata" \
    && -f "$snapshot/kanata.kbd" \
    && -f "$snapshot/com.fcomrqz.kanata.plist" \
    && -f "$snapshot/com.fcomrqz.karabiner.plist" ]]
}

snapshot_current_deployment() {
  local timestamp snapshot

  if [[ ! -x "$KANATA_DEST" \
    || ! -f "$CONFIG_DEST" \
    || ! -f "$KANATA_PLIST" \
    || ! -f "$KARABINER_PLIST" ]]; then
    return 1
  fi

  timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
  snapshot="$DEPLOYMENT_BACKUPS/$timestamp-$$"
  /usr/bin/install -d -o root -g wheel -m 700 "$snapshot"
  /usr/bin/install -o root -g wheel -m 555 "$KANATA_DEST" "$snapshot/kanata"
  if [[ -f "$LAUNCHER_DEST" ]]; then
    /usr/bin/install -o root -g wheel -m 555 "$LAUNCHER_DEST" "$snapshot/kanata-launcher"
  fi
  /usr/bin/install -o root -g wheel -m 444 "$CONFIG_DEST" "$snapshot/kanata.kbd"
  /usr/bin/install -o root -g wheel -m 644 "$KANATA_PLIST" "$snapshot/com.fcomrqz.kanata.plist"
  /usr/bin/install -o root -g wheel -m 644 "$KARABINER_PLIST" "$snapshot/com.fcomrqz.karabiner.plist"
  echo "$snapshot"
}

validate_payload() {
  local binary="$1"
  local config="$2"
  local launcher="$3"
  local kanata_plist="$4"
  local karabiner_plist="$5"

  [[ -x "$binary" ]] || { echo "Kanata binary is not executable: $binary" >&2; return 1; }
  [[ -f "$config" ]] || { echo "Kanata configuration does not exist: $config" >&2; return 1; }
  [[ -z "$launcher" || -f "$launcher" ]] \
    || { echo "Kanata launcher does not exist: $launcher" >&2; return 1; }
  [[ -f "$kanata_plist" ]] || { echo "Kanata plist does not exist: $kanata_plist" >&2; return 1; }
  [[ -f "$karabiner_plist" ]] || { echo "Karabiner plist does not exist: $karabiner_plist" >&2; return 1; }

  "$binary" --check -c "$config"
  if [[ -n "$launcher" ]]; then
    /bin/bash -n "$launcher"
  fi
  /usr/bin/plutil -lint "$kanata_plist" "$karabiner_plist"
}

install_payload() {
  local binary="$1"
  local config="$2"
  local launcher="$3"
  local kanata_plist="$4"
  local karabiner_plist="$5"

  validate_payload "$binary" "$config" "$launcher" "$kanata_plist" "$karabiner_plist" || return 1
  /usr/bin/install -o root -g wheel -m 555 "$binary" "$KANATA_DEST" || return 1
  if [[ -n "$launcher" ]]; then
    /usr/bin/install -o root -g wheel -m 555 "$launcher" "$LAUNCHER_DEST" || return 1
  fi
  /usr/bin/install -o root -g wheel -m 444 "$config" "$CONFIG_DEST" || return 1
  /usr/bin/install -o root -g wheel -m 644 "$kanata_plist" "$KANATA_PLIST" || return 1
  /usr/bin/install -o root -g wheel -m 644 "$karabiner_plist" "$KARABINER_PLIST" || return 1
  validate_payload "$KANATA_DEST" "$CONFIG_DEST" "$launcher" "$KANATA_PLIST" "$KARABINER_PLIST"
}

activate_payload() {
  local binary="$1"
  local config="$2"
  local launcher="$3"
  local kanata_plist="$4"
  local karabiner_plist="$5"

  install_payload "$binary" "$config" "$launcher" "$kanata_plist" "$karabiner_plist" || return 1
  stop_system_jobs
  start_system_jobs
}

activate_snapshot() {
  local snapshot="$1"
  local launcher=""

  if ! snapshot_is_complete "$snapshot"; then
    echo "Deployment snapshot is incomplete: $snapshot" >&2
    return 1
  fi
  if [[ -f "$snapshot/kanata-launcher" ]]; then
    launcher="$snapshot/kanata-launcher"
  fi

  activate_payload \
    "$snapshot/kanata" \
    "$snapshot/kanata.kbd" \
    "$launcher" \
    "$snapshot/com.fcomrqz.kanata.plist" \
    "$snapshot/com.fcomrqz.karabiner.plist"
}

set_pointer() {
  local pointer="$1"
  local snapshot="$2"
  local temporary_link
  temporary_link="$SUPPORT_DIR/.$(basename "$pointer").$$"

  /bin/rm -f "$temporary_link"
  /bin/ln -s "$snapshot" "$temporary_link"
  /bin/mv -f "$temporary_link" "$pointer"
}

snapshot_from_pointer() {
  local pointer="$1"
  local snapshot

  [[ -L "$pointer" ]] || return 1
  snapshot="$(/usr/bin/readlink "$pointer")"
  case "$snapshot" in
    "$DEPLOYMENT_BACKUPS"/*) ;;
    *)
      echo "Refusing snapshot path outside deployment backups: $snapshot" >&2
      return 1
      ;;
  esac
  snapshot_is_complete "$snapshot" || return 1
  echo "$snapshot"
}

cleanup_legacy_artifacts() {
  local user_uid="$1"
  local user_home="$2"
  local home_owner

  [[ "$user_uid" =~ ^[0-9]+$ ]] \
    || { echo "Invalid user ID: $user_uid" >&2; return 1; }
  [[ "$user_home" == /Users/* && "$user_home" != *"/../"* && -d "$user_home" ]] \
    || { echo "Invalid user home: $user_home" >&2; return 1; }
  home_owner="$(/usr/bin/stat -f %u "$user_home")"
  [[ "$home_owner" == "$user_uid" ]] \
    || { echo "User home is not owned by UID $user_uid: $user_home" >&2; return 1; }

  bootout_if_loaded "gui/$user_uid/$KANATA_LABEL"
  bootout_if_loaded "gui/$user_uid/$KARABINER_LABEL"
  /bin/rm -f \
    "$user_home/Library/LaunchAgents/com.fcomrqz.kanata.plist" \
    "$user_home/Library/LaunchAgents/com.fcomrqz.karabiner.plist" \
    /etc/sudoers.d/kanata \
    /etc/sudoers.d/karabiner
  /bin/rm -rf "$SUPPORT_DIR/migration-backup"
}

restore_after_failure() {
  local snapshot="$1"

  stop_system_jobs
  if [[ -n "$snapshot" ]] && activate_snapshot "$snapshot"; then
    echo "Restored the previous protected system deployment." >&2
    return 0
  fi
  echo "Could not restore a previous protected deployment. Inspect $LOG_DIR." >&2
  return 1
}

prepare_directories() {
  /usr/bin/install -d -o root -g wheel -m 755 "$SUPPORT_DIR" "$BIN_DIR" "$LOG_DIR"
  /usr/bin/install -d -o root -g wheel -m 700 "$DEPLOYMENT_BACKUPS"
}

install_daemons() {
  if [[ "$#" -ne 4 ]]; then
    usage >&2
    exit 2
  fi

  local source_binary="$1"
  local source_config="$2"
  local user_uid="$3"
  local user_home="$4"
  local current_snapshot=""

  [[ -x "$KARABINER_DAEMON" ]] \
    || { echo "Karabiner VirtualHIDDevice daemon is not installed: $KARABINER_DAEMON" >&2; exit 1; }
  [[ ! -L "$STAGED_ROLLBACK" ]] \
    || { echo "A Kanata update is staged. Activate or abort it before installing." >&2; exit 1; }

  validate_payload "$source_binary" "$source_config" "$SOURCE_LAUNCHER" \
    "$SOURCE_KANATA_PLIST" "$SOURCE_KARABINER_PLIST"
  prepare_directories

  if [[ -x "$KANATA_DEST" ]] && ! /usr/bin/cmp -s "$source_binary" "$KANATA_DEST"; then
    echo "The Kanata binary changed. Use the stage/activate-staged workflow so macOS permissions can be renewed safely." >&2
    exit 1
  fi

  current_snapshot="$(snapshot_current_deployment || true)"
  if ! activate_payload "$source_binary" "$source_config" "$SOURCE_LAUNCHER" \
    "$SOURCE_KANATA_PLIST" "$SOURCE_KARABINER_PLIST"; then
    echo "The new deployment failed its health check." >&2
    restore_after_failure "$current_snapshot" || true
    exit 1
  fi

  if [[ -n "$current_snapshot" ]]; then
    set_pointer "$PREVIOUS_DEPLOYMENT" "$current_snapshot"
  fi
  cleanup_legacy_artifacts "$user_uid" "$user_home"

  echo "Kanata and Karabiner are running as root-owned system LaunchDaemons."
  [[ ! -L "$PREVIOUS_DEPLOYMENT" ]] \
    || echo "Rollback: sudo /bin/bash $SCRIPT_DIR/manage-daemons.sh rollback"
}

stage_update() {
  if [[ "$#" -ne 2 ]]; then
    usage >&2
    exit 2
  fi

  local source_binary="$1"
  local source_config="$2"
  local current_snapshot

  [[ ! -L "$STAGED_ROLLBACK" ]] \
    || { echo "A Kanata update is already staged." >&2; exit 1; }
  validate_payload "$source_binary" "$source_config" "$SOURCE_LAUNCHER" \
    "$SOURCE_KANATA_PLIST" "$SOURCE_KARABINER_PLIST"
  prepare_directories
  current_snapshot="$(snapshot_current_deployment)" \
    || { echo "A protected deployment is required before staging an update." >&2; exit 1; }

  set_pointer "$STAGED_ROLLBACK" "$current_snapshot"
  suspend_system_jobs
  if ! install_payload "$source_binary" "$source_config" "$SOURCE_LAUNCHER" \
    "$SOURCE_KANATA_PLIST" "$SOURCE_KARABINER_PLIST"; then
    echo "Could not stage the candidate; restoring the active deployment." >&2
    if activate_snapshot "$current_snapshot"; then
      /bin/rm -f "$STAGED_ROLLBACK"
    fi
    exit 1
  fi

  echo "Kanata update staged with system jobs intentionally stopped."
  echo "Grant Input Monitoring and Accessibility to: $KANATA_DEST"
  echo "Then run: sudo /bin/bash $SCRIPT_DIR/manage-daemons.sh activate-staged <user-uid> <user-home>"
}

activate_staged() {
  if [[ "$#" -ne 2 ]]; then
    usage >&2
    exit 2
  fi

  local user_uid="$1"
  local user_home="$2"
  local rollback_snapshot
  rollback_snapshot="$(snapshot_from_pointer "$STAGED_ROLLBACK")" \
    || { echo "No complete staged update is available." >&2; exit 1; }

  if ! start_system_jobs; then
    echo "The staged update failed its health check." >&2
    if restore_after_failure "$rollback_snapshot"; then
      /bin/rm -f "$STAGED_ROLLBACK"
    fi
    exit 1
  fi

  set_pointer "$PREVIOUS_DEPLOYMENT" "$rollback_snapshot"
  /bin/rm -f "$STAGED_ROLLBACK"
  cleanup_legacy_artifacts "$user_uid" "$user_home"
  echo "Activated the staged Kanata update."
}

abort_staged() {
  if [[ "$#" -ne 0 ]]; then
    usage >&2
    exit 2
  fi

  local rollback_snapshot
  rollback_snapshot="$(snapshot_from_pointer "$STAGED_ROLLBACK")" \
    || { echo "No complete staged update is available." >&2; exit 1; }
  activate_snapshot "$rollback_snapshot"
  /bin/rm -f "$STAGED_ROLLBACK"
  echo "Discarded the staged update and restored the protected deployment."
}

rollback_daemons() {
  if [[ "$#" -ne 0 ]]; then
    usage >&2
    exit 2
  fi

  local target_snapshot current_snapshot
  [[ ! -L "$STAGED_ROLLBACK" ]] \
    || { echo "Abort or activate the staged update before rollback." >&2; exit 1; }
  target_snapshot="$(snapshot_from_pointer "$PREVIOUS_DEPLOYMENT")" \
    || { echo "No complete protected deployment is available for rollback." >&2; exit 1; }
  current_snapshot="$(snapshot_current_deployment)"

  if ! activate_snapshot "$target_snapshot"; then
    echo "Rollback target failed its health check; restoring the current deployment." >&2
    restore_after_failure "$current_snapshot" || true
    exit 1
  fi

  set_pointer "$PREVIOUS_DEPLOYMENT" "$current_snapshot"
  echo "Restored protected deployment: $target_snapshot"
  echo "The deployment replaced by this rollback is now the next rollback target."
}

require_root

case "${1:-}" in
  install)
    shift
    install_daemons "$@"
    ;;
  stage)
    shift
    stage_update "$@"
    ;;
  activate-staged)
    shift
    activate_staged "$@"
    ;;
  abort-staged)
    shift
    abort_staged "$@"
    ;;
  rollback)
    shift
    rollback_daemons "$@"
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
