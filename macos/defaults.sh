#!/bin/bash

set -euo pipefail

DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly DOTFILES_ROOT
# shellcheck source=install/shared.sh
source "$DOTFILES_ROOT/install/shared.sh"

step() {
  local title=""
  if [[ "${1:-}" == "--title" ]]; then
    title="$2"
    shift 2
  fi
  if [[ "${1:-}" == "--" ]]; then
    shift
  fi
  run_step "$title" "$@"
}

# Finder
# defaults write NSGlobalDomain "AppleShowAllExtensions" -bool "false"

# Hide Menu Bar
# defaults write NSGlobalDomain _HIHideMenuBar -bool true

# Auto hide Dock
# defaults write com.apple.dock autohide -bool true
# defaults write com.apple.dock no-bouncing -bool TRUE && killall Dock

# Do not create `.DS_Store` files in Network Drives
# defaults write com.apple.desktopservices DSDontWriteNetworkStores true

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

log_section "Applying macOS defaults"
# step --title "Spotlight" -- defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 '{ enabled = 0; value = { parameters = (32,49,1048576); type = standard; }; }'
step --title "Desktop" -- defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false

step --title "Dock" -- defaults write com.apple.dock persistent-apps -array
step --title "Dock" -- defaults write com.apple.dock persistent-others -array
step --title "Dock" -- defaults write com.apple.dock static-only -bool true
step --title "Dock" -- defaults write com.apple.dock show-recents -bool false
step --title "Dock" -- defaults write com.apple.dock show-process-indicators -bool false
step --title "Dock" -- defaults write com.apple.dock tilesize -int 48
step --title "Dock" -- defaults write com.apple.dock autohide -bool true
step --title "Dock" -- defaults write com.apple.dock no-bouncing -bool true
step --title "Dock" -- killall Dock

step --title "Safari" -- defaults write com.apple.Safari HomePage -string 'https://www.youtube.com/feed/subscriptions'

step --title "Trackpad" -- defaults write NSGlobalDomain AppleEnableSwipeNavigateWithScrolls -bool false # Don't back or next on swipe in Safari
step --title "General" -- defaults write NSGlobalDomain _HIHideMenuBar -bool true

step --title "Menu Bar" -- defaults write com.apple.menuextra.clock ShowAMPM -bool false
step --title "Menu Bar" -- defaults write com.apple.menuextra.clock ShowDayOfMonth -bool true
step --title "Menu Bar" -- defaults write com.apple.menuextra.clock ShowDayOfWeek -bool true

step --title "Spaces" -- defaults write com.apple.spaces spans-displays -bool false
step --title "Spaces" -- killall SystemUIServer


step --title "Finder" -- defaults write NSGlobalDomain AppleShowAllExtensions -bool true

step --title "Finder" -- defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true # Avoid creating .DS_Store files on network or USB volumes
step --title "Finder" -- defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

