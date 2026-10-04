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
