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
        let parseOptions = buildParseOptions(from: options)
        let document = Document(parsing: markdown, options: parseOptions)

        switch format {
        case .html:
            return renderHTML(document)
        case .plainText:
            return renderPlainText(document)
        }
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

    private static func renderHTML(_ document: Document) -> String {
        var html = HTMLFormatter()
        html.visit(document)
        return html.result
    }

    private static func renderPlainText(_ document: Document) -> String {
        var formatter = PlainTextFormatter()
        formatter.visit(document)
        return formatter.result
    }
}

// MARK: - HTML Formatter

private struct HTMLFormatter: MarkupWalker {
    var result = ""

    mutating func visitDocument(_ document: Document) {
        for child in document.children {
            visit(child)
        }
    }

    mutating func visitHeading(_ heading: Heading) {
        let level = heading.level
        result += "<h\(level)>"
        for child in heading.children {
            visit(child)
        }
        result += "</h\(level)>\n"
    }

    mutating func visitParagraph(_ paragraph: Paragraph) {
        result += "<p>"
        for child in paragraph.children {
            visit(child)
        }
        result += "</p>\n"
    }

    mutating func visitText(_ text: Text) {
        result += escapeHTML(text.string)
    }

    mutating func visitEmphasis(_ emphasis: Emphasis) {
        result += "<em>"
        for child in emphasis.children {
            visit(child)
        }
        result += "</em>"
    }

    mutating func visitStrong(_ strong: Strong) {
        result += "<strong>"
        for child in strong.children {
            visit(child)
        }
        result += "</strong>"
    }

    mutating func visitStrikethrough(_ strikethrough: Strikethrough) {
        result += "<del>"
        for child in strikethrough.children {
            visit(child)
        }
        result += "</del>"
    }

    mutating func visitInlineCode(_ inlineCode: InlineCode) {
        result += "<code>\(escapeHTML(inlineCode.code))</code>"
    }

    mutating func visitCodeBlock(_ codeBlock: CodeBlock) {
        if let language = codeBlock.language, !language.isEmpty {
            result += "<pre><code class=\"language-\(escapeHTML(language))\">"
        } else {
            result += "<pre><code>"
        }
        result += escapeHTML(codeBlock.code)
        result += "</code></pre>\n"
    }

    mutating func visitLink(_ link: Link) {
        let href = link.destination ?? ""
        result += "<a href=\"\(escapeHTML(href))\">"
        for child in link.children {
            visit(child)
        }
        result += "</a>"
    }

    mutating func visitImage(_ image: Image) {
        let src = image.source ?? ""
        let alt = image.plainText
        result += "<img src=\"\(escapeHTML(src))\" alt=\"\(escapeHTML(alt))\">"
    }

    mutating func visitUnorderedList(_ unorderedList: UnorderedList) {
        result += "<ul>\n"
        for child in unorderedList.children {
            visit(child)
        }
        result += "</ul>\n"
    }

    mutating func visitOrderedList(_ orderedList: OrderedList) {
        result += "<ol>\n"
        for child in orderedList.children {
            visit(child)
        }
        result += "</ol>\n"
    }

    mutating func visitListItem(_ listItem: ListItem) {
        if let checkbox = listItem.checkbox {
            let checked = checkbox == .checked ? " checked" : ""
            result += "<li><input type=\"checkbox\" disabled\(checked)> "
        } else {
            result += "<li>"
        }
        for child in listItem.children {
            visitListItemChild(child)
        }
        result += "</li>\n"
    }

    private mutating func visitListItemChild(_ markup: Markup) {
        if let paragraph = markup as? Paragraph {
            for child in paragraph.children {
                visit(child)
            }
        } else {
            visit(markup)
        }
    }

    mutating func visitBlockQuote(_ blockQuote: BlockQuote) {
        result += "<blockquote>\n"
        for child in blockQuote.children {
            visit(child)
        }
        result += "</blockquote>\n"
    }

    mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) {
        result += "<hr>\n"
    }

    mutating func visitTable(_ table: Table) {
        result += "<table>\n"
        let head = table.head
        result += "<thead>\n<tr>\n"
        for cell in head.cells {
            result += "<th>"
            for child in cell.children {
                visit(child)
            }
            result += "</th>\n"
        }
        result += "</tr>\n</thead>\n"
        result += "<tbody>\n"
        for row in table.body.rows {
            result += "<tr>\n"
            for cell in row.cells {
                result += "<td>"
                for child in cell.children {
                    visit(child)
                }
                result += "</td>\n"
            }
            result += "</tr>\n"
        }
        result += "</tbody>\n</table>\n"
    }

    mutating func visitLineBreak(_ lineBreak: LineBreak) {
        result += "<br>\n"
    }

    mutating func visitSoftBreak(_ softBreak: SoftBreak) {
        result += "\n"
    }

    mutating func visitHTMLBlock(_ html: HTMLBlock) {
        result += html.rawHTML
    }

    mutating func visitInlineHTML(_ html: InlineHTML) {
        result += html.rawHTML
    }

    private func escapeHTML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}

// MARK: - Plain Text Formatter

private struct PlainTextFormatter: MarkupWalker {
    var result = ""

    mutating func visitDocument(_ document: Document) {
        for child in document.children {
            visit(child)
        }
    }

    mutating func visitText(_ text: Text) {
        result += text.string
    }

    mutating func visitHeading(_ heading: Heading) {
        for child in heading.children {
            visit(child)
        }
        result += "\n"
    }

    mutating func visitParagraph(_ paragraph: Paragraph) {
        for child in paragraph.children {
            visit(child)
        }
        result += "\n"
    }

    mutating func visitEmphasis(_ emphasis: Emphasis) {
        for child in emphasis.children {
            visit(child)
        }
    }

    mutating func visitStrong(_ strong: Strong) {
        for child in strong.children {
            visit(child)
        }
    }

    mutating func visitStrikethrough(_ strikethrough: Strikethrough) {
        for child in strikethrough.children {
            visit(child)
        }
    }

    mutating func visitInlineCode(_ inlineCode: InlineCode) {
        result += inlineCode.code
    }

    mutating func visitCodeBlock(_ codeBlock: CodeBlock) {
        result += codeBlock.code
        result += "\n"
    }

    mutating func visitLink(_ link: Link) {
        for child in link.children {
            visit(child)
        }
    }

    mutating func visitImage(_ image: Image) {
        result += image.plainText
    }

    mutating func visitUnorderedList(_ unorderedList: UnorderedList) {
        for child in unorderedList.children {
            visit(child)
        }
    }

    mutating func visitOrderedList(_ orderedList: OrderedList) {
        for child in orderedList.children {
            visit(child)
        }
    }

    mutating func visitListItem(_ listItem: ListItem) {
        result += "• "
        for child in listItem.children {
            if let paragraph = child as? Paragraph {
                for pChild in paragraph.children {
                    visit(pChild)
                }
            } else {
                visit(child)
            }
        }
        result += "\n"
    }

    mutating func visitBlockQuote(_ blockQuote: BlockQuote) {
        for child in blockQuote.children {
            visit(child)
        }
    }

    mutating func visitSoftBreak(_ softBreak: SoftBreak) {
        result += " "
    }

    mutating func visitLineBreak(_ lineBreak: LineBreak) {
        result += "\n"
    }
}
