import ClipqCore
import SwiftUI

struct FormCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            Color.black.opacity(0.25)
            content
                .padding(14)
                .frame(width: 320)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(nsColor: .windowBackgroundColor)))
                .shadow(radius: 8)
        }
    }
}

struct ItemFormView: View {
    let model: PopupModel
    @State var form: ItemForm
    let groups: [ClipGroup]
    @FocusState private var titleFocused: Bool

    init(model: PopupModel, form: ItemForm, groups: [ClipGroup]) {
        self.model = model
        _form = State(initialValue: form)
        self.groups = groups
    }

    private var isNew: Bool {
        if case .new = form.target { return true }
        return false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(isNew ? "Save Item" : "Edit Item").font(.headline)
            TextField("Title (optional)", text: $form.title)
                .focused($titleFocused)
            Picker("Group", selection: $form.groupID) {
                Text("Ungrouped").tag(UUID?.none)
                ForEach(groups) { Text($0.name).tag(UUID?.some($0.id)) }
            }
            .disabled(!form.newGroupName.trimmingCharacters(in: .whitespaces).isEmpty)
            TextField("Or new group name", text: $form.newGroupName)
            HStack {
                Spacer()
                Button("Cancel") { model.itemForm = nil }
                    .keyboardShortcut(.cancelAction)
                Button("Save") { model.commit(form) }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .textFieldStyle(.roundedBorder)
        .onAppear { DispatchQueue.main.async { titleFocused = true } }
    }
}

struct GroupFormView: View {
    let model: PopupModel
    @State var form: GroupForm
    @FocusState private var nameFocused: Bool

    init(model: PopupModel, form: GroupForm) {
        self.model = model
        _form = State(initialValue: form)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(form.groupID == nil ? "New Group" : "Rename Group").font(.headline)
            TextField("Group name", text: $form.name)
                .textFieldStyle(.roundedBorder)
                .focused($nameFocused)
            HStack {
                Spacer()
                Button("Cancel") { model.groupForm = nil }
                    .keyboardShortcut(.cancelAction)
                Button("Save") { model.commit(form) }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .onAppear { DispatchQueue.main.async { nameFocused = true } }
    }
}
