import Foundation

/// Rules for the full-contents preview card.
public enum ItemPreview {
    public struct Excerpt: Equatable {
        public let text: String
        public let hiddenLines: Int
    }

    static let maxLines = 20

    /// Roughly what fits on one 380pt popup row before it truncates.
    static let singleLineLimit = 44

    /// True when the row hides something: extra lines, a cut-off line, an image, or contents behind a title.
    public static func isNeeded(for content: ClipContent, title: String?) -> Bool {
        if title != nil { return true }
        switch content {
        case .image: return true
        case let .text(text, _):
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.contains(where: \.isNewline) || trimmed.count > singleLineLimit
        }
    }

    /// The first 20 lines, keeping indentation; trailing blank lines don't count.
    public static func excerpt(of text: String) -> Excerpt {
        let lines = trimmingTrailing(text).split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
        return Excerpt(
            text: lines.prefix(maxLines).joined(separator: "\n"),
            hiddenLines: max(lines.count - maxLines, 0)
        )
    }

    /// "1,204 characters, 38 lines", ignoring trailing blank lines.
    public static func detail(of text: String, locale: Locale = .current) -> String {
        let trimmed = trimmingTrailing(text)
        let lines = trimmed.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline).count
        func count(_ n: Int, _ noun: String) -> String {
            "\(n.formatted(.number.locale(locale))) \(noun)\(n == 1 ? "" : "s")"
        }
        return "\(count(trimmed.count, "character")), \(count(lines, "line"))"
    }

    private static func trimmingTrailing(_ text: String) -> Substring {
        text[..<(text.lastIndex { !$0.isWhitespace }.map(text.index(after:)) ?? text.startIndex)]
    }
}
