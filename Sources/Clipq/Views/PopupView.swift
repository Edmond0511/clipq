import ClipqCore
import SwiftUI

/// shadcn Command palette: search, tabs, list, key hints. Settings is a page inside it.
struct PopupView: View {
    @ObservedObject var model: PopupModel
    @ObservedObject var history: HistoryStore
    @ObservedObject var saved: SavedStore
    @FocusState private var searchFocused: Bool

    init(model: PopupModel) {
        self.model = model
        history = model.history
        saved = model.saved
    }

    var body: some View {
        VStack(spacing: 0) {
            switch model.page {
            case .clipboard: clipboardPage
            case .settings: settingsPage
            }
        }
        .frame(width: 380, height: 460)
        // Behind everything, so any surface that isn't a control drags the window.
        .background {
            ZStack {
                Theme.background
                WindowDragArea()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.border))
        .overlay { forms }
        .onAppear { DispatchQueue.main.async { searchFocused = true } }
        .onChange(of: model.isFormOpen) { open in
            if !open { searchFocused = true }
        }
        .onChange(of: model.page) { page in
            if page == .clipboard { searchFocused = true }
        }
    }

    @ViewBuilder private var clipboardPage: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13))
                .foregroundStyle(Theme.mutedForeground)
            TextField("Search clipboard", text: $model.query)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .foregroundStyle(Theme.foreground)
                .focused($searchFocused)
            Button { model.page = .settings } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.icon)
            .help("Settings (⌘,)")
            CloseButton(model: model)
        }
        .padding(.leading, 14)
        .padding(.trailing, 10)
        .frame(height: 46)
        Hairline()

        HStack {
            Segmented(selection: $model.tab, options: [("Recent", .recent), ("Saved", .saved)])
            Spacer()
            switch model.tab {
            case .recent where !history.items.isEmpty:
                Button {
                    model.confirmingClear = true
                } label: {
                    Label("Clear", systemImage: "trash")
                }
                .buttonStyle(.ghost)
            case .saved:
                Button {
                    model.groupForm = GroupForm(groupID: nil)
                } label: {
                    Label("New group", systemImage: "plus")
                }
                .buttonStyle(.ghost)
            default:
                EmptyView()
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 4)

        Group {
            switch model.tab {
            case .recent: RecentList(model: model)
            case .saved: SavedList(model: model)
            }
        }
        .frame(maxHeight: .infinity)
        .onHover { if !$0 { model.hidePreview() } }
        .onPreferenceChange(SelectedRowFrameKey.self) { model.selectedRowFrame = $0 }

        Hairline()
        KeyHints(tab: model.tab, pastes: model.pastesOnSelect)
    }

    @ViewBuilder private var settingsPage: some View {
        HStack(spacing: 8) {
            Button { model.page = .clipboard } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.icon)
            .help("Back (esc)")
            Text("Settings")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.foreground)
            Spacer()
            CloseButton(model: model)
        }
        .padding(.leading, 10)
        .padding(.trailing, 10)
        .frame(height: 46)
        Hairline()
        ScrollView {
            SettingsView(prefs: model.prefs)
        }
        .frame(maxHeight: .infinity)
        Hairline()
        HStack {
            KeyHint(keys: "esc", label: "Back")
            Spacer()
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
        .background(Theme.muted.opacity(0.4).allowsHitTesting(false))
    }

    @ViewBuilder private var forms: some View {
        if let form = model.itemForm {
            Dialog { ItemFormView(model: model, form: form, groups: saved.groups) }
        } else if let form = model.groupForm {
            Dialog { GroupFormView(model: model, form: form) }
        } else if model.confirmingClear {
            Dialog { ConfirmClearView(model: model, count: history.items.count) }
        }
    }
}

private struct KeyHints: View {
    let tab: Tab
    let pastes: Bool

    var body: some View {
        HStack(spacing: 12) {
            if pastes {
                hint("↩", "Paste")
                hint("⌘↩", "Copy")
            } else {
                hint("↩", "Copy")
            }
            if tab == .recent { hint("⌘S", "Save") }
            hint("⌘⌫", "Delete")
            Spacer()
            hint("⇥", "Tabs")
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
        .background(Theme.muted.opacity(0.4).allowsHitTesting(false))
    }

    private func hint(_ keys: String, _ label: String) -> some View {
        KeyHint(keys: keys, label: label)
    }
}

private struct KeyHint: View {
    let keys: String
    let label: String

    var body: some View {
        HStack(spacing: 5) {
            Kbd(keys: keys)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Theme.mutedForeground)
        }
    }
}

private struct CloseButton: View {
    let model: PopupModel

    var body: some View {
        Button { model.onClose() } label: {
            Image(systemName: "xmark")
        }
        .buttonStyle(.icon)
        .help("Close")
    }
}

struct RecentList: View {
    @ObservedObject var model: PopupModel

    var body: some View {
        let rows = model.recentRows
        if rows.isEmpty {
            if model.query.isEmpty {
                EmptyState(icon: "doc.on.clipboard", title: "No copies yet",
                           detail: "Copy anything and it shows up here.")
            } else {
                EmptyState(icon: "magnifyingglass", title: "No results",
                           detail: "Nothing in Recent matches “\(model.query)”.")
            }
        } else {
            SelectableList(selection: model.selection, ids: rows.map(\.id)) {
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, item in
                    ClipRow(model: model, content: item.content, title: nil, date: item.copiedAt, index: index)
                        .contextMenu {
                            Button("Copy") { model.copy(item.content) }
                            Button("Save…") { model.startSave(item) }
                            Divider()
                            Button("Delete") { model.history.remove(item.id) }
                        }
                }
            }
        }
    }
}

