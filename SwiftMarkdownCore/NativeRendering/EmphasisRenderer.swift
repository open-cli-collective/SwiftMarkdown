import AppKit

/// Renders emphasized text (bold, italic, bold+italic) to NSAttributedString.
///
/// Emphasis is applied by modifying font traits to add bold and/or italic.
///
/// ## Example
/// ```swift
/// let renderer = EmphasisRenderer()
/// let result = renderer.render(
///     EmphasisRenderer.Input(text: "important", style: .bold),
///     theme: .default,
///     context: RenderContext()
/// )
/// ```
public struct EmphasisRenderer: MarkdownElementRenderer {
    /// The style of emphasis to apply.
    public enum Style {
        /// Bold text.
        case bold
        /// Italic text.
        case italic
        /// Bold and italic text.
        case boldItalic
    }

    /// Input for emphasis rendering.
    public struct Input {
        /// The text to emphasize.
        public let text: String
        /// The emphasis style to apply.
        public let style: Style

        public init(text: String, style: Style) {
            self.text = text
            self.style = style
        }
    }

    public init() {}

    public func render(_ input: Input, theme: MarkdownTheme, context: RenderContext) -> NSAttributedString {
        let font = makeFont(for: input.style, theme: theme)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: theme.textColor
        ]

        return NSAttributedString(string: input.text, attributes: attributes)
    }

    private func makeFont(for style: Style, theme: MarkdownTheme) -> NSFont {
        let baseFont = theme.bodyFont
        var traits: NSFontDescriptor.SymbolicTraits = []

        switch style {
        case .bold:
            traits.insert(.bold)
        case .italic:
            traits.insert(.italic)
        case .boldItalic:
            traits.insert(.bold)
            traits.insert(.italic)
        }

        let descriptor = baseFont.fontDescriptor.withSymbolicTraits(traits)
        return NSFont(descriptor: descriptor, size: baseFont.pointSize) ?? baseFont
    }
}
