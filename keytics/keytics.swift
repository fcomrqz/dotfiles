import Cocoa
import CoreGraphics
import Dispatch
import Foundation

// MARK: Config / Paths

let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
  .first!.appendingPathComponent("keytics", isDirectory: true)
try? FileManager.default.createDirectory(at: appSupportDir, withIntermediateDirectories: true)

let statsURL = appSupportDir.appendingPathComponent("stats.json")

// MARK: State

// Global counts (as before)
var keyNameCounts: [String: Int] = [:]  // plain keys (no modifiers), counted by printed string
var comboCounts: [String: Int] = [:]  // combos (has at least one modifier), counted by printed string

// Per-app counts
var appKeyNameCounts: [String: [String: Int]] = [:]  // [appBundleID: [keyName: count]]
var appComboCounts: [String: [String: Int]] = [:]  // [appBundleID: [combo: count]]

var currentFlags: CGEventFlags = []  // updated via flagsChanged

// MARK: App Detection

func getCurrentAppBundleIdentifier() -> String {
  if let app = NSWorkspace.shared.frontmostApplication {
    return app.bundleIdentifier ?? "unknown"
  }
  return "unknown"
}

// MARK: Persistence

struct Persisted: Codable {
  var keyNameCounts: [String: Int]
  var comboCounts: [String: Int]
  var appKeyNameCounts: [String: [String: Int]]
  var appComboCounts: [String: [String: Int]]
}

func loadStats() {
  guard FileManager.default.fileExists(atPath: statsURL.path) else { return }
  do {
    let data = try Data(contentsOf: statsURL)
    let p = try JSONDecoder().decode(Persisted.self, from: data)
    keyNameCounts = p.keyNameCounts
    comboCounts = p.comboCounts
    appKeyNameCounts = p.appKeyNameCounts
    appComboCounts = p.appComboCounts
    print("loaded \(statsURL.path)")
    print(
      "   global keys: \(keyNameCounts.values.reduce(0, +)), combos: \(comboCounts.values.reduce(0, +))"
    )
    print(
      "   apps tracked: \(Set(Array(appKeyNameCounts.keys) + Array(appComboCounts.keys)).count)")
  } catch {
    fputs("  load error: \(error). Starting fresh.\n", stderr)
  }
}

func saveStats() {
  do {
    let payload = Persisted(
      keyNameCounts: keyNameCounts,
      comboCounts: comboCounts,
      appKeyNameCounts: appKeyNameCounts,
      appComboCounts: appComboCounts
    )
    let data = try JSONEncoder().encode(payload)
    try data.write(to: statsURL, options: .atomic)
    print("saved → \(statsURL.path)")
  } catch {
    fputs("save error: \(error)\n", stderr)
  }
}

// Keep signal sources alive
var signalSources: [DispatchSourceSignal] = []
func setupTerminationHandlers() {
  for sig in [SIGINT, SIGTERM, SIGQUIT, SIGHUP] {
    signal(sig, SIG_IGN)
    let src = DispatchSource.makeSignalSource(signal: sig, queue: .main)
    src.setEventHandler {
      print("\nsaving and exiting…")
      saveStats()
      exit(0)
    }
    src.resume()
    signalSources.append(src)
  }
  atexit {
    saveStats()
  }
}

// MARK: Key map (ANSI US)

