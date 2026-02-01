import XCTest
@testable import SwiftMarkdownCore

final class BlockquoteRendererTests: XCTestCase {
    // MARK: - Indentation Tests

    func test_blockquote_hasLeftIndent() {
        let renderer = BlockquoteRenderer()
        let content = NSAttributedString(string: "quoted text")
        let result = renderer.render(
            content,
            theme: .default,
            context: RenderContext()
        )

        guard let style = result.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle else {
            XCTFail("Expected paragraph style")
            return
        }
        XCTAssertGreaterThan(style.headIndent, 0)
    }

    func test_blockquote_hasFirstLineIndent() {
        let renderer = BlockquoteRenderer()
        let content = NSAttributedString(string: "quoted text")
        let result = renderer.render(
            content,
            theme: .default,
            context: RenderContext()
        )

        guard let style = result.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle else {
            XCTFail("Expected paragraph style")
            return
        }
        XCTAssertGreaterThan(style.firstLineHeadIndent, 0)
    }

    func test_blockquote_usesThemeBlockquoteIndent() {
        let renderer = BlockquoteRenderer()
        let content = NSAttributedString(string: "quoted")
        let result = renderer.render(
            content,
            theme: .default,
            context: RenderContext()
        )

        guard let style = result.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle else {
            XCTFail("Expected paragraph style")
            return
        }
        XCTAssertEqual(style.headIndent, MarkdownTheme.default.blockquoteIndent, accuracy: 0.1)
    }

    // MARK: - Nesting Tests

    func test_blockquote_nested_increasesIndent() {
        let renderer = BlockquoteRenderer()
        let content = NSAttributedString(string: "nested")
        let context = RenderContext(nestingLevel: 1)
        let result = renderer.render(
            content,
            theme: .default,
            context: context
        )

        guard let style = result.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle else {
            XCTFail("Expected paragraph style")
            return
        }
        // Nested indent should be greater than single indent
        XCTAssertGreaterThan(style.headIndent, MarkdownTheme.default.blockquoteIndent)
    }

    func test_blockquote_deeplyNested_scaledIndent() {
        let renderer = BlockquoteRenderer()
        let content = NSAttributedString(string: "deeply nested")
        let context = RenderContext(nestingLevel: 2)
        let result = renderer.render(
            content,
            theme: .default,
            context: context
        )

        guard let style = result.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle else {
            XCTFail("Expected paragraph style")
            return
        }
        let expectedIndent = MarkdownTheme.default.blockquoteIndent * 3 // level 2 = 3x indent
        XCTAssertEqual(style.headIndent, expectedIndent, accuracy: 0.1)
    }

    // MARK: - Color Tests

    func test_blockquote_usesBlockquoteColor() {
        let renderer = BlockquoteRenderer()
        let content = NSAttributedString(string: "quoted")
        let result = renderer.render(
            content,
            theme: .default,
            context: RenderContext()
        )

        let color = result.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? NSColor
        XCTAssertNotNil(color)
    }

    // MARK: - Content Tests

    func test_blockquote_preservesContent() {
        let renderer = BlockquoteRenderer()
        let content = NSAttributedString(string: "my quote text")
        let result = renderer.render(
            content,
            theme: .default,
            context: RenderContext()
        )

        XCTAssertTrue(result.string.contains("my quote text"))
    }

    func test_blockquote_addsTrailingNewline() {
        let renderer = BlockquoteRenderer()
        let content = NSAttributedString(string: "quote")
        let result = renderer.render(
            content,
            theme: .default,
            context: RenderContext()
        )

        XCTAssertTrue(result.string.hasSuffix("\n"))
    }

    // MARK: - Font Tests

    func test_blockquote_usesBodyFont() {
        let renderer = BlockquoteRenderer()
        let content = NSAttributedString(string: "quote")
        let result = renderer.render(
            content,
            theme: .default,
            context: RenderContext()
        )

        guard let font = result.attribute(.font, at: 0, effectiveRange: nil) as? NSFont else {
            XCTFail("Expected font attribute")
            return
        }
        XCTAssertEqual(font.pointSize, MarkdownTheme.default.bodyFontSize, accuracy: 0.1)
    }
}
