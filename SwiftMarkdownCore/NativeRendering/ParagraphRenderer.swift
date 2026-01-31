import AppKit

/// Renders markdown paragraphs to NSAttributedString.
///
/// Paragraphs use the body font with appropriate line and paragraph spacing.
///
/// ## Example
/// ```swift
/// let renderer = ParagraphRenderer()
/// let result = renderer.render(
///     "Hello world",
///     theme: .default,
///     context: RenderContext()
/// )
/// ```
public struct ParagraphRenderer: MarkdownElementRenderer {
    public typealias Input = String

    public init() {}

    public func render(_ input: String, theme: MarkdownTheme, context: RenderContext) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = theme.lineSpacing
        paragraphStyle.paragraphSpacing = theme.paragraphSpacing

        let attributes: [NSAttributedString.Key: Any] = [
            .font: theme.bodyFont,
            .foregroundColor: theme.textColor,
            .paragraphStyle: paragraphStyle
        ]

        // Always add trailing newline for block separation
        let text = input.isEmpty ? "" : input
        return NSAttributedString(string: text + "\n", attributes: attributes)
    }
}
