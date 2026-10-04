import Foundation

/// A LaunchAgent pointing at this executable. SMAppService is avoided because the
/// npm global install path isn't a registered app location and can change.
enum LoginItem {
    static let label = "com.clipq.Clipq"

    static var plistURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(label).plist")
    }

    static var isEnabled: Bool {
        FileManager.default.fileExists(atPath: plistURL.path)
    }

    static func setEnabled(_ enabled: Bool) {
        guard enabled else {
            try? FileManager.default.removeItem(at: plistURL)
            return
        }
        guard let executable = Bundle.main.executablePath else { return }
        let plist: [String: Any] = [
            "Label": label,
            "ProgramArguments": [executable],
            "RunAtLoad": true,
        ]
        try? FileManager.default.createDirectory(
            at: plistURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        (plist as NSDictionary).write(to: plistURL, atomically: true)
    }
}
