import AppKit

/// Renders fenced code blocks to NSAttributedString with optional syntax highlighting.
///
/// Code blocks use monospace font with a background color. When a highlighter
/// is provided and a language is specified, syntax colors are applied based
/// on the token types.
///
/// ## Example
/// ```swift
/// // Without highlighting
/// let renderer = CodeBlockRenderer()
/// let result = renderer.render(
///     CodeBlockRenderer.Input(code: "let x = 1", language: nil),
///     theme: .default,
///     context: RenderContext()
/// )
///
/// // With highlighting
/// let highlighter = LazyTreeSitterHighlighter.shared
/// let renderer = CodeBlockRenderer(highlighter: highlighter)
/// let result = renderer.render(
///     CodeBlockRenderer.Input(code: "let x = 1", language: "swift"),
///     theme: .default,
///     context: RenderContext()
/// )
/// ```
public struct CodeBlockRenderer: MarkdownElementRenderer {
    /// Input for code block rendering.
    public struct Input {
        /// The code content.
        public let code: String
        /// The language identifier for syntax highlighting (e.g., "swift").
        public let language: String?

        public init(code: String, language: String?) {
            self.code = code
            self.language = language
        }
    }

    private let highlighter: (any SyntaxHighlighter)?

    /// Creates a code block renderer.
    ///
    /// - Parameter highlighter: Optional syntax highlighter for colorizing code.
    public init(highlighter: (any SyntaxHighlighter)? = nil) {
        self.highlighter = highlighter
    }

    public func render(_ input: Input, theme: MarkdownTheme, context: RenderContext) -> NSAttributedString {
        let code = input.code.isEmpty ? "" : input.code

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 0

        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: theme.codeFont,
            .foregroundColor: theme.textColor,
            .backgroundColor: theme.codeBlockBackground,
            .paragraphStyle: paragraphStyle
        ]

        let result = NSMutableAttributedString(string: code + "\n", attributes: baseAttributes)

        if let language = input.language,
           let highlighter = highlighter {
            let tokens = highlighter.highlight(code: code, language: language)
            applySyntaxColors(tokens: tokens, to: result, code: code, theme: theme)
        }

        return result
    }

    private func applySyntaxColors(
        tokens: [HighlightToken],
        to attributedString: NSMutableAttributedString,
        code: String,
        theme: MarkdownTheme
    ) {
        for token in tokens {
            guard let color = theme.syntaxColor(for: token.tokenType.rawValue) else {
                continue
            }

            let start = code.distance(from: code.startIndex, to: token.range.lowerBound)
            let length = code.distance(from: token.range.lowerBound, to: token.range.upperBound)
            let nsRange = NSRange(location: start, length: length)

            guard nsRange.location >= 0,
                  nsRange.location + nsRange.length <= attributedString.length else {
                continue
            }

            attributedString.addAttribute(.foregroundColor, value: color, range: nsRange)
        }
    }
}
