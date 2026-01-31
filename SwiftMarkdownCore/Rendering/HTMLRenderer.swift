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
        result += HTMLElementRenderer.openHeading(level: heading.level)
        for child in heading.children {
            visit(child)
        }
        result += HTMLElementRenderer.closeHeading(level: heading.level)
    }

    mutating func visitParagraph(_ paragraph: Paragraph) {
        result += HTMLElementRenderer.openTag("p")
        for child in paragraph.children {
            visit(child)
        }
        result += HTMLElementRenderer.closeTagWithNewline("p")
    }

    mutating func visitText(_ text: Text) {
        result += HTMLElementRenderer.renderText(text)
    }

    mutating func visitEmphasis(_ emphasis: Emphasis) {
        result += HTMLElementRenderer.openTag("em")
        for child in emphasis.children {
            visit(child)
        }
        result += HTMLElementRenderer.closeTag("em")
    }

    mutating func visitStrong(_ strong: Strong) {
        result += HTMLElementRenderer.openTag("strong")
        for child in strong.children {
            visit(child)
        }
        result += HTMLElementRenderer.closeTag("strong")
    }

    mutating func visitStrikethrough(_ strikethrough: Strikethrough) {
        result += HTMLElementRenderer.openTag("del")
        for child in strikethrough.children {
            visit(child)
        }
        result += HTMLElementRenderer.closeTag("del")
    }

    mutating func visitInlineCode(_ inlineCode: InlineCode) {
        result += HTMLElementRenderer.renderInlineCode(inlineCode)
    }

    mutating func visitCodeBlock(_ codeBlock: CodeBlock) {
        let language = codeBlock.language ?? ""
        result += HTMLElementRenderer.openCodeBlock(language: language)

        // Use syntax highlighter if available and language is supported
        if let highlighter = syntaxHighlighter,
           !language.isEmpty,
           highlighter.supportsLanguage(language) {
            result += highlighter.highlightToHTML(code: codeBlock.code, language: language)
        } else {
            result += codeBlock.code.htmlEscaped
        }

        result += HTMLElementRenderer.closeCodeBlock()
    }

    mutating func visitLink(_ link: Link) {
        result += HTMLElementRenderer.openLink(link)
        for child in link.children {
            visit(child)
        }
        result += HTMLElementRenderer.closeLink()
    }

    mutating func visitImage(_ image: Image) {
        result += HTMLElementRenderer.renderImage(image, validateImages: validateImages)
    }

    mutating func visitUnorderedList(_ unorderedList: UnorderedList) {
        result += HTMLElementRenderer.openTagWithNewline("ul")
        for child in unorderedList.children {
            visit(child)
        }
        result += HTMLElementRenderer.closeTagWithNewline("ul")
    }

    mutating func visitOrderedList(_ orderedList: OrderedList) {
        result += HTMLElementRenderer.openTagWithNewline("ol")
        for child in orderedList.children {
            visit(child)
        }
        result += HTMLElementRenderer.closeTagWithNewline("ol")
    }

    mutating func visitListItem(_ listItem: ListItem) {
        result += HTMLElementRenderer.openListItem(listItem)
        for child in listItem.children {
            visitListItemChild(child)
        }
        result += HTMLElementRenderer.closeListItem()
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
        result += HTMLElementRenderer.openTagWithNewline("blockquote")
        for child in blockQuote.children {
            visit(child)
        }
        result += HTMLElementRenderer.closeTagWithNewline("blockquote")
    }

    mutating func visitThematicBreak(_: ThematicBreak) {
        result += HTMLElementRenderer.renderThematicBreak()
    }

    mutating func visitTable(_ table: Table) {
        result += HTMLElementRenderer.openTable()
        result += HTMLElementRenderer.openTableHead()
        for cell in table.head.cells {
            result += HTMLElementRenderer.openTableHeader()
            for child in cell.children {
                visit(child)
            }
            result += HTMLElementRenderer.closeTableHeader()
        }
        result += HTMLElementRenderer.closeTableHead()
        for row in table.body.rows {
            result += HTMLElementRenderer.openTableRow()
            for cell in row.cells {
                result += HTMLElementRenderer.openTableCell()
                for child in cell.children {
                    visit(child)
                }
                result += HTMLElementRenderer.closeTableCell()
            }
            result += HTMLElementRenderer.closeTableRow()
        }
        result += HTMLElementRenderer.closeTable()
    }

    mutating func visitLineBreak(_: LineBreak) {
        result += HTMLElementRenderer.renderLineBreak()
    }

    mutating func visitSoftBreak(_: SoftBreak) {
        result += HTMLElementRenderer.renderSoftBreak()
    }

    mutating func visitHTMLBlock(_ html: HTMLBlock) {
        result += HTMLElementRenderer.renderHTMLBlock(html)
    }

    mutating func visitInlineHTML(_ html: InlineHTML) {
        result += HTMLElementRenderer.renderInlineHTML(html)
    }
}
