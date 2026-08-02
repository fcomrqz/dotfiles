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

log_section "Applying macOS defaults"

log_section "macOS: Appearance and windows"
step --title "Automatically hide and show the menu bar" -- defaults write NSGlobalDomain \
  _HIHideMenuBar -bool true
step --title "Use automatic icon and widget style" -- defaults write NSGlobalDomain \
  AppleIconAppearanceTheme -string "RegularAutomatic"
step --title "Automatically switch between light and dark appearance" -- defaults write NSGlobalDomain \
  AppleInterfaceStyleSwitchesAutomatically -bool true
step --title "Use medium Finder sidebar icons" -- defaults write NSGlobalDomain \
  NSTableViewDefaultSizeMode -int 2
step --title "Set the alert volume" -- defaults write NSGlobalDomain \
  com.apple.sound.beep.volume -float 0.8514607

step --title "Use expanded Save dialogs" -- defaults write NSGlobalDomain \
  NSNavPanelExpandedStateForSaveMode -bool true
step --title "Use expanded Save dialogs in older apps" -- defaults write NSGlobalDomain \
  NSNavPanelExpandedStateForSaveMode2 -bool true
step --title "Drag windows from anywhere" -- defaults write NSGlobalDomain \
  NSWindowShouldDragOnGesture -bool true

log_section "macOS: Keyboard and text input"
step --title "Set the key repeat rate" -- defaults write NSGlobalDomain KeyRepeat -int 5
step --title "Set the delay until repeat" -- defaults write NSGlobalDomain InitialKeyRepeat -int 25
step --title "Press and hold keys for accents" -- defaults write NSGlobalDomain \
  ApplePressAndHoldEnabled -bool true
step --title "Capitalize words automatically" -- defaults write NSGlobalDomain \
  NSAutomaticCapitalizationEnabled -bool true
step --title "Add a period with double-space" -- defaults write NSGlobalDomain \
  NSAutomaticPeriodSubstitutionEnabled -bool true

log_section "macOS: Pointing devices and gestures"
step --title "Set the mouse tracking speed" -- defaults write NSGlobalDomain \
  com.apple.mouse.scaling -float 1
step --title "Disable Swipe between pages" -- defaults write NSGlobalDomain \
  AppleEnableSwipeNavigateWithScrolls -bool false
step --title "Enable Force Click and haptic feedback" -- defaults write NSGlobalDomain \
  com.apple.trackpad.forceClick -bool true
step --title "Set the trackpad tracking speed" -- defaults write NSGlobalDomain \
  com.apple.trackpad.scaling -float 0.875

step --title "Enable trackpad haptic feedback" -- defaults write com.apple.AppleMultitouchTrackpad \
  ActuateDetents -bool true
step --title "Disable Silent clicking" -- defaults write com.apple.AppleMultitouchTrackpad \
  ActuationStrength -int 1
step --title "Disable Tap to click" -- defaults write com.apple.AppleMultitouchTrackpad \
  Clicking -bool false
step --title "Disable Drag Lock" -- defaults write com.apple.AppleMultitouchTrackpad \
  DragLock -bool false
step --title "Disable tap to drag" -- defaults write com.apple.AppleMultitouchTrackpad \
  Dragging -bool false
step --title "Set click pressure to Medium" -- defaults write com.apple.AppleMultitouchTrackpad \
  FirstClickThreshold -int 1
step --title "Enable Force Click" -- defaults write com.apple.AppleMultitouchTrackpad \
  ForceSuppressed -bool false
step --title "Set Force Click pressure to Medium" -- defaults write com.apple.AppleMultitouchTrackpad \
  SecondClickThreshold -int 1
step --title "Disable corner secondary click" -- defaults write com.apple.AppleMultitouchTrackpad \
  TrackpadCornerSecondaryClick -int 0
step --title "Swipe between full-screen applications with four fingers" -- defaults write com.apple.AppleMultitouchTrackpad \
  TrackpadFourFingerHorizSwipeGesture -int 2
step --title "Enable four-finger pinch gestures" -- defaults write com.apple.AppleMultitouchTrackpad \
  TrackpadFourFingerPinchGesture -int 2
step --title "Use four-finger Mission Control gestures" -- defaults write com.apple.AppleMultitouchTrackpad \
  TrackpadFourFingerVertSwipeGesture -int 2
step --title "Enable scroll momentum" -- defaults write com.apple.AppleMultitouchTrackpad \
  TrackpadMomentumScroll -bool true
step --title "Zoom in or out with two fingers" -- defaults write com.apple.AppleMultitouchTrackpad \
  TrackpadPinch -bool true
step --title "Secondary click with two fingers" -- defaults write com.apple.AppleMultitouchTrackpad \
  TrackpadRightClick -bool true
