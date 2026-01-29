import Foundation
import Markdown

/// A renderer that converts Markdown documents to HTML.
///
/// This renderer produces HTML fragment strings by default. Set `wrapInDocument`
/// to `true` to produce complete HTML documents with DOCTYPE and head/body elements.
///
/// ## Example
/// ```swift
/// let renderer = HTMLRenderer()
/// let document = MarkdownParser.parseDocument("# Hello")
/// let html = renderer.render(document)
/// // "<h1>Hello</h1>\n"
/// ```
public final class HTMLRenderer: HTMLMarkdownRenderer {
    /// CSS styles to include with rendered HTML.
    /// Returns the bundled highlight.css, or falls back to generated CSS if unavailable.
    public var cssStyles: String {
        // Try to load bundled CSS from framework resources
        if let url = Bundle(for: HTMLRenderer.self).url(forResource: "highlight", withExtension: "css"),
           let css = try? String(contentsOf: url) {
            return css
        }
        // Fallback to generated CSS from default theme
        return SyntaxTheme.default.generateCSS()
    }

    /// Whether to wrap output in a complete HTML document.
    public var wrapInDocument: Bool

    /// Optional syntax highlighter for code blocks.
    public var syntaxHighlighter: (any HTMLSyntaxHighlighter)?

    /// Whether to validate data URI images by checking magic bytes.
    /// When enabled, images with mismatched MIME types get an `invalid-image` class.
    public var validateImages: Bool

    /// Creates a new HTML renderer.
    /// - Parameters:
    ///   - wrapInDocument: Whether to wrap output in a complete HTML document. Defaults to `false`.
    ///   - syntaxHighlighter: Optional syntax highlighter for code blocks.
    ///   - validateImages: Whether to validate data URI images. Defaults to `false`.
    public init(
        wrapInDocument: Bool = false,
        syntaxHighlighter: (any HTMLSyntaxHighlighter)? = nil,
        validateImages: Bool = false
    ) {
        self.wrapInDocument = wrapInDocument
        self.syntaxHighlighter = syntaxHighlighter
        self.validateImages = validateImages
    }

    /// Renders a Markdown document to HTML.
    /// - Parameter document: The parsed Markdown document.
    /// - Returns: The rendered HTML string.
    public func render(_ document: Document) -> String {
        var walker = HTMLWalker(syntaxHighlighter: syntaxHighlighter, validateImages: validateImages)
        walker.visit(document)

        if wrapInDocument {
            return wrapHTML(walker.result)
        }
        return walker.result
    }

    /// Renders a Markdown document to HTML with lazy-loaded syntax highlighting.
    ///
    /// Use this method when you need syntax highlighting for languages other than Swift.
    /// The highlighter will download grammars on first use and cache them permanently.
    ///
    /// - Parameters:
    ///   - document: The parsed Markdown document.
    ///   - highlighter: A lazy highlighter that can download grammars on demand.
    /// - Returns: The rendered HTML string.
    public func renderAsync(_ document: Document, highlighter: LazyTreeSitterHighlighter) async -> String {
        var walker = AsyncHTMLWalker(highlighter: highlighter, validateImages: validateImages)
        await walker.visit(document)

        if wrapInDocument {
            return wrapHTML(walker.result)
        }
        return walker.result
    }

    private func wrapHTML(_ content: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <style>\(cssStyles)</style>
        </head>
        <body>
        \(content)
        </body>
        </html>
        """
    }
}

// MARK: - HTML Walker

struct HTMLWalker: MarkupWalker {
    var result = ""
    let syntaxHighlighter: (any HTMLSyntaxHighlighter)?
    let validateImages: Bool

    init(syntaxHighlighter: (any HTMLSyntaxHighlighter)? = nil, validateImages: Bool = false) {
        self.syntaxHighlighter = syntaxHighlighter
        self.validateImages = validateImages
    }

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
        result += text.string.htmlEscaped
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
        result += "<code>\(inlineCode.code.htmlEscaped)</code>"
    }

    mutating func visitCodeBlock(_ codeBlock: CodeBlock) {
        let language = codeBlock.language ?? ""

        if !language.isEmpty {
            result += "<pre><code class=\"language-\(language.htmlEscaped)\">"
        } else {
            result += "<pre><code>"
        }

        // Use syntax highlighter if available and language is supported
        if let highlighter = syntaxHighlighter,
           !language.isEmpty,
           highlighter.supportsLanguage(language) {
            result += highlighter.highlightToHTML(code: codeBlock.code, language: language)
        } else {
            result += codeBlock.code.htmlEscaped
        }

        result += "</code></pre>\n"
    }

    mutating func visitLink(_ link: Link) {
        let href = link.destination ?? ""
        result += "<a href=\"\(href.htmlEscaped)\">"
        for child in link.children {
            visit(child)
        }
        result += "</a>"
    }

    mutating func visitImage(_ image: Image) {
        let src = image.source ?? ""
        let alt = image.plainText

        var cssClass: String?

        // Validate data URI images if enabled
        if validateImages && ImageValidator.isDataURI(src) {
            let validationResult = ImageValidator.validate(dataURI: src)
            switch validationResult {
            case .valid:
                break // Image is valid, no special class needed
            case .mismatch, .unrecognized, .invalidData:
                cssClass = "invalid-image"
            }
        }

        if let cls = cssClass {
            result += "<img class=\"\(cls)\" src=\"\(src.htmlEscaped)\" alt=\"\(alt.htmlEscaped)\">"
        } else {
            result += "<img src=\"\(src.htmlEscaped)\" alt=\"\(alt.htmlEscaped)\">"
        }
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
}
