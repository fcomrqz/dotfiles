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
  if ! command_exists brew; then
    run_step "Homebrew: macOS package manager" \
      env NONINTERACTIVE=1 \
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
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
    run_step "$title" brew install "$formula"
  fi
}

install_cask() {
  local cask="$1"
  local title="${2:-$cask}"
  local installed_name="${cask##*/}"
  if ! brew list --cask "$installed_name" >/dev/null 2>&1; then
    run_step "$title" brew install --cask "$cask"
  fi
}

install_mas_app() {
  local id="$1"
  local title="$2"
  if ! mas list | awk '{print $1}' | grep -Fxq "$id"; then
    run_step "$title" mas install "$id"
  fi
}

install_launch_agent() {
  local label="$1"
  local template="$2"
  local executable="$3"
  local destination="$HOME/Library/LaunchAgents/$label.plist"
  local domain
  domain="gui/$(id -u)"

  ensure_dir "$HOME/Library/LaunchAgents"
  cp "$template" "$destination"
  /usr/libexec/PlistBuddy -c "Set :ProgramArguments:0 $executable" "$destination"
  launchctl bootout "$domain/$label" >/dev/null 2>&1 || true
  launchctl bootstrap "$domain" "$destination"
}

install_github_app_helper() {
  local build_directory executable_directory executable template destination
  local domain

  command_exists swift || {
    log_error "Swift is required to build the GitHub App helper."
    return 1
  }
  build_directory="$(mktemp -d "${TMPDIR:-/tmp}/github-app-build.XXXXXX")"
  swift build \
    --package-path "$DOTFILES_ROOT/github" \
    --scratch-path "$build_directory" \
    --configuration release
  executable="$(
    find "$build_directory" -type f -name github-app-helper -perm -111 \
      -print -quit
  )"
  if [[ -z "$executable" ]]; then
    rm -rf -- "$build_directory"
    log_error "Swift did not produce the GitHub App helper executable."
    return 1
  fi

  executable_directory="$HOME/Library/Application Support/com.fcomrqz.github-app/bin"
  ensure_dir "$executable_directory"
  chmod 0700 "$HOME/Library/Application Support/com.fcomrqz.github-app"
  chmod 0700 "$executable_directory"
  /usr/bin/install -m 0700 \
    "$executable" "$executable_directory/github-app-helper"
  rm -rf -- "$build_directory"

  template="$DOTFILES_ROOT/github/com.fcomrqz.github-app.plist"
  destination="$HOME/Library/LaunchAgents/com.fcomrqz.github-app.plist"
  ensure_dir "$HOME/Library/LaunchAgents"
  cp "$template" "$destination"
  /usr/libexec/PlistBuddy -c \
    "Set :ProgramArguments:0 $executable_directory/github-app-helper" \
    "$destination"
  ensure_dir "$HOME/Library/Logs"
  /usr/libexec/PlistBuddy -c \
    "Set :StandardOutPath $HOME/Library/Logs/com.fcomrqz.github-app.stdout.log" \
    "$destination"
  /usr/libexec/PlistBuddy -c \
    "Set :StandardErrorPath $HOME/Library/Logs/com.fcomrqz.github-app.stderr.log" \
    "$destination"

  # A fresh installation has no App credentials yet. Re-enable the agent only
  # when the existing Keychain and non-secret configuration are complete.
  if "$executable_directory/github-app-helper" status --quiet \
    >/dev/null 2>&1; then
    domain="gui/$(id -u)"
    launchctl bootout \
      "$domain/com.fcomrqz.github-app" >/dev/null 2>&1 || true
    launchctl bootstrap "$domain" "$destination"
  fi
}

log_section "Authorizing required macOS changes"
sudo -v

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
install_cask zed "Zed"
# install_cask nikitabobko/tap/aerospace "AeroSpace"
install_cask google-chrome "Google Chrome"
install_cask orbstack "OrbStack"
install_cask keycastr "KeyCastr"
install_cask figma "Figma"
install_cask android-studio "Android Studio"
install_cask temurin@17 "Temurin 17"
install_cask chatgpt "ChatGPT"
install_cask sf-symbols "SF Symbols"
install_cask parallels "Parallels Desktop"

log_section "Installing Mac App Store applications"
install_mas_app 497799835 "Xcode"
install_mas_app 409203825 "Numbers"
install_mas_app 310633997 "WhatsApp"
install_mas_app 1611378436 "Pure Paste"
install_mas_app 1569600264 "Pandan"
install_mas_app 6744867438 "Base"
install_mas_app 904280696 "Things"

if command_exists xcodebuild; then
  sudo -v
  run_step "Accepting the Xcode license" sudo xcodebuild -license accept
fi

run_step "Building macOS display controls" \
  make -C "$DOTFILES_ROOT/display"
run_step "Installing the display command" \
  safe_link "$DOTFILES_ROOT/display/display" "$(brew --prefix)/bin/display"

run_step "Installing GitHub App token helper" install_github_app_helper

log_section "Linking macOS configuration"
ensure_dir "$HOME/.config/fish/themes"
safe_link "$DOTFILES_ROOT/fish/functions" "$HOME/.config/fish/functions"
safe_link "$DOTFILES_ROOT/fish/config.fish" "$HOME/.config/fish/config.fish"
safe_link "$DOTFILES_ROOT/fish/themes/alavesper.theme" "$HOME/.config/fish/themes/alavesper.theme"
safe_link "$DOTFILES_ROOT/git/.gitconfig" "$HOME/.gitconfig"
ensure_dir "$HOME/.config/git"
safe_link "$DOTFILES_ROOT/git/attributes" "$HOME/.config/git/attributes"
safe_link "$DOTFILES_ROOT/git/macos.gitconfig" "$HOME/.config/git/platform.gitconfig"
ensure_dir "$HOME/.config/gh"
safe_link "$DOTFILES_ROOT/gh/config.yml" "$HOME/.config/gh/config.yml"
ensure_dir "$HOME/.config/zed"
safe_link "$DOTFILES_ROOT/zed/settings.json" "$HOME/.config/zed/settings.json"
safe_link "$DOTFILES_ROOT/zed/keymap.json" "$HOME/.config/zed/keymap.json"
safe_link "$DOTFILES_ROOT/zed/alavesper.json" "$HOME/.config/zed/themes/alavesper.json"
safe_link "$DOTFILES_ROOT/aerospace/.aerospace.toml" "$HOME/.aerospace.toml"
touch "$HOME/.hushlogin"

sudo -v
run_step "Validating Kanata configuration" \
  kanata --check -c "$DOTFILES_ROOT/kanata/kanata.kbd"
run_step "Installing Kanata system daemons" \
  sudo /bin/bash "$DOTFILES_ROOT/kanata/manage-daemons.sh" install \
    "$(command -v kanata)" "$DOTFILES_ROOT/kanata/kanata.kbd" "$(id -u)" "$HOME"

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
