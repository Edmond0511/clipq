import CryptoKit
import Foundation

public enum ClipContent: Codable, Equatable {
    case text(String, rtf: Data?)
    case image(fileName: String)

    /// First non-empty line, for list rows.
    public var preview: String {
        switch self {
        case let .text(text, _):
            let line = text.split(whereSeparator: \.isNewline)
                .first { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            return line.map { $0.trimmingCharacters(in: .whitespaces) } ?? text
        case .image:
            return "Image"
        }
    }

    var searchableText: String? {
        if case let .text(text, _) = self { return text }
        return nil
    }
}

public struct HistoryItem: Codable, Equatable, Identifiable {
    public let id: UUID
    public let content: ClipContent
    /// Dedupe key: SHA-256 of the text, or of the PNG bytes.
    public let hash: String
    public var copiedAt: Date
}

public struct SavedItem: Codable, Equatable, Identifiable {
    public let id: UUID
    public let content: ClipContent
    public var title: String?
    /// nil means Ungrouped.
    public var groupID: UUID?
    public let savedAt: Date
}

public struct ClipGroup: Codable, Equatable, Identifiable {
    public let id: UUID
    public var name: String
}

public func sha256(_ data: Data) -> String {
    SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
}

public func matches(_ query: String, content: ClipContent, title: String? = nil) -> Bool {
    let query = query.trimmingCharacters(in: .whitespaces)
    if query.isEmpty { return true }
    return [title, content.searchableText].contains {
        $0?.localizedCaseInsensitiveContains(query) ?? false
    }
}
