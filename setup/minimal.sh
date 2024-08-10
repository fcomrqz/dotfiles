#!/bin/zsh
echo ""
echo "Wait until Homebrew is installed to enter sudo mode..."
echo ""
curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash -s arg1 arg2  > /dev/null 2>&1
echo "  Homebrew: macOS Package Manager"

echo ""
echo "[brew]: Installing Packages"

brew install fish > /dev/null 2>&1
echo "  Fish Shell: Finally, a command line shell for the 90s"

mkdir ~/.config
brew install starship > /dev/null 2>&1
ln -sF ~/Developer/fcomrqz/dotfiles/starship/starship.toml ~/.config/starship.toml
echo "  starship: The minimal, blazing-fast, and infinitely customizable prompt for any shell"

mkdir ~/.config/fish
ln -sF ~/Developer/fcomrqz/dotfiles/shells/fish/functions ~/.config/fish
ln -sF ~/Developer/fcomrqz/dotfiles/shells/fish/config.fish ~/.config/fish/config.fish
ln -sF ~/Developer/fcomrqz/dotfiles/shells/.bashrc ~/.bashrc
ln -sF ~/Developer/fcomrqz/dotfiles/shells/.zshrc ~/.zshrc
echo "    [dotfiles]: Shells linked"

echo ""
sudo -v
sudo sh -c "echo $(which fish) >> /etc/shells"
echo ""

chsh -s /usr/local/bin/fish
echo "    [sudo]: Fish shell is the default shell"

# Add ~/.hushlogin to remove the last login message when you open Terminal.app
touch ~/.hushlogin

brew install node > /dev/null 2>&1
echo "  node: JavaScript Runtime built on Google V8"

# Zed's JavaScript REPL engine
brew install deno > /dev/null 2>&1
echo "  deno: Runtime for JavaScript, TypeScript, and WebAssembly built on Google V8 and Rust "

# Jupyter is Zed's REPL engine
deno jupyter --install
echo "  jupyter: Documents that combine live code, equations, visualizations, and narrative text"

brew install git > /dev/null 2>&1
ln -sF ~/Developer/fcomrqz/dotfiles/git/.gitconfig ~/.gitconfig
echo "  git: The stupid content tracker"

brew install gh > /dev/null 2>&1
mkdir ~/.config/gh
ln -sF ~/Developer/fcomrqz/dotfiles/gh/config.yml ~/.config/gh/
echo "  gh: GitHub CLI"

brew install gitui > /dev/null 2>&1
echo "  gitui: Git graphical interface"
mkdir ~/.config/gitui
ln -sF ~/Developer/fcomrqz/dotfiles/gitui/theme.ron ~/.config/gitui/theme.ron

brew install git-jump > /dev/null 2>&1
echo "  git-jump: Improved navigation between Git branches"

brew install git-delta > /dev/null 2>&1
echo "  delta: A better diff"

brew install tree > /dev/null 2>&1
echo "  tree: Display directories as trees"

brew install bat > /dev/null 2>&1
mkdir ~/.config/bat
ln -sF ~/Developer/fcomrqz/dotfiles/bat/.batrc ~/.config/bat/.batrc
echo "  bat: A cat clone with syntax highlighting and Git integration"

brew install htop > /dev/null 2>&1
mkdir ~/.config/htop
ln -sF ~/Developer/fcomrqz/dotfiles/htop/htoprc ~/.config/htop/htoprc
echo "  htop: An interactive process viewer"

echo ""
echo "[brew]: Installing Desktop Apps"

echo "  Zed: Code at the speed of thought"
brew install --cask zed > /dev/null 2>&1

mkdir ~/.config/zed
ln -sF ~/Developer/fcomrqz/dotfiles/zed/settings.json ~/.config/zed/
ln -sF ~/Developer/fcomrqz/dotfiles/zed/keymap.json ~/.config/zed/

echo ""
echo "[npm]: Installing Global Node Packages"
npm i -g npm@latest --force > /dev/null 2>&1

npm i -g npm-check-updates > /dev/null 2>&1
echo "  ncu: npm check updates"

npm i -g prettier > /dev/null 2>&1
npm i -g prettier-plugin-toml > /dev/null 2>&1
echo "  prettier: Opinionated code formatter"
ln -sF ~/Developer/fcomrqz/dotfiles/prettier/.prettierrc ~/

npm i -g lighthouse > /dev/null 2>&1
echo "  lighthouse: Automated auditing, performance metrics, and best practices for the web."

echo "  bun: JavaScript Runtime built on Apple JavaScriptCore"
curl -fsSL https://bun.sh/install | bash
