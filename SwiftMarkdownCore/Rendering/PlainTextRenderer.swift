import Foundation
import Markdown

/// A renderer that converts Markdown documents to plain text.
///
/// This renderer strips all formatting and produces readable plain text.
/// Lists are rendered with bullet points, and structure is preserved
/// through line breaks.
///
/// ## Example
/// ```swift
/// let renderer = PlainTextRenderer()
/// let document = MarkdownParser.parseDocument("# Hello **World**")
/// let text = renderer.render(document)
/// // "Hello World\n"
/// ```
public final class PlainTextRenderer: MarkdownRenderer {
    /// Creates a new plain text renderer.
    public init() {}

    /// Renders a Markdown document to plain text.
    /// - Parameter document: The parsed Markdown document.
    /// - Returns: The rendered plain text string.
    public func render(_ document: Document) -> String {
        var walker = PlainTextWalker()
        walker.visit(document)
        return walker.result
    }
}

// MARK: - Plain Text Walker

struct PlainTextWalker: MarkupWalker {
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

    mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) {
        result += "---\n"
    }

    mutating func visitTable(_ table: Table) {
        // Render table header
        let head = table.head
        for cell in head.cells {
            for child in cell.children {
                visit(child)
            }
            result += "\t"
        }
        result += "\n"

        // Render table body rows
        for row in table.body.rows {
            for cell in row.cells {
                for child in cell.children {
                    visit(child)
                }
                result += "\t"
            }
            result += "\n"
        }
    }

    mutating func visitSoftBreak(_ softBreak: SoftBreak) {
        result += " "
    }

    mutating func visitLineBreak(_ lineBreak: LineBreak) {
        result += "\n"
    }

    mutating func visitHTMLBlock(_ html: HTMLBlock) {
        // Strip HTML in plain text output
    }

    mutating func visitInlineHTML(_ html: InlineHTML) {
        // Strip HTML in plain text output
    }
}