step --title "Finder" -- defaults write com.apple.Finder "PreferencesWindow.LastSelection" "ADVD"
step --title "Finder" -- defaults write com.apple.Finder CreateDesktop -bool false
step --title "Finder" -- defaults write com.apple.Finder FXDefaultSearchScope -string "SCcf"
step --title "Finder" -- defaults write com.apple.Finder FXEnableExtensionChangeWarning -bool false
step --title "Finder" -- defaults write com.apple.Finder NewWindowTarget "PfLo"
step --title "Finder" -- defaults write com.apple.Finder NewWindowTargetPath "file://$HOME/Developer/"
step --title "Finder" -- defaults write com.apple.Finder FinderSpawnTab -int 0
step --title "Finder" -- defaults write com.apple.Finder "_FXSortFoldersFirst" -int 1
step --title "Finder" -- defaults write com.apple.Finder WarnOnEmptyTrash -int 0
step --title "Finder" -- defaults write com.apple.Finder ComputerViewSettings -dict-add CustomViewStyle "Nlsv"
step --title "Finder" -- defaults write com.apple.Finder ComputerViewSettings -dict-add GroupBy "Kind"
step --title "Finder" -- defaults write com.apple.Finder FXPreferredGroupBy "Kind"
step --title "Finder" -- defaults write com.apple.Finder ComputerViewSettings -dict-add ExtendedListViewSettingsV2 '{
  "calculateAllSizes" = 0;
  "columns" = (
    { "ascending" = 1; "identifier" = "name"; "visible" = 1; "width" = 288; },
    { "ascending" = 0; "identifier" = "ubiquity"; "visible" = 0; "width" = 35; },
    { "ascending" = 0; "identifier" = "size"; "visible" = 1; "width" = 91; },
    { "ascending" = 0; "identifier" = "dateModified"; "visible" = 1; "width" = 181; },
    { "ascending" = 0; "identifier" = "dateCreated"; "visible" = 0; "width" = 181; },
    { "ascending" = 1; "identifier" = "kind"; "visible" = 0; "width" = 115; },
    { "ascending" = 1; "identifier" = "label"; "visible" = 0; "width" = 100; },
    { "ascending" = 1; "identifier" = "version"; "visible" = 0; "width" = 75; },
    { "ascending" = 1; "identifier" = "comments"; "visible" = 0; "width" = 300; },
    { "ascending" = 0; "identifier" = "dateLastOpened"; "visible" = 0; "width" = 200; },
    { "ascending" = 0; "identifier" = "dateAdded"; "visible" = 0; "width" = 181; },
    { "ascending" = 0; "identifier" = "shareOwner"; "visible" = 0; "width" = 210; },
    { "ascending" = 0; "identifier" = "shareLastEditor"; "visible" = 0; "width" = 210; },
    { "ascending" = 0; "identifier" = "invitationStatus"; "visible" = 0; "width" = 210; }
  );
  "iconSize" = 32;
  "showIconPreview" = 0;
  "sortColumn" = "dateModified";
  "textSize" = 12;
  "useRelativeDates" = 1;
  "viewOptionsVersion" = 1;
}'
step --title "Finder" -- defaults write com.apple.Finder ComputerViewSettings -dict-add ListViewSettings  '{
  "calculateAllSizes" = 0;
  "columns" = (
    { "ascending" = 1; "identifier" = "name"; "visible" = 1; "width" = 288; },
    { "ascending" = 0; "identifier" = "ubiquity"; "visible" = 0; "width" = 35; },
    { "ascending" = 0; "identifier" = "size"; "visible" = 1; "width" = 91; },
    { "ascending" = 0; "identifier" = "dateModified"; "visible" = 1; "width" = 181; },
    { "ascending" = 0; "identifier" = "dateCreated"; "visible" = 0; "width" = 181; },
    { "ascending" = 1; "identifier" = "kind"; "visible" = 0; "width" = 115; },
    { "ascending" = 1; "identifier" = "label"; "visible" = 0; "width" = 100; },
    { "ascending" = 1; "identifier" = "version"; "visible" = 0; "width" = 75; },
    { "ascending" = 1; "identifier" = "comments"; "visible" = 0; "width" = 300; },
    { "ascending" = 0; "identifier" = "dateLastOpened"; "visible" = 0; "width" = 200; },
    { "ascending" = 0; "identifier" = "dateAdded"; "visible" = 0; "width" = 181; },
    { "ascending" = 0; "identifier" = "shareOwner"; "visible" = 0; "width" = 210; },
    { "ascending" = 0; "identifier" = "shareLastEditor"; "visible" = 0; "width" = 210; },
    { "ascending" = 0; "identifier" = "invitationStatus"; "visible" = 0; "width" = 210; }
  );
  "iconSize" = 32;
  "showIconPreview" = 0;
  "sortColumn" = "dateModified";
  "textSize" = 12;
  "useRelativeDates" = 1;
  "viewOptionsVersion" = 1;
}'

# step --title "Finder" -- defaults write com.apple.Finder ComputerViewSettings -dict-add WindowState '{
#     ContainerShowSidebar = 0;
#     ShowSidebar = 0;
#     ShowStatusBar = 0;
#     ShowTabView = 0;
#     ShowToolbar = 1;
# }'