struct SavedList: View {
    @ObservedObject var model: PopupModel

    var body: some View {
        let sections = model.savedSections
        if sections.isEmpty {
            if model.query.isEmpty {
                EmptyState(icon: "bookmark", title: "Nothing saved yet",
                           detail: "Select a copy in Recent and press ⌘S to keep it here.")
            } else {
                EmptyState(icon: "magnifyingglass", title: "No results",
                           detail: "Nothing in Saved matches “\(model.query)”.")
            }
        } else {
            SelectableList(selection: model.selection, ids: model.savedRows.map(\.id)) {
                ForEach(Array(sections.enumerated()), id: \.element.id) { sectionIndex, section in
                    SectionHeader(model: model, group: section.group)
                    if section.items.isEmpty {
                        Text("Empty group")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.mutedForeground)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                    }
                    ForEach(Array(section.items.enumerated()), id: \.element.id) { itemIndex, item in
                        ClipRow(model: model, content: item.content, title: item.title, date: item.savedAt,
                                index: Self.startIndex(of: sectionIndex, in: sections) + itemIndex)
                            .contextMenu {
                                Button("Copy") { model.copy(item.content) }
                                Button("Edit…") { model.startEdit(item) }
                                Divider()
                                Button("Delete") { model.saved.remove(item.id) }
                            }
                    }
                }
            }
        }
    }

    /// Row indices run across sections to match model.savedRows.
    private static func startIndex(of sectionIndex: Int, in sections: [SavedSection]) -> Int {
        sections.prefix(sectionIndex).reduce(0) { $0 + $1.items.count }
    }
}

private struct SectionHeader: View {
    @ObservedObject var model: PopupModel
    let group: ClipGroup?

    var body: some View {
        Text(group?.name ?? "Ungrouped")
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(Theme.mutedForeground)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.top, 10)
            .padding(.bottom, 2)
            .contentShape(Rectangle())
            .contextMenu {
                if let group {
                    Button("Rename…") { model.groupForm = GroupForm(groupID: group.id, name: group.name) }
                    Button("Delete group") { model.saved.deleteGroup(group.id) }
                }
            }
    }
}

/// Scroll container that keeps the keyboard selection in view.
private struct SelectableList<Content: View>: View {
    let selection: Int
    let ids: [UUID]
    @ViewBuilder let content: Content

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 1) { content }
                    .padding(.horizontal, 6)
                    .padding(.bottom, 6)
            }
            .onChange(of: selection) { index in
                if ids.indices.contains(index) { proxy.scrollTo(ids[index]) }
            }
        }
    }
}

private struct ClipRow: View {
    @ObservedObject var model: PopupModel
    let content: ClipContent
    let title: String?
    let date: Date
    let index: Int

    private var isSelected: Bool { index == model.selection }

    var body: some View {
        HStack(spacing: 10) {
            leading
            VStack(alignment: .leading, spacing: 1) {
                Text(primary)
                    .font(.system(size: 13, weight: title == nil ? .regular : .medium))
                    .foregroundStyle(Theme.foreground)
                if let secondary {
                    Text(secondary)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.mutedForeground)
                }
            }
            .lineLimit(1)
            Spacer(minLength: 8)
            if isSelected {
                Kbd(keys: "↩")
            } else {
                Text(shortAge(since: date))
                    .font(.system(size: 11).monospacedDigit())
                    .foregroundStyle(Theme.mutedForeground)
            }
        }
        .padding(.horizontal, 8)
        .frame(minHeight: 36)
        .background(RoundedRectangle(cornerRadius: 6).fill(isSelected ? Theme.muted : .clear))
        .contentShape(Rectangle())
        .onHover { if $0 { model.hoverRow(index) } }
        .background {
            GeometryReader { geometry in
                Color.clear.preference(key: SelectedRowFrameKey.self,
                                       value: isSelected ? geometry.frame(in: .global) : nil)
            }
        }
        .onTapGesture { model.select(content) }
    }

    @ViewBuilder private var leading: some View {
        if case let .image(fileName) = content, let image = model.thumbnail(fileName) {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 24, height: 24)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(Theme.border))
        } else {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(Theme.mutedForeground)
                .frame(width: 24, height: 24)
        }
    }

    private var icon: String {
        switch content {
        case let .text(text, _):
            text.hasPrefix("http://") || text.hasPrefix("https://") ? "link" : "text.alignleft"
        case .image:
            "photo"
        }
    }

    private var imageLabel: String {
        guard case let .image(fileName) = content, let size = model.pixelSize(fileName) else { return "Image" }
        return "Image, \(size)"
    }

    private var primary: String {
        if let title { return title }
        if case .image = content { return imageLabel }
        return content.preview
    }

    private var secondary: String? {
        guard title != nil else { return nil }
        if case .image = content { return imageLabel }
        return content.preview
    }
}

private struct EmptyState: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Theme.mutedForeground)
                .padding(.bottom, 4)
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.foreground)
            Text(detail)
                .font(.system(size: 12))
                .foregroundStyle(Theme.mutedForeground)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
