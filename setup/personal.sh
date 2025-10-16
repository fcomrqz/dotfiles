#!/bin/bash
gum log --prefix Installing "Command Line Tools"

gum spin --title "sqlite: Command-line interface for SQLite" -- brew install sqlite

gum spin --title "mongodb-community: MongoDB server" -- brew tap mongodb/brew

gum spin --title "mongodb-community: MongoDB server" -- brew install mongodb-community

gum spin --title "mongodb-database-tools: standard utilities" -- brew install mongodb-database-tools

gum spin --title "mongosh: MongoDB Shell" -- brew install mongosh

gum spin --title "httpie: HTTP client for the API era" -- brew install httpie

gum spin --title "httpstat: Curl statistics made simple" -- brew install httpstat

gum spin --title "dog: DNS client" -- brew install dog

gum spin --title "jq: Lightweight and flexible command-line JSON processor" -- brew install jq

gum spin --title "ripgrep: Better grep" -- brew install ripgrep

gum spin --title "rename: Rename multiple files" -- brew install rename

gum spin --title "trash: tool that moves files or folder to the trash" -- brew install trash

gum spin --title "scc: Fast and accurate code counter with complexity and COCOMO estimates" -- brew install scc

gum spin --title "mas: AppStore CLI" -- brew install mas

gum spin --title "ollama: Create, run, and share large language models (LLMs)" -- brew install ollama

gum spin --title "cloudflared: Cloudflare Tunnel client" -- brew install cloudflared

gum spin --title "codex: OpenAI's coding agent that runs in your terminal" -- brew install codex

gum spin --title "micro: A modern and intuitive terminal-based text editor" -- brew install micro
gum spin --title "micro: A modern and intuitive terminal-based text editor" -- ln -sF ~/Developer/fcomrqz/dotfiles/micro/settings.json ~/.config/micro/settings.json
gum spin --title "micro: A modern and intuitive terminal-based text editor" -- ln -sF ~/Developer/fcomrqz/dotfiles/micro/bindings.json ~/.config/micro/bindings.json
gum spin --title "micro: A modern and intuitive terminal-based text editor" -- ln -sF ~/Developer/fcomrqz/dotfiles/micro/syntax ~/.config/micro/syntax
gum spin --title "micro: A modern and intuitive terminal-based text editor" -- ln -sF ~/Developer/fcomrqz/dotfiles/micro/colorschemes ~/.config/micro/colorschemes

clear

gum log --prefix Installing "Desktop Apps"

gum spin --title "Aerospace: Tiling Window Manager for macOS" -- brew install --cask nikitabobko/tap/aerospace
gum spin --title "Aerospace: Tiling Window Manager for macOS" -- ln -sF ~/Developer/fcomrqz/dotfiles/aerospace/.aerospace.toml ~/.aerospace.toml

gum spin --title "Google Chrome: Google's Web Browser" -- brew install --cask google-chrome

# gum spin --title "Loopback: Cable-Free Audio Routing" -- brew install --cask loopback

# gum spin --title "Raycast: Better Spotlight" -- brew install --cask raycast

gum spin --title "MongoDB Compass: GUI for MongoDB" -- brew install --cask mongodb-compass

gum spin --title "Proxyman: Apple Native Web Debugging Proxy" -- brew install --cask proxyman

gum spin --title "OrbStack: Fast, light, powerful way to run containers" -- brew install --cask orbstack

gum spin --title "Keycastr: Mesh VPN based on WireGuard" -- brew install --cask keycastr

gum spin --title "Figma: The collaborative interface design tool" -- brew install --cask figma

gum spin --title "Tailscale: Mesh VPN based on WireGuard" brew install --cask tailscale

gum spin --title "Android Studio: Integrated Development Environment for Android" brew install --cask android-studio

gum spin --title "ChatGPT: OpenAI's official desktop app" brew install --cask chatgpt

