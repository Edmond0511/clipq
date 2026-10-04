import ClipqCore
import SwiftUI

/// shadcn HoverCard showing a row's full contents.
struct PreviewCard: View {
    let model: PopupModel
    let target: PreviewTarget

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title = target.title {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.foreground)
            }
            switch target.content {
            case let .text(text, _):
                let excerpt = ItemPreview.excerpt(of: text)
                Text(excerpt.text)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Theme.foreground)
                    .fixedSize(horizontal: false, vertical: true)
                if excerpt.hiddenLines > 0 {
                    Text("+\(excerpt.hiddenLines) more \(excerpt.hiddenLines == 1 ? "line" : "lines")")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.mutedForeground)
                }
            case let .image(fileName):
                if let image = model.thumbnail(fileName) {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Theme.border))
                }
            }
            Hairline()
            Text(detail)
                .font(.system(size: 11))
                .foregroundStyle(Theme.mutedForeground)
        }
        .padding(12)
        .frame(width: 320, alignment: .leading)
        .background(Theme.background)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.border))
    }

    private var detail: String {
        let age = shortAge(since: target.date)
        let when = age == "now" ? "\(target.dateVerb) just now" : "\(target.dateVerb) \(age) ago"
        switch target.content {
        case let .text(text, _):
            return "\(ItemPreview.detail(of: text)), \(when)"
        case let .image(fileName):
            let size = model.pixelSize(fileName).map { ", \($0)" } ?? ""
            return "Image\(size), \(when)"
        }
    }
}

/// Reports the selected row's frame up to PopupView.
struct SelectedRowFrameKey: PreferenceKey {
    static var defaultValue: CGRect?
    static func reduce(value: inout CGRect?, nextValue: () -> CGRect?) {
        value = value ?? nextValue()
    }
}
