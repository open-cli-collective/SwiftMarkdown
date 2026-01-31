import AppKit

/// Renders markdown headings (H1-H6) to NSAttributedString.
///
/// Headings use bold fonts at sizes determined by the theme,
/// with appropriate paragraph spacing for visual hierarchy.
///
/// ## Example
/// ```swift
/// let renderer = HeadingRenderer()
/// let result = renderer.render(
///     HeadingRenderer.Input(text: "My Title", level: 1),
///     theme: .default,
///     context: RenderContext()
/// )
/// ```
public struct HeadingRenderer: MarkdownElementRenderer {
    /// Input for heading rendering.
    public struct Input {
        /// The heading text content.
        public let text: String
        /// The heading level (1-6).
        public let level: Int

        public init(text: String, level: Int) {
            self.text = text
            self.level = level
        }
    }

    public init() {}

    public func render(_ input: Input, theme: MarkdownTheme, context: RenderContext) -> NSAttributedString {
        let font = theme.headingFont(level: input.level)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacingBefore = theme.paragraphSpacing * 1.5
        paragraphStyle.paragraphSpacing = theme.paragraphSpacing * 0.5

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: theme.textColor,
            .paragraphStyle: paragraphStyle
        ]

        return NSAttributedString(string: input.text + "\n", attributes: attributes)
    }
}
