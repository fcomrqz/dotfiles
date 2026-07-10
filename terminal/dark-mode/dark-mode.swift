import Cocoa

func applyTheme() {
  let isDark = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
  let theme = isDark ? "dark" : "light"

  // Do not use System Events for this check: doing so adds a second Automation
  // permission that can prevent the theme update before Terminal is contacted.
  guard !NSRunningApplication.runningApplications(
    withBundleIdentifier: "com.apple.Terminal"
  ).isEmpty else {
    return
  }

  // Apply the theme
  let themeScript = NSAppleScript(
    source: """
        tell application "Terminal"
          set themeSettings to settings set "\(theme)"
          set default settings to themeSettings
          set startup settings to themeSettings
          set current settings of tabs of windows to themeSettings
        end tell
      """)

  var error: NSDictionary?
  themeScript?.executeAndReturnError(&error)
  if let error {
    fputs("dark-mode: failed to apply \(theme) Terminal theme: \(error)\n", stderr)
  }
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

NSWorkspace.shared.notificationCenter.addObserver(
  forName: NSWorkspace.didLaunchApplicationNotification,
  object: nil,
  queue: nil
) { notification in
  guard
    let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
      as? NSRunningApplication,
    application.bundleIdentifier == "com.apple.Terminal"
  else {
    return
  }

  applyTheme()
}

setupTerminationHandlers()
NSApplication.shared.run()