# step --title "Finder" -- defaults write com.apple.Finder StandardViewSettings -dict-add ExtendedListViewSettingsV2 '{
#   "calculateAllSizes" = 0;
#   "columns" = (
#     { "ascending" = 1; "identifier" = "name"; "visible" = 1; "width" = 288; },
#     { "ascending" = 0; "identifier" = "ubiquity"; "visible" = 0; "width" = 35; },
#     { "ascending" = 0; "identifier" = "size"; "visible" = 1; "width" = 91; },
#     { "ascending" = 0; "identifier" = "dateModified"; "visible" = 1; "width" = 181; },
#     { "ascending" = 0; "identifier" = "dateCreated"; "visible" = 0; "width" = 181; },
#     { "ascending" = 1; "identifier" = "kind"; "visible" = 0; "width" = 115; },
#     { "ascending" = 1; "identifier" = "label"; "visible" = 0; "width" = 100; },
#     { "ascending" = 1; "identifier" = "version"; "visible" = 0; "width" = 75; },
#     { "ascending" = 1; "identifier" = "comments"; "visible" = 0; "width" = 300; },
#     { "ascending" = 0; "identifier" = "dateLastOpened"; "visible" = 0; "width" = 200; },
#     { "ascending" = 0; "identifier" = "dateAdded"; "visible" = 0; "width" = 181; },
#     { "ascending" = 0; "identifier" = "shareOwner"; "visible" = 0; "width" = 210; },
#     { "ascending" = 0; "identifier" = "shareLastEditor"; "visible" = 0; "width" = 210; },
#     { "ascending" = 0; "identifier" = "invitationStatus"; "visible" = 0; "width" = 210; }
#   );
#   "iconSize" = 32;
#   "showIconPreview" = 0;
#   "sortColumn" = "dateModified";
#   "textSize" = 12;
#   "useRelativeDates" = 1;
#   "viewOptionsVersion" = 1;
# }'
# step --title "Finder" -- defaults write com.apple.Finder StandardViewSettings -dict-add ListViewSettings  '{
#   "calculateAllSizes" = 0;
#   "columns" = {
#     "comments" = {
#       "ascending" = 1;
#       "index" = 7;
#       "visible" = 0;
#       "width" = 300;
#     };
#     "dateCreated" = {
#       "ascending" = 0;
#       "index" = 3;
#       "visible" = 0;
#       "width" = 181;
#     };
#     "dateLastOpened" = {
#       "ascending" = 0;
#       "index" = 8;
#       "visible" = 0;
#       "width" = 200;
#     };
#     "dateModified" = {
#       "ascending" = 0;
#       "index" = 2;
#       "visible" = 1;
#       "width" = 181;
#     };
#     "kind" = {
#       "ascending" = 1;
#       "index" = 4;
#       "visible" = 0;
#       "width" = 115;
#     };
#     "label" = {
#       "ascending" = 1;
#       "index" = 5;
#       "visible" = 0;
#       "width" = 100;
#     };
#     "name" = {
#       "ascending" = 1;
#       "index" = 0;
#       "visible" = 1;
#       "width" = 268;
#     };
#     "size" = {
#       "ascending" = 0;
#       "index" = 1;
#       "visible" = 1;
#       "width" = 97;
#     };
#     "version" = {
#       "ascending" = 1;
#       "index" = 6;
#       "visible" = 0;
#       "width" = 75;
#     };
#   };
#   "iconSize" = 32;
#   "showIconPreview" = 0;
#   "sortColumn" = "dateModified";
#   "textSize" = 12;
#   "useRelativeDates" = 1;
#   "viewOptionsVersion" = 1;
# }'

# step --title "Finder" -- defaults write com.apple.Finder StandardViewSettings -dict-add WindowState '{
#     ContainerShowSidebar = 0;
#     ShowSidebar = 0;
#     ShowStatusBar = 0;
#     ShowTabView = 0;
#     ShowToolbar = 1;
# }'

# step --title "Finder" -- defaults write com.apple.Finder SearchViewSettings -dict-add WindowState '{
#     ContainerShowSidebar = 0;
#     ShowSidebar = 0;
#     ShowStatusBar = 0;
#     ShowTabView = 0;
#     ShowToolbar = 1;
# }'

# step --title "Finder" -- defaults write com.apple.Finder "NSToolbar Configuration Browser" -dict-add "TB Default Item Identifiers" "('com.apple.finder.BACK', 'com.apple.finder.SWCH', 'NSToolbarSpaceItem', 'com.apple.finder.ARNG', 'com.apple.finder.SHAR', 'com.apple.finder.LABL', 'com.apple.finder.ACTN', 'NSToolbarSpaceItem', 'com.apple.finder.SRCH')"
# step --title "Finder" -- defaults write com.apple.Finder "NSToolbar Configuration Browser" -dict-add "TB Item Identifiers" "()"

step --title "Keyboard" -- killall Finder


step --title "Keyboard" -- defaults write NSGlobalDomain KeyRepeat -int 2
step --title "Keyboard" -- defaults write NSGlobalDomain InitialKeyRepeat -int 15
step --title "Keyboard" -- killall SystemUIServer


# step --title "Expanded Save Dialog" -- defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
# step --title "Expanded Save Dialog" -- defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true


