import AppKit

/// Renders markdown images to NSAttributedString with NSTextAttachment.
///
/// Images are displayed inline using text attachments. Size is constrained
/// to a maximum width while maintaining aspect ratio. Accessibility
/// descriptions are set from alt text.
///
/// ## Example
/// ```swift
/// let renderer = ImageRenderer(maxWidth: 600)
/// let image = NSImage(contentsOf: imageURL)
/// let result = renderer.render(
///     ImageRenderer.Input(image: image, altText: "Photo of sunset"),
///     theme: .default,
///     context: RenderContext()
/// )
/// ```
public struct ImageRenderer: MarkdownElementRenderer {
    /// Input for image rendering.
    public struct Input {
        /// The image to render (nil for placeholder).
        public let image: NSImage?
        /// Alt text for accessibility.
        public let altText: String

        public init(image: NSImage?, altText: String) {
            self.image = image
            self.altText = altText
        }
    }

    /// Maximum width for images.
    private let maxWidth: CGFloat

    /// Creates an image renderer.
    ///
    /// - Parameter maxWidth: Maximum width for displayed images. Images wider than
    ///   this will be scaled down while maintaining aspect ratio.
    public init(maxWidth: CGFloat = 800) {
        self.maxWidth = maxWidth
    }

    public func render(_ input: Input, theme: MarkdownTheme, context: RenderContext) -> NSAttributedString {
        let result = NSMutableAttributedString()

        if let image = input.image {
            // Set accessibility description
            if !input.altText.isEmpty {
                image.accessibilityDescription = input.altText
            }

            // Calculate constrained size
            let constrainedSize = calculateConstrainedSize(for: image)

            // Create attachment
            let attachment = NSTextAttachment()
            attachment.image = image
            attachment.bounds = NSRect(origin: .zero, size: constrainedSize)

            result.append(NSAttributedString(attachment: attachment))
        } else {
            // Placeholder for missing image
            let placeholder = "[\(input.altText.isEmpty ? "Image" : input.altText)]"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: theme.bodyFont,
                .foregroundColor: NSColor.secondaryLabelColor
            ]
            result.append(NSAttributedString(string: placeholder, attributes: attributes))
        }

        // Add trailing newline for block separation
        result.append(NSAttributedString(string: "\n"))

        return result
    }

    private func calculateConstrainedSize(for image: NSImage) -> NSSize {
        let originalSize = image.size

        // If image is smaller than max width, keep original size
        guard originalSize.width > maxWidth else {
            return originalSize
        }

        // Scale down while maintaining aspect ratio
        let scale = maxWidth / originalSize.width
        return NSSize(
            width: maxWidth,
            height: originalSize.height * scale
        )
    }
}
