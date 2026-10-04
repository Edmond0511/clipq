import Combine
import Foundation

/// Recent copies, newest first, capped FIFO. Re-copying an existing item moves it to the top.
public final class HistoryStore: ObservableObject {
    public static let fileName = "history.json"

    @Published public private(set) var items: [HistoryItem]
    /// Lowering it trims the oldest items right away.
    public var capacity: Int {
        didSet {
            trimToCapacity()
            persist()
        }
    }
    public var capturesImages = true
    private let storage: Storage
    private let now: () -> Date

    public init(storage: Storage, capacity: Int = 25, now: @escaping () -> Date = Date.init) {
        self.storage = storage
        self.capacity = capacity
        self.now = now
        items = storage.load([HistoryItem].self, from: Self.fileName) ?? []
    }

    public func addText(_ text: String, rtf: Data? = nil) {
        guard !text.isEmpty else { return }
        record(hash: sha256(Data(text.utf8))) { .text(text, rtf: rtf) }
    }

    public func addImage(png: Data) {
        guard capturesImages else { return }
        record(hash: sha256(png)) { .image(fileName: storage.writeImage(png)) }
    }

    public func remove(_ id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        storage.deleteFiles(of: items.remove(at: index).content)
        persist()
    }

    public func clear() {
        items.forEach { storage.deleteFiles(of: $0.content) }
        items = []
        persist()
    }

    // makeContent is only called for new items, so duplicate images aren't written to disk.
    private func record(hash: String, makeContent: () -> ClipContent) {
        if let index = items.firstIndex(where: { $0.hash == hash }) {
            var existing = items.remove(at: index)
            existing.copiedAt = now()
            items.insert(existing, at: 0)
        } else {
            items.insert(HistoryItem(id: UUID(), content: makeContent(), hash: hash, copiedAt: now()), at: 0)
            trimToCapacity()
        }
        persist()
    }

    private func trimToCapacity() {
        while items.count > capacity {
            storage.deleteFiles(of: items.removeLast().content)
        }
    }

    private func persist() {
        storage.save(items, to: Self.fileName)
    }
}
