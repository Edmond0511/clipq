import KeyboardShortcuts
import SwiftUI

extension KeyboardShortcuts.Name {
    static let togglePanel = Self("togglePanel", default: .init(.v, modifiers: [.command, .shift]))
}

struct SettingsView: View {
    @State private var launchAtLogin = LoginItem.isEnabled

    var body: some View {
        Form {
            KeyboardShortcuts.Recorder("Open clipboard:", name: .togglePanel)
            Toggle("Launch at login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { LoginItem.setEnabled($0) }
        }
        .padding(20)
        .frame(width: 340)
    }
}
