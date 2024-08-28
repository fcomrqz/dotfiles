# Finder
defaults write NSGlobalDomain "AppleShowAllExtensions" -bool "true"

# Hide Menu Bar
defaults write NSGlobalDomain _HIHideMenuBar -bool true

# Auto hide Dock
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock no-bouncing -bool TRUE && killall Dock

# Do not create `.DS_Store` files in Network Drives
defaults write com.apple.desktopservices DSDontWriteNetworkStores true

# Omit crash report dialog {none|basic|developer|server}
# defaults write com.apple.CrashReporter DialogType none

# Displays have separate Spaces
# defaults write com.apple.spaces spans-displays -bool true && killall SystemUIServer

# Don't back or next on swipe in Safari
defaults write NSGlobalDomain AppleEnableSwipeNavigateWithScrolls -bool false

# system.defaults.NSGlobalDomain.KeyRepeat
# system.defaults.NSGlobalDomain.InitialKeyRepeat
#
# expanded save panel
# system.defaults.NSGlobalDomain.NSNavPanelExpandedStateForSaveMode true
# system.defaults.NSGlobalDomain.NSNavPanelExpandedStateForSaveMode2
#
# system.defaults.NSGlobalDomain.NSWindowShouldDragOnGesture
# Whether to enable moving window by holding anywhere on it like on Linux. The default is false.
#
# system.defaults.SoftwareUpdate.AutomaticallyInstallMacOSUpdates
# Automatically install Mac OS software updates. Defaults to false.
#
# system.defaults.WindowManager.EnableStandardClickToShowDesktop
# Click wallpaper to reveal desktop Clicking your wallpaper will move all windows out of the way to allow access to your desktop items and widgets. Default is true. false means “Only in Stage Manager” true means “Always”
#
#
