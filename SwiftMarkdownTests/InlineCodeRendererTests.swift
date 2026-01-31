import XCTest
@testable import SwiftMarkdownCore

final class InlineCodeRendererTests: XCTestCase {
    // MARK: - Font Tests

    func test_inlineCode_usesMonospaceFont() {
        let renderer = InlineCodeRenderer()
        let result = renderer.render(
            "var x = 1",
            theme: .default,
            context: RenderContext()
        )

        guard let font = result.attribute(.font, at: 0, effectiveRange: nil) as? NSFont else {
            XCTFail("Expected font attribute")
            return
        }
        XCTAssertTrue(font.fontDescriptor.symbolicTraits.contains(.monoSpace))
    }

    func test_inlineCode_usesThemeCodeFontSize() {
        let renderer = InlineCodeRenderer()
        let result = renderer.render(
            "let x",
            theme: .default,
            context: RenderContext()
        )

        guard let font = result.attribute(.font, at: 0, effectiveRange: nil) as? NSFont else {
            XCTFail("Expected font attribute")
            return
        }
        XCTAssertEqual(font.pointSize, MarkdownTheme.default.codeFontSize, accuracy: 0.1)
    }

    // MARK: - Background Color Tests

    func test_inlineCode_hasBackgroundColor() {
        let renderer = InlineCodeRenderer()
        let result = renderer.render(
            "code",
            theme: .default,
            context: RenderContext()
        )

        let backgroundColor = result.attribute(.backgroundColor, at: 0, effectiveRange: nil) as? NSColor
        XCTAssertNotNil(backgroundColor)
    }

    func test_inlineCode_backgroundColorSpansEntireText() {
        let renderer = InlineCodeRenderer()
        let result = renderer.render(
            "some code here",
            theme: .default,
            context: RenderContext()
        )

        var range = NSRange(location: 0, length: 0)
        _ = result.attribute(.backgroundColor, at: 0, effectiveRange: &range)
        XCTAssertEqual(range.length, result.length)
    }

    // MARK: - Content Tests

    func test_inlineCode_containsText() {
        let renderer = InlineCodeRenderer()
        let result = renderer.render(
            "myFunction()",
            theme: .default,
            context: RenderContext()
        )

        XCTAssertEqual(result.string, "myFunction()")
    }

    func test_inlineCode_doesNotAddTrailingNewline() {
        let renderer = InlineCodeRenderer()
        let result = renderer.render(
            "code",
            theme: .default,
            context: RenderContext()
        )

        XCTAssertFalse(result.string.hasSuffix("\n"))
    }

    // MARK: - Text Color Tests

    func test_inlineCode_usesTextColor() {
        let renderer = InlineCodeRenderer()
        let result = renderer.render(
            "code",
            theme: .default,
            context: RenderContext()
        )

        let color = result.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? NSColor
        XCTAssertNotNil(color)
    }
}
