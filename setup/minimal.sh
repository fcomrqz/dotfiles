!/bin/bash

echo ' Installing "Command Line Tools"'
echo ' Homebrew: macOS package manager'
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
clear

echo ' Installing "Command Line Tools"'
echo ' gum: A tool for glamorous shell scripts'
brew install gum
clear

touch ~/.hushlogin # Remove the last login message when you open Terminal.app

mkdir ~/.config

clear

gum log --prefix Installing "Command Line Tools"

gum spin --title "fish: Finally, a command line shell for the 90s" -- brew install fish
gum spin --title "fish: Finally, a command line shell for the 90s" -- mkdir ~/.config/fish
gum spin --title "fish: Finally, a command line shell for the 90s" -- ln -sF ~/Developer/fcomrqz/dotfiles/shells/fish/functions ~/.config/fish/functions
gum spin --title "fish: Finally, a command line shell for the 90s" -- ln -sF ~/Developer/fcomrqz/dotfiles/shells/fish/config.fish ~/.config/fish/config.fish

gum spin --title "node: JavaScript Runtime built on Google V8" -- brew install node
gum spin --title "node: JavaScript Runtime built on Google V8" -- ln -sF ~/Developer/fcomrqz/dotfiles/npm/.npmrc ~/.npmrc

gum spin --title "bun: JavaScript Runtime built on Apple JavaScriptCore" -- curl -fsSL https://bun.sh/install | bash > /dev/null 2>&1
gum spin --title "bun: JavaScript Runtime built on Apple JavaScriptCore" -- ln -sF ~/Developer/fcomrqz/dotfiles/bun/.bunfig.toml ~/.bunfig.toml

gum spin --title "git: The stupid content tracker" -- brew install git
gum spin --title "git: The stupid content tracker" -- ln -sF ~/Developer/fcomrqz/dotfiles/git/.gitconfig ~/.gitconfig

gum spin --title "jj: Git-compatible distributed version control system" -- brew install jj
gum spin --title "jj: Git-compatible distributed version control system" -- mkdir ~/.config/jj
gum spin --title "jj: Git-compatible distributed version control system" -- ln -sF ~/Developer/fcomrqz/dotfiles/jujutsu/jujutsu.config.toml ~/.config/jj/config.toml

gum spin --title "direnv: Load/unload environment variables based on \$PWD" -- brew install direnv
gum spin --title "direnv: Load/unload environment variables based on \$PWD" -- ln -sF ~/Developer/fcomrqz/dotfiles/direnv/direnv.toml ~/.config/direnv/direnv.toml

gum spin --title "gh: GitHub CLI" -- brew install gh
gum spin --title "gh: GitHub CLI" -- mkdir ~/.config/gh
gum spin --title "gh: GitHub CLI" -- ln -sF ~/Developer/fcomrqz/dotfiles/gh/config.yml ~/.config/gh/config.yml

gum spin --title "gitui: git graphical interface" -- brew install gitui
gum spin --title "gitui: git graphical interface" -- mkdir ~/.config/gitui
gum spin --title "gitui: git graphical interface" -- ln -sF ~/Developer/fcomrqz/dotfiles/gitui/key_bindings.ron ~/.config/gitui/key_bindings.ron

gum spin --title "delta: A better diff" -- brew install git-delta

gum spin --title "bat: A cat clone with syntax highlighting and Git integration" -- brew install bat
gum spin --title "bat: A cat clone with syntax highlighting and Git integration" -- mkdir ~/.config/bat
gum spin --title "bat: A cat clone with syntax highlighting and Git integration" -- ln -sF ~/Developer/fcomrqz/dotfiles/bat/.batrc ~/.config/bat/.batrc

gum spin --title "screen: Terminal multiplexer with VT100/ANSI terminal emulation" -- brew install screen
gum spin --title "screen: Terminal multiplexer with VT100/ANSI terminal emulation" -- ln -sF ~/Developer/fcomrqz/dotfiles/screen/.screenrc ~/.screenrc

gum spin --title "htop: An interactive process viewer" -- brew install htop
gum spin --title "htop: An interactive process viewer" -- mkdir ~/.config/htop
gum spin --title "htop: An interactive process viewer" -- ln -sF ~/Developer/fcomrqz/dotfiles/htop/htoprc ~/.config/htop/htoprc

gum spin --title "swift-format: Formatting technology for Swift source code" -- brew install swift-format

gum spin --title "flyctl: Command Line Tools for fly.io services" -- brew install flyctl

clear

gum log --prefix Installing "npm global packages"
gum spin --title "np: A better `npm publish`" -- bun i -g np
# gum spin --title "prettier: Opinionated code formatter" -- bun i -g prettier && bun i -g prettier-plugin-toml && ln -sF ~/Developer/fcomrqz/dotfiles/prettier/.prettierrc ~/
# gum spin --title "stylelint: A mighty CSS linter that helps you avoid errors and enforce conventions" -- bun i -g stylelint
# gum spin --title "postcss: Transforming styles with JS plugins" -- bun i -g postcss
# gum spin --title "postcss-html: PostCSS syntax for parsing HTML (and HTML-like)" -- npm i -g postcss-html
# clear


gum log --prefix Installing "Desktop Apps"
gum spin --title "Zed: Code at the speed of thought" -- brew install --cask zed
gum spin --title "Zed: Code at the speed of thought" -- mkdir ~/.config/zed
gum spin --title "Zed: Code at the speed of thought" -- ln -sF ~/Developer/fcomrqz/dotfiles/zed/settings.json ~/.config/zed/settings.json
gum spin --title "Zed: Code at the speed of thought" -- ln -sF ~/Developer/fcomrqz/dotfiles/zed/keymap.json ~/.config/zed/keymap.json

gum spin --title "Dataflare: Manage Your Database Better" -- brew install --cask dataflare

# gum spin --title "deno: Runtime for JavaScript, TypeScript, and WebAssembly built on Google V8 and Rust" -- curl -fsSL https://deno.land/install.sh | sh > /dev/null 2>&1

# Jupyter is Zed's REPL engine
# gum spin --title "jupyter: Documents that combine live code, equations, visualizations, and narrative text" -- deno jupyter --install

clear