# step --title "Software Update" -- defaults write com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool true
# step --title "Software Update" -- defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true
# step --title "Software Update" -- defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1
# step --title "Software Update" -- defaults write com.apple.SoftwareUpdate AutomaticDownload -int 1
# step --title "Software Update" -- defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -int 1


# step --title "Drag Window" -- defaults write NSGlobalDomain NSWindowShouldDragOnGesture -bool true
# defaults write -g NSWindowShouldDragOnGesture -bool true
# step --title "Window Manager" -- defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool true

step --title "macOS Appearance" -- defaults write NSGlobalDomain AppleInterfaceStyleSwitchesAutomatically -bool true

step --title "Mail" -- defaults write com.apple.mail ColorQuoterColorIncoming -int 0
step --title "Mail" -- defaults write com.apple.mail NumberOfSnippetLines -int 0
step --title "Mail" -- defaults write com.apple.mail ShowCcHeader -int 0
# step --title "Mail" -- defaults write com.apple.mail "NSToolbar Configuration MainWindow" -dict-add "TB Default Item Identifiers" "('toggleMessageListFilter:', 'SeparatorToolbarItem', 'checkNewMail:', 'showComposeWindow:', 'NSToolbarFlexibleSpaceItem', 'archive_delete_junk', 'reply_replyAll_forward', 'FlaggedStatus', 'muteFromToolbar:', 'moveMessagesFromToolbar:', 'Search')"
# step --title "Mail" -- defaults write com.apple.mail "NSToolbar Configuration MainWindow" -dict-add "TB Item Identifiers" "('toggleMessageListFilter:', 'Search', 'SeparatorToolbarItem')"
# step --title "Mail" -- defaults write com.apple.mail "NSToolbar Configuration ComposeWindow" -dict-add "TB Default Item Identifiers" "('send:', 'header_fields', 'EXTENSIONS_TOOLBAR_ITEMS', 'NSToolbarFlexibleSpaceItem', 'changeReplyMode:', 'insertFile:', 'insertOriginalAttachments:', 'toggleComposeFormatInspectorBar:', 'insertEmoji:', 'showMediaBrowser:')"
# step --title "Mail" -- defaults write com.apple.mail "NSToolbar Configuration ComposeWindow" -dict-add "TB Item Identifiers" "('NSToolbarFlexibleSpaceItem', 'send:')"
# step --title "Mail" -- defaults write com.apple.mail "NSToolbar Configuration SingleMessageViewer" -dict-add "TB Item Identifiers" "('archive_delete_junk', 'reply_replyAll_forward', 'NSToolbarFlexibleSpaceItem', 'showPrintPanel:', FlaggedStatus, 'moveMessagesFromToolbar:')"
# step --title "Mail" -- defaults write com.apple.mail "NSToolbar Configuration SingleMessageViewer" -dict-add "TB Item Identifiers" "()"

# step --title "Safari" -- defaults write com.apple.Safari AlwaysRestoreSessionAtLaunch -int 1
# step --title "Safari" -- defaults write com.apple.Safari HistoryAgeInDaysLimit -int 7
# step --title "Safari" -- defaults write com.apple.Safari HomePage "https://www.youtube.com/feed/subscriptions"
# step --title "Safari" -- defaults write com.apple.Safari IncludeDevelopMenu -int 1
# step --title "Safari" -- defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -int 1
# step --title "Safari" -- defaults write com.apple.Safari "WebKitPreferences.developerExtrasEnabled" -int 1

# step --title "Notes" -- defaults write com.apple.Notes "NSToolbar Configuration MainWindowToolbar" -dict-add "TB Default Item Identifiers" "('FoldersToolbarItem', 'NSToolbarSidebarTrackingSeparatorItemIdentifier', 'ViewModeToolbarItem', 'NoteGridBackToolbarItem', 'NSToolbarFlexibleSpaceItem', 'DeleteToolbarItem', 'NewNoteToolbarItem', 'NSToolbarFlexibleSpaceItem', 'FormatToolbarItem', 'ChecklistToolbarItem', 'TableToolbarItem', 'RecordAudioToolbarItem', 'MediaToolbarItem', 'NSToolbarFlexibleSpaceItem', 'LinkToolbarItem', 'LockToolbarItem', 'CollaborationToolbarItem', 'SearchToolbarItem')"
# step --title "Notes" -- defaults write com.apple.Notes "NSToolbar Configuration MainWindowToolbar" -dict-add "TB Item Identifiers" "('NSToolbarSidebarTrackingSeparatorItemIdentifier', 'NoteGridBackToolbarItem', 'NSToolbarFlexibleSpaceItem', 'CollaborationToolbarItem')"

