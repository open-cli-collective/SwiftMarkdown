import Foundation
import Markdown

/// An async walker that supports lazy-loaded syntax highlighting.
struct AsyncHTMLWalker {
    var result = ""
    let highlighter: LazyTreeSitterHighlighter
    let validateImages: Bool

    init(highlighter: LazyTreeSitterHighlighter, validateImages: Bool = false) {
        self.highlighter = highlighter
        self.validateImages = validateImages
    }

    mutating func visit(_ document: Document) async {
        for child in document.children {
            await visitMarkup(child)
        }
    }

    // swiftlint:disable cyclomatic_complexity
    private mutating func visitMarkup(_ markup: Markup) async {
        switch markup {
        case let heading as Heading:
            await visitHeading(heading)
        case let paragraph as Paragraph:
            visitParagraph(paragraph)
        case let codeBlock as CodeBlock:
            await visitCodeBlock(codeBlock)
        case let unorderedList as UnorderedList:
            await visitUnorderedList(unorderedList)
        case let orderedList as OrderedList:
            await visitOrderedList(orderedList)
        case let listItem as ListItem:
            visitListItem(listItem)
        case let blockQuote as BlockQuote:
            await visitBlockQuote(blockQuote)
        case let table as Table:
            visitTable(table)
        case let thematicBreak as ThematicBreak:
            visitThematicBreak(thematicBreak)
        case let htmlBlock as HTMLBlock:
            visitHTMLBlock(htmlBlock)
        case let text as Text:
            visitText(text)
        case let emphasis as Emphasis:
            visitEmphasis(emphasis)
        case let strong as Strong:
            visitStrong(strong)
        case let strikethrough as Strikethrough:
            visitStrikethrough(strikethrough)
        case let inlineCode as InlineCode:
            visitInlineCode(inlineCode)
        case let link as Link:
            visitLink(link)
        case let image as Image:
            visitImage(image)
        case let lineBreak as LineBreak:
            visitLineBreak(lineBreak)
        case let softBreak as SoftBreak:
            visitSoftBreak(softBreak)
        case let inlineHTML as InlineHTML:
            visitInlineHTML(inlineHTML)
        default:
            break
        }
    }

    private mutating func visitInlineMarkup(_ markup: Markup) {
        switch markup {
        case let text as Text:
            visitText(text)
        case let emphasis as Emphasis:
            visitEmphasis(emphasis)
        case let strong as Strong:
            visitStrong(strong)
        case let strikethrough as Strikethrough:
            visitStrikethrough(strikethrough)
        case let inlineCode as InlineCode:
            visitInlineCode(inlineCode)
        case let link as Link:
            visitLink(link)
        case let image as Image:
            visitImage(image)
        case let lineBreak as LineBreak:
            visitLineBreak(lineBreak)
        case let softBreak as SoftBreak:
            visitSoftBreak(softBreak)
        case let inlineHTML as InlineHTML:
            visitInlineHTML(inlineHTML)
        default:
            break
        }
    }
    // swiftlint:enable cyclomatic_complexity

    private mutating func visitHeading(_ heading: Heading) async {
        result += HTMLElementRenderer.openHeading(level: heading.level)
        for child in heading.children {
            await visitMarkup(child)
        }
        result += HTMLElementRenderer.closeHeading(level: heading.level)
    }

    private mutating func visitParagraph(_ paragraph: Paragraph) {
        result += HTMLElementRenderer.openTag("p")
        for child in paragraph.children {
            visitInlineMarkup(child)
        }
        result += HTMLElementRenderer.closeTagWithNewline("p")
    }

    private mutating func visitText(_ text: Text) {
        result += HTMLElementRenderer.renderText(text)
    }

    private mutating func visitEmphasis(_ emphasis: Emphasis) {
        result += HTMLElementRenderer.openTag("em")
        for child in emphasis.children {
            visitInlineMarkup(child)
        }
        result += HTMLElementRenderer.closeTag("em")
    }

    private mutating func visitStrong(_ strong: Strong) {
        result += HTMLElementRenderer.openTag("strong")
        for child in strong.children {
            visitInlineMarkup(child)
        }
        result += HTMLElementRenderer.closeTag("strong")
    }

