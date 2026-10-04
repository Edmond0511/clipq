import Combine
import Foundation

/// User settings, stored in UserDefaults.
public final class Preferences: ObservableObject {
    public static let historyLimits = [25, 50, 100]

    @Published public var historyLimit: Int {
        didSet { defaults.set(historyLimit, forKey: Key.historyLimit) }
    }
    @Published public var captureImages: Bool {
        didSet { defaults.set(captureImages, forKey: Key.captureImages) }
    }
    @Published public var autoPaste: Bool {
        didSet { defaults.set(autoPaste, forKey: Key.autoPaste) }
    }

    private enum Key {
        static let historyLimit = "historyLimit"
        static let captureImages = "captureImages"
        static let autoPaste = "autoPaste"
    }

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let defaultLimit = Self.historyLimits[0]
        defaults.register(defaults: [Key.historyLimit: defaultLimit, Key.captureImages: true, Key.autoPaste: false])
        let storedLimit = defaults.integer(forKey: Key.historyLimit)
        historyLimit = Self.historyLimits.contains(storedLimit) ? storedLimit : defaultLimit
        captureImages = defaults.bool(forKey: Key.captureImages)
        autoPaste = defaults.bool(forKey: Key.autoPaste)
    }
}
