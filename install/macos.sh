#!/bin/bash

set -euo pipefail

DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly DOTFILES_ROOT
# shellcheck source=install/shared.sh
source "$DOTFILES_ROOT/install/shared.sh"

if [[ "$(uname -s)" != "Darwin" ]]; then
  log_error "The macOS installer can only run on Darwin."
  exit 1
fi

install_homebrew() {
  if command_exists brew \
    || [[ -x /opt/homebrew/bin/brew ]] \
    || [[ -x /usr/local/bin/brew ]]; then
    log_skip "Homebrew is already installed"
  else
    sudo -v
    run_step "Installing Homebrew package manager" \
      env NONINTERACTIVE=1 \
      /bin/bash -c \
      'set -o pipefail
      curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | /bin/bash'
  fi

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

install_formula() {
  local formula="$1"
  local title="${2:-$formula}"
  if ! brew list --formula "$formula" >/dev/null 2>&1; then
    run_step "Installing $title" brew install "$formula"
  else
    log_skip "$title is already installed"
  fi
}

install_cask() {
  local cask="$1"
  local title="${2:-$cask}"
  local application="${3:-}"
  local requires_sudo="${4:-false}"
  local installed_name="${cask##*/}"

  if brew list --cask "$installed_name" >/dev/null 2>&1 \
    || [[ -n "$application" && -d "$application" ]]; then
    log_skip "$title is already installed"
  else
    if [[ "$requires_sudo" == "true" ]]; then
      sudo -v
    fi
    run_step "Installing $title" brew install --cask "$cask"
  fi
}

install_mas_app() {
  local id="$1"
  local title="$2"
  local application="${3:?application path is required}"

  if [[ -d "$application" ]]; then
    log_skip "$title is already installed"
  else
    sudo -v
    run_step "Installing $title from the Mac App Store" mas install "$id"
  fi
}

kanata_system_is_current() {
  local support_directory="/Library/Application Support/com.fcomrqz.kanata"
  local kanata_binary
  kanata_binary="$(command -v kanata)"

  cmp -s "$kanata_binary" "$support_directory/bin/kanata" \
    && cmp -s \
      "$DOTFILES_ROOT/kanata/kanata.kbd" \
      "$support_directory/kanata.kbd" \
    && cmp -s \
      "$DOTFILES_ROOT/kanata/kanata-launcher.sh" \
      "$support_directory/bin/kanata-launcher" \
    && cmp -s \
      "$DOTFILES_ROOT/kanata/com.fcomrqz.kanata.plist" \
      /Library/LaunchDaemons/com.fcomrqz.kanata.plist \
    && cmp -s \
      "$DOTFILES_ROOT/kanata/com.fcomrqz.karabiner.plist" \
      /Library/LaunchDaemons/com.fcomrqz.karabiner.plist \
    && launchctl print system/com.fcomrqz.kanata 2>/dev/null \
      | grep -Fq "state = running" \
    && launchctl print system/com.fcomrqz.karabiner 2>/dev/null \
      | grep -Fq "state = running"
}

github_token_manager_source_fingerprint() {
  local file

  {
    shasum -a 256 < "$DOTFILES_ROOT/github/Package.swift"
    while IFS= read -r file; do
      shasum -a 256 < "$file"
    done < <(
      find "$DOTFILES_ROOT/github/Sources" -type f -print | LC_ALL=C sort
    )
  } | shasum -a 256 | awk '{print $1}'
}

migrate_github_token_manager() {
  local legacy_directory legacy_plist manager_directory domain

  legacy_directory="$HOME/Library/Application Support/com.fcomrqz.github-app"
  legacy_plist="$HOME/Library/LaunchAgents/com.fcomrqz.github-app.plist"
  manager_directory="$HOME/Library/Application Support/com.fcomrqz.github-token-manager"
  domain="gui/$(id -u)"

  if [[ -f "$legacy_directory/config.json" \
    && ! -e "$manager_directory/config.json" ]]; then
    ensure_dir "$manager_directory"
    /usr/bin/install -m 0600 \
      "$legacy_directory/config.json" "$manager_directory/config.json"
  fi

  launchctl bootout \
    "$domain/com.fcomrqz.github-app" >/dev/null 2>&1 || true
  rm -f -- "$legacy_plist" "$legacy_directory/bin/github-app-helper"
  if [[ -f "$legacy_directory/config.json" \
    && -f "$manager_directory/config.json" ]] \
    && cmp -s \
      "$legacy_directory/config.json" "$manager_directory/config.json"; then
    rm -f -- "$legacy_directory/config.json"
  fi
  rmdir "$legacy_directory/bin" "$legacy_directory" >/dev/null 2>&1 || true
}

install_github_token_manager() {
  local build_directory executable_directory executable fingerprint_file
  local installed_executable source_fingerprint template destination domain

  executable_directory="$HOME/Library/Application Support/com.fcomrqz.github-token-manager/bin"
  installed_executable="$executable_directory/github-token-manager"
  fingerprint_file="$executable_directory/source.sha256"
  source_fingerprint="$(github_token_manager_source_fingerprint)"

  ensure_dir "$executable_directory"
  chmod 0700 "$HOME/Library/Application Support/com.fcomrqz.github-token-manager"
  chmod 0700 "$executable_directory"

  if [[ -x "$installed_executable" \
    && -f "$fingerprint_file" \
    && "$(<"$fingerprint_file")" == "$source_fingerprint" ]]; then
    step_progress "the installed executable is current"
  else
    command_exists swift || {
      log_error "Swift is required to build the GitHub token manager."
      return 1
    }
    step_progress "compiling the Swift executable"
    build_directory="$(
      mktemp -d "${TMPDIR:-/tmp}/github-token-manager-build.XXXXXX"
    )"
    swift build \
      --package-path "$DOTFILES_ROOT/github" \
      --scratch-path "$build_directory" \
      --configuration release
    executable="$(
      find "$build_directory" -type f -name github-token-manager -perm -111 \
        -print -quit
    )"
    if [[ -z "$executable" ]]; then
      rm -rf -- "$build_directory"
      log_error "Swift did not produce the GitHub token manager executable."
      return 1
    fi

    step_progress "installing the manager executable"
    /usr/bin/install -m 0700 "$executable" "$installed_executable"
    printf '%s\n' "$source_fingerprint" > "$fingerprint_file"
    chmod 0600 "$fingerprint_file"
    rm -rf -- "$build_directory"
  fi

  migrate_github_token_manager
  step_progress "configuring the LaunchAgent"
  template="$DOTFILES_ROOT/github/com.fcomrqz.github-token-manager.plist"
  destination="$HOME/Library/LaunchAgents/com.fcomrqz.github-token-manager.plist"
  ensure_dir "$HOME/Library/Logs"
  write_launch_agent_plist \
    "$template" \
    "$destination" \
    "Set :ProgramArguments:0 $installed_executable" \
    "Set :StandardOutPath $HOME/Library/Logs/com.fcomrqz.github-token-manager.stdout.log" \
    "Set :StandardErrorPath $HOME/Library/Logs/com.fcomrqz.github-token-manager.stderr.log"

  # A fresh installation has no App credentials yet. Re-enable the agent only
  # when the existing Keychain and non-secret configuration are complete.
  if "$installed_executable" status --quiet >/dev/null 2>&1; then
    domain="gui/$(id -u)"
    launchctl bootout \
      "$domain/com.fcomrqz.github-token-manager" >/dev/null 2>&1 || true
    launchctl bootstrap "$domain" "$destination"
  fi
}

