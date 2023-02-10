#!/bin/bash

mkdir ~/.atom
ln -sF ~/dotfiles/atom/config.cson ~/.atom/config.cson
ln -sF ~/dotfiles/atom/init.coffee ~/.atom/init.coffee
ln -sF ~/dotfiles/atom/keymap.cson ~/.atom/keymap.cson
ln -sF ~/dotfiles/atom/snippets.cson ~/.atom/snippets.cson
ln -sF ~/dotfiles/atom/styles.less ~/.atom/styles.less

echo ''
read -p 'Enter your GitHub Token: ' GITHUB_TOKEN
export GITHUB_TOKEN=$GITHUB_TOKEN

echo ''
echo 'Wait until Homebrew is installed to enter sudo mode'
echo ''
echo '[brew]: Installing Packages'
curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash -s arg1 arg2  > /dev/null 2>&1
echo '  Homebrew: macOS Package Manager'

brew install fish > /dev/null 2>&1
echo '  Fish Shell: Finally, a command line shell for the 90s'

mkdir ~/.config
brew install starship > /dev/null 2>&1
ln -sF ~/dotfiles/starship/starship.toml ~/.config/starship.toml
echo '  starship: The minimal, blazing-fast, and infinitely customizable prompt for any shell'

mkdir ~/.config/fish
ln -sF ~/dotfiles/shells/fish/functions ~/.config/fish
ln -sF ~/dotfiles/shells/fish/config.fish ~/.config/fish/config.fish
ln -sF ~/dotfiles/shells/.bashrc ~/.bashrc
ln -sF ~/dotfiles/shells/.zshrc ~/.zshrc
echo '    [dotfiles]: Shells linked'

echo ''
sudo -v
sudo sh -c "echo $(which fish) >> /etc/shells"
echo ''

chsh -s /usr/local/bin/fish
echo '    [sudo]: Fish shell is the default shell'

# Add ~/.hushlogin to remove the last login message when you open Terminal.app
touch ~/.hushlogin

fish ~/dotfiles/tokens.fish
echo '    [fish]: Tokens are exported'

brew install --cask adobe-creative-cloud > /dev/null 2>&1
echo '  Adobe Creative Cloud: Adobe App Manager'

brew install bat > /dev/null 2>&1
mkdir ~/.config/bat
ln -sF ~/dotfiles/bat/.batrc ~/.config/bat/.batrc
echo '  bat: A cat clone with syntax highlighting and Git integration'

brew install screen > /dev/null 2>&1
ln -sF ~/dotfiles/screen/.screenrc ~/.screenrc
echo '  screen: screen manager with VT100/ANSI terminal emulation'

brew install cloc > /dev/null 2>&1
echo '  cloc: Count Lines of Code'

brew install node > /dev/null 2>&1
brew install node@16 > /dev/null 2>&1
brew install node@10 > /dev/null 2>&1
echo "  node: A JavaScript runtime built on Chrome's V8 JavaScript engine"

brew install dog > /dev/null 2>&1
echo '  dog: DNS client'

brew install httpstat > /dev/null 2>&1
echo '  httpstat: Curl statistics made simple'

brew install ripgrep > /dev/null 2>&1
echo '  ripgrep: Better grep'

brew install rename > /dev/null 2>&1
echo '  rename: Rename multiple files'

brew install git > /dev/null 2>&1
ln -sF ~/dotfiles/git/.gitconfig ~/.gitconfig
echo '  git: The stupid content tracker'

brew install gh > /dev/null 2>&1
mkdir ~/.config/gh
ln -sF ~/dotfiles/gh/config.yml ~/.config/gh/config.yml
echo '  gh: GitHub CLI'

brew install git-delta > /dev/null 2>&1
echo '  delta: A better diff'

brew install htop > /dev/null 2>&1
mkdir ~/.config/htop
ln -sF ~/dotfiles/htop/htoprc ~/.config/htop/htoprc
echo '  htop: An interactive process viewer'

brew install httpie > /dev/null 2>&1
echo '  httpie: HTTP client for the API era'

brew install mas > /dev/null 2>&1
echo '  mas: AppStore CLI'

brew install sqlite > /dev/null 2>&1
echo '  sqlite: Command-line interface for SQLite'

brew tap mongodb/brew > /dev/null 2>&1
brew install mongodb-community > /dev/null 2>&1
echo '  mongodb-community: MongoDB server'

brew install mongodb-database-tools > /dev/null 2>&1
echo '  mongodb-database-tools: standard utilities'

brew install mongosh > /dev/null 2>&1
echo '  mongosh: MongoDB Shell'

brew install trash > /dev/null 2>&1
echo '  trash: tool that moves files or folder to the trash'

brew install tree > /dev/null 2>&1
echo '  tree: Display directories as trees'

echo ''
echo ' [brew]: Installing Desktop Apps'

brew install --cask google-chrome > /dev/null 2>&1
echo "  Google Chrome: Google's Web Browser"

brew install --cask loopback > /dev/null 2>&1
echo '  Loopback: Cable-Free Audio Routing'

brew install --cask raycast > /dev/null 2>&1
echo '  Raycast: Better Spotlight'

brew install --cask mongodb-compass > /dev/null 2>&1
echo '  MongoDB Compass: GUI for MongoDB'

brew install --cask proxyman > /dev/null 2>&1
echo '  Proxyman: Apple Native Web Debugging Proxy'

brew install --cask github > /dev/null 2>&1
echo '  GitHub Desktop: Desktop client for GitHub repositories'

brew install --cask android-studio > /dev/null 2>&1
echo '  Android Studio:  Integrated Development Environment for Android'

echo ''
echo '[npm]: Installing Global Node Packages'
npm i -g npm@latest --force > /dev/null 2>&1
echo '    [dotfiles]: npm linked'
ln -sF ~/dotfiles/npm/.npmrc ~/.npmrc

npm i -g npm-check-updates > /dev/null 2>&1
echo '  ncu: npm check updates'

npm i -g np > /dev/null 2>&1
echo '  np: A better `npm publish`'

npm i -g lighthouse > /dev/null 2>&1
echo '  lighthouse: Automated auditing, performance metrics, and best practices for the web.'

echo ''
echo '[mas]: Installing apps from AppStore'

mas install 1480933944 > /dev/null 2>&1
echo '  Vimari: Add Vim keybindings to Safari'

mas install 904280696 > /dev/null 2>&1
echo '  Things: To-do list'

mas install 1482454543 > /dev/null 2>&1
echo "  Twitter: It's what's happening"

mas install 409203825 > /dev/null 2>&1
echo "  Numbers: Apple's Spreadsheets"

mas install 405399194 > /dev/null 2>&1
echo '  Kindle: Ebook Reader'

mas install 497799835 > /dev/null 2>&1
echo '  Xcode: Integrated Development Environment for Apple Products'
