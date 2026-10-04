import ClipqCore
import SwiftUI

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
        VStack(spacing: 8) {
            Picker("", selection: $model.tab) {
                Text("Recent").tag(Tab.recent)
                Text("Saved").tag(Tab.saved)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            TextField("Search", text: $model.query)
                .textFieldStyle(.roundedBorder)
                .focused($searchFocused)

            switch model.tab {
            case .recent: RecentList(model: model)
            case .saved: SavedList(model: model)
            }
        }
        .padding(10)
        .frame(width: 380, height: 460)
        .overlay { forms }
        .onAppear { DispatchQueue.main.async { searchFocused = true } }
        .onChange(of: model.isFormOpen) { open in
            if !open { searchFocused = true }
        }
    }

    @ViewBuilder private var forms: some View {
        if let form = model.itemForm {
            FormCard { ItemFormView(model: model, form: form, groups: saved.groups) }
        } else if let form = model.groupForm {
            FormCard { GroupFormView(model: model, form: form) }
        }
    }
}

struct RecentList: View {
    @ObservedObject var model: PopupModel

    var body: some View {
        let rows = model.recentRows
        if rows.isEmpty {
            EmptyState(text: model.query.isEmpty ? "Copy something and it will show up here." : "No matches.")
        } else {
            SelectableList(selection: model.selection, ids: rows.map(\.id)) {
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, item in
                    ClipRow(model: model, content: item.content, title: nil, index: index)
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
        VStack(spacing: 6) {
            if sections.isEmpty {
                EmptyState(text: model.query.isEmpty
                    ? "Save items from Recent with ⌘S or right-click → Save."
                    : "No matches.")
            } else {
                SelectableList(selection: model.selection, ids: model.savedRows.map(\.id)) {
                    ForEach(Array(sections.enumerated()), id: \.element.id) { sectionIndex, section in
                        SectionHeader(model: model, group: section.group)
                        ForEach(Array(section.items.enumerated()), id: \.element.id) { itemIndex, item in
                            ClipRow(model: model, content: item.content, title: item.title,
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
            HStack {
                Spacer()
                Button {
                    model.groupForm = GroupForm(groupID: nil)
                } label: {
                    Label("New Group", systemImage: "folder.badge.plus")
                }
                .buttonStyle(.borderless)
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
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 6)
            .contentShape(Rectangle())
            .contextMenu {
                if let group {
                    Button("Rename…") { model.groupForm = GroupForm(groupID: group.id, name: group.name) }
                    Button("Delete Group") { model.saved.deleteGroup(group.id) }
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
                LazyVStack(alignment: .leading, spacing: 2) { content }
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
    let index: Int

    var body: some View {
        HStack(spacing: 8) {
            if case let .image(fileName) = content, let image = model.thumbnail(fileName) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: title == nil ? .infinity : 64, maxHeight: 64, alignment: .leading)
            }
            VStack(alignment: .leading, spacing: 2) {
                if let title {
                    Text(title).fontWeight(.semibold).lineLimit(1)
                    if case .text = content {
                        Text(content.preview).foregroundStyle(.secondary).lineLimit(1)
                    }
                } else if case let .text(text, _) = content {
                    Text(text.prefix(300).trimmingCharacters(in: .whitespacesAndNewlines)).lineLimit(2)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(index == model.selection ? Color.accentColor.opacity(0.25) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { if $0 { model.selection = index } }
        .onTapGesture { model.copy(content) }
    }
}

private struct EmptyState: View {
    let text: String

    var body: some View {
        Text(text)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
