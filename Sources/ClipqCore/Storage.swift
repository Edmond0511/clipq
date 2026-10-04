import Foundation

/// JSON files plus an images directory under one root folder.
public final class Storage {
    public let root: URL
    public let imagesDir: URL

    public static var defaultRoot: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("clipq", isDirectory: true)
    }

    public init(root: URL = Storage.defaultRoot) {
        self.root = root
        imagesDir = root.appendingPathComponent("images", isDirectory: true)
        try? FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)
    }

    public func load<T: Decodable>(_ type: T.Type, from name: String) -> T? {
        guard let data = try? Data(contentsOf: root.appendingPathComponent(name)) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    public func save<T: Encodable>(_ value: T, to name: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        try? data.write(to: root.appendingPathComponent(name), options: .atomic)
    }

    public func imageURL(_ fileName: String) -> URL {
        imagesDir.appendingPathComponent(fileName)
    }

    public func writeImage(_ png: Data) -> String {
        let fileName = UUID().uuidString + ".png"
        try? png.write(to: imageURL(fileName), options: .atomic)
        return fileName
    }

    public func copyImage(_ fileName: String) -> String {
        let newName = UUID().uuidString + ".png"
        try? FileManager.default.copyItem(at: imageURL(fileName), to: imageURL(newName))
        return newName
    }

    public func deleteImage(_ fileName: String) {
        try? FileManager.default.removeItem(at: imageURL(fileName))
    }

    /// Saved items get their own copy of image files, so either side can delete freely.
    func detachedCopy(of content: ClipContent) -> ClipContent {
        if case let .image(fileName) = content { return .image(fileName: copyImage(fileName)) }
        return content
    }

    func deleteFiles(of content: ClipContent) {
        if case let .image(fileName) = content { deleteImage(fileName) }
    }
}
