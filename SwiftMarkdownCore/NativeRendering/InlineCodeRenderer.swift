import AppKit

/// Renders inline code spans to NSAttributedString with monospace font and background.
///
/// Inline code uses the theme's code font and inline code background color.
///
/// ## Example
/// ```swift
/// let renderer = InlineCodeRenderer()
/// let result = renderer.render(
///     "var x = 1",
///     theme: .default,
///     context: RenderContext()
/// )
/// ```
public struct InlineCodeRenderer: MarkdownElementRenderer {
    public typealias Input = String

    public init() {}

    public func render(_ input: String, theme: MarkdownTheme, context: RenderContext) -> NSAttributedString {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: theme.codeFont,
            .foregroundColor: theme.textColor,
            .backgroundColor: theme.inlineCodeBackground
        ]

        return NSAttributedString(string: input, attributes: attributes)
    }
}