gum spin --title "SF Symbols: System font for Apple platforms" brew install --cask sf-symbols

gum spin --title "Parallels Desktop: Run Windows on Mac" brew install --cask parallels

clear

gum log --prefix Installing "Desktop Apps from AppStore"
gum spin --title "Xcode: Developer Tools" -- mas install 497799835
gum spin --title "Numbers: Create impressive spreadsheets" -- mas install 409203825
gum spin --title "WhatsApp: Simple. Reliable. Private." -- mas install 310633997
gum spin --title "Pure Paste: Paste as plain text by default" -- mas install 1611378436
gum spin --title "Pandan: Time awareness tool" -- mas install 1569600264
gum spin --title "Base: SQLite Editor" -- mas install 6744867438
# gum spin --title "Things: Organize your life" -- mas install 904280696
clear


gum log --prefix Defaults "macOS"
# gum spin --title "Spotlight" -- defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 '{ enabled = 0; value = { parameters = (32,49,1048576); type = standard; }; }'
gum spin --title "Desktop" -- defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false

gum spin --title "Dock" -- defaults write com.apple.dock persistent-apps -array
gum spin --title "Dock" -- defaults write com.apple.dock persistent-others -array
gum spin --title "Dock" -- defaults write com.apple.dock static-only -bool true
gum spin --title "Dock" -- defaults write com.apple.dock show-recents -bool false
gum spin --title "Dock" -- defaults write com.apple.dock show-process-indicators -bool false
gum spin --title "Dock" -- defaults write com.apple.dock tilesize -int 48
gum spin --title "Dock" -- defaults write com.apple.dock autohide -bool true
gum spin --title "Dock" -- defaults write com.apple.dock no-bouncing -bool true
gum spin --title "Dock" -- killall Dock

gum spin --title "Safari" -- defaults write com.apple.Safari HomePage -string 'https://www.youtube.com/feed/subscriptions'

gum spin --title "Trackpad" -- defaults write NSGlobalDomain AppleEnableSwipeNavigateWithScrolls -bool false # Don't back or next on swipe in Safari
gum spin --title "General" -- defaults write NSGlobalDomain _HIHideMenuBar -bool true

gum spin --title "Menu Bar" -- defaults write com.apple.menuextra.clock ShowAMPM -bool false
gum spin --title "Menu Bar" -- defaults write com.apple.menuextra.clock ShowDayOfMonth -bool true
gum spin --title "Menu Bar" -- defaults write com.apple.menuextra.clock ShowDayOfWeek -bool true

gum spin --title "Spaces" -- defaults write com.apple.spaces spans-displays -bool false
gum spin --title "Spaces" -- killall SystemUIServer


gum spin --title "Finder" -- defaults write NSGlobalDomain AppleShowAllExtensions -bool true

gum spin --title "Finder" -- defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true # Avoid creating .DS_Store files on network or USB volumes
gum spin --title "Finder" -- defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

gum spin --title "Finder" -- defaults write com.apple.Finder "PreferencesWindow.LastSelection" "ADVD"
gum spin --title "Finder" -- defaults write com.apple.Finder CreateDesktop -bool false
gum spin --title "Finder" -- defaults write com.apple.Finder FXDefaultSearchScope -string "SCcf"
gum spin --title "Finder" -- defaults write com.apple.Finder FXEnableExtensionChangeWarning -bool false
gum spin --title "Finder" -- defaults write com.apple.Finder NewWindowTarget "PfLo"
gum spin --title "Finder" -- defaults write com.apple.Finder NewWindowTargetPath "file:///Users/fran/Developer/"
gum spin --title "Finder" -- defaults write com.apple.Finder FinderSpawnTab -int 0
gum spin --title "Finder" -- defaults write com.apple.Finder "_FXSortFoldersFirst" -int 1
gum spin --title "Finder" -- defaults write com.apple.Finder WarnOnEmptyTrash -int 0
gum spin --title "Finder" -- defaults write com.apple.Finder ComputerViewSettings -dict-add CustomViewStyle "Nlsv"
gum spin --title "Finder" -- defaults write com.apple.Finder ComputerViewSettings -dict-add GroupBy "Kind"
gum spin --title "Finder" -- defaults write com.apple.Finder FXPreferredGroupBy "Kind"
gum spin --title "Finder" -- defaults write com.apple.Finder ComputerViewSettings -dict-add ExtendedListViewSettingsV2 '{
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
gum spin --title "Finder" -- defaults write com.apple.Finder ComputerViewSettings -dict-add ListViewSettings  '{
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