link_macos_configuration() {
  step_progress "linking Fish"
  ensure_dir "$HOME/.config/fish/themes"
  safe_link "$DOTFILES_ROOT/fish/functions" "$HOME/.config/fish/functions"
  safe_link "$DOTFILES_ROOT/fish/config.fish" "$HOME/.config/fish/config.fish"
  safe_link "$DOTFILES_ROOT/fish/themes/alavesper.theme" "$HOME/.config/fish/themes/alavesper.theme"

  step_progress "linking Git and GitHub CLI"
  safe_link "$DOTFILES_ROOT/git/.gitconfig" "$HOME/.gitconfig"
  ensure_dir "$HOME/.config/git"
  safe_link "$DOTFILES_ROOT/git/attributes" "$HOME/.config/git/attributes"
  safe_link "$DOTFILES_ROOT/git/macos.gitconfig" "$HOME/.config/git/platform.gitconfig"
  ensure_dir "$HOME/.config/gh"
  safe_link "$DOTFILES_ROOT/gh/config.yml" "$HOME/.config/gh/config.yml"

  step_progress "linking Zed and AeroSpace"
  ensure_dir "$HOME/.config/zed"
  safe_link "$DOTFILES_ROOT/zed/settings.json" "$HOME/.config/zed/settings.json"
  safe_link "$DOTFILES_ROOT/zed/keymap.json" "$HOME/.config/zed/keymap.json"
  safe_link "$DOTFILES_ROOT/zed/alavesper.json" "$HOME/.config/zed/themes/alavesper.json"
  safe_link "$DOTFILES_ROOT/aerospace/.aerospace.toml" "$HOME/.aerospace.toml"
  touch "$HOME/.hushlogin"
}

