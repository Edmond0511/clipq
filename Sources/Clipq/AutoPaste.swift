import AppKit
import ApplicationServices

/// Sends Cmd+V to the frontmost app. Needs Accessibility permission, which macOS
/// ties to the code signature, so ad-hoc builds lose it on every update.
enum AutoPaste {
    static var isTrusted: Bool { AXIsProcessTrusted() }

    static func requestPermission() {
        let prompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        AXIsProcessTrustedWithOptions([prompt: true] as CFDictionary)
    }

    static func openSystemSettings() {
        let url = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        if let url = URL(string: url) { NSWorkspace.shared.open(url) }
    }

    /// Delayed so the previous app's window is key again once the panel hides.
    static func pasteIntoFrontApp() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            let source = CGEventSource(stateID: .combinedSessionState)
            let vKey: CGKeyCode = 9 // ANSI "v"
            for keyDown in [true, false] {
                let event = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: keyDown)
                event?.flags = .maskCommand
                event?.post(tap: .cghidEventTap)
            }
        }
    }
}