private let keyNames: [UInt16: String] = [
  // Letters
  0x00: "A", 0x01: "S", 0x02: "D", 0x03: "F", 0x04: "H", 0x05: "G",
  0x06: "Z", 0x07: "X", 0x08: "C", 0x09: "V", 0x0B: "B",
  0x0C: "Q", 0x0D: "W", 0x0E: "E", 0x0F: "R", 0x10: "Y", 0x11: "T",
  0x1F: "O", 0x20: "U", 0x21: "[", 0x22: "I", 0x23: "P",
  0x25: "L", 0x26: "J", 0x27: "'", 0x28: "K", 0x29: ";",
  0x2D: "N", 0x2E: "M", 0x2B: "comma", 0x2F: ".", 0x2C: "/",
  // Top row
  0x12: "1", 0x13: "2", 0x14: "3", 0x15: "4", 0x16: "6", 0x17: "5",
  0x18: "=", 0x19: "9", 0x1A: "7", 0x1B: "-", 0x1C: "8", 0x1D: "0", 0x1E: "]",
  0x32: "`", 0x2A: "\\",
  // Controls
  0x24: "RETURN", 0x30: "TAB", 0x31: "SPACE", 0x33: "DELETE", 0x34: "ENTER", 0x35: "ESC",
  // Modifiers (for reference; we don't count modifier-only presses)
  0x36: "RIGHT_CMD", 0x37: "LEFT_CMD",
  0x38: "LEFT_SHIFT", 0x39: "CAPS",
  0x3A: "LEFT_ALT", 0x3B: "LEFT_CTRL",
  0x3C: "RIGHT_SHIFT", 0x3D: "RIGHT_ALT", 0x3E: "RIGHT_CTRL", 0x3F: "FN",
  // Function / nav (subset)
  0x7A: "F1", 0x78: "F2", 0x63: "F3", 0x76: "F4", 0x60: "F5",
  0x61: "F6", 0x62: "F7", 0x64: "F8", 0x65: "F9", 0x6B: "F10",
  0x6D: "F12", 0x66: "F11", 0x40: "F17",
  0x7B: "ARROW_LEFT", 0x7C: "ARROW_RIGHT", 0x7D: "ARROW_DOWN", 0x7E: "ARROW_UP",
  0x75: "DEL_FWD", 0x72: "HELP", 0x73: "HOME", 0x74: "PGUP", 0x77: "END", 0x79: "PGDN",
]

@inline(__always) func keyName(for code: UInt16) -> String { keyNames[code] ?? "key_\(code)" }
@inline(__always) func normalize(_ flags: CGEventFlags) -> [String] {
  var m: [String] = []
  if flags.contains(.maskCommand) { m.append("cmd") }
  if flags.contains(.maskControl) { m.append("ctrl") }
  if flags.contains(.maskAlternate) { m.append("alt") }
  if flags.contains(.maskShift) { m.append("shift") }
  return m
}
@inline(__always) func printedCombo(_ flags: CGEventFlags, _ code: UInt16) -> (String, Bool) {
  let mods = normalize(flags)
  let k = keyName(for: code).lowercased()
  return mods.isEmpty ? (k, false) : ((mods + [k]).joined(separator: "+"), true)
}
@inline(__always) func bump(_ dict: inout [String: Int], _ key: String) {
  dict[key, default: 0] += 1
}
@inline(__always) func bumpApp(_ dict: inout [String: [String: Int]], _ app: String, _ key: String)
{
  dict[app, default: [:]][key, default: 0] += 1
}

// MARK: Tap

let eventMask: CGEventMask =
  (1 << CGEventType.keyUp.rawValue) | (1 << CGEventType.keyDown.rawValue)
  | (1 << CGEventType.flagsChanged.rawValue)

guard
  let tap = CGEvent.tapCreate(
    tap: .cgSessionEventTap,
    place: .headInsertEventTap,
    options: .defaultTap,
    eventsOfInterest: eventMask,
    callback: { _, type, event, _ in
      switch type {
      case .flagsChanged:
        currentFlags = event.flags
      case .keyDown:
        break  // ignore repeats; count only on release
      case .keyUp:
        let code = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        let (s, hasMod) = printedCombo(currentFlags, code)
        let currentApp = getCurrentAppBundleIdentifier()

        // Count globally and per-app
        if hasMod {
          bump(&comboCounts, s)
          bumpApp(&appComboCounts, currentApp, s)
        } else {
          bump(&keyNameCounts, s)
          bumpApp(&appKeyNameCounts, currentApp, s)
        }

      // print(s)

      default:
        break
      }
      return Unmanaged.passUnretained(event)
    }, userInfo: nil
  )
else { fatalError("Failed to create event tap. Grant Input Monitoring & try again.") }

let src = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
CFRunLoopAddSource(CFRunLoopGetCurrent(), src, .commonModes)
CGEvent.tapEnable(tap: tap, enable: true)

// MARK: Boot

loadStats()
setupTerminationHandlers()

print("keytics running...")

CFRunLoopRun()
