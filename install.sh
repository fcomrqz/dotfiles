#!/bin/bash

set -euo pipefail

# Install gum
mkdir ~/.gum
curl -sfL https://github.com/charmbracelet/gum/releases/download/v0.14.5/gum_0.14.5_Darwin_arm64.tar.gz | tar -xz --strip-components=1 -C ~/.gum

~/.gum/gum log --prefix Authorizing "Required sudo permissions to install Command Line Tools"
sudo -v

~/.gum/gum spin --title "Accepting Xcode License" -- sudo xcodebuild -license accept

~/.gum/gum spin --title "Creating Homebrew folder" -- sudo mkdir -p /opt/homebrew/bin

USER_NAME="${SUDO_USER:-$(id -un)}"

ENTRY="$USER_NAME ALL=(ALL) NOPASSWD: /Library/Application\ Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon"
TMP="$(mktemp)"; trap 'rm -f "$TMP"' EXIT
echo "$ENTRY" > "$TMP"
~/.gum/gum spin --title "Creating Karabiner DriverKit VirtualHIDDevice sudoers entry" -- sudo install -o root -g wheel -m 440 "$TMP" /etc/sudoers.d/karabiner

ENTRY="$USER_NAME ALL=(ALL) NOPASSWD: /opt/homebrew/bin/kanata"
TMP="$(mktemp)"; trap 'rm -f "$TMP"' EXIT
echo "$ENTRY" > "$TMP"
~/.gum/gum spin --title "Creating sudoers entry" -- sudo install -o root -g wheel -m 440 "$TMP" /etc/sudoers.d/kanata

clear

~/.gum/gum log --prefix Installing "Command Line Tools"
~/.gum/gum spin --title "Homebrew: macOS package manager" -- /bin/bash -c "$(curl -sfL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

touch ~/.hushlogin
mkdir ~/.config

~/.gum/gum spin --title "fish: Finally, a command line shell for the 90s" -- brew install fish
~/.gum/gum spin --title "fish: Finally, a command line shell for the 90s" -- mkdir ~/.config/fish
~/.gum/gum spin --title "fish: Finally, a command line shell for the 90s" -- ln -sF ~/Developer/fcomrqz/dotfiles/fish/functions ~/.config/fish/functions
~/.gum/gum spin --title "fish: Finally, a command line shell for the 90s" -- ln -sF ~/Developer/fcomrqz/dotfiles/fish/config.fish ~/.config/fish/config.fish

~/.gum/gum spin --title "node: JavaScript Runtime built on Google V8" -- brew install node
~/.gum/gum spin --title "node: JavaScript Runtime built on Google V8" -- ln -sF ~/Developer/fcomrqz/dotfiles/npm/.npmrc ~/.npmrc

~/.gum/gum spin --title "bun: JavaScript Runtime built on Apple JavaScriptCore" -- curl -fsSL https://bun.sh/install | bash > /dev/null 2>&1
~/.gum/gum spin --title "bun: JavaScript Runtime built on Apple JavaScriptCore" -- ln -sF ~/Developer/fcomrqz/dotfiles/bun/.bunfig.toml ~/.bunfig.toml

~/.gum/gum spin --title "git: The stupid content tracker" -- brew install git
~/.gum/gum spin --title "git: The stupid content tracker" -- ln -sF ~/Developer/fcomrqz/dotfiles/git/.gitconfig ~/.gitconfig

~/.gum/gum spin --title "jj: Git-compatible distributed version control system" -- brew install jj
~/.gum/gum spin --title "jj: Git-compatible distributed version control system" -- mkdir ~/.config/jj
~/.gum/gum spin --title "jj: Git-compatible distributed version control system" -- ln -sF ~/Developer/fcomrqz/dotfiles/jujutsu/jujutsu.config.toml ~/.config/jj/config.toml

~/.gum/gum spin --title "direnv: Load/unload environment variables based on \$PWD" -- brew install direnv
~/.gum/gum spin --title "direnv: Load/unload environment variables based on \$PWD" -- mkdir ~/.config/direnv
~/.gum/gum spin --title "direnv: Load/unload environment variables based on \$PWD" -- ln -sF ~/Developer/fcomrqz/dotfiles/direnv/direnv.toml ~/.config/direnv/direnv.toml

~/.gum/gum spin --title "gh: GitHub CLI" -- brew install gh
~/.gum/gum spin --title "gh: GitHub CLI" -- mkdir ~/.config/gh
~/.gum/gum spin --title "gh: GitHub CLI" -- ln -sF ~/Developer/fcomrqz/dotfiles/gh/config.yml ~/.config/gh/config.yml

~/.gum/gum spin --title "gitui: git graphical interface" -- brew install gitui
~/.gum/gum spin --title "gitui: git graphical interface" -- mkdir ~/.config/gitui
~/.gum/gum spin --title "gitui: git graphical interface" -- ln -sF ~/Developer/fcomrqz/dotfiles/gitui/key_bindings.ron ~/.config/gitui/key_bindings.ron

~/.gum/gum spin --title "delta: A better diff" -- brew install git-delta

