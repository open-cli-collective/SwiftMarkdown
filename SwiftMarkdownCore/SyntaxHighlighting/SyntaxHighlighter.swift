import Foundation

/// Represents a highlighted token with its range and type.
public struct HighlightToken: Equatable, Sendable {
    /// The range of the token in the source string.
    public let range: Range<String.Index>

    /// The type of syntax element this token represents.
    public let tokenType: TokenType

    public init(range: Range<String.Index>, tokenType: TokenType) {
        self.range = range
        self.tokenType = tokenType
    }

    /// Types of syntax tokens for highlighting.
    public enum TokenType: String, CaseIterable, Sendable {
        case keyword
        case string
        case comment
        case number
        case function
        case type
        case variable
        case `operator`
        case punctuation
        case property
        case attribute
        case plain
    }
}

/// A protocol for types that can perform syntax highlighting on code.
public protocol SyntaxHighlighter: Sendable {
    /// Highlights the given code and returns tokens.
    /// - Parameters:
    ///   - code: The source code to highlight.
    ///   - language: The language identifier (e.g., "swift").
    /// - Returns: An array of highlight tokens, or empty if unsupported.
    func highlight(code: String, language: String) -> [HighlightToken]

    /// Checks if the highlighter supports the given language.
    /// - Parameter language: The language identifier to check.
    /// - Returns: `true` if the language is supported.
    func supportsLanguage(_ language: String) -> Bool

    /// The list of supported language identifiers.
    var supportedLanguages: [String] { get }
}

/// A syntax highlighter that can produce HTML output.
public protocol HTMLSyntaxHighlighter: SyntaxHighlighter {
    /// Highlights code and returns HTML with span elements.
    /// - Parameters:
    ///   - code: The source code to highlight.
    ///   - language: The language identifier.
    /// - Returns: HTML string with token spans, or escaped code if unsupported.
    func highlightToHTML(code: String, language: String) -> String
}
