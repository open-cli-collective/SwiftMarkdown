import AppKit

/// Renders markdown links to NSAttributedString with clickable link attributes.
///
/// Links use the theme's link color and include underline styling.
///
/// ## Example
/// ```swift
/// let renderer = LinkRenderer()
/// let result = renderer.render(
///     LinkRenderer.Input(text: "Click here", url: URL(string: "https://example.com")!),
///     theme: .default,
///     context: RenderContext()
/// )
/// ```
public struct LinkRenderer: MarkdownElementRenderer {
    /// Input for link rendering.
    public struct Input {
        /// The link text to display.
        public let text: String
        /// The URL the link points to.
        public let url: URL

        public init(text: String, url: URL) {
            self.text = text
            self.url = url
        }
    }

    public init() {}

    public func render(_ input: Input, theme: MarkdownTheme, context: RenderContext) -> NSAttributedString {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: theme.bodyFont,
            .foregroundColor: theme.linkColor,
            .link: input.url,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]

        return NSAttributedString(string: input.text, attributes: attributes)
    }
}
