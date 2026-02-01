import XCTest
@testable import SwiftMarkdownCore

final class HorizontalRuleRendererTests: XCTestCase {
    // MARK: - Attachment Tests

    func test_horizontalRule_createsAttachment() {
        let renderer = HorizontalRuleRenderer()
        let result = renderer.render(
            (),
            theme: .default,
            context: RenderContext()
        )

        // Attachment is at position 1 (after leading newline)
        let attachment = result.attribute(.attachment, at: 1, effectiveRange: nil)
        XCTAssertNotNil(attachment)
    }

    func test_horizontalRule_containsAttachmentCharacter() {
        let renderer = HorizontalRuleRenderer()
        let result = renderer.render(
            (),
            theme: .default,
            context: RenderContext()
        )

        // NSTextAttachment uses the object replacement character
        XCTAssertTrue(result.string.contains("\u{FFFC}"))
    }

    // MARK: - Spacing Tests

    func test_horizontalRule_addsTrailingNewline() {
        let renderer = HorizontalRuleRenderer()
        let result = renderer.render(
            (),
            theme: .default,
            context: RenderContext()
        )

        XCTAssertTrue(result.string.hasSuffix("\n"))
    }

    func test_horizontalRule_hasLeadingNewline() {
        let renderer = HorizontalRuleRenderer()
        let result = renderer.render(
            (),
            theme: .default,
            context: RenderContext()
        )

        XCTAssertTrue(result.string.hasPrefix("\n"))
    }

    // MARK: - Size Tests

    func test_horizontalRule_attachmentHasSize() {
        let renderer = HorizontalRuleRenderer()
        let result = renderer.render(
            (),
            theme: .default,
            context: RenderContext()
        )

        guard let attachment = result.attribute(.attachment, at: 1, effectiveRange: nil) as? NSTextAttachment else {
            XCTFail("Expected text attachment")
            return
        }
        // Attachment should have non-zero bounds
        XCTAssertGreaterThan(attachment.bounds.height, 0)
    }
}
