import AppKit

/// The menu bar mark: the app icon's "Cut" square (a rounded square sliced across one corner),
/// drawn in code as a template image so it follows the menu bar's light/dark appearance.
/// Drawing it avoids shipping an image resource, which would need its own bundle (see the
/// KeyboardShortcuts bundle gotcha in CLAUDE.md). Source artwork: `assets/icon/clipq-mark.svg`.
enum MenuBarIcon {
    /// Filled when capturing, outlined when paused.
    static func image(paused: Bool) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: true) { _ in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            // Geometry comes from the 64-unit SVG artboard: square at 12...52 with radius 9,
            // cut along (28,56)-(56,28) with width 4.5. Scaled so the square spans 14pt.
            let k: CGFloat = 14.0 / 40.0
            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: 2 + (x - 12) * k, y: 2 + (y - 12) * k) }

            let square = CGRect(origin: p(12, 12), size: CGSize(width: 40 * k, height: 40 * k))
            ctx.setFillColor(NSColor.black.cgColor)
            ctx.setStrokeColor(NSColor.black.cgColor)
            if paused {
                let lineWidth: CGFloat = 1.5
                let inset = square.insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
                let radius = 9 * k - lineWidth / 2
                ctx.addPath(CGPath(roundedRect: inset, cornerWidth: radius, cornerHeight: radius, transform: nil))
                ctx.setLineWidth(lineWidth)
                ctx.strokePath()
            } else {
                ctx.addPath(CGPath(roundedRect: square, cornerWidth: 9 * k, cornerHeight: 9 * k, transform: nil))
                ctx.fillPath()
            }

            // Erase the diagonal slice so the menu bar shows through it.
            ctx.setBlendMode(.clear)
            ctx.setLineWidth(4.5 * k)
            ctx.move(to: p(28, 56))
            ctx.addLine(to: p(56, 28))
            ctx.strokePath()
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = paused ? "clipq (paused)" : "clipq"
        return image
    }
}
