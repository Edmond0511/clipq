import AppKit
import ClipqCore
import SwiftUI

/// Borderless-looking panels can't become key by default, and we need key status for typing.
private final class KeyPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

/// A non-activating panel, so the app the user was in stays frontmost and Cmd+V pastes there.
final class PanelController: NSObject, NSWindowDelegate {
    private let panel: KeyPanel
    private let model: PopupModel
    private var keyMonitor: Any?

    init(model: PopupModel) {
        self.model = model
        panel = KeyPanel(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 460),
            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
            backing: .buffered,
            defer: true
        )
        super.init()
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        for button in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
            panel.standardWindowButton(button)?.isHidden = true
        }
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.delegate = self
        model.onClose = { [weak self] in self?.hide() }
    }

    func toggle() {
        panel.isVisible ? hide() : show()
    }

    func show() {
        model.reset()
        // A fresh hosting view resets view state and re-runs onAppear focus.
        panel.contentView = NSHostingView(rootView: PopupView(model: model))
        positionAtMouse()
        panel.makeKeyAndOrderFront(nil)
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, event.window === self.panel, !self.model.isFormOpen else { return event }
            return self.model.handleKey(event) ? nil : event
        }
    }

    func hide() {
        panel.orderOut(nil)
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        keyMonitor = nil
    }

    func windowDidResignKey(_ notification: Notification) {
        hide()
    }

    private func positionAtMouse() {
        let mouse = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { NSMouseInRect(mouse, $0.frame, false) }) ?? NSScreen.main
        else { return }
        let visible = screen.visibleFrame
        let size = panel.frame.size
        // Top-left corner at the pointer, clamped to the screen.
        let x = min(max(mouse.x, visible.minX), visible.maxX - size.width)
        let y = min(max(mouse.y - size.height, visible.minY), visible.maxY - size.height)
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
