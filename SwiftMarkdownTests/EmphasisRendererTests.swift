import XCTest
@testable import SwiftMarkdownCore

final class EmphasisRendererTests: XCTestCase {
    // MARK: - Bold Tests

    func test_emphasis_bold_addsBoldTrait() {
        let renderer = EmphasisRenderer()
        let result = renderer.render(
            EmphasisRenderer.Input(text: "strong", style: .bold),
            theme: .default,
            context: RenderContext()
        )

        guard let font = result.attribute(.font, at: 0, effectiveRange: nil) as? NSFont else {
            XCTFail("Expected font attribute")
            return
        }
        XCTAssertTrue(font.fontDescriptor.symbolicTraits.contains(.bold))
    }

    func test_emphasis_bold_doesNotAddItalicTrait() {
        let renderer = EmphasisRenderer()
        let result = renderer.render(
            EmphasisRenderer.Input(text: "strong", style: .bold),
            theme: .default,
            context: RenderContext()
        )

        guard let font = result.attribute(.font, at: 0, effectiveRange: nil) as? NSFont else {
            XCTFail("Expected font attribute")
            return
        }
        XCTAssertFalse(font.fontDescriptor.symbolicTraits.contains(.italic))
    }

    // MARK: - Italic Tests

    func test_emphasis_italic_addsItalicTrait() {
        let renderer = EmphasisRenderer()
        let result = renderer.render(
            EmphasisRenderer.Input(text: "emphasized", style: .italic),
            theme: .default,
            context: RenderContext()
        )

        guard let font = result.attribute(.font, at: 0, effectiveRange: nil) as? NSFont else {
            XCTFail("Expected font attribute")
            return
        }
        XCTAssertTrue(font.fontDescriptor.symbolicTraits.contains(.italic))
    }

    func test_emphasis_italic_doesNotAddBoldTrait() {
        let renderer = EmphasisRenderer()
        let result = renderer.render(
            EmphasisRenderer.Input(text: "emphasized", style: .italic),
            theme: .default,
            context: RenderContext()
        )

        guard let font = result.attribute(.font, at: 0, effectiveRange: nil) as? NSFont else {
            XCTFail("Expected font attribute")
            return
        }
        XCTAssertFalse(font.fontDescriptor.symbolicTraits.contains(.bold))
    }

    // MARK: - Bold+Italic Tests

    func test_emphasis_boldItalic_addsBothTraits() {
        let renderer = EmphasisRenderer()
        let result = renderer.render(
            EmphasisRenderer.Input(text: "both", style: .boldItalic),
            theme: .default,
            context: RenderContext()
        )

        guard let font = result.attribute(.font, at: 0, effectiveRange: nil) as? NSFont else {
            XCTFail("Expected font attribute")
            return
        }
        let traits = font.fontDescriptor.symbolicTraits
        XCTAssertTrue(traits.contains(.bold) && traits.contains(.italic))
    }

    // MARK: - Font Size Tests

    func test_emphasis_bold_usesBodyFontSize() {
        let renderer = EmphasisRenderer()
        let result = renderer.render(
            EmphasisRenderer.Input(text: "strong", style: .bold),
            theme: .default,
            context: RenderContext()
        )

        guard let font = result.attribute(.font, at: 0, effectiveRange: nil) as? NSFont else {
            XCTFail("Expected font attribute")
            return
        }
        XCTAssertEqual(font.pointSize, MarkdownTheme.default.bodyFontSize, accuracy: 0.1)
    }

    func test_emphasis_italic_usesBodyFontSize() {
        let renderer = EmphasisRenderer()
        let result = renderer.render(
            EmphasisRenderer.Input(text: "emphasized", style: .italic),
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

    func test_emphasis_containsText() {
        let renderer = EmphasisRenderer()
        let result = renderer.render(
            EmphasisRenderer.Input(text: "My Text", style: .bold),
            theme: .default,
            context: RenderContext()
        )

        XCTAssertEqual(result.string, "My Text")
    }

    func test_emphasis_doesNotAddTrailingNewline() {
        let renderer = EmphasisRenderer()
        let result = renderer.render(
            EmphasisRenderer.Input(text: "Text", style: .italic),
            theme: .default,
            context: RenderContext()
        )

        XCTAssertFalse(result.string.hasSuffix("\n"))
    }

    // MARK: - Color Tests

    func test_emphasis_usesTextColor() {
        let renderer = EmphasisRenderer()
        let result = renderer.render(
            EmphasisRenderer.Input(text: "text", style: .bold),
            theme: .default,
            context: RenderContext()
        )

        let color = result.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? NSColor
        XCTAssertNotNil(color)
    }
}
