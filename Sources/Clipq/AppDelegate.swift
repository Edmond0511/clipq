import AppKit
import ClipqCore
import Combine
import KeyboardShortcuts
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let storage = Storage()
    private let prefs = Preferences()
    private lazy var history = HistoryStore(storage: storage, capacity: prefs.historyLimit)
    private lazy var saved = SavedStore(storage: storage)
    private lazy var monitor = ClipboardMonitor(history: history)
    private lazy var model = PopupModel(history: history, saved: saved, storage: storage, prefs: prefs)
    private lazy var panel = PanelController(model: model)
    private var subscriptions = Set<AnyCancellable>()
    private var statusItem: NSStatusItem!
    private let pauseItem = NSMenuItem(title: "Pause Capturing", action: #selector(togglePause), keyEquivalent: "")
    private let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLogin), keyEquivalent: "")

    func applicationDidFinishLaunching(_ notification: Notification) {
        prefs.$historyLimit.sink { [weak self] in self?.history.capacity = $0 }.store(in: &subscriptions)
        prefs.$captureImages.sink { [weak self] in self?.history.capturesImages = $0 }.store(in: &subscriptions)
        monitor.start()
        KeyboardShortcuts.onKeyUp(for: .togglePanel) { [weak self] in self?.panel.toggle() }
        setUpStatusItem()
    }

    private func setUpStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        updateIcon()

        let menu = NSMenu()
        menu.delegate = self
        let open = NSMenuItem(title: "Open Clipboard", action: #selector(openPanel), keyEquivalent: "")
        open.setShortcut(for: .togglePanel)
        menu.addItem(open)
        menu.addItem(.separator())
        menu.addItem(pauseItem)
        menu.addItem(NSMenuItem(title: "Clear Recent", action: #selector(clearRecent), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(loginItem)
        menu.addItem(NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit clipq", action: #selector(NSApplication.terminate), keyEquivalent: "q"))
        for item in menu.items where item.action != #selector(NSApplication.terminate) {
            item.target = self
        }
        statusItem.menu = menu
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        pauseItem.state = monitor.isPaused ? .on : .off
        loginItem.state = LoginItem.isEnabled ? .on : .off
    }

    private func updateIcon() {
        let name = monitor.isPaused ? "pause.circle" : "doc.on.clipboard"
        statusItem.button?.image = NSImage(systemSymbolName: name, accessibilityDescription: "clipq")
    }

    @objc private func openPanel() {
        panel.show()
    }

    @objc private func togglePause() {
        monitor.isPaused.toggle()
        updateIcon()
    }

    /// Same confirmation as the popup's Clear button.
    @objc private func clearRecent() {
        panel.show()
        model.confirmingClear = true
    }

    @objc private func toggleLogin() {
        LoginItem.setEnabled(!LoginItem.isEnabled)
    }

    @objc private func openSettings() {
        panel.show()
        model.page = .settings
    }
}