~/.gum/gum spin --title "bat: A cat clone with syntax highlighting and Git integration" -- brew install bat
~/.gum/gum spin --title "bat: A cat clone with syntax highlighting and Git integration" -- mkdir ~/.config/bat
~/.gum/gum spin --title "bat: A cat clone with syntax highlighting and Git integration" -- ln -sF ~/Developer/fcomrqz/dotfiles/bat/.batrc ~/.config/bat/.batrc

~/.gum/gum spin --title "screen: Terminal multiplexer with VT100/ANSI terminal emulation" -- brew install screen
~/.gum/gum spin --title "screen: Terminal multiplexer with VT100/ANSI terminal emulation" -- ln -sF ~/Developer/fcomrqz/dotfiles/screen/.screenrc ~/.screenrc

~/.gum/gum spin --title "htop: An interactive process viewer" -- brew install htop
~/.gum/gum spin --title "htop: An interactive process viewer" -- mkdir ~/.config/htop
~/.gum/gum spin --title "htop: An interactive process viewer" -- ln -sF ~/Developer/fcomrqz/dotfiles/htop/htoprc ~/.config/htop/htoprc

~/.gum/gum spin --title "swift-format: Formatting technology for Swift source code" -- brew install swift-format

~/.gum/gum spin --title "flyctl: Command Line Tools for fly.io services" -- brew install flyctl

~/.gum/gum spin --title "stripe: Command Line Tools for Stripe services" -- brew install stripe/stripe-cli/stripe

~/.gum/gum spin --title "sqlite: Command-line interface for SQLite" -- brew install sqlite

~/.gum/gum spin --title "mongodb-community: MongoDB server" -- brew tap mongodb/brew

~/.gum/gum spin --title "mongodb-community: MongoDB server" -- brew install mongodb-community

~/.gum/gum spin --title "mongodb-database-tools: standard utilities" -- brew install mongodb-database-tools

~/.gum/gum spin --title "mongosh: MongoDB Shell" -- brew install mongosh

~/.gum/gum spin --title "httpie: HTTP client for the API era" -- brew install httpie

~/.gum/gum spin --title "httpstat: Curl statistics made simple" -- brew install httpstat

~/.gum/gum spin --title "dog: DNS client" -- brew install dog

~/.gum/gum spin --title "jq: Lightweight and flexible command-line JSON processor" -- brew install jq

~/.gum/gum spin --title "ripgrep: Better grep" -- brew install ripgrep

~/.gum/gum spin --title "rename: Rename multiple files" -- brew install rename

~/.gum/gum spin --title "trash: tool that moves files or folder to the trash" -- brew install trash

~/.gum/gum spin --title "scc: Fast and accurate code counter with complexity and COCOMO estimates" -- brew install scc

~/.gum/gum spin --title "mas: AppStore CLI" -- brew install mas

~/.gum/gum spin --title "ollama: Create, run, and share large language models (LLMs)" -- brew install ollama

~/.gum/gum spin --title "cloudflared: Cloudflare Tunnel client" -- brew install cloudflared

~/.gum/gum spin --title "codex: OpenAI's coding agent that runs in your terminal" -- brew install --cask codex

~/.gum/gum spin --title "claude-code: Terminal-based AI coding assistant" -- brew install --cask claude-code

~/.gum/gum spin --title "sox: SOund eXchange universal sound sample translator (rec, play)" -- brew install sox

~/.gum/gum spin --title "kanata: Keyboard remapper" -- brew install kanata
~/.gum/gum spin --title "kanata: Keyboard remapper" -- ln ~/Developer/fcomrqz/dotfiles/kanata/kanata.plist ~/Library/LaunchAgents/com.fcomrqz.kanata.plist
~/.gum/gum spin --title "kanata: Keyboard remapper" -- launchctl load ~/Library/LaunchAgents/com.fcomrqz.kanata.plist
~/.gum/gum spin --title "kanata: Keyboard remapper" -- ln ~/Developer/fcomrqz/dotfiles/kanata/karabiner.plist ~/Library/LaunchAgents/com.fcomrqz.karabiner.plist
~/.gum/gum spin --title "kanata: Keyboard remapper" -- launchctl load ~/Library/LaunchAgents/com.fcomrqz.karabiner.plist


~/.gum/gum spin --title "micro: A modern and intuitive terminal-based text editor" -- brew install micro
~/.gum/gum spin --title "micro: A modern and intuitive terminal-based text editor" -- mkdir ~/.config/micro
~/.gum/gum spin --title "micro: A modern and intuitive terminal-based text editor" -- ln -sF ~/Developer/fcomrqz/dotfiles/micro/settings.json ~/.config/micro/settings.json
~/.gum/gum spin --title "micro: A modern and intuitive terminal-based text editor" -- ln -sF ~/Developer/fcomrqz/dotfiles/micro/bindings.json ~/.config/micro/bindings.json
~/.gum/gum spin --title "micro: A modern and intuitive terminal-based text editor" -- ln -sF ~/Developer/fcomrqz/dotfiles/micro/syntax ~/.config/micro/syntax
~/.gum/gum spin --title "micro: A modern and intuitive terminal-based text editor" -- ln -sF ~/Developer/fcomrqz/dotfiles/micro/colorschemes ~/.config/micro/colorschemes

