import XCTest
@testable import ClipqCore

final class HistoryStoreTests: XCTestCase {
    var root: URL!
    var storage: Storage!

    override func setUp() {
        root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        storage = Storage(root: root)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: root)
    }

    private func texts(_ store: HistoryStore) -> [String] {
        store.items.map { $0.content.preview }
    }

    func testNewestFirstAndCappedFIFO() {
        let store = HistoryStore(storage: storage, capacity: 3)
        ["a", "b", "c", "d"].forEach { store.addText($0) }
        XCTAssertEqual(texts(store), ["d", "c", "b"])
    }

    func testDefaultCapacityIs25() {
        let store = HistoryStore(storage: storage)
        (1...30).forEach { store.addText("item \($0)") }
        XCTAssertEqual(store.items.count, 25)
        XCTAssertEqual(store.items.first?.content.preview, "item 30")
        XCTAssertEqual(store.items.last?.content.preview, "item 6")
    }

    func testDuplicateMovesToTopKeepingID() {
        let store = HistoryStore(storage: storage)
        ["a", "b", "c"].forEach { store.addText($0) }
        let idOfA = store.items.last!.id
        store.addText("a")
        XCTAssertEqual(texts(store), ["a", "c", "b"])
        XCTAssertEqual(store.items.first?.id, idOfA)
    }

    func testEmptyTextIgnored() {
        let store = HistoryStore(storage: storage)
        store.addText("")
        XCTAssertTrue(store.items.isEmpty)
    }

    func testDuplicateImageNotWrittenTwice() throws {
        let store = HistoryStore(storage: storage)
        store.addImage(png: Data([1, 2, 3]))
        store.addImage(png: Data([1, 2, 3]))
        XCTAssertEqual(store.items.count, 1)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: storage.imagesDir.path).count, 1)
    }

    func testEvictionDeletesImageFile() {
        let store = HistoryStore(storage: storage, capacity: 1)
        store.addImage(png: Data([1, 2, 3]))
        guard case let .image(fileName) = store.items[0].content else { return XCTFail() }
        store.addText("pushes the image out")
        XCTAssertFalse(FileManager.default.fileExists(atPath: storage.imageURL(fileName).path))
    }

    func testPersistsAcrossInstances() {
        let store = HistoryStore(storage: storage)
        store.addText("hello", rtf: Data([9]))
        store.addImage(png: Data([1]))
        let reloaded = HistoryStore(storage: Storage(root: root))
        XCTAssertEqual(reloaded.items, store.items)
    }

    func testRemoveAndClear() {
        let store = HistoryStore(storage: storage)
        ["a", "b", "c"].forEach { store.addText($0) }
        store.remove(store.items[1].id)
        XCTAssertEqual(texts(store), ["c", "a"])
        store.clear()
        XCTAssertTrue(HistoryStore(storage: storage).items.isEmpty)
    }
}

final class SavedStoreTests: XCTestCase {
    var root: URL!
    var storage: Storage!

    override func setUp() {
        root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        storage = Storage(root: root)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: root)
    }

    func testSavedImageSurvivesHistoryEviction() {
        let history = HistoryStore(storage: storage, capacity: 1)
        let saved = SavedStore(storage: storage)
        history.addImage(png: Data([1, 2, 3]))
        let item = saved.save(history.items[0].content, title: "Logo", groupID: nil)
        history.addText("evicts the image")
        guard case let .image(fileName) = item.content else { return XCTFail() }
        XCTAssertEqual(try Data(contentsOf: storage.imageURL(fileName)), Data([1, 2, 3]))
    }

    func testBlankTitleBecomesNil() {
        let saved = SavedStore(storage: storage)
        let item = saved.save(.text("x", rtf: nil), title: "   ", groupID: nil)
        XCTAssertNil(item.title)
        saved.update(item.id, title: "  Named ", groupID: nil)
        XCTAssertEqual(saved.items[0].title, "Named")
    }

    func testDeleteGroupMovesItemsToUngrouped() {
        let saved = SavedStore(storage: storage)
        let work = saved.createGroup(named: "Work")
        let item = saved.save(.text("x", rtf: nil), title: nil, groupID: work.id)
        saved.deleteGroup(work.id)
        XCTAssertTrue(saved.groups.isEmpty)
        XCTAssertEqual(saved.items(in: nil).map(\.id), [item.id])
    }

    func testRenameAndPersist() {
        let saved = SavedStore(storage: storage)
        let group = saved.createGroup(named: "Wrok")
        saved.renameGroup(group.id, to: "Work")
        saved.save(.text("x", rtf: nil), title: "T", groupID: group.id)
        let reloaded = SavedStore(storage: Storage(root: root))
        XCTAssertEqual(reloaded.groups.map(\.name), ["Work"])
        XCTAssertEqual(reloaded.items, saved.items)
    }

    func testRemoveDeletesOwnImageCopy() {
        let saved = SavedStore(storage: storage)
        let original = storage.writeImage(Data([1]))
        let item = saved.save(.image(fileName: original), title: nil, groupID: nil)
        saved.remove(item.id)
        guard case let .image(copy) = item.content else { return XCTFail() }
        XCTAssertFalse(FileManager.default.fileExists(atPath: storage.imageURL(copy).path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: storage.imageURL(original).path))
    }
}

final class SearchTests: XCTestCase {
    func testMatchesTextAndTitleCaseInsensitive() {
        XCTAssertTrue(matches("HELLO", content: .text("say hello", rtf: nil)))
        XCTAssertTrue(matches("logo", content: .image(fileName: "a.png"), title: "Company Logo"))
        XCTAssertFalse(matches("logo", content: .image(fileName: "a.png")))
        XCTAssertTrue(matches("  ", content: .image(fileName: "a.png")))
    }

    func testPreviewSkipsBlankLines() {
        XCTAssertEqual(ClipContent.text("\n\n  first line \nsecond", rtf: nil).preview, "first line")
    }
}

final class HistoryLimitTests: XCTestCase {
    var root: URL!
    var storage: Storage!

    override func setUp() {
        root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        storage = Storage(root: root)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: root)
    }

    func testLoweringCapacityTrimsOldestAndDeletesTheirImages() {
        let store = HistoryStore(storage: storage, capacity: 50)
        store.addImage(png: Data([1]))
        ["a", "b", "c"].forEach { store.addText($0) }
        guard case let .image(fileName) = store.items.last!.content else { return XCTFail() }

        store.capacity = 2

        XCTAssertEqual(store.items.map(\.content.preview), ["c", "b"])
        XCTAssertFalse(FileManager.default.fileExists(atPath: storage.imageURL(fileName).path))
        XCTAssertEqual(HistoryStore(storage: storage).items.count, 2)
    }

    func testImagesIgnoredWhenCaptureOff() throws {
        let store = HistoryStore(storage: storage)
        store.capturesImages = false
        store.addImage(png: Data([1]))
        store.addText("still captured")
        XCTAssertEqual(store.items.map(\.content.preview), ["still captured"])
        XCTAssertTrue(try FileManager.default.contentsOfDirectory(atPath: storage.imagesDir.path).isEmpty)
    }
}