step --title "Disable rotation with two fingers" -- defaults write com.apple.AppleMultitouchTrackpad \
  TrackpadRotate -bool false
step --title "Disable three-finger drag" -- defaults write com.apple.AppleMultitouchTrackpad \
  TrackpadThreeFingerDrag -bool false
step --title "Swipe between full-screen applications with three fingers" -- defaults write com.apple.AppleMultitouchTrackpad \
  TrackpadThreeFingerHorizSwipeGesture -int 2
step --title "Disable Look up with three fingers" -- defaults write com.apple.AppleMultitouchTrackpad \
  TrackpadThreeFingerTapGesture -int 0
step --title "Use three-finger Mission Control gestures" -- defaults write com.apple.AppleMultitouchTrackpad \
  TrackpadThreeFingerVertSwipeGesture -int 2
step --title "Smart zoom with two fingers" -- defaults write com.apple.AppleMultitouchTrackpad \
  TrackpadTwoFingerDoubleTapGesture -int 1
step --title "Swipe from the right edge for Notification Center" -- defaults write com.apple.AppleMultitouchTrackpad \
  TrackpadTwoFingerFromRightEdgeSwipeGesture -int 3

step --title "Enable secondary click on Magic Mouse" -- defaults write com.apple.AppleMultitouchMouse \
  MouseButtonMode -string "TwoButton"

log_section "macOS: Window management"
step --title "Click wallpaper to reveal desktop: Only in Stage Manager" -- defaults write com.apple.WindowManager \
  EnableStandardClickToShowDesktop -bool false
step --title "Automatically hide recent apps in Stage Manager" -- defaults write com.apple.WindowManager \
  AutoHide -bool true
step --title "Show windows from an application: All at Once" -- defaults write com.apple.WindowManager \
  AppWindowGroupingBehavior -bool true
step --title "Show items on the desktop" -- defaults write com.apple.WindowManager \
  StandardHideDesktopIcons -bool false
step --title "Hide items in Stage Manager" -- defaults write com.apple.WindowManager \
  HideDesktop -bool true
step --title "Disable dragging windows to screen edges to tile" -- defaults write com.apple.WindowManager \
  EnableTilingByEdgeDrag -bool false
step --title "Disable dragging windows to the menu bar to fill the screen" -- defaults write com.apple.WindowManager \
  EnableTopTilingByEdgeDrag -bool false
step --title "Disable holding Option while dragging to tile" -- defaults write com.apple.WindowManager \
  EnableTilingOptionAccelerator -bool false
step --title "Disable margins around tiled windows" -- defaults write com.apple.WindowManager \
  EnableTiledWindowMargins -bool false
step --title "Hide widgets on the desktop" -- defaults write com.apple.WindowManager \
  StandardHideWidgets -bool true
step --title "Hide widgets in Stage Manager" -- defaults write com.apple.WindowManager \
  StageManagerHideWidgets -bool true

# These settings are required for reliable display and Space focus in yabai.
# https://github.com/asmvik/yabai/wiki#installation-requirements
log_section "macOS: Spaces and Dock"
step --title "Displays have separate Spaces" -- defaults write com.apple.spaces \
  spans-displays -bool false
step --title "Do not rearrange Spaces based on recent use" -- defaults write com.apple.dock mru-spaces -bool false
step --title "Show desktop icons" -- defaults write com.apple.Finder CreateDesktop -bool true

step --title "Remove pinned applications from the Dock" -- defaults write com.apple.dock persistent-apps -array
step --title "Remove files and folders from the Dock" -- defaults write com.apple.dock persistent-others -array
step --title "Show only open applications in the Dock" -- defaults write com.apple.dock static-only -bool true
step --title "Hide recent applications in the Dock" -- defaults write com.apple.dock show-recents -bool false
step --title "Hide indicators for open applications" -- defaults write com.apple.dock \
  show-process-indicators -bool false
step --title "Set the Dock size" -- defaults write com.apple.dock tilesize -int 48
step --title "Automatically hide and show the Dock" -- defaults write com.apple.dock autohide -bool true
step --title "Prevent pointer activation of the Dock" -- defaults write com.apple.dock \
  autohide-delay -float 8640000
step --title "Group Mission Control windows by application" -- defaults write com.apple.dock expose-group-apps -bool true
step --title "Disable animation when opening applications" -- defaults write com.apple.dock launchanim -bool false
step --title "Prevent applications from bouncing in the Dock" -- defaults write com.apple.dock no-bouncing -bool true
step --title "Disable the App Exposé trackpad gesture" -- defaults write com.apple.dock \
  showAppExposeGestureEnabled -bool false
step --title "Disable the Show Desktop trackpad gesture" -- defaults write com.apple.dock \
  showDesktopGestureEnabled -bool false
