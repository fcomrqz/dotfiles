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