# # Omit crash report dialog {none|basic|developer|server}
# # defaults write com.apple.CrashReporter DialogType none

# networking.computerName
# The user-friendly name for the system, set in System Preferences > Sharing > Computer Name.

# Setting this option is equivalent to running scutil --set ComputerName.

# networking.hostName
# The hostname of your system, as visible from the command line and used by local and remote networks when connecting through SSH and Remote Login.

# Setting this option is equivalent to running the command scutil --set HostName.

# networking.localHostName
# The local hostname, or local network name, is displayed beneath the computer’s name at the top of the Sharing preferences pane. It identifies your Mac to Bonjour-compatible services.

# Setting this option is equivalent to running the command scutil --set LocalHostName, where running, e.g., scutil --set LocalHostName 'Johns-MacBook-Pro', would set the systems local hostname to “Johns-MacBook-Pro.local”. The value of this option defaults to the value of the networking.hostName option.

# By default on macOS the local hostname is your computer’s name with “.local” appended, with any spaces replaced with hyphens, and invalid characters omitted.

# system.defaults.".GlobalPreferences"."com.apple.sound.beep.sound"
# Sets the system-wide alert sound. Found under “Sound Effects” in the “Sound” section of “System Preferences”. Look in “/System/Library/Sounds” for possible candidates.

#   system.defaults.WindowManager.AutoHide
#   Auto hide stage strip showing recent apps. Default is false.

#   system.defaults.universalaccess.reduceMotion
#   Disable animation when switching screens or opening apps

#   system.defaults.universalaccess.reduceTransparency
#   Disable transparency in the menu bar and elsewhere. Requires macOS Yosemite or later. The default is false.

#   system.startup.chime
#   Whether to enable the startup chime.

#   system.defaults.trackpad.TrackpadRightClick
#   Whether to enable trackpad right click. The default is false.

#   Set Safari’s home page to `about:blank` for faster loading
#  defaults write com.apple.Safari HomePage -string "about:blank"

#  # Enable the Develop menu and the Web Inspector in Safari
#  defaults write com.apple.Safari IncludeDevelopMenu -bool true
#  defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
#  defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true

#  # Add the keyboard shortcut ⌘ + Enter to send an email in Mail.app
#  defaults write com.apple.mail NSUserKeyEquivalents -dict-add "Send" "@\U21a9"

#  defaults write com.apple.spotlight orderedItems -array \
# 	'{"enabled" = 0;"name" = "APPLICATIONS";}' \
# 	'{"enabled" = 0;"name" = "SYSTEM_PREFS";}' \
# 	'{"enabled" = 0;"name" = "DIRECTORIES";}' \
# 	'{"enabled" = 0;"name" = "PDF";}' \
# 	'{"enabled" = 0;"name" = "FONTS";}' \
# 	'{"enabled" = 0;"name" = "DOCUMENTS";}' \
# 	'{"enabled" = 0;"name" = "MESSAGES";}' \
# 	'{"enabled" = 0;"name" = "CONTACT";}' \
# 	'{"enabled" = 0;"name" = "EVENT_TODO";}' \
# 	'{"enabled" = 0;"name" = "IMAGES";}' \
# 	'{"enabled" = 0;"name" = "BOOKMARKS";}' \
# 	'{"enabled" = 0;"name" = "MUSIC";}' \
# 	'{"enabled" = 0;"name" = "MOVIES";}' \
# 	'{"enabled" = 0;"name" = "PRESENTATIONS";}' \
# 	'{"enabled" = 0;"name" = "SPREADSHEETS";}' \
# 	'{"enabled" = 0;"name" = "SOURCE";}' \
# 	'{"enabled" = 0;"name" = "MENU_DEFINITION";}' \
# 	'{"enabled" = 0;"name" = "MENU_OTHER";}' \
# 	'{"enabled" = 0;"name" = "MENU_CONVERSION";}' \
# 	'{"enabled" = 0;"name" = "MENU_EXPRESSION";}' \
# 	'{"enabled" = 0;"name" = "MENU_WEBSEARCH";}' \
# 	'{"enabled" = 0;"name" = "MENU_SPOTLIGHT_SUGGESTIONS";}'

# 	# Disable the annoying line marks
# defaults write com.apple.Terminal ShowLineMarks -int 0
