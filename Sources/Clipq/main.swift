import AppKit

let arguments = CommandLine.arguments.dropFirst()
if arguments.contains("--enable-login") {
    LoginItem.setEnabled(true)
    exit(0)
}
if arguments.contains("--disable-login") {
    LoginItem.setEnabled(false)
    exit(0)
}

// Only one instance may watch the clipboard.
if let bundleID = Bundle.main.bundleIdentifier,
   NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).count > 1 {
    exit(0)
}

MainActor.assumeIsolated {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.accessory)
    app.run()
}
