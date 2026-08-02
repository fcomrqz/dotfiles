#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=install/shared.sh
source "$ROOT/install/shared.sh"

temporary="$(mktemp -d)"
trap 'rm -rf "$temporary"' EXIT

success_output="$(
  CI=1 run_step "Running a successful step" \
    printf 'command output\n'
)"
[[ "$success_output" == *"Running a successful step"* ]]
[[ "$success_output" == *"command output"* ]]
[[ "$success_output" != *"(0s)"* ]]

if failure_output="$(
  CI=1 run_step "Running a failed step" \
    /bin/bash -c 'printf "failure details\n" >&2; exit 7' 2>&1
)"; then
  printf 'run_step did not preserve a failure status\n' >&2
  exit 1
fi
[[ "$failure_output" == *"Running a failed step"* ]]
[[ "$failure_output" == *"failure details"* ]]

if function_failure_output="$(
  CI=1 /bin/bash -c '
    set -euo pipefail
    source "$1"
    fail_before_last_command() {
      printf "before failure\n"
      false
      printf "after failure\n"
    }
    run_step "Running a function that fails early" fail_before_last_command
  ' bash "$ROOT/install/shared.sh" 2>&1
)"; then
  printf 'run_step masked a failure inside a shell function\n' >&2
  exit 1
fi
[[ "$function_failure_output" == *"before failure"* ]]
[[ "$function_failure_output" != *"after failure"* ]]
[[ "$function_failure_output" == *"Running a function that fails early"* ]]

if spinner_failure_output="$(
  is_interactive_terminal() {
    return 0
  }
  LC_ALL=C LANG=C LC_CTYPE=C \
    TMPDIR="$temporary" INSTALL_FAILURE_LINES=2 \
    run_step "Running an interactive failed step" \
    /bin/bash -c \
    'printf "first line\nsecond line\nthird line\n"; sleep 0.1; exit 9' 2>&1
)"; then
  printf 'interactive run_step did not preserve a failure status\n' >&2
  exit 1
fi
[[ "$spinner_failure_output" == *"⠋"* ]]
[[ "$spinner_failure_output" == *"Last output:"* ]]
[[ "$spinner_failure_output" == *"second line"* ]]
[[ "$spinner_failure_output" == *"third line"* ]]
[[ "$spinner_failure_output" == *"Full log:"* ]]
failure_log="$(
  find "$temporary" -type f -name 'dotfiles-install.*' -print -quit
)"
[[ -f "$failure_log" ]]
[[ "$(sed -n '1p' "$failure_log")" == "first line" ]]

skip_output="$(log_skip "Existing tool is already installed")"
[[ "$skip_output" == *"Existing tool is already installed"* ]]

progress_file="$temporary/progress"
DOTFILES_PROGRESS_FILE="$progress_file" step_progress "configuring a test phase"
[[ "$(cat "$progress_file")" == "configuring a test phase" ]]

if [[ "$(uname -s)" == "Darwin" ]]; then
  launch_agent_template="$temporary/launch-agent-template.plist"
  launch_agent_destination="$temporary/launch-agent.plist"
  cp "$ROOT/keytics/keytics.plist" "$launch_agent_template"
  ln "$launch_agent_template" "$launch_agent_destination"
  [[ "$launch_agent_template" -ef "$launch_agent_destination" ]]

  write_launch_agent_plist \
    "$launch_agent_template" \
    "$launch_agent_destination" \
    "Set :ProgramArguments:0 $temporary/first-executable"
  [[ ! "$launch_agent_template" -ef "$launch_agent_destination" ]]
  [[ "$(
    /usr/libexec/PlistBuddy \
      -c "Print :ProgramArguments:0" "$launch_agent_template"
  )" != "$temporary/first-executable" ]]
  [[ "$(
    /usr/libexec/PlistBuddy \
      -c "Print :ProgramArguments:0" "$launch_agent_destination"
  )" == "$temporary/first-executable" ]]

  write_launch_agent_plist \
    "$launch_agent_template" \
    "$launch_agent_destination" \
    "Set :ProgramArguments:0 $temporary/second-executable"
  [[ "$(
    /usr/libexec/PlistBuddy \
      -c "Print :ProgramArguments:0" "$launch_agent_destination"
  )" == "$temporary/second-executable" ]]

  launch_agent_loaded=false
  launch_agent_removal_pending=false
  launch_agent_removal_polls=0
  launch_agent_bootstraps=0
  launch_agent_bootouts=0
  launchctl() {
    case "$1" in
      print)
        if [[ "$launch_agent_removal_pending" == "true" ]]; then
          if (( launch_agent_removal_polls > 0 )); then
            launch_agent_removal_polls=$(( launch_agent_removal_polls - 1 ))
            return 0
          fi
          launch_agent_removal_pending=false
          launch_agent_loaded=false
        fi
        [[ "$launch_agent_loaded" == "true" ]]
        ;;
      bootout)
        launch_agent_bootouts=$(( launch_agent_bootouts + 1 ))
        launch_agent_removal_pending=true
        launch_agent_removal_polls=2
        ;;
      bootstrap)
        launch_agent_bootstraps=$(( launch_agent_bootstraps + 1 ))
        launch_agent_loaded=true
        ;;
      *)
        return 2
        ;;
    esac
  }

  HOME="$temporary/home" TMPDIR="$temporary" \
    install_launch_agent \
      com.fcomrqz.test \
      "$launch_agent_template" \
      "$temporary/first-executable"
  [[ "$launch_agent_bootstraps" -eq 1 ]]
  [[ "$launch_agent_bootouts" -eq 0 ]]

  HOME="$temporary/home" TMPDIR="$temporary" \
    install_launch_agent \
      com.fcomrqz.test \
      "$launch_agent_template" \
      "$temporary/first-executable"
  [[ "$launch_agent_bootstraps" -eq 1 ]]
  [[ "$launch_agent_bootouts" -eq 0 ]]

  HOME="$temporary/home" TMPDIR="$temporary" \
    install_launch_agent \
      com.fcomrqz.test \
      "$launch_agent_template" \
      "$temporary/second-executable"
  [[ "$launch_agent_bootstraps" -eq 2 ]]
  [[ "$launch_agent_bootouts" -eq 1 ]]
  [[ "$(
    /usr/libexec/PlistBuddy \
      -c "Print :ProgramArguments:0" \
      "$temporary/home/Library/LaunchAgents/com.fcomrqz.test.plist"
  )" == "$temporary/second-executable" ]]
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
