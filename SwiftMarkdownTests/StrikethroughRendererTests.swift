import XCTest
@testable import SwiftMarkdownCore

final class StrikethroughRendererTests: XCTestCase {
    // MARK: - Strikethrough Attribute Tests

    func test_strikethrough_hasStrikethroughAttribute() {
        let renderer = StrikethroughRenderer()
        let result = renderer.render(
            "deleted text",
            theme: .default,
            context: RenderContext()
        )

        let strikethrough = result.attribute(.strikethroughStyle, at: 0, effectiveRange: nil) as? Int
        XCTAssertEqual(strikethrough, NSUnderlineStyle.single.rawValue)
    }

    func test_strikethrough_strikethroughSpansEntireText() {
        let renderer = StrikethroughRenderer()
        let result = renderer.render(
            "deleted text",
            theme: .default,
            context: RenderContext()
        )

        var range = NSRange(location: 0, length: 0)
        _ = result.attribute(.strikethroughStyle, at: 0, effectiveRange: &range)
        XCTAssertEqual(range.length, result.length)
    }

    // MARK: - Font Tests

    func test_strikethrough_usesBodyFont() {
        let renderer = StrikethroughRenderer()
        let result = renderer.render(
            "text",
            theme: .default,
            context: RenderContext()
        )

        guard let font = result.attribute(.font, at: 0, effectiveRange: nil) as? NSFont else {
            XCTFail("Expected font attribute")
            return
        }
        XCTAssertEqual(font.pointSize, MarkdownTheme.default.bodyFontSize, accuracy: 0.1)
    }

    // MARK: - Content Tests

    func test_strikethrough_containsText() {
        let renderer = StrikethroughRenderer()
        let result = renderer.render(
            "crossed out",
            theme: .default,
            context: RenderContext()
        )

        XCTAssertEqual(result.string, "crossed out")
    }

    func test_strikethrough_doesNotAddTrailingNewline() {
        let renderer = StrikethroughRenderer()
        let result = renderer.render(
            "text",
            theme: .default,
            context: RenderContext()
        )

        XCTAssertFalse(result.string.hasSuffix("\n"))
    }

    // MARK: - Color Tests

    func test_strikethrough_usesTextColor() {
        let renderer = StrikethroughRenderer()
        let result = renderer.render(
            "text",
            theme: .default,
            context: RenderContext()
        )

        let color = result.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? NSColor
        XCTAssertNotNil(color)
    }

    // MARK: - Strikethrough Color Tests

    func test_strikethrough_hasStrikethroughColor() {
        let renderer = StrikethroughRenderer()
        let result = renderer.render(
            "text",
            theme: .default,
            context: RenderContext()
        )

        let strikethroughColor = result.attribute(.strikethroughColor, at: 0, effectiveRange: nil) as? NSColor
        XCTAssertNotNil(strikethroughColor)
    }
}
