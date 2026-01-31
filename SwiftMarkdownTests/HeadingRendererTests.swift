import XCTest
@testable import SwiftMarkdownCore

final class HeadingRendererTests: XCTestCase {
    // MARK: - Font Tests

    func test_heading_level1_usesBoldLargeFont() {
        let renderer = HeadingRenderer()
        let result = renderer.render(
            HeadingRenderer.Input(text: "Title", level: 1),
            theme: .default,
            context: RenderContext()
        )

        guard let font = result.attribute(.font, at: 0, effectiveRange: nil) as? NSFont else {
            XCTFail("Expected font attribute")
            return
        }
        XCTAssertEqual(font.pointSize, 28, accuracy: 0.1)
        XCTAssertTrue(font.fontDescriptor.symbolicTraits.contains(.bold))
    }

    func test_heading_level2_usesCorrectFont() {
        let renderer = HeadingRenderer()
        let result = renderer.render(
            HeadingRenderer.Input(text: "Subtitle", level: 2),
            theme: .default,
            context: RenderContext()
        )

        guard let font = result.attribute(.font, at: 0, effectiveRange: nil) as? NSFont else {
            XCTFail("Expected font attribute")
            return
        }
        XCTAssertEqual(font.pointSize, 24, accuracy: 0.1)
    }

    func test_heading_level6_usesSmallestFont() {
        let renderer = HeadingRenderer()
        let result = renderer.render(
            HeadingRenderer.Input(text: "Small heading", level: 6),
            theme: .default,
            context: RenderContext()
        )

        guard let font = result.attribute(.font, at: 0, effectiveRange: nil) as? NSFont else {
            XCTFail("Expected font attribute")
            return
        }
        XCTAssertEqual(font.pointSize, 14, accuracy: 0.1)
    }

    // MARK: - Content Tests

    func test_heading_containsText() {
        let renderer = HeadingRenderer()
        let result = renderer.render(
            HeadingRenderer.Input(text: "My Heading", level: 1),
            theme: .default,
            context: RenderContext()
        )

        XCTAssertTrue(result.string.contains("My Heading"))
    }

    func test_heading_addsTrailingNewline() {
        let renderer = HeadingRenderer()
        let result = renderer.render(
            HeadingRenderer.Input(text: "Title", level: 1),
            theme: .default,
            context: RenderContext()
        )

        XCTAssertTrue(result.string.hasSuffix("\n"))
    }

    // MARK: - Color Tests

    func test_heading_usesTextColor() {
        let renderer = HeadingRenderer()
        let result = renderer.render(
            HeadingRenderer.Input(text: "Title", level: 1),
            theme: .default,
            context: RenderContext()
        )

        let color = result.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? NSColor
        XCTAssertNotNil(color)
    }

    // MARK: - Paragraph Style Tests

    func test_heading_hasParagraphSpacing() {
        let renderer = HeadingRenderer()
        let result = renderer.render(
            HeadingRenderer.Input(text: "Title", level: 1),
            theme: .default,
            context: RenderContext()
        )

        guard let style = result.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle else {
            XCTFail("Expected paragraph style")
            return
        }
        XCTAssertGreaterThan(style.paragraphSpacingBefore, 0)
    }
}
