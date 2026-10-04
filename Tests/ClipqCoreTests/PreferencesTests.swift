import XCTest
@testable import ClipqCore

final class PreferencesTests: XCTestCase {
    var defaults: UserDefaults!
    let suite = "clipq-tests-\(UUID().uuidString)"

    override func setUp() {
        defaults = UserDefaults(suiteName: suite)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
    }

    func testDefaults() {
        let prefs = Preferences(defaults: defaults)
        XCTAssertEqual(prefs.historyLimit, 25)
        XCTAssertTrue(prefs.captureImages)
        XCTAssertFalse(prefs.autoPaste)
    }

    func testChangesPersistAcrossInstances() {
        let prefs = Preferences(defaults: defaults)
        prefs.historyLimit = 100
        prefs.captureImages = false
        prefs.autoPaste = true

        let reloaded = Preferences(defaults: defaults)
        XCTAssertEqual(reloaded.historyLimit, 100)
        XCTAssertFalse(reloaded.captureImages)
        XCTAssertTrue(reloaded.autoPaste)
    }

    func testUnsupportedStoredLimitFallsBackTo25() {
        defaults.set(7, forKey: "historyLimit")
        XCTAssertEqual(Preferences(defaults: defaults).historyLimit, 25)
    }
}
