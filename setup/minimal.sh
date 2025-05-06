!/bin/bash
echo " Installing: Command Line Tools"
echo " Homebrew: macOS package manager"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
clear

echo " Installing: Command Line Tools"
echo " gum: A tool for glamorous shell scripts"
brew install gum
clear

# Add ~/.hushlogin to remove the last login message when you open Terminal.app
touch ~/.hushlogin

# Create config directory
mkdir ~/.config

gum log --prefix Installing "Command Line Tools"
gum spin --title "fish: Finally, a command line shell for the 90s" -- brew install fish && mkdir ~/.config/fish && ln -sF ~/Developer/fcomrqz/dotfiles/shells/fish/functions ~/.config/fish && ln -sF ~/Developer/fcomrqz/dotfiles/shells/fish/config.fish ~/.config/fish/config.fish
# gum spin --title "starship: The minimal, blazing-fast, and infinitely customizable prompt for any shell" -- brew install starship && ln -sF ~/Developer/fcomrqz/dotfiles/starship/starship.toml ~/.config/starship.toml && ln -sF ~/Developer/fcomrqz/dotfiles/shells/.bashrc ~/.bashrc && ln -sF ~/Developer/fcomrqz/dotfiles/shells/.zshrc ~/.zshrc
gum spin --title "node: JavaScript Runtime built on Google V8" -- brew install node
gum spin --title "bun: JavaScript Runtime built on Apple JavaScriptCore" -- curl -fsSL https://bun.sh/install | bash > /dev/null 2>&1
gum spin --title "deno: Runtime for JavaScript, TypeScript, and WebAssembly built on Google V8 and Rust" -- curl -fsSL https://deno.land/install.sh | sh > /dev/null 2>&1
gum spin --title "git: The stupid content tracker" -- brew install git && ln -sF ~/Developer/fcomrqz/dotfiles/git/.gitconfig ~/
gum spin --title "direnv: Load/unload environment variables based on \$PWD" -- brew install direnv && ln -sF ~/Developer/fcomrqz/dotfiles/direnv/direnv.toml ~/.config/direnv/
gum spin --title "gh: GitHub CLI" -- brew install gh && mkdir ~/.config/gh && ln -sF ~/Developer/fcomrqz/dotfiles/gh/config.yml ~/.config/gh/
gum spin --title "gitui: git graphical interface" -- brew install gitui && mkdir ~/.config/gitui && ln -sF ~/Developer/fcomrqz/dotfiles/gitui/theme.ron ~/.config/gitui/ && ln -sF ~/Developer/fcomrqz/dotfiles/gitui/key_bindings.ron ~/.config/gitui/
gum spin --title "delta: A better diff" -- brew install git-delta
gum spin --title "bat: A cat clone with syntax highlighting and Git integration" -- brew install bat && mkdir ~/.config/bat && ln -sF ~/Developer/fcomrqz/dotfiles/bat/.batrc ~/.config/bat/.batrc
gum spin --title "htop: An interactive process viewer" -- brew install htop && mkdir ~/.config/htop && ln -sF ~/Developer/fcomrqz/dotfiles/htop/htoprc ~/.config/htop/htoprc
gum spin --title "swift-format: Formatting technology for Swift source code" -- brew install swift-format
gum spin --title "flyctl: Command Line Tools for fly.io services" -- brew install flyctl
clear

gum log --prefix Installing "npm global packages"
gum spin --title "npm: node package manager" -- npm i -g npm@latest --force && ln -sF ~/Developer/fcomrqz/dotfiles/npm/.npmrc ~/
gum spin --title "ni: Use the right package manager" -- npm i -g @antfu/ni
gum spin --title "ncu: npm check updates" -- npm i -g npm-check-updates
gum spin --title "np: A better `npm publish`" -- npm i -g np
gum spin --title "prettier: Opinionated code formatter" -- npm i -g prettier && npm i -g prettier-plugin-toml && ln -sF ~/Developer/fcomrqz/dotfiles/prettier/.prettierrc ~/
gum spin --title "stylelint: A mighty CSS linter that helps you avoid errors and enforce conventions" -- npm i -g stylelint
gum spin --title "postcss: Transforming styles with JS plugins" -- npm i -g postcss
gum spin --title "postcss-html: PostCSS syntax for parsing HTML (and HTML-like)" -- npm i -g postcss-html
gum spin --title "lighthouse: Automated auditing, performance metrics, and best practices for the web." -- npm i -g lighthouse
clear

gum log --prefix Installing "Desktop Apps"
gum spin --title "Zed: Code at the speed of thought" -- brew install --cask zed && mkdir ~/.config/zed && ln -sF ~/Developer/fcomrqz/dotfiles/zed/settings.json ~/.config/zed/ && ln -sF ~/Developer/fcomrqz/dotfiles/zed/keymap.json ~/.config/zed/
# Jupyter is Zed's REPL engine
gum spin --title "jupyter: Documents that combine live code, equations, visualizations, and narrative text" -- deno jupyter --install
clear
