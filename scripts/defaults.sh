# Finder
defaults write NSGlobalDomain "AppleShowAllExtensions" -bool "true"
defaults write com.apple.Finder "AppleShowAllFiles" -bool "true"

# Menu Bar
defaults write NSGlobalDomain _HIHideMenuBar -bool true

# Hide Dock
defaults write com.apple.dock autohide -bool true && killall Dock
defaults write com.apple.dock autohide-delay -float 1000 && killall Dock
defaults write com.apple.dock no-bouncing -bool TRUE && killall Dock

# Do not create `.DS_Store` files
defaults write com.apple.desktopservices DSDontWriteNetworkStores true