# gum spin --title "Finder" -- defaults write com.apple.Finder ComputerViewSettings -dict-add WindowState '{
#     ContainerShowSidebar = 0;
#     ShowSidebar = 0;
#     ShowStatusBar = 0;
#     ShowTabView = 0;
#     ShowToolbar = 1;
# }'

# gum spin --title "Finder" -- defaults write com.apple.Finder StandardViewSettings -dict-add ExtendedListViewSettingsV2 '{
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
# gum spin --title "Finder" -- defaults write com.apple.Finder StandardViewSettings -dict-add ListViewSettings  '{
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

# gum spin --title "Finder" -- defaults write com.apple.Finder StandardViewSettings -dict-add WindowState '{
#     ContainerShowSidebar = 0;
#     ShowSidebar = 0;
#     ShowStatusBar = 0;
#     ShowTabView = 0;
#     ShowToolbar = 1;
# }'

# gum spin --title "Finder" -- defaults write com.apple.Finder SearchViewSettings -dict-add WindowState '{
#     ContainerShowSidebar = 0;
#     ShowSidebar = 0;
#     ShowStatusBar = 0;
#     ShowTabView = 0;
#     ShowToolbar = 1;
# }'

# gum spin --title "Finder" -- defaults write com.apple.Finder "NSToolbar Configuration Browser" -dict-add "TB Default Item Identifiers" "('com.apple.finder.BACK', 'com.apple.finder.SWCH', 'NSToolbarSpaceItem', 'com.apple.finder.ARNG', 'com.apple.finder.SHAR', 'com.apple.finder.LABL', 'com.apple.finder.ACTN', 'NSToolbarSpaceItem', 'com.apple.finder.SRCH')"
# gum spin --title "Finder" -- defaults write com.apple.Finder "NSToolbar Configuration Browser" -dict-add "TB Item Identifiers" "()"

gum spin --title "Keyboard" -- killall Finder


gum spin --title "Keyboard" -- defaults write NSGlobalDomain KeyRepeat -int 2
gum spin --title "Keyboard" -- defaults write NSGlobalDomain InitialKeyRepeat -int 15
gum spin --title "Keyboard" -- killall SystemUIServer


# gum spin --title "Expanded Save Dialog" -- defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
# gum spin --title "Expanded Save Dialog" -- defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true


# gum spin --title "Software Update" -- defaults write com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool true
# gum spin --title "Software Update" -- defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true
# gum spin --title "Software Update" -- defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1
# gum spin --title "Software Update" -- defaults write com.apple.SoftwareUpdate AutomaticDownload -int 1
# gum spin --title "Software Update" -- defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -int 1


# gum spin --title "Drag Window" -- defaults write NSGlobalDomain NSWindowShouldDragOnGesture -bool true
# defaults write -g NSWindowShouldDragOnGesture -bool true
# gum spin --title "Window Manager" -- defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool true

gum spin --title "macOS Appearance" -- defaults write NSGlobalDomain AppleInterfaceStyleSwitchesAutomatically -bool true

