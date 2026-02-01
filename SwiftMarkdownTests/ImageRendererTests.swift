import XCTest
@testable import SwiftMarkdownCore

final class ImageRendererTests: XCTestCase {
    // MARK: - Test Helpers

    /// Creates a test image of specified size
    private func createTestImage(width: CGFloat, height: CGFloat, color: NSColor = .red) -> NSImage {
        let image = NSImage(size: NSSize(width: width, height: height))
        image.lockFocus()
        color.setFill()
        NSRect(x: 0, y: 0, width: width, height: height).fill()
        image.unlockFocus()
        return image
    }

    // MARK: - Attachment Tests

    func test_image_createsAttachment() {
        let renderer = ImageRenderer()
        let image = createTestImage(width: 100, height: 100)
        let result = renderer.render(
            ImageRenderer.Input(image: image, altText: "Test"),
            theme: .default,
            context: RenderContext()
        )

        let attachment = result.attribute(.attachment, at: 0, effectiveRange: nil)
        XCTAssertNotNil(attachment)
    }

    func test_image_containsAttachmentCharacter() {
        let renderer = ImageRenderer()
        let image = createTestImage(width: 100, height: 100)
        let result = renderer.render(
            ImageRenderer.Input(image: image, altText: "Test"),
            theme: .default,
            context: RenderContext()
        )

        XCTAssertTrue(result.string.contains("\u{FFFC}"))
    }

    // MARK: - Accessibility Tests

    func test_image_setsAccessibilityDescription() {
        let renderer = ImageRenderer()
        let image = createTestImage(width: 100, height: 100)
        let result = renderer.render(
            ImageRenderer.Input(image: image, altText: "A cute cat"),
            theme: .default,
            context: RenderContext()
        )

        guard let attachment = result.attribute(.attachment, at: 0, effectiveRange: nil) as? NSTextAttachment else {
            XCTFail("Expected text attachment")
            return
        }
        XCTAssertEqual(attachment.image?.accessibilityDescription, "A cute cat")
    }

    func test_image_emptyAltText_noAccessibilityDescription() {
        let renderer = ImageRenderer()
        let image = createTestImage(width: 100, height: 100)
        let result = renderer.render(
            ImageRenderer.Input(image: image, altText: ""),
            theme: .default,
            context: RenderContext()
        )

        guard let attachment = result.attribute(.attachment, at: 0, effectiveRange: nil) as? NSTextAttachment else {
            XCTFail("Expected text attachment")
            return
        }
        // Empty alt text should not set description (or set empty)
        let description = attachment.image?.accessibilityDescription ?? ""
        XCTAssertTrue(description.isEmpty)
    }

    // MARK: - Size Constraint Tests

    func test_image_constrainsWidth() {
        let renderer = ImageRenderer(maxWidth: 200)
        let image = createTestImage(width: 500, height: 250)
        let result = renderer.render(
            ImageRenderer.Input(image: image, altText: "Wide"),
            theme: .default,
            context: RenderContext()
        )

        guard let attachment = result.attribute(.attachment, at: 0, effectiveRange: nil) as? NSTextAttachment else {
            XCTFail("Expected text attachment")
            return
        }
        XCTAssertLessThanOrEqual(attachment.bounds.width, 200)
    }

    func test_image_maintainsAspectRatio() {
        let renderer = ImageRenderer(maxWidth: 100)
        let image = createTestImage(width: 200, height: 100) // 2:1 aspect ratio
        let result = renderer.render(
            ImageRenderer.Input(image: image, altText: "Landscape"),
            theme: .default,
            context: RenderContext()
        )

        guard let attachment = result.attribute(.attachment, at: 0, effectiveRange: nil) as? NSTextAttachment else {
            XCTFail("Expected text attachment")
            return
        }
        let bounds = attachment.bounds
        // Width should be constrained to 100, height should be 50 (maintaining 2:1)
        XCTAssertEqual(bounds.width, 100, accuracy: 0.1)
        XCTAssertEqual(bounds.height, 50, accuracy: 0.1)
    }

    func test_image_smallerThanMaxWidth_notScaled() {
        let renderer = ImageRenderer(maxWidth: 500)
        let image = createTestImage(width: 100, height: 100)
        let result = renderer.render(
            ImageRenderer.Input(image: image, altText: "Small"),
            theme: .default,
            context: RenderContext()
        )

        guard let attachment = result.attribute(.attachment, at: 0, effectiveRange: nil) as? NSTextAttachment else {
            XCTFail("Expected text attachment")
            return
        }
        // Image smaller than max width should keep original size
        XCTAssertEqual(attachment.bounds.width, 100, accuracy: 0.1)
        XCTAssertEqual(attachment.bounds.height, 100, accuracy: 0.1)
    }

    // MARK: - Spacing Tests

    func test_image_addsTrailingNewline() {
        let renderer = ImageRenderer()
        let image = createTestImage(width: 100, height: 100)
        let result = renderer.render(
            ImageRenderer.Input(image: image, altText: "Test"),
            theme: .default,
            context: RenderContext()
        )

        XCTAssertTrue(result.string.hasSuffix("\n"))
    }

    // MARK: - Placeholder Tests

    func test_image_nil_createsPlaceholder() {
        let renderer = ImageRenderer()
        let result = renderer.render(
            ImageRenderer.Input(image: nil, altText: "Missing image"),
            theme: .default,
            context: RenderContext()
        )

        // Should still have content (placeholder text with alt)
        XCTAssertTrue(result.string.contains("Missing image"))
    }
}