step --title "Disable the bottom-right Hot Corner" -- defaults write com.apple.dock wvous-br-corner -int 1

log_section "macOS: Menu bar and screenshots"
step --title "Hide AM/PM in the menu bar clock" -- defaults write com.apple.menuextra.clock \
  ShowAMPM -bool false
step --title "Show the date when space allows" -- defaults write com.apple.menuextra.clock \
  ShowDate -int 0
step --title "Show the date in the menu bar" -- defaults write com.apple.menuextra.clock \
  ShowDayOfMonth -bool true
step --title "Show the day of the week in the menu bar" -- defaults write com.apple.menuextra.clock \
  ShowDayOfWeek -bool true

step --title "Save screenshots to Downloads" -- defaults write com.apple.screencapture \
  location -string "$HOME/Downloads"
step --title "Save screenshots as files" -- defaults write com.apple.screencapture \
  target -string "file"

log_section "macOS: Software Update"
step --title "Automatically install macOS updates" -- defaults write com.apple.SoftwareUpdate \
  AutomaticallyInstallMacOSUpdates -bool true
step --title "Automatically check for updates" -- defaults write com.apple.SoftwareUpdate \
  AutomaticCheckEnabled -bool true
step --title "Check for updates daily" -- defaults write com.apple.SoftwareUpdate \
  ScheduleFrequency -int 1
step --title "Automatically download updates" -- defaults write com.apple.SoftwareUpdate \
  AutomaticDownload -int 1
step --title "Install Security Responses and system files" -- defaults write com.apple.SoftwareUpdate \
  CriticalUpdateInstall -int 1

log_section "Finder"
step --title "Hide all filename extensions" -- defaults write NSGlobalDomain \
  AppleShowAllExtensions -bool false
step --title "Do not create .DS_Store files on network volumes" -- defaults write com.apple.desktopservices \
  DSDontWriteNetworkStores -bool true
step --title "Do not create .DS_Store files on removable volumes" -- defaults write com.apple.desktopservices \
  DSDontWriteUSBStores -bool true

step --title "Open Finder Settings to Advanced" -- defaults write com.apple.Finder \
  "PreferencesWindow.LastSelection" -string "ADVD"
step --title "Search the current folder by default" -- defaults write com.apple.Finder \
  FXDefaultSearchScope -string "SCcf"
step --title "Do not warn before changing a filename extension" -- defaults write com.apple.Finder \
  FXEnableExtensionChangeWarning -bool false
step --title "Group Finder items by kind" -- defaults write com.apple.Finder \
  FXPreferredGroupBy -string "Kind"
step --title "Use List View in Finder" -- defaults write com.apple.Finder \
  FXPreferredViewStyle -string "Nlsv"
step --title "Remove items from the Trash after 30 days" -- defaults write com.apple.Finder \
  FXRemoveOldTrashItems -bool true
step --title "Use a custom new Finder window location" -- defaults write com.apple.Finder \
  NewWindowTarget -string "PfLo"
step --title "Open new Finder windows to Downloads" -- defaults write com.apple.Finder \
  NewWindowTargetPath -string "file://$HOME/Downloads/"
step --title "Open folders in new windows instead of tabs" -- defaults write com.apple.Finder FinderSpawnTab -bool false
step --title "Show external disks on the desktop" -- defaults write com.apple.Finder \
  ShowExternalHardDrivesOnDesktop -bool true
step --title "Hide hard disks on the desktop" -- defaults write com.apple.Finder \
  ShowHardDrivesOnDesktop -bool false
step --title "Show CDs, DVDs, and iPods on the desktop" -- defaults write com.apple.Finder \
  ShowRemovableMediaOnDesktop -bool true
step --title "Keep folders on top when sorting by name" -- defaults write com.apple.Finder \
  _FXSortFoldersFirst -bool true
step --title "Empty the Trash without a warning" -- defaults write com.apple.Finder \
  WarnOnEmptyTrash -bool false

log_section "Activity Monitor"
step --title "Show My Processes in Activity Monitor" -- defaults write com.apple.ActivityMonitor \
  ShowCategory -int 102
step --title "Open the main Activity Monitor window" -- defaults write com.apple.ActivityMonitor \
  OpenMainWindow -bool true

log_section "Calendar"
step --title "Hide the calendar list" -- defaults write com.apple.iCal \
  CalendarSidebarShown -bool false
step --title "Disable time zone support in Calendar" -- defaults write com.apple.iCal \
  "TimeZone support enabled" -bool false

log_section "Terminal"
step --title "Hide line marks in Terminal" -- defaults write com.apple.Terminal ShowLineMarks -bool false

log_section "Refreshing macOS preferences"
step --title "Restart Dock" -- killall Dock
step --title "Restart Finder" -- killall Finder
step --title "Restart SystemUIServer" -- killall SystemUIServer