~/.gum/gum spin --title "keytics: Keyboard Analytics" -- ln ~/Developer/fcomrqz/dotfiles/keytics/keytics.plist ~/Library/LaunchAgents/com.fcomrqz.keytics.plist
~/.gum/gum spin --title "keytics: Keyboard Analytics" -- launchctl load ~/Library/LaunchAgents/com.fcomrqz.keytics.plist

~/.gum/gum spin --title "dark-mode: Toggle Apple Terminal theme based in macOS dark mode" -- ln ~/Developer/fcomrqz/dotfiles/terminal/dark-mode/dark-mode.plist ~/Library/LaunchAgents/com.fcomrqz.dark-mode.plist
~/.gum/gum spin --title "dark-mode: Toggle Apple Terminal theme based in macOS dark mode" -- launchctl load ~/Library/LaunchAgents/com.fcomrqz.dark-mode.plist
clear

~/.gum/gum log --prefix Installing "npm global packages"
~/.gum/gum spin --title "np: A better `npm publish`" -- bun i -g np
# ~/.gum/gum spin --title "prettier: Opinionated code formatter" -- bun i -g prettier && bun i -g prettier-plugin-toml && ln -sF ~/Developer/fcomrqz/dotfiles/prettier/.prettierrc ~/
# ~/.gum/gum spin --title "stylelint: A mighty CSS linter that helps you avoid errors and enforce conventions" -- bun i -g stylelint
# ~/.gum/gum spin --title "postcss: Transforming styles with JS plugins" -- bun i -g postcss
# ~/.gum/gum spin --title "postcss-html: PostCSS syntax for parsing HTML (and HTML-like)" -- npm i -g postcss-html
clear


~/.gum/gum log --prefix Installing "Desktop Apps"
~/.gum/gum spin --title "Zed: Code at the speed of thought" -- brew install --cask zed
~/.gum/gum spin --title "Zed: Code at the speed of thought" -- mkdir ~/.config/zed
~/.gum/gum spin --title "Zed: Code at the speed of thought" -- ln -sF ~/Developer/fcomrqz/dotfiles/zed/settings.json ~/.config/zed/settings.json
~/.gum/gum spin --title "Zed: Code at the speed of thought" -- ln -sF ~/Developer/fcomrqz/dotfiles/zed/keymap.json ~/.config/zed/keymap.json

~/.gum/gum spin --title "Aerospace: Tiling Window Manager for macOS" -- brew install --cask nikitabobko/tap/aerospace
~/.gum/gum spin --title "Aerospace: Tiling Window Manager for macOS" -- ln -sF ~/Developer/fcomrqz/dotfiles/aerospace/.aerospace.toml ~/.aerospace.toml

~/.gum/gum spin --title "Google Chrome: Google's Web Browser" -- brew install --cask google-chrome

~/.gum/gum spin --title "MongoDB Compass: GUI for MongoDB" -- brew install --cask mongodb-compass

# ~/.gum/gum spin --title "Proxyman: Apple Native Web Debugging Proxy" -- brew install --cask proxyman

~/.gum/gum spin --title "OrbStack: Fast, light, powerful way to run containers" -- brew install --cask orbstack

~/.gum/gum spin --title "Keycastr: Mesh VPN based on WireGuard" -- brew install --cask keycastr

~/.gum/gum spin --title "Figma: The collaborative interface design tool" -- brew install --cask figma

~/.gum/gum spin --title "Tailscale: Mesh VPN based on WireGuard" -- brew install --cask tailscale

# ~/.gum/gum spin --title "Android Studio: Integrated Development Environment for Android" brew install --cask android-studio

~/.gum/gum spin --title "ChatGPT: OpenAI's official desktop app" -- brew install --cask chatgpt

~/.gum/gum spin --title "SF Symbols: System font for Apple platforms" -- brew install --cask sf-symbols

~/.gum/gum spin --title "Parallels Desktop: Run Windows on Mac" -- brew install --cask parallels

~/.gum/gum spin --title "Dataflare: Manage Your Database Better" -- brew install --cask dataflare

~/.gum/gum spin --title "Blackholde: Virtual Audio Driver" -- brew install --cask blackhole-2ch

clear

~/.gum/gum log --prefix Installing "Desktop Apps from AppStore"
~/.gum/gum spin --title "Xcode: Developer Tools" -- mas install 497799835
~/.gum/gum spin --title "Numbers: Create impressive spreadsheets" -- mas install 409203825
~/.gum/gum spin --title "WhatsApp: Simple. Reliable. Private." -- mas install 310633997
~/.gum/gum spin --title "Pure Paste: Paste as plain text by default" -- mas install 1611378436
~/.gum/gum spin --title "Pandan: Time awareness tool" -- mas install 1569600264
~/.gum/gum spin --title "Base: SQLite Editor" -- mas install 6744867438
~/.gum/gum spin --title "Things: Organize your life" -- mas install 904280696

clear
