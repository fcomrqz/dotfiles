#!/bin/bash
echo ''
printf "\033[1;34mEnter your tokens\033[0m\n"
read -p 'GitHub Token: ' MY_GITHUB_TOKEN
read -p 'Postmark Account Token: ' POSTMARK_ACCOUNT_TOKEN
read -p 'Postmark Server Token: ' POSTMARK_SERVER_TOKEN
export MY_GITHUB_TOKEN=$MY_GITHUB_TOKEN
export POSTMARK_ACCOUNT_TOKEN=$POSTMARK_ACCOUNT_TOKEN
export POSTMARK_SERVER_TOKEN=$POSTMARK_SERVER_TOKEN
sudo -v

echo ''
printf "\033[1;34m[brew]: Installing Packages\033[0m\n"
curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash -s arg1 arg2  > /dev/null 2>&1
echo '  Homebrew: macOS Package Manager'

brew install fish > /dev/null 2>&1
echo '  Fish Shell: Finally, a command line shell for the 90s'

ln -sF ~/dotfiles/shells/fish/functions ~/.config/fish/functions
ln -sF ~/dotfiles/shells/fish/config.fish ~/.config/fish/config.fish
ln -sF ~/dotfiles/shells/.bashrc ~/.bashrc
ln -sF ~/dotfiles/shells/.zshrc ~/.zshrc
echo '    [dotfiles]: Shells are linked'

sudo sh -c "echo $(which fish) >> /etc/shells"

chsh -s /usr/local/bin/fish
echo '    [sudo]: Fish shell is the default shell'

# Add ~/.hushlogin to remove the last login message when you open Terminal.app
touch ~/.hushlogin

fish ~/dotfiles/tokens.fish
echo '    [fish]: Tokens are exported'

brew install bat > /dev/null 2>&1
ln -sF ~/dotfiles/bat/.batrc ~/.config/bat/.batrc
echo '  bat: A cat clone with syntax highlighting and Git integration'

brew install cloc > /dev/null 2>&1
echo '  cloc: Count Lines of Code'

brew install deno > /dev/null 2>&1
echo '  deno: A secure runtime for JavaScript and TypeScript'

brew install node@14 > /dev/null 2>&1
brew link node@14 > /dev/null 2>&1
echo "  node v14: A JavaScript runtime built on Chrome's V8 JavaScript engine"

brew install dog > /dev/null 2>&1
echo '  dog: DNS client'

brew install fd > /dev/null 2>&1
echo '  fd: A simple, fast and user-friendly alternative to find'

brew install git > /dev/null 2>&1
ln -sF ~/dotfiles/git/.gitconfig ~/.gitconfig
echo '  git: The stupid content tracker'

brew install gh > /dev/null 2>&1
ln -sF ~/dotfiles/gh/config.yml ~/.config/gh/config.yml
echo '  gh: GitHub CLI'

brew install htop > /dev/null 2>&1
ln -sF ~/dotfiles/htop/htoprc ~/.config/htop/htoprc
echo '  htop: An interactive process viewer'

brew install httpie > /dev/null 2>&1
echo '  httpie: HTTP client for the API era'

brew install mas > /dev/null 2>&1
echo '  mas: AppStore CLI'

brew install mongodb-community > /dev/null 2>&1
echo '  mongodb-community: MongoDB server and tools'

brew install starship > /dev/null 2>&1
ln -sF ~/dotfiles/starship/starship.toml ~/.config/starship.toml
echo '  starship: The minimal, blazing-fast, and infinitely customizable prompt for any shell'

brew install trash > /dev/null 2>&1
echo '  trash: tool that moves files or folder to the trash'

brew install tree > /dev/null 2>&1
echo '  tree: Display directories as trees'

brew install universal-ctags > /dev/null 2>&1
echo '  universal-ctags: A maintained implementation of ctags'

echo ''
printf "\033[1;34m[brew]: Installing Desktop Apps\033[0m\n"

brew install --cask google-chrome > /dev/null 2>&1
echo "  Google Chrome: Google's Web Browser"

brew install --cask firefox > /dev/null 2>&1
cp ~/dotfiles/icons/firefox.icns /Applications/Firefox.app/Contents/Resources/firefox.icns
touch /Applications/Firefox.app
echo "  Firefox: Mozillaz' Web Browser"

brew install --cask maccy > /dev/null 2>&1
echo '  Maccy: Clipboard manager'

