import Foundation
import Markdown

/// Converts Markdown text to various output formats.
public struct MarkdownParser {
    /// Output format for markdown conversion.
    public enum OutputFormat {
        case html
        case plainText
    }

    /// Parsing options for markdown conversion.
    public struct Options: OptionSet {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        /// Parse block directives (e.g., @Comment, @Metadata)
        public static let parseBlockDirectives = Options(rawValue: 1 << 0)

        /// Parse minimal Doxygen commands
        public static let parseMinimalDoxygen = Options(rawValue: 1 << 1)

        /// Default options (none enabled)
        public static let `default`: Options = []

        /// All options enabled
        public static let all: Options = [.parseBlockDirectives, .parseMinimalDoxygen]
    }

    /// Parse markdown and convert to the specified output format.
    /// - Parameters:
    ///   - markdown: The markdown string to parse.
    ///   - format: The desired output format (default: .html).
    ///   - options: Parsing options (default: .default).
    /// - Returns: The converted string in the specified format.
    public static func parse(_ markdown: String, format: OutputFormat = .html, options: Options = .default) -> String {
        let document = parseDocument(markdown, options: options)

        switch format {
        case .html:
            return HTMLRenderer().render(document)
        case .plainText:
            return PlainTextRenderer().render(document)
        }
    }

    /// Parse markdown using a custom renderer.
    /// - Parameters:
    ///   - markdown: The markdown string to parse.
    ///   - renderer: The renderer to use for output.
    ///   - options: Parsing options (default: .default).
    /// - Returns: The output produced by the renderer.
    public static func parse<R: MarkdownRenderer>(_ markdown: String, renderer: R, options: Options = .default) -> R.Output {
        let document = parseDocument(markdown, options: options)
        return renderer.render(document)
    }

    /// Parse markdown to HTML with syntax highlighting for code blocks.
    /// - Parameters:
    ///   - markdown: The markdown string to parse.
    ///   - options: Parsing options (default: .default).
    /// - Returns: HTML string with syntax-highlighted code blocks.
    public static func parseWithHighlighting(_ markdown: String, options: Options = .default) -> String {
        let highlighter = TreeSitterHighlighter()
        let renderer = HTMLRenderer(syntaxHighlighter: highlighter)
        return parse(markdown, renderer: renderer, options: options)
    }

    /// Parse markdown and return the document AST for inspection.
    /// - Parameters:
    ///   - markdown: The markdown string to parse.
    ///   - options: Parsing options (default: .default).
    /// - Returns: The parsed Document.
    public static func parseDocument(_ markdown: String, options: Options = .default) -> Document {
        let parseOptions = buildParseOptions(from: options)
        return Document(parsing: markdown, options: parseOptions)
    }

    // MARK: - Private

    private static func buildParseOptions(from options: Options) -> ParseOptions {
        var parseOptions: ParseOptions = []
        if options.contains(.parseBlockDirectives) {
            parseOptions.insert(.parseBlockDirectives)
        }
        if options.contains(.parseMinimalDoxygen) {
            parseOptions.insert(.parseMinimalDoxygen)
        }
        return parseOptions
    }
}
