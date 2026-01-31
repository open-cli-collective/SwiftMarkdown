import AppKit

/// Renders strikethrough text to NSAttributedString.
///
/// Strikethrough uses the theme's body font with a single-line strikethrough style.
///
/// ## Example
/// ```swift
/// let renderer = StrikethroughRenderer()
/// let result = renderer.render(
///     "deleted text",
///     theme: .default,
///     context: RenderContext()
/// )
/// ```
public struct StrikethroughRenderer: MarkdownElementRenderer {
    public typealias Input = String

    public init() {}

    public func render(_ input: String, theme: MarkdownTheme, context: RenderContext) -> NSAttributedString {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: theme.bodyFont,
            .foregroundColor: theme.textColor,
            .strikethroughStyle: NSUnderlineStyle.single.rawValue,
            .strikethroughColor: theme.textColor
        ]

        return NSAttributedString(string: input, attributes: attributes)
    }
}
