import AppKit
import SwiftUI

/// shadcn/ui zinc tokens, resolved per light/dark appearance.
enum Theme {
    static let background = dynamic(light: 0xFFFFFF, dark: 0x18181B)
    static let foreground = dynamic(light: 0x09090B, dark: 0xFAFAFA)
    static let muted = dynamic(light: 0xF4F4F5, dark: 0x27272A)
    static let mutedForeground = dynamic(light: 0x71717A, dark: 0xA1A1AA)
    static let border = dynamic(light: 0xE4E4E7, dark: 0x27272A)
    static let ring = dynamic(light: 0xA1A1AA, dark: 0x52525B)

    private static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let hex = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
            return NSColor(
                srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: 1
            )
        })
    }
}

struct Hairline: View {
    var body: some View {
        Rectangle().fill(Theme.border).frame(height: 1)
    }
}

/// shadcn Kbd.
struct Kbd: View {
    let keys: String

    var body: some View {
        Text(keys)
            .font(.system(size: 10.5, weight: .medium))
            .foregroundStyle(Theme.mutedForeground)
            .padding(.horizontal, 5)
            .frame(minWidth: 18, minHeight: 18)
            .background(RoundedRectangle(cornerRadius: 4).fill(Theme.background))
            .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(Theme.border))
    }
}

/// shadcn Button variants.
struct ShadButtonStyle: ButtonStyle {
    enum Variant { case primary, outline, ghost }
    var variant: Variant

    func makeBody(configuration: Configuration) -> some View {
        ShadButton(configuration: configuration, variant: variant)
    }

    private struct ShadButton: View {
        let configuration: Configuration
        let variant: Variant
        @State private var hovering = false

        var body: some View {
            configuration.label
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 10)
                .frame(height: 28)
                .foregroundStyle(variant == .primary ? Theme.background : Theme.foreground)
                .background(RoundedRectangle(cornerRadius: 6).fill(fill))
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(variant == .outline ? Theme.border : .clear))
                .opacity(configuration.isPressed ? 0.8 : 1)
                .contentShape(Rectangle())
                .onHover { hovering = $0 }
        }

        private var fill: Color {
            switch variant {
            case .primary: Theme.foreground.opacity(hovering ? 0.9 : 1)
            case .outline, .ghost: hovering ? Theme.muted : .clear
            }
        }
    }
}

extension ButtonStyle where Self == ShadButtonStyle {
    static var primary: ShadButtonStyle { ShadButtonStyle(variant: .primary) }
    static var outline: ShadButtonStyle { ShadButtonStyle(variant: .outline) }
    static var ghost: ShadButtonStyle { ShadButtonStyle(variant: .ghost) }
}

/// shadcn ghost icon Button (the Dialog close "X").
struct IconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        IconButton(configuration: configuration)
    }

    private struct IconButton: View {
        let configuration: Configuration
        @State private var hovering = false

        var body: some View {
            configuration.label
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(hovering ? Theme.foreground : Theme.mutedForeground)
                .frame(width: 24, height: 24)
                .background(RoundedRectangle(cornerRadius: 6).fill(hovering ? Theme.muted : .clear))
                .opacity(configuration.isPressed ? 0.7 : 1)
                .contentShape(Rectangle())
                .onHover { hovering = $0 }
        }
    }
}

extension ButtonStyle where Self == IconButtonStyle {
    static var icon: IconButtonStyle { IconButtonStyle() }
}

/// shadcn Switch.
struct ShadSwitchStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            Capsule()
                .fill(configuration.isOn ? Theme.foreground : Theme.border)
                .frame(width: 34, height: 20)
                .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                    Circle()
                        .fill(Theme.background)
                        .shadow(color: .black.opacity(0.15), radius: 1, y: 1)
                        .padding(2)
                }
                .animation(.easeOut(duration: 0.12), value: configuration.isOn)
        }
        .buttonStyle(.plain)
    }
}

extension ToggleStyle where Self == ShadSwitchStyle {
    static var shadSwitch: ShadSwitchStyle { ShadSwitchStyle() }
}

/// shadcn Tabs-style segmented control: a muted track with the active segment raised.
struct Segmented<Value: Hashable>: View {
    @Binding var selection: Value
    let options: [(label: String, value: Value)]
    var segmentWidth: CGFloat = 72

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.value) { option in
                let active = selection == option.value
                Button { selection = option.value } label: {
                    Text(option.label)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(active ? Theme.foreground : Theme.mutedForeground)
                        .frame(width: segmentWidth, height: 24)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(active ? Theme.background : .clear)
                                .shadow(color: .black.opacity(active ? 0.08 : 0), radius: 1, y: 1)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(RoundedRectangle(cornerRadius: 8).fill(Theme.muted))
    }
}

/// Drags the window from empty space behind it; SwiftUI's own drag gesture needs macOS 15.
struct WindowDragArea: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView { DragView() }
    func updateNSView(_ nsView: NSView, context: Context) {}

    private final class DragView: NSView {
        override func mouseDown(with event: NSEvent) {
            window?.performDrag(with: event)
        }
    }
}

extension View {
    /// shadcn Input chrome around a plain TextField or a menu label.
    func inputChrome(focused: Bool = false) -> some View {
        font(.system(size: 13))
            .padding(.horizontal, 10)
            .frame(height: 30)
            .background(RoundedRectangle(cornerRadius: 6).fill(Theme.background))
            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(focused ? Theme.ring : Theme.border))
    }
}

/// Compact age for list rows: "now", "5m", "3h", "2d", then a short date.
func shortAge(since date: Date, now: Date = Date()) -> String {
    let seconds = Int(now.timeIntervalSince(date))
    switch seconds {
    case ..<60: return "now"
    case ..<3600: return "\(seconds / 60)m"
    case ..<86400: return "\(seconds / 3600)h"
    case ..<(7 * 86400): return "\(seconds / 86400)d"
    default: return date.formatted(.dateTime.month(.abbreviated).day())
    }
}
