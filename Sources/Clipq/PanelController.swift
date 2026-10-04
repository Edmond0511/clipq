import AppKit
import ClipqCore
import Combine
import SwiftUI

/// Borderless panels can't become key by default, and we need key status for typing.
private final class KeyPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

/// A non-activating panel, so the app the user was in stays frontmost and Cmd+V pastes there.
final class PanelController: NSObject, NSWindowDelegate {
    private let panel: KeyPanel
    private let model: PopupModel
    private var keyMonitor: Any?
    /// Display-only preview card beside the popup; a child window so it moves with drags.
    private let card = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel],
                               backing: .buffered, defer: true)
    private var modelChanges: AnyCancellable?

    init(model: PopupModel) {
        self.model = model
        panel = KeyPanel(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 460),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: true
        )
        super.init()
        // Transparent window so the SwiftUI view's rounded corners and border show.
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.delegate = self
        model.onClose = { [weak self] in self?.hide() }

        card.backgroundColor = .clear
        card.isOpaque = false
        card.hasShadow = true
        card.ignoresMouseEvents = true
        card.level = .floating
        card.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        // objectWillChange fires before the change lands, so read the model on the next turn.
        modelChanges = model.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async { self?.updatePreview() }
        }
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
        panel.invalidateShadow()
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, event.window === self.panel, !self.model.isFormOpen else { return event }
            return self.model.handleKey(event) ? nil : event
        }
    }

    func hide() {
        hideCard()
        panel.orderOut(nil)
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        keyMonitor = nil
    }

    func windowDidResignKey(_ notification: Notification) {
        hide()
    }

    private func updatePreview() {
        guard panel.isVisible, model.previewShown, let target = model.previewTarget,
              let row = model.selectedRowFrame, let screen = panel.screen ?? NSScreen.main
        else { return hideCard() }
        let host = NSHostingView(rootView: PreviewCard(model: model, target: target))
        let size = host.fittingSize
        card.contentView = host

        // Beside the popup, flipping left near the screen edge; top aligned with the row.
        // row is in SwiftUI's space, measured down from the popup's top edge.
        let popup = panel.frame
        let visible = screen.visibleFrame
        var x = popup.maxX + 8
        if x + size.width > visible.maxX { x = popup.minX - 8 - size.width }
        let y = min(max(popup.maxY - row.minY - size.height, visible.minY), visible.maxY - size.height)
        card.setFrame(NSRect(x: x, y: y, width: size.width, height: size.height), display: true)
        if card.parent == nil { panel.addChildWindow(card, ordered: .above) }
        card.orderFront(nil)
    }

    private func hideCard() {
        card.parent?.removeChildWindow(card)
        card.orderOut(nil)
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
