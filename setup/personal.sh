#!/bin/zsh
gum log --prefix Installing "Command Line Tools"
gum spin --title "sqlite: Command-line interface for SQLite" brew install sqlite
gum spin --title "mongodb-community: MongoDB server" brew tap mongodb/brew && brew install mongodb-community
gum spin --title "mongodb-database-tools: standard utilities" brew install mongodb-database-tools
gum spin --title "mongosh: MongoDB Shell" brew install mongosh
gum spin --title "displayplacer: Utility to configure multi-display resolutions and arrangements" brew install displayplacer
gum spin --title "skhd: Simple hotkey-daemon for macOS" brew install skhd && ln -sF ~/Developer/fcomrqz/dotfiles/skhd/.skhdrc ~/
gum spin --title "httpie: HTTP client for the API era" brew install httpie
gum spin --title "httpstat: Curl statistics made simple" brew install httpstat
gum spin --title "dog: DNS client" brew install dog
gum spin --title "jq: Lightweight and flexible command-line JSON processor" brew install jq
gum spin --title "ripgrep: Better grep" brew install ripgrep
gum spin --title "rename: Rename multiple files" brew install rename
gum spin --title "trash: tool that moves files or folder to the trash" brew install trash
gum spin --title "cloc: Count Lines of Code" brew install cloc
gum spin --title "mas: AppStore CLI" brew install mas
clear

gum log --prefix Installing "npm global packages"
gum spin --title "ncu: npm check updates" npm i -g npm-check-updates
gum spin --title "np: A better `npm publish`" npm i -g np
gum spin --title "lighthouse: Automated auditing, performance metrics, and best practices for the web." npm i -g lighthouse
clear

gum log --prefix Installing "Desktop Apps"
gum spin --title "Aerospace: Tiling Window Manager for macOS" brew install --cask aerospace && ln -sF ~/Developer/fcomrqz/dotfiles/aerospace/.aerospace.toml ~/
gum spin --title "Google Chrome: Google's Web Browser" brew install --cask google-chrome
gum spin --title "Loopback: Cable-Free Audio Routing" brew install --cask loopback
gum spin --title "Raycast: Better Spotlight" brew install --cask raycast
gum spin --title "MongoDB Compass: GUI for MongoDB" brew install --cask mongodb-compass
gum spin --title "Proxyman: Apple Native Web Debugging Proxy" brew install --cask proxyman
gum spin --title "OrbStack: Fast, light, powerful way to run containers" brew install --cask orbstack
gum spin --title "Keycastr: Mesh VPN based on WireGuard" brew install --cask keycastr
gum spin --title "Figma: The collaborative interface design tool" brew install --cask figma
# gum spin --title "Tailscale: Mesh VPN based on WireGuard" brew install --cask tailscale
# gum spin --title "  Android Studio:  Integrated Development Environment for Android" brew install --cask android-studio
clear

gum log --prefix Installing "Desktop Apps from AppStore"
gum spin --title "Xcode: Developer Tools" && mas install 497799835
gum spin --title "Things: Organize your life" && mas install 904280696
gum spin --title "Numbers: Create impressive spreadsheets" && mas install 409203825
gum spin --title "WhatsApp: Simple. Reliable. Private." && mas install 310633997
clear
