import Cocoa

func applyTheme() {
  let isDark = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
  let theme = isDark ? "dark" : "light"

  // Check if Terminal is running
  let checkScript = NSAppleScript(
    source: """
        tell application "System Events"
          count (every process whose bundle identifier is "com.apple.Terminal")
        end tell
      """)

  guard let result = checkScript?.executeAndReturnError(nil),
    result.int32Value > 0
  else {
    return  // Terminal is not running
  }

  // Apply the theme
  let themeScript = NSAppleScript(
    source: """
        tell application "Terminal"
          set current settings of tabs of windows to settings set "\(theme)"
        end tell
      """)

  themeScript?.executeAndReturnError(nil)
}

var signalSources: [DispatchSourceSignal] = []
func setupTerminationHandlers() {
  for sig in [SIGINT, SIGTERM, SIGQUIT, SIGHUP] {
    signal(sig, SIG_IGN)
    let src = DispatchSource.makeSignalSource(signal: sig, queue: .main)
    src.setEventHandler { exit(0) }
    src.resume()
    signalSources.append(src)
  }
}

applyTheme()

DistributedNotificationCenter.default.addObserver(
  forName: Notification.Name("AppleInterfaceThemeChangedNotification"),
  object: nil,
  queue: nil
) { _ in applyTheme() }

NSWorkspace.shared.notificationCenter.addObserver(
  forName: NSWorkspace.didWakeNotification,
  object: nil,
  queue: nil
) { _ in applyTheme() }

setupTerminationHandlers()
NSApplication.shared.run()
