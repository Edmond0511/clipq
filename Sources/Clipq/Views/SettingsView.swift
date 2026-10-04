import AppKit
import ClipqCore
import KeyboardShortcuts
import SwiftUI

extension KeyboardShortcuts.Name {
    static let togglePanel = Self("togglePanel", default: .init(.v, modifiers: [.command, .shift]))
}

struct SettingsView: View {
    @ObservedObject var prefs: Preferences
    @State private var launchAtLogin = LoginItem.isEnabled
    @State private var hasAccessibility = AutoPaste.isTrusted

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingRow(title: "Open clipboard", detail: "Shortcut that shows clipq from any app.") {
                KeyboardShortcuts.Recorder("", name: .togglePanel)
            }
            Hairline()
            SettingRow(title: "Paste automatically", detail: "Picking an item pastes it into the app you were using. ⌘↩ still copies only.") {
                Toggle("", isOn: $prefs.autoPaste).toggleStyle(.shadSwitch)
            }
            if prefs.autoPaste && !hasAccessibility {
                PermissionNote()
                    .padding(.bottom, 14)
            }
            Hairline()
            SettingRow(title: "Keep in Recent", detail: "Older items are removed first. Saved items are never removed.") {
                Segmented(
                    selection: $prefs.historyLimit,
                    options: Preferences.historyLimits.map { ("\($0)", $0) },
                    segmentWidth: 40
                )
            }
            Hairline()
            SettingRow(title: "Capture images", detail: "Screenshots and copied images. Text is always captured.") {
                Toggle("", isOn: $prefs.captureImages).toggleStyle(.shadSwitch)
            }
            Hairline()
            SettingRow(title: "Launch at login", detail: "Start clipq when you log in to your Mac.") {
                Toggle("", isOn: $launchAtLogin).toggleStyle(.shadSwitch)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 2)
        .onChange(of: prefs.autoPaste) { on in
            if on && !AutoPaste.isTrusted { AutoPaste.requestPermission() }
        }
        .onChange(of: launchAtLogin) { LoginItem.setEnabled($0) }
    }
}

private struct SettingRow<Control: View>: View {
    let title: String
    let detail: String
    @ViewBuilder let control: Control

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.foreground)
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.mutedForeground)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            control.labelsHidden()
        }
        .padding(.vertical, 14)
    }
}

/// Shown while auto-paste is on but macOS hasn't granted Accessibility access.
private struct PermissionNote: View {
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 13))
                .foregroundStyle(Theme.foreground)
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Allow clipq to paste")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.foreground)
                    Text("Turn on clipq in Privacy & Security → Accessibility. Until then, items are only copied. You may need to do this again after updating clipq.")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.mutedForeground)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Button("Open System Settings") { AutoPaste.openSystemSettings() }
                    .buttonStyle(.outline)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(Theme.muted.opacity(0.5)))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.border))
    }
}
