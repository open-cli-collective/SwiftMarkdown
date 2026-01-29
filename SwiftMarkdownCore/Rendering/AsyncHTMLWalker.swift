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
        let level = heading.level
        result += "<h\(level)>"
        for child in heading.children {
            await visitMarkup(child)
        }
        result += "</h\(level)>\n"
    }

    private mutating func visitParagraph(_ paragraph: Paragraph) {
        result += "<p>"
        for child in paragraph.children {
            visitInlineMarkup(child)
        }
        result += "</p>\n"
    }

    private mutating func visitText(_ text: Text) {
        result += text.string.htmlEscaped
    }

    private mutating func visitEmphasis(_ emphasis: Emphasis) {
        result += "<em>"
        for child in emphasis.children {
            visitInlineMarkup(child)
        }
        result += "</em>"
    }

    private mutating func visitStrong(_ strong: Strong) {
        result += "<strong>"
        for child in strong.children {
            visitInlineMarkup(child)
        }
        result += "</strong>"
    }

    private mutating func visitStrikethrough(_ strikethrough: Strikethrough) {
        result += "<del>"
        for child in strikethrough.children {
            visitInlineMarkup(child)
        }
        result += "</del>"
    }

    private mutating func visitInlineCode(_ inlineCode: InlineCode) {
        result += "<code>\(inlineCode.code.htmlEscaped)</code>"
    }

    private mutating func visitCodeBlock(_ codeBlock: CodeBlock) async {
        let language = codeBlock.language ?? ""

        if !language.isEmpty {
            result += "<pre><code class=\"language-\(language.htmlEscaped)\">"
        } else {
            result += "<pre><code>"
        }

        if !language.isEmpty {
            let highlighted = await highlighter.highlightToHTMLAsync(code: codeBlock.code, language: language)
            result += highlighted
        } else {
            result += codeBlock.code.htmlEscaped
        }

        result += "</code></pre>\n"
    }

    private mutating func visitLink(_ link: Link) {
        let href = link.destination ?? ""
        result += "<a href=\"\(href.htmlEscaped)\">"
        for child in link.children {
            visitInlineMarkup(child)
        }
        result += "</a>"
    }

    private mutating func visitImage(_ image: Image) {
        let src = image.source ?? ""
        let alt = image.plainText

        var cssClass: String?

        if validateImages && ImageValidator.isDataURI(src) {
            if !ImageValidator.validate(dataURI: src).isValid {
                cssClass = "invalid-image"
            }
        }

        if let cls = cssClass {
            result += "<img class=\"\(cls)\" src=\"\(src.htmlEscaped)\" alt=\"\(alt.htmlEscaped)\">"
        } else {
            result += "<img src=\"\(src.htmlEscaped)\" alt=\"\(alt.htmlEscaped)\">"
        }
    }

    private mutating func visitUnorderedList(_ unorderedList: UnorderedList) async {
        result += "<ul>\n"
        for child in unorderedList.children {
            await visitMarkup(child)
        }
        result += "</ul>\n"
    }

    private mutating func visitOrderedList(_ orderedList: OrderedList) async {
        result += "<ol>\n"
        for child in orderedList.children {
            await visitMarkup(child)
        }
        result += "</ol>\n"
    }

    private mutating func visitListItem(_ listItem: ListItem) {
        if let checkbox = listItem.checkbox {
            let checked = checkbox == .checked ? " checked" : ""
            result += "<li><input type=\"checkbox\" disabled\(checked)> "
        } else {
            result += "<li>"
        }
        for child in listItem.children {
            if let paragraph = child as? Paragraph {
                for inlineChild in paragraph.children {
                    visitInlineMarkup(inlineChild)
                }
            } else {
                visitInlineMarkup(child)
            }
        }
        result += "</li>\n"
    }

    private mutating func visitBlockQuote(_ blockQuote: BlockQuote) async {
        result += "<blockquote>\n"
        for child in blockQuote.children {
            await visitMarkup(child)
        }
        result += "</blockquote>\n"
    }

    private mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) {
        result += "<hr>\n"
    }

    private mutating func visitTable(_ table: Table) {
        result += "<table>\n"
        let head = table.head
        result += "<thead>\n<tr>\n"
        for cell in head.cells {
            result += "<th>"
            for child in cell.children {
                visitInlineMarkup(child)
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
                    visitInlineMarkup(child)
                }
                result += "</td>\n"
            }
            result += "</tr>\n"
        }
        result += "</tbody>\n</table>\n"
    }

    private mutating func visitLineBreak(_ lineBreak: LineBreak) {
        result += "<br>\n"
    }

    private mutating func visitSoftBreak(_ softBreak: SoftBreak) {
        result += "\n"
    }

    private mutating func visitHTMLBlock(_ html: HTMLBlock) {
        result += html.rawHTML
    }

    private mutating func visitInlineHTML(_ html: InlineHTML) {
        result += html.rawHTML
    }
}
