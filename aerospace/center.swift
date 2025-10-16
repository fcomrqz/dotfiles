#!/usr/bin/swift
import Cocoa
import Foundation

// Get command line argument for direction (prev/next)
let arguments = CommandLine.arguments
guard arguments.count > 1 else {
  print("Usage: center.swift [prev|next]")
  exit(1)
}

let direction = arguments[1]
guard direction == "prev" || direction == "next" else {
  print("Direction must be 'prev' or 'next'")
  exit(1)
}

// Get the frontmost application
guard let frontmostApp = NSWorkspace.shared.frontmostApplication,
  let bundleID = frontmostApp.bundleIdentifier
else {
  exit(1)
}

// List of app bundle IDs that are configured as floating in aerospace config
let floatingApps = [
  "com.apple.Passwords",
  "com.culturedcode.ThingsMac",
  "com.apple.MobileSMS",
  "com.apple.FaceTime",
  "net.whatsapp.WhatsApp",
  "com.apple.reminders",
  "com.apple.iphonesimulator",
  "com.apple.Home",
  "com.apple.findmy",
  "com.apple.AddressBook",
  "com.apple.ScreenSharing",
]

// Check if this app should be floating
let isFloatingApp = floatingApps.contains(bundleID)

if isFloatingApp {
  // Handle floating windows with our perfect centering
  let screens = NSScreen.screens.sorted { $0.frame.minX < $1.frame.minX }

  let currentMouseLocation = NSEvent.mouseLocation

  let appElement = AXUIElementCreateApplication(frontmostApp.processIdentifier)

  var focusedWindow: CFTypeRef?
  let result = AXUIElementCopyAttributeValue(
    appElement, "AXFocusedWindow" as CFString, &focusedWindow)

  guard result == .success, let window = focusedWindow else {
    exit(1)
  }

  var currentPosValue: CFTypeRef?
  AXUIElementCopyAttributeValue(window as! AXUIElement, "AXPosition" as CFString, &currentPosValue)

  var windowPosition = CGPoint.zero
  if let currentPos = currentPosValue {
    AXValueGetValue(currentPos as! AXValue, .cgPoint, &windowPosition)
  }

  let currentScreen: NSScreen
  if let windowScreen = screens.first(where: { $0.frame.contains(windowPosition) }) {
    currentScreen = windowScreen
  } else {
    guard let fallbackScreen = screens.first(where: { $0.frame.contains(currentMouseLocation) })
    else {
      exit(1)
    }
    currentScreen = fallbackScreen
  }

  guard let currentIndex = screens.firstIndex(of: currentScreen) else {
    exit(1)
  }

  let targetIndex: Int
  if direction == "next" {
    targetIndex = (currentIndex + 1) % screens.count
  } else {
    targetIndex = (currentIndex - 1 + screens.count) % screens.count
  }

  let targetScreen = screens[targetIndex]

  var sizeValue: CFTypeRef?
  AXUIElementCopyAttributeValue(window as! AXUIElement, "AXSize" as CFString, &sizeValue)

  guard let size = sizeValue else {
    exit(1)
  }

  var windowSize = CGSize.zero
  AXValueGetValue(size as! AXValue, .cgSize, &windowSize)

  let screenFrame = targetScreen.frame
  let screenBounds = targetScreen.visibleFrame

  let isMainMonitor = screenFrame.origin.y == 0

  let centerX = screenBounds.minX + (screenBounds.width / 2)
  let newX = centerX - (windowSize.width / 2)

  let newY: CGFloat
  if isMainMonitor {
    // Main monitor: 240px from top (accounts for menu bar)
    newY = screenBounds.minY + 240
  } else {
    // External monitors: 200px from top, centered on window
    newY = screenBounds.minY + 200 - (windowSize.height / 2)
  }

  var newPosition = CGPoint(x: newX, y: newY)
  let newPositionValue = AXValueCreate(.cgPoint, &newPosition)!

  let setResult = AXUIElementSetAttributeValue(
    window as! AXUIElement, "AXPosition" as CFString, newPositionValue)

  let mouseX = newX + (windowSize.width / 2)
  let mouseY = newY + (windowSize.height / 2)
  CGWarpMouseCursorPosition(CGPoint(x: mouseX, y: mouseY))

  if setResult != .success {
    exit(1)
  }

} else {
  // Handle tiling windows with AeroSpace commands
  let moveProcess = Process()
  moveProcess.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/aerospace")
  moveProcess.arguments = [
    "move-node-to-monitor",
    direction == "next" ? "next" : "prev",
    "--wrap-around",
  ]

  do {
    try moveProcess.run()
    moveProcess.waitUntilExit()

    let focusProcess = Process()
    focusProcess.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/aerospace")
    focusProcess.arguments = [
      "focus-monitor",
      direction == "next" ? "next" : "prev",
      "--wrap-around",
    ]

    try focusProcess.run()
    focusProcess.waitUntilExit()

  } catch {
    exit(1)
  }
}
