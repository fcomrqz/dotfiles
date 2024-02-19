if osascript -e 'tell application "System Events" to count (every process whose bundle identifier is "com.apple.Terminal")' | grep -q 1; then
  if [ "$DARKMODE" -eq 1 ]; then
    osascript -e 'tell application "Terminal"
      set current settings of tabs of windows to settings set "dark"
      end tell'
  else
    osascript -e 'tell application "Terminal"
      set current settings of tabs of windows to settings set "light"
      end tell'
  fi
fi
