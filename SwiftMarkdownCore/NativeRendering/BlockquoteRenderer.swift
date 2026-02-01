import AppKit

/// Renders markdown blockquotes to NSAttributedString with indentation and styling.
///
/// Blockquotes use the theme's blockquote color and indentation. Nesting is supported
/// via the render context's nesting level, which increases the indentation.
///
/// ## Example
/// ```swift
/// let renderer = BlockquoteRenderer()
/// let content = NSAttributedString(string: "A famous quote")
/// let result = renderer.render(
///     content,
///     theme: .default,
///     context: RenderContext()
/// )
/// ```
public struct BlockquoteRenderer: MarkdownElementRenderer {
    public typealias Input = NSAttributedString

    public init() {}

    public func render(_ input: NSAttributedString, theme: MarkdownTheme, context: RenderContext) -> NSAttributedString {
        // Indent increases with nesting depth (1x for level 0, 2x for level 1, etc.)
        let indentMultiplier = CGFloat(context.nestingLevel + 1)
        let indent = theme.blockquoteIndent * indentMultiplier

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.headIndent = indent
        paragraphStyle.firstLineHeadIndent = indent
        paragraphStyle.paragraphSpacing = theme.paragraphSpacing

        let attributes: [NSAttributedString.Key: Any] = [
            .font: theme.bodyFont,
            .foregroundColor: theme.blockquoteColor,
            .paragraphStyle: paragraphStyle
        ]

        // Create new attributed string with blockquote styling
        let result = NSMutableAttributedString(string: input.string, attributes: attributes)

        // Ensure trailing newline for block separation
        if !result.string.hasSuffix("\n") {
            result.append(NSAttributedString(string: "\n", attributes: attributes))
        }

        return result
    }
}