brew install --cask atom > /dev/null 2>&1
echo '  Atom: A hackable text editor for the 21st Century'
ln -sF ~/dotfiles/atom/config.cson ~/.atom/config.cson
ln -sF ~/dotfiles/atom/init.coffee ~/.atom/init.coffee
ln -sF ~/dotfiles/atom/keymap.cson ~/.atom/keymap.cson
ln -sF ~/dotfiles/atom/snippets.cson ~/.atom/snippets.cson
ln -sF ~/dotfiles/atom/styles.less ~/.atom/styles.less
cp ~/dotfiles/atom/atom.icns /Applications/Atom.app/Contents/Resources/atom.icns
touch /Applications/Atom.app
echo '  [dotfiles]: Atom Linked'
echo '  [apm]: Installing Atom Packages'
apm i atom-quokka > /dev/null 2>&1
echo '    atom-quokka: A hackable text editor for the 21st Century'
apm i atom-wallaby > /dev/null 2>&1
echo '    atom-wallaby: A hackable text editor for the 21st Century'
apm i auto-dark-mode > /dev/null 2>&1
echo '    auto-dark-mode: A hackable text editor for the 21st Century'
apm i busy-signal > /dev/null 2>&1
echo '    busy-signal: A hackable text editor for the 21st Century'
apm i highlight-selected > /dev/null 2>&1
echo '    highlight-selected: A hackable text editor for the 21st Century'
apm i intentions > /dev/null 2>&1
echo '    intentions: A hackable text editor for the 21st Century'
apm i keyboard-scroll > /dev/null 2>&1
echo '    keyboard-scroll: A hackable text editor for the 21st Century'
apm i language-fish-shell > /dev/null 2>&1
echo '    language-fish-shell: A hackable text editor for the 21st Century'
apm i linter > /dev/null 2>&1
echo '    linter: A hackable text editor for the 21st Century'
apm i linter-eslint > /dev/null 2>&1
echo '    linter-eslint: A hackable text editor for the 21st Century'
apm i linter-ui-default > /dev/null 2>&1
echo '    linter-ui-default: A hackable text editor for the 21st Century'
apm i prettier-atom > /dev/null 2>&1
echo '    prettier-atom: A hackable text editor for the 21st Century'
ln -sF ~/dotfiles/prettier/.prettierrc ~/.prettierrc
echo '    [dotfiles]: Prettier Linked'
apm i smart-tags > /dev/null 2>&1
echo '    smart-tags: A hackable text editor for the 21st Century'
apm i fcomrqz/atom-ide-typescript > /dev/null 2>&1
echo '    fcomrqz/atom-ide-typescript: A hackable text editor for the 21st Century'
apm i fcomrqz/atom-ide-vue > /dev/null 2>&1
echo '    fcomrqz/atom-ide-vue: A hackable text editor for the 21st Century'
apm i fcomrqz/atom-language-vue > /dev/null 2>&1
echo '    fcomrqz/atom-language-vue: A hackable text editor for the 21st Century'

brew install --cask insomnia > /dev/null 2>&1
cp ~/dotfiles/icons/Insomnia.icns /Applications/Insomnia.app/Contents/Resources/Insomnia.icns
touch /Applications/Insomnia.app
echo '  Insomnia: The Collaborative API Client and Design Tool'

brew install --cask google-analytics-opt-out > /dev/null 2>&1
echo '  Google Analytics Opt Out: Hide your traffic from Google Analytics'

brew install --cask mongodb-compass > /dev/null 2>&1
cp ~/dotfiles/icons/MongoDB.icns /Applications/MongoDB\ Compass.app/Contents/Resources/electron.icns
touch /Applications/MongoDB\ Compass.app
echo '  MongoDB Compass: The GUI for MongoDB'

brew install --cask loopback > /dev/null 2>&1
echo '  Loopback: Cable-Free Audio Routing'

brew install --cask dash > /dev/null 2>&1
echo '  Dash: Offline Software Documentation'

brew install --cask tunnelbear > /dev/null 2>&1
echo '  TunnelBear: Take back your online privacy with TunnelBear VPN'

brew install --cask adobe-creative-cloud > /dev/null 2>&1
echo '  Adobe Creative Cloud: Adobe App Manager'

brew install --cask android-studio > /dev/null 2>&1
cp ~/dotfiles/icons/Android\ Studio.icns /Applications/Android\ Studio.app/Contents/Resources/studio.icns
touch /Applications/Android\ Studio.app
echo '  Android Studio:  Integrated Development Environment for Android'

echo ''
printf "\033[1;34m[npm]: Installing Global Node Packages\033[0m\n"
npm i -g npm@latest > /dev/null 2>&1
ln -sF ~/dotfiles/npm/.npmrc ~/.npmrc

npm i -g npm-check-updates > /dev/null 2>&1
echo '  ncu: npm check updates'

npm i -g postmark-cli > /dev/null 2>&1
echo '  postmark-cli: Reliable delivery for your application emails'

npm i -g vercel > /dev/null 2>&1
echo '  vercel: Develop. Preview. Ship.'

echo ''
printf "\033[1;34m[mas]: Installing apps from AppStore\033[0m\n"

mas install 904280696 > /dev/null 2>&1
echo '  Things: To-do list'

mas install 1448916662 > /dev/null 2>&1
echo '  Step Two: A beautiful, modern two-step verification app'

mas install 409203825 > /dev/null 2>&1
echo "  Numbers: Apple's Spreadsheets"

mas install 405399194 > /dev/null 2>&1
echo '  Kindle: Ebook Reader'

mas install 497799835 > /dev/null 2>&1
echo '  Xcode: Integrated Development Environment for Apple Products'

mas install 441258766 > /dev/null 2>&1
echo '  Magnet: Window Manager'

mas install 1482454543 > /dev/null 2>&1
echo "  Twitter: It's what's happening"
echo ''
