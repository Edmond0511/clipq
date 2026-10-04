import AppKit
import ClipqCore

/// Polls the general pasteboard, since macOS has no change notification for it.
final class ClipboardMonitor {
    var isPaused = false
    private let history: HistoryStore
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var timer: Timer?

    init(history: HistoryStore) {
        self.history = history
        lastChangeCount = pasteboard.changeCount
    }

    func start() {
        let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in self?.poll() }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func poll() {
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount
        guard !isPaused else { return }

        // Prefer text: apps like Word and Excel also put an image rendering of copied text.
        if let text = pasteboard.string(forType: .string) {
            history.addText(text, rtf: pasteboard.data(forType: .rtf))
        } else if let png = Self.readPNG(from: pasteboard) {
            history.addImage(png: png)
        }
    }

    private static func readPNG(from pasteboard: NSPasteboard) -> Data? {
        if let png = pasteboard.data(forType: .png) { return png }
        guard let tiff = pasteboard.data(forType: .tiff) else { return nil }
        return NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:])
    }
}

enum Pasteboard {
    /// Our own write is picked up by the monitor, which moves the item to the top of Recent.
    static func write(_ content: ClipContent, storage: Storage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        switch content {
        case let .text(text, rtf):
            pasteboard.setString(text, forType: .string)
            if let rtf { pasteboard.setData(rtf, forType: .rtf) }
        case let .image(fileName):
            guard let png = try? Data(contentsOf: storage.imageURL(fileName)) else { return }
            pasteboard.setData(png, forType: .png)
            if let tiff = NSImage(data: png)?.tiffRepresentation {
                pasteboard.setData(tiff, forType: .tiff)
            }
        }
    }
}
