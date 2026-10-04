import AppKit
import ClipqCore

enum Tab: Hashable {
    case recent, saved
}

enum Page: Hashable {
    case clipboard, settings
}

struct ItemForm {
    enum Target {
        case new(ClipContent)
        case existing(UUID)
    }

    var target: Target
    var title = ""
    var groupID: UUID?
    var newGroupName = ""
}

struct GroupForm {
    var groupID: UUID? // nil creates a new group
    var name = ""
}

struct SavedSection: Identifiable {
    let group: ClipGroup? // nil is Ungrouped
    let items: [SavedItem]
    var id: UUID? { group?.id }
}

final class PopupModel: ObservableObject {
    // Guarded: the search field writes back unchanged values on focus.
    @Published var tab: Tab = .recent { didSet { if tab != oldValue { selection = 0 } } }
    @Published var query = "" { didSet { if query != oldValue { selection = 0 } } }
    @Published var selection = 0
    @Published var itemForm: ItemForm?
    @Published var groupForm: GroupForm?
    @Published var confirmingClear = false
    @Published var page: Page = .clipboard

    let history: HistoryStore
    let saved: SavedStore
    let storage: Storage
    let prefs: Preferences
    var onClose: () -> Void = {}
    private let thumbnails = NSCache<NSString, NSImage>()

    init(history: HistoryStore, saved: SavedStore, storage: Storage, prefs: Preferences) {
        self.history = history
        self.saved = saved
        self.storage = storage
        self.prefs = prefs
    }

    var isFormOpen: Bool { itemForm != nil || groupForm != nil || confirmingClear }

    var pastesOnSelect: Bool { prefs.autoPaste && AutoPaste.isTrusted }

    func reset() {
        tab = .recent
        query = ""
        selection = 0
        itemForm = nil
        groupForm = nil
        confirmingClear = false
        page = .clipboard
    }

    // MARK: Rows

    var recentRows: [HistoryItem] {
        history.items.filter { matches(query, content: $0.content) }
    }

    /// Ungrouped first, then groups in creation order. Empty groups are hidden while searching.
    var savedSections: [SavedSection] {
        let all = [nil] + saved.groups.map(Optional.some)
        return all.compactMap { group in
            let items = saved.items(in: group?.id).filter { matches(query, content: $0.content, title: $0.title) }
            if items.isEmpty && (group == nil || !query.isEmpty) { return nil }
            return SavedSection(group: group, items: items)
        }
    }

    var savedRows: [SavedItem] { savedSections.flatMap(\.items) }

    private var rowCount: Int { tab == .recent ? recentRows.count : savedRows.count }

    func thumbnail(_ fileName: String) -> NSImage? {
        if let cached = thumbnails.object(forKey: fileName as NSString) { return cached }
        guard let image = NSImage(contentsOf: storage.imageURL(fileName)) else { return nil }
        thumbnails.setObject(image, forKey: fileName as NSString)
        return image
    }

    /// "1280 × 720", from the image's pixel dimensions.
    func pixelSize(_ fileName: String) -> String? {
        guard let rep = thumbnail(fileName)?.representations.first, rep.pixelsWide > 0 else { return nil }
        return "\(rep.pixelsWide) × \(rep.pixelsHigh)"
    }

    // MARK: Keyboard

    /// Returns true when the key was handled and should not reach the search field.
    func handleKey(_ event: NSEvent) -> Bool {
        let command = event.modifierFlags.contains(.command)
        // Settings only claims Esc and ⌘, so the shortcut recorder gets every other key.
        if page == .settings {
            guard event.keyCode == 53 || (command && event.charactersIgnoringModifiers == ",") else { return false }
            page = .clipboard
            return true
        }
        switch (event.keyCode, command) {
        case (125, _): moveSelection(1) // down
        case (126, _): moveSelection(-1) // up
        case (36, false), (76, false): useSelected(paste: pastesOnSelect) // return, keypad enter
        case (36, true), (76, true): useSelected(paste: false) // cmd+return copies only
        case (53, _): onClose() // escape
        case (48, _): tab = tab == .recent ? .saved : .recent
        case (51, true): deleteSelected() // cmd+backspace
        default:
            guard command else { return false }
            switch event.charactersIgnoringModifiers {
            case "1": tab = .recent
            case "2": tab = .saved
            case ",": page = .settings
            case "s": if tab == .recent, recentRows.indices.contains(selection) { startSave(recentRows[selection]) }
            default: return false
            }
        }
        return true
    }

    private func moveSelection(_ delta: Int) {
        guard rowCount > 0 else { return }
        selection = min(max(selection + delta, 0), rowCount - 1)
    }

    // MARK: Actions

    func copy(_ content: ClipContent) {
        use(content, paste: false)
    }

    /// What Return and clicking a row do: paste when auto-paste is available, else copy.
    func select(_ content: ClipContent) {
        use(content, paste: pastesOnSelect)
    }

    private func use(_ content: ClipContent, paste: Bool) {
        let written = Pasteboard.write(content, storage: storage)
        onClose()
        if paste && written { AutoPaste.pasteIntoFrontApp() }
    }


    private func useSelected(paste: Bool) {
        switch tab {
        case .recent: if recentRows.indices.contains(selection) { use(recentRows[selection].content, paste: paste) }
        case .saved: if savedRows.indices.contains(selection) { use(savedRows[selection].content, paste: paste) }
        }
    }

    func clearRecent() {
        history.clear()
        confirmingClear = false
        page = .clipboard
    }

    private func deleteSelected() {
        switch tab {
        case .recent: if recentRows.indices.contains(selection) { history.remove(recentRows[selection].id) }
        case .saved: if savedRows.indices.contains(selection) { saved.remove(savedRows[selection].id) }
        }
        selection = min(selection, max(rowCount - 1, 0))
    }

    func startSave(_ item: HistoryItem) {
        itemForm = ItemForm(target: .new(item.content))
    }

    func startEdit(_ item: SavedItem) {
        itemForm = ItemForm(target: .existing(item.id), title: item.title ?? "", groupID: item.groupID)
    }

    func commit(_ form: ItemForm) {
        var groupID = form.groupID
        let newGroupName = form.newGroupName.trimmingCharacters(in: .whitespaces)
        if !newGroupName.isEmpty {
            groupID = saved.createGroup(named: newGroupName).id
        }
        switch form.target {
        case let .new(content): saved.save(content, title: form.title, groupID: groupID)
        case let .existing(id): saved.update(id, title: form.title, groupID: groupID)
        }
        itemForm = nil
    }

    func commit(_ form: GroupForm) {
        let name = form.name.trimmingCharacters(in: .whitespaces)
        if !name.isEmpty {
            if let id = form.groupID {
                saved.renameGroup(id, to: name)
            } else {
                saved.createGroup(named: name)
            }
        }
        groupForm = nil
    }
}
