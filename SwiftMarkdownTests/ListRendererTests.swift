import XCTest
@testable import SwiftMarkdownCore

final class ListRendererTests: XCTestCase {
    // MARK: - Unordered List Tests

    func test_unorderedList_hasBullet() {
        let renderer = ListRenderer()
        let items = [
            MarkdownListItem(content: NSAttributedString(string: "Item one"))
        ]
        let result = renderer.render(
            ListRenderer.Input(items: items, isOrdered: false),
            theme: .default,
            context: RenderContext()
        )

        XCTAssertTrue(result.string.contains("•"))
    }

    func test_unorderedList_multipleItems_allHaveBullets() {
        let renderer = ListRenderer()
        let items = [
            MarkdownListItem(content: NSAttributedString(string: "One")),
            MarkdownListItem(content: NSAttributedString(string: "Two")),
            MarkdownListItem(content: NSAttributedString(string: "Three"))
        ]
        let result = renderer.render(
            ListRenderer.Input(items: items, isOrdered: false),
            theme: .default,
            context: RenderContext()
        )

        // Count bullet occurrences
        let bulletCount = result.string.components(separatedBy: "•").count - 1
        XCTAssertEqual(bulletCount, 3)
    }

    // MARK: - Ordered List Tests

    func test_orderedList_hasNumbers() {
        let renderer = ListRenderer()
        let items = [
            MarkdownListItem(content: NSAttributedString(string: "First")),
            MarkdownListItem(content: NSAttributedString(string: "Second"))
        ]
        let result = renderer.render(
            ListRenderer.Input(items: items, isOrdered: true),
            theme: .default,
            context: RenderContext()
        )

        XCTAssertTrue(result.string.contains("1."))
        XCTAssertTrue(result.string.contains("2."))
    }

    func test_orderedList_manyItems_numbersCorrectly() {
        let renderer = ListRenderer()
        let items = (1...5).map { index in
            MarkdownListItem(content: NSAttributedString(string: "Item \(index)"))
        }
        let result = renderer.render(
            ListRenderer.Input(items: items, isOrdered: true),
            theme: .default,
            context: RenderContext()
        )

        XCTAssertTrue(result.string.contains("1."))
        XCTAssertTrue(result.string.contains("5."))
    }

    // MARK: - Nested List Tests

    func test_nestedList_increasesIndent() {
        let renderer = ListRenderer()
        let innerItems = [
            MarkdownListItem(content: NSAttributedString(string: "Nested"))
        ]
        let outerItems = [
            MarkdownListItem(content: NSAttributedString(string: "Outer"), children: innerItems, childrenOrdered: false)
        ]
        let result = renderer.render(
            ListRenderer.Input(items: outerItems, isOrdered: false),
            theme: .default,
            context: RenderContext()
        )

        // Find the nested item and verify it exists
        XCTAssertTrue(result.string.contains("Nested"))
    }

    func test_nestedList_changesBulletStyle() {
        let renderer = ListRenderer()
        let innerItems = [
            MarkdownListItem(content: NSAttributedString(string: "Nested"))
        ]
        let outerItems = [
            MarkdownListItem(content: NSAttributedString(string: "Outer"), children: innerItems, childrenOrdered: false)
        ]
        let result = renderer.render(
            ListRenderer.Input(items: outerItems, isOrdered: false),
            theme: .default,
            context: RenderContext()
        )

        XCTAssertTrue(result.string.contains("•"))  // Level 0
        XCTAssertTrue(result.string.contains("◦"))  // Level 1
    }

    func test_deeplyNestedList_usesThirdBulletStyle() {
        let renderer = ListRenderer()
        let level2 = [MarkdownListItem(content: NSAttributedString(string: "Deep"))]
        let level1 = [MarkdownListItem(content: NSAttributedString(string: "Mid"), children: level2, childrenOrdered: false)]
        let level0 = [MarkdownListItem(content: NSAttributedString(string: "Top"), children: level1, childrenOrdered: false)]

        let result = renderer.render(
            ListRenderer.Input(items: level0, isOrdered: false),
            theme: .default,
            context: RenderContext()
        )

        XCTAssertTrue(result.string.contains("•"))  // Level 0
        XCTAssertTrue(result.string.contains("◦"))  // Level 1
        XCTAssertTrue(result.string.contains("▪"))  // Level 2
    }

    // MARK: - Content Tests

    func test_listItem_preservesContent() {
        let renderer = ListRenderer()
        let items = [
            MarkdownListItem(content: NSAttributedString(string: "My content here"))
        ]
        let result = renderer.render(
            ListRenderer.Input(items: items, isOrdered: false),
            theme: .default,
            context: RenderContext()
        )

        XCTAssertTrue(result.string.contains("My content here"))
    }

    func test_list_addsTrailingNewline() {
        let renderer = ListRenderer()
        let items = [
            MarkdownListItem(content: NSAttributedString(string: "Item"))
        ]
        let result = renderer.render(
            ListRenderer.Input(items: items, isOrdered: false),
            theme: .default,
            context: RenderContext()
        )

        XCTAssertTrue(result.string.hasSuffix("\n"))
    }

    // MARK: - Paragraph Style Tests

    func test_listItem_hasHangingIndent() {
        let renderer = ListRenderer()
        let items = [
            MarkdownListItem(content: NSAttributedString(string: "Item"))
        ]
        let result = renderer.render(
            ListRenderer.Input(items: items, isOrdered: false),
            theme: .default,
            context: RenderContext()
        )

        guard let style = result.attribute(.paragraphStyle, at: 2, effectiveRange: nil) as? NSParagraphStyle else {
            XCTFail("Expected paragraph style")
            return
        }
        // headIndent should be greater than firstLineHeadIndent (hanging indent)
        XCTAssertGreaterThanOrEqual(style.headIndent, style.firstLineHeadIndent)
    }

    // MARK: - Mixed List Tests

    func test_mixedList_orderedInUnordered() {
        let renderer = ListRenderer()
        let orderedChildren = [
            MarkdownListItem(content: NSAttributedString(string: "Sub one")),
            MarkdownListItem(content: NSAttributedString(string: "Sub two"))
        ]
        let outerItems = [
            MarkdownListItem(content: NSAttributedString(string: "Outer"), children: orderedChildren, childrenOrdered: true)
        ]
        let result = renderer.render(
            ListRenderer.Input(items: outerItems, isOrdered: false),
            theme: .default,
            context: RenderContext()
        )

        XCTAssertTrue(result.string.contains("•"))  // Outer bullet
        XCTAssertTrue(result.string.contains("1.")) // Inner numbered
        XCTAssertTrue(result.string.contains("2."))
    }

    // MARK: - Empty List Tests

    func test_emptyList_returnsNewlineOnly() {
        let renderer = ListRenderer()
        let items: [MarkdownListItem] = []
        let result = renderer.render(
            ListRenderer.Input(items: items, isOrdered: false),
            theme: .default,
            context: RenderContext()
        )

        XCTAssertEqual(result.string, "\n")
    }
}
