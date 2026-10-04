import ClipqCore
import SwiftUI

/// shadcn Dialog: dimmed overlay with a bordered card.
struct Dialog<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
            content
                .padding(16)
                .frame(width: 300)
                .background(Theme.background)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.border))
                .shadow(color: .black.opacity(0.2), radius: 16, y: 8)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct DialogHeader: View {
    let title: String
    let detail: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.foreground)
            if let detail {
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.mutedForeground)
                    .lineLimit(1)
            }
        }
    }
}

private struct FieldLabel: View {
    let text: String
    var optional = false

    var body: some View {
        HStack(spacing: 4) {
            Text(text).foregroundStyle(Theme.foreground)
            if optional { Text("Optional").foregroundStyle(Theme.mutedForeground) }
        }
        .font(.system(size: 12, weight: .medium))
    }
}

private struct DialogButtons: View {
    let confirm: String
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Spacer()
            Button("Cancel", action: onCancel)
                .buttonStyle(.outline)
                .keyboardShortcut(.cancelAction)
            Button(confirm, action: onConfirm)
                .buttonStyle(.primary)
                .keyboardShortcut(.defaultAction)
        }
        .padding(.top, 2)
    }
}

struct ItemFormView: View {
    private enum Field { case title, newGroup }

    let model: PopupModel
    @State private var form: ItemForm
    @State private var creatingGroup = false
    let groups: [ClipGroup]
    @FocusState private var focus: Field?

    init(model: PopupModel, form: ItemForm, groups: [ClipGroup]) {
        self.model = model
        _form = State(initialValue: form)
        self.groups = groups
    }

    private var isNew: Bool {
        if case .new = form.target { return true }
        return false
    }

    private var groupName: String {
        if creatingGroup { return "New group" }
        return groups.first { $0.id == form.groupID }?.name ?? "Ungrouped"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            DialogHeader(title: isNew ? "Save item" : "Edit item", detail: preview)

            VStack(alignment: .leading, spacing: 6) {
                FieldLabel(text: "Title", optional: true)
                TextField("Add a title", text: $form.title)
                    .textFieldStyle(.plain)
                    .focused($focus, equals: .title)
                    .inputChrome(focused: focus == .title)
            }

            VStack(alignment: .leading, spacing: 6) {
                FieldLabel(text: "Group")
                Menu {
                    Button("Ungrouped") { pick(nil) }
                    ForEach(groups) { group in
                        Button(group.name) { pick(group.id) }
                    }
                    Divider()
                    Button("New group…") {
                        creatingGroup = true
                        focus = .newGroup
                    }
                } label: {
                    HStack {
                        Text(groupName).foregroundStyle(Theme.foreground)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.mutedForeground)
                    }
                    .inputChrome()
                    .contentShape(Rectangle())
                }
                .menuStyle(.button)
                .buttonStyle(.plain)
                .menuIndicator(.hidden)

                if creatingGroup {
                    TextField("Group name", text: $form.newGroupName)
                        .textFieldStyle(.plain)
                        .focused($focus, equals: .newGroup)
                        .inputChrome(focused: focus == .newGroup)
                }
            }

            DialogButtons(
                confirm: isNew ? "Save" : "Save changes",
                onCancel: { model.itemForm = nil },
                onConfirm: {
                    if !creatingGroup { form.newGroupName = "" }
                    model.commit(form)
                }
            )
        }
        .onAppear { DispatchQueue.main.async { focus = .title } }
    }

    private var preview: String? {
        guard case let .new(content) = form.target else { return nil }
        return content.preview
    }

    private func pick(_ groupID: UUID?) {
        creatingGroup = false
        form.groupID = groupID
    }
}

struct GroupFormView: View {
    let model: PopupModel
    @State private var form: GroupForm
    @FocusState private var nameFocused: Bool

    init(model: PopupModel, form: GroupForm) {
        self.model = model
        _form = State(initialValue: form)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            DialogHeader(title: form.groupID == nil ? "New group" : "Rename group", detail: nil)
            VStack(alignment: .leading, spacing: 6) {
                FieldLabel(text: "Name")
                TextField("e.g. Work", text: $form.name)
                    .textFieldStyle(.plain)
                    .focused($nameFocused)
                    .inputChrome(focused: nameFocused)
            }
            DialogButtons(
                confirm: form.groupID == nil ? "Create" : "Rename",
                onCancel: { model.groupForm = nil },
                onConfirm: { model.commit(form) }
            )
        }
        .onAppear { DispatchQueue.main.async { nameFocused = true } }
    }
}

struct ConfirmClearView: View {
    let model: PopupModel
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            DialogHeader(title: "Clear Recent?", detail: nil)
            Text("This removes \(count == 1 ? "1 item" : "\(count) items") from Recent. Saved items stay. This can't be undone.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.mutedForeground)
                .fixedSize(horizontal: false, vertical: true)
            DialogButtons(
                confirm: "Clear",
                onCancel: { model.confirmingClear = false },
                onConfirm: { model.clearRecent() }
            )
        }
    }
}