gum spin --title "Mail" -- defaults write com.apple.mail ColorQuoterColorIncoming -int 0
gum spin --title "Mail" -- defaults write com.apple.mail NumberOfSnippetLines -int 0
gum spin --title "Mail" -- defaults write com.apple.mail ShowCcHeader -int 0
# gum spin --title "Mail" -- defaults write com.apple.mail "NSToolbar Configuration MainWindow" -dict-add "TB Default Item Identifiers" "('toggleMessageListFilter:', 'SeparatorToolbarItem', 'checkNewMail:', 'showComposeWindow:', 'NSToolbarFlexibleSpaceItem', 'archive_delete_junk', 'reply_replyAll_forward', 'FlaggedStatus', 'muteFromToolbar:', 'moveMessagesFromToolbar:', 'Search')"
# gum spin --title "Mail" -- defaults write com.apple.mail "NSToolbar Configuration MainWindow" -dict-add "TB Item Identifiers" "('toggleMessageListFilter:', 'Search', 'SeparatorToolbarItem')"
# gum spin --title "Mail" -- defaults write com.apple.mail "NSToolbar Configuration ComposeWindow" -dict-add "TB Default Item Identifiers" "('send:', 'header_fields', 'EXTENSIONS_TOOLBAR_ITEMS', 'NSToolbarFlexibleSpaceItem', 'changeReplyMode:', 'insertFile:', 'insertOriginalAttachments:', 'toggleComposeFormatInspectorBar:', 'insertEmoji:', 'showMediaBrowser:')"
# gum spin --title "Mail" -- defaults write com.apple.mail "NSToolbar Configuration ComposeWindow" -dict-add "TB Item Identifiers" "('NSToolbarFlexibleSpaceItem', 'send:')"
# gum spin --title "Mail" -- defaults write com.apple.mail "NSToolbar Configuration SingleMessageViewer" -dict-add "TB Item Identifiers" "('archive_delete_junk', 'reply_replyAll_forward', 'NSToolbarFlexibleSpaceItem', 'showPrintPanel:', FlaggedStatus, 'moveMessagesFromToolbar:')"
# gum spin --title "Mail" -- defaults write com.apple.mail "NSToolbar Configuration SingleMessageViewer" -dict-add "TB Item Identifiers" "()"

# gum spin --title "Safari" -- defaults write com.apple.Safari AlwaysRestoreSessionAtLaunch -int 1
# gum spin --title "Safari" -- defaults write com.apple.Safari HistoryAgeInDaysLimit -int 7
# gum spin --title "Safari" -- defaults write com.apple.Safari HomePage "https://www.youtube.com/feed/subscriptions"
# gum spin --title "Safari" -- defaults write com.apple.Safari IncludeDevelopMenu -int 1
# gum spin --title "Safari" -- defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -int 1
# gum spin --title "Safari" -- defaults write com.apple.Safari "WebKitPreferences.developerExtrasEnabled" -int 1

# gum spin --title "Notes" -- defaults write com.apple.Notes "NSToolbar Configuration MainWindowToolbar" -dict-add "TB Default Item Identifiers" "('FoldersToolbarItem', 'NSToolbarSidebarTrackingSeparatorItemIdentifier', 'ViewModeToolbarItem', 'NoteGridBackToolbarItem', 'NSToolbarFlexibleSpaceItem', 'DeleteToolbarItem', 'NewNoteToolbarItem', 'NSToolbarFlexibleSpaceItem', 'FormatToolbarItem', 'ChecklistToolbarItem', 'TableToolbarItem', 'RecordAudioToolbarItem', 'MediaToolbarItem', 'NSToolbarFlexibleSpaceItem', 'LinkToolbarItem', 'LockToolbarItem', 'CollaborationToolbarItem', 'SearchToolbarItem')"
# gum spin --title "Notes" -- defaults write com.apple.Notes "NSToolbar Configuration MainWindowToolbar" -dict-add "TB Item Identifiers" "('NSToolbarSidebarTrackingSeparatorItemIdentifier', 'NoteGridBackToolbarItem', 'NSToolbarFlexibleSpaceItem', 'CollaborationToolbarItem')"

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
