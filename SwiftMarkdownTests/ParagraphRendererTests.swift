import XCTest
@testable import SwiftMarkdownCore

final class ParagraphRendererTests: XCTestCase {
    // MARK: - Font Tests

    func test_paragraph_usesBodyFont() {
        let renderer = ParagraphRenderer()
        let result = renderer.render(
            "Hello world",
            theme: .default,
            context: RenderContext()
        )

        guard let font = result.attribute(.font, at: 0, effectiveRange: nil) as? NSFont else {
            XCTFail("Expected font attribute")
            return
        }
        XCTAssertEqual(font.pointSize, MarkdownTheme.default.bodyFont.pointSize, accuracy: 0.1)
    }

    // MARK: - Content Tests

    func test_paragraph_containsText() {
        let renderer = ParagraphRenderer()
        let result = renderer.render(
            "Hello world",
            theme: .default,
            context: RenderContext()
        )

        XCTAssertTrue(result.string.contains("Hello world"))
    }

    func test_paragraph_addsTrailingNewline() {
        let renderer = ParagraphRenderer()
        let result = renderer.render(
            "Some text",
            theme: .default,
            context: RenderContext()
        )

        XCTAssertTrue(result.string.hasSuffix("\n"))
    }

    // MARK: - Color Tests

    func test_paragraph_usesTextColor() {
        let renderer = ParagraphRenderer()
        let result = renderer.render(
            "Hello",
            theme: .default,
            context: RenderContext()
        )

        let color = result.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? NSColor
        XCTAssertNotNil(color)
    }

    // MARK: - Paragraph Style Tests

    func test_paragraph_hasLineSpacing() {
        let renderer = ParagraphRenderer()
        let result = renderer.render(
            "Hello",
            theme: .default,
            context: RenderContext()
        )

        let style = result.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle
        XCTAssertNotNil(style)
    }

    func test_paragraph_hasParagraphSpacing() {
        let renderer = ParagraphRenderer()
        let result = renderer.render(
            "Hello",
            theme: .default,
            context: RenderContext()
        )

        let style = result.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle
        XCTAssertGreaterThan(style?.paragraphSpacing ?? 0, 0)
    }

    // MARK: - Empty Content

    func test_paragraph_emptyString_returnsEmptyAttributedString() {
        let renderer = ParagraphRenderer()
        let result = renderer.render(
            "",
            theme: .default,
            context: RenderContext()
        )

        // Empty paragraph should still have newline for block separation
        XCTAssertEqual(result.string, "\n")
    }
}
