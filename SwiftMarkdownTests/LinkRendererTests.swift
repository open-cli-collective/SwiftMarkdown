import XCTest
@testable import SwiftMarkdownCore

final class LinkRendererTests: XCTestCase {
    // swiftlint:disable:next force_unwrapping
    private static let testURL = URL(string: "https://example.com")!

    // MARK: - Link Attribute Tests

    func test_link_hasLinkAttribute() {
        let renderer = LinkRenderer()
        let result = renderer.render(
            LinkRenderer.Input(text: "Click here", url: Self.testURL),
            theme: .default,
            context: RenderContext()
        )

        let linkAttr = result.attribute(.link, at: 0, effectiveRange: nil) as? URL
        XCTAssertEqual(linkAttr?.absoluteString, "https://example.com")
    }

    func test_link_linkAttributeSpansEntireText() {
        let renderer = LinkRenderer()
        let result = renderer.render(
            LinkRenderer.Input(text: "Click here", url: Self.testURL),
            theme: .default,
            context: RenderContext()
        )

        var range = NSRange(location: 0, length: 0)
        _ = result.attribute(.link, at: 0, effectiveRange: &range)
        XCTAssertEqual(range.length, result.length)
    }

    // MARK: - Color Tests

    func test_link_usesThemeLinkColor() {
        let renderer = LinkRenderer()
        let result = renderer.render(
            LinkRenderer.Input(text: "Click", url: Self.testURL),
            theme: .default,
            context: RenderContext()
        )

        let color = result.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? NSColor
        XCTAssertNotNil(color)
    }

    // MARK: - Content Tests

    func test_link_containsText() {
        let renderer = LinkRenderer()
        let result = renderer.render(
            LinkRenderer.Input(text: "My Link", url: Self.testURL),
            theme: .default,
            context: RenderContext()
        )

        XCTAssertEqual(result.string, "My Link")
    }

    func test_link_doesNotAddTrailingNewline() {
        let renderer = LinkRenderer()
        let result = renderer.render(
            LinkRenderer.Input(text: "Link", url: Self.testURL),
            theme: .default,
            context: RenderContext()
        )

        XCTAssertFalse(result.string.hasSuffix("\n"))
    }

    // MARK: - Font Tests

    func test_link_usesBodyFont() {
        let renderer = LinkRenderer()
        let result = renderer.render(
            LinkRenderer.Input(text: "Link", url: Self.testURL),
            theme: .default,
            context: RenderContext()
        )

        guard let font = result.attribute(.font, at: 0, effectiveRange: nil) as? NSFont else {
            XCTFail("Expected font attribute")
            return
        }
        XCTAssertEqual(font.pointSize, MarkdownTheme.default.bodyFont.pointSize, accuracy: 0.1)
    }

    // MARK: - Underline Tests

    func test_link_hasUnderlineStyle() {
        let renderer = LinkRenderer()
        let result = renderer.render(
            LinkRenderer.Input(text: "Link", url: Self.testURL),
            theme: .default,
            context: RenderContext()
        )

        let underline = result.attribute(.underlineStyle, at: 0, effectiveRange: nil) as? Int
        XCTAssertEqual(underline, NSUnderlineStyle.single.rawValue)
    }
}
