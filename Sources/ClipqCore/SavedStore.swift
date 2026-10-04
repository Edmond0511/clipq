import Combine
import Foundation

/// Items the user chose to keep, in folder-style groups. Never evicted.
public final class SavedStore: ObservableObject {
    public static let fileName = "saved.json"

    private struct Snapshot: Codable {
        var groups: [ClipGroup]
        var items: [SavedItem]
    }

    @Published public private(set) var groups: [ClipGroup]
    @Published public private(set) var items: [SavedItem]
    private let storage: Storage
    private let now: () -> Date

    public init(storage: Storage, now: @escaping () -> Date = Date.init) {
        self.storage = storage
        self.now = now
        let snapshot = storage.load(Snapshot.self, from: Self.fileName)
        groups = snapshot?.groups ?? []
        items = snapshot?.items ?? []
    }

    @discardableResult
    public func save(_ content: ClipContent, title: String?, groupID: UUID?) -> SavedItem {
        let item = SavedItem(
            id: UUID(),
            content: storage.detachedCopy(of: content),
            title: normalized(title),
            groupID: groupID,
            savedAt: now()
        )
        items.append(item)
        persist()
        return item
    }

    public func update(_ id: UUID, title: String?, groupID: UUID?) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].title = normalized(title)
        items[index].groupID = groupID
        persist()
    }

    public func remove(_ id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        storage.deleteFiles(of: items.remove(at: index).content)
        persist()
    }

    @discardableResult
    public func createGroup(named name: String) -> ClipGroup {
        let group = ClipGroup(id: UUID(), name: name)
        groups.append(group)
        persist()
        return group
    }

    public func renameGroup(_ id: UUID, to name: String) {
        guard let index = groups.firstIndex(where: { $0.id == id }) else { return }
        groups[index].name = name
        persist()
    }

    /// Items in the deleted group move to Ungrouped rather than being deleted.
    public func deleteGroup(_ id: UUID) {
        groups.removeAll { $0.id == id }
        for index in items.indices where items[index].groupID == id {
            items[index].groupID = nil
        }
        persist()
    }

    public func items(in groupID: UUID?) -> [SavedItem] {
        items.filter { $0.groupID == groupID }
    }

    private func normalized(_ title: String?) -> String? {
        let trimmed = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    private func persist() {
        storage.save(Snapshot(groups: groups, items: items), to: Self.fileName)
    }
}