    private mutating func visitStrikethrough(_ strikethrough: Strikethrough) {
        result += HTMLElementRenderer.openTag("del")
        for child in strikethrough.children {
            visitInlineMarkup(child)
        }
        result += HTMLElementRenderer.closeTag("del")
    }

    private mutating func visitInlineCode(_ inlineCode: InlineCode) {
        result += HTMLElementRenderer.renderInlineCode(inlineCode)
    }

    private mutating func visitCodeBlock(_ codeBlock: CodeBlock) async {
        let language = codeBlock.language ?? ""
        result += HTMLElementRenderer.openCodeBlock(language: language)

        if !language.isEmpty {
            let highlighted = await highlighter.highlightToHTMLAsync(code: codeBlock.code, language: language)
            result += highlighted
        } else {
            result += codeBlock.code.htmlEscaped
        }

        result += HTMLElementRenderer.closeCodeBlock()
    }

    private mutating func visitLink(_ link: Link) {
        result += HTMLElementRenderer.openLink(link)
        for child in link.children {
            visitInlineMarkup(child)
        }
        result += HTMLElementRenderer.closeLink()
    }

    private mutating func visitImage(_ image: Image) {
        result += HTMLElementRenderer.renderImage(image, validateImages: validateImages)
    }

    private mutating func visitUnorderedList(_ unorderedList: UnorderedList) async {
        result += HTMLElementRenderer.openTagWithNewline("ul")
        for child in unorderedList.children {
            await visitMarkup(child)
        }
        result += HTMLElementRenderer.closeTagWithNewline("ul")
    }

    private mutating func visitOrderedList(_ orderedList: OrderedList) async {
        result += HTMLElementRenderer.openTagWithNewline("ol")
        for child in orderedList.children {
            await visitMarkup(child)
        }
        result += HTMLElementRenderer.closeTagWithNewline("ol")
    }

    private mutating func visitListItem(_ listItem: ListItem) {
        result += HTMLElementRenderer.openListItem(listItem)
        for child in listItem.children {
            if let paragraph = child as? Paragraph {
                for inlineChild in paragraph.children {
                    visitInlineMarkup(inlineChild)
                }
            } else {
                visitInlineMarkup(child)
            }
        }
        result += HTMLElementRenderer.closeListItem()
    }

    private mutating func visitBlockQuote(_ blockQuote: BlockQuote) async {
        result += HTMLElementRenderer.openTagWithNewline("blockquote")
        for child in blockQuote.children {
            await visitMarkup(child)
        }
        result += HTMLElementRenderer.closeTagWithNewline("blockquote")
    }

    private mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) {
        result += HTMLElementRenderer.renderThematicBreak()
    }

    private mutating func visitTable(_ table: Table) {
        result += HTMLElementRenderer.openTable()
        result += HTMLElementRenderer.openTableHead()
        for cell in table.head.cells {
            result += HTMLElementRenderer.openTableHeader()
            for child in cell.children {
                visitInlineMarkup(child)
            }
            result += HTMLElementRenderer.closeTableHeader()
        }
        result += HTMLElementRenderer.closeTableHead()
        for row in table.body.rows {
            result += HTMLElementRenderer.openTableRow()
            for cell in row.cells {
                result += HTMLElementRenderer.openTableCell()
                for child in cell.children {
                    visitInlineMarkup(child)
                }
                result += HTMLElementRenderer.closeTableCell()
            }
            result += HTMLElementRenderer.closeTableRow()
        }
        result += HTMLElementRenderer.closeTable()
    }

    private mutating func visitLineBreak(_ lineBreak: LineBreak) {
        result += HTMLElementRenderer.renderLineBreak()
    }

    private mutating func visitSoftBreak(_ softBreak: SoftBreak) {
        result += HTMLElementRenderer.renderSoftBreak()
    }

    private mutating func visitHTMLBlock(_ html: HTMLBlock) {
        result += HTMLElementRenderer.renderHTMLBlock(html)
    }

    private mutating func visitInlineHTML(_ html: InlineHTML) {
        result += HTMLElementRenderer.renderInlineHTML(html)
    }
}
