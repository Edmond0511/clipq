import XCTest
@testable import ClipqCore

final class ItemPreviewTests: XCTestCase {
    private func text(_ s: String) -> ClipContent { .text(s, rtf: nil) }

    func testOnlyItemsWithHiddenContentNeedAPreview() {
        XCTAssertFalse(ItemPreview.isNeeded(for: text("brew install gh"), title: nil))
        XCTAssertTrue(ItemPreview.isNeeded(for: text("line one\nline two"), title: nil))
        XCTAssertTrue(ItemPreview.isNeeded(for: text(String(repeating: "a", count: 80)), title: nil))
        XCTAssertTrue(ItemPreview.isNeeded(for: .image(fileName: "x.png"), title: nil))
        XCTAssertTrue(ItemPreview.isNeeded(for: text("short"), title: "Has a title"))
    }

    func testTrailingNewlineHidesNothing() {
        XCTAssertFalse(ItemPreview.isNeeded(for: text("brew install gh\n"), title: nil))
    }

    func testExcerptCapsAt20LinesAndCountsTheRest() {
        let long = (1...25).map(String.init).joined(separator: "\n")
        let excerpt = ItemPreview.excerpt(of: long)
        XCTAssertEqual(excerpt.text, "1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n11\n12\n13\n14\n15\n16\n17\n18\n19\n20")
        XCTAssertEqual(excerpt.hiddenLines, 5)

        let short = ItemPreview.excerpt(of: "a\nb\n")
        XCTAssertEqual(short.text, "a\nb")
        XCTAssertEqual(short.hiddenLines, 0)
    }

    func testDetailCountsCharactersAndLines() {
        let us = Locale(identifier: "en_US")
        XCTAssertEqual(ItemPreview.detail(of: "hello\nworld\n", locale: us), "11 characters, 2 lines")
        XCTAssertEqual(ItemPreview.detail(of: "x", locale: us), "1 character, 1 line")
        XCTAssertEqual(ItemPreview.detail(of: String(repeating: "a", count: 1204), locale: us), "1,204 characters, 1 line")
    }
}