install_homebrew

log_section "Installing macOS command-line tools"
install_formula fish "Fish shell"
install_formula micro "Micro editor"
install_formula gh "GitHub CLI"
install_formula git-delta "Git Delta"
install_formula mas "Mac App Store CLI"
install_formula kanata "Kanata keyboard remapper"
install_formula tailscale "Tailscale"

log_section "Installing macOS desktop applications"
install_cask zed "Zed" "/Applications/Zed.app"
# install_cask nikitabobko/tap/aerospace "AeroSpace"
install_cask google-chrome "Google Chrome" \
  "/Applications/Google Chrome.app"
install_cask orbstack "OrbStack" "/Applications/OrbStack.app"
install_cask keycastr "KeyCastr" "/Applications/KeyCastr.app"
install_cask figma "Figma" "/Applications/Figma.app"
install_cask android-studio "Android Studio" \
  "/Applications/Android Studio.app"
install_cask temurin@17 "Temurin 17" \
  "/Library/Java/JavaVirtualMachines/temurin-17.jdk" \
  true
# install_cask chatgpt "ChatGPT"
install_cask parallels "Parallels Desktop" \
  "/Applications/Parallels Desktop.app"

log_section "Installing Mac App Store applications"
install_mas_app 497799835 "Xcode" "/Applications/Xcode.app"
install_mas_app 361304891 "Numbers" \
  "/Applications/Numbers Creator Studio.app"
install_mas_app 310633997 "WhatsApp" "/Applications/WhatsApp.app"
install_mas_app 1611378436 "Pure Paste" "/Applications/Pure Paste.app"
install_mas_app 1569600264 "Pandan" "/Applications/Pandan.app"
install_mas_app 6744867438 "Base" "/Applications/Base.app"
install_mas_app 904280696 "Things" "/Applications/Things3.app"

if command_exists xcodebuild \
  && ! xcodebuild -license check >/dev/null 2>&1; then
  sudo -v
  run_step "Accepting the Xcode license" sudo xcodebuild -license accept
elif command_exists xcodebuild; then
  log_skip "Xcode license is already accepted"
fi

run_step "Building macOS display controls" \
  make -C "$DOTFILES_ROOT/display"
run_step "Installing the display command" \
  safe_link "$DOTFILES_ROOT/display/display" "$(brew --prefix)/bin/display"

run_step "Installing GitHub token manager" install_github_token_manager

log_section "Configuring macOS"
run_step "Linking macOS configuration" link_macos_configuration

run_step "Validating Kanata configuration" \
  kanata --check -c "$DOTFILES_ROOT/kanata/kanata.kbd"
if kanata_system_is_current; then
  log_skip "Kanata system daemons are already current"
else
  sudo -v
  run_step "Installing Kanata system daemons" \
    sudo /bin/bash "$DOTFILES_ROOT/kanata/manage-daemons.sh" install \
      "$(command -v kanata)" "$DOTFILES_ROOT/kanata/kanata.kbd" "$(id -u)" "$HOME"
fi

run_step "Installing Keytics LaunchAgent" \
  install_launch_agent \
    com.fcomrqz.keytics \
    "$DOTFILES_ROOT/keytics/keytics.plist" \
    "$DOTFILES_ROOT/keytics/keytics"
run_step "Installing Terminal theme LaunchAgent" \
  install_launch_agent \
    com.fcomrqz.dark-mode \
    "$DOTFILES_ROOT/terminal/dark-mode/dark-mode.plist" \
    "$DOTFILES_ROOT/terminal/dark-mode/dark-mode"

run_step "Applying macOS defaults" /bin/bash "$DOTFILES_ROOT/macos/defaults.sh"

log_success "macOS setup is complete."
