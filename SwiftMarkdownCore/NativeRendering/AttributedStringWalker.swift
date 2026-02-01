import AppKit
import Markdown

/// Walks a swift-markdown AST and builds an NSAttributedString.
///
/// This struct traverses each node in the markdown document and dispatches
/// to the appropriate element renderer based on node type.
struct AttributedStringWalker {
    /// The accumulated result.
    private(set) var result = NSMutableAttributedString()

    private let theme: MarkdownTheme
    private var context: RenderContext

    // Renderers
    private let headingRenderer: HeadingRenderer
    private let paragraphRenderer: ParagraphRenderer
    private let codeBlockRenderer: CodeBlockRenderer
    private let blockquoteRenderer: BlockquoteRenderer
    private let listRenderer: ListRenderer
    private let horizontalRuleRenderer: HorizontalRuleRenderer
    private let tableRenderer: TableRenderer
    private let imageRenderer: ImageRenderer
    private let emphasisRenderer: EmphasisRenderer
    private let inlineCodeRenderer: InlineCodeRenderer
    private let linkRenderer: LinkRenderer
    private let strikethroughRenderer: StrikethroughRenderer

    init(
        theme: MarkdownTheme,
        context: RenderContext,
        headingRenderer: HeadingRenderer,
        paragraphRenderer: ParagraphRenderer,
        codeBlockRenderer: CodeBlockRenderer,
        blockquoteRenderer: BlockquoteRenderer,
        listRenderer: ListRenderer,
        horizontalRuleRenderer: HorizontalRuleRenderer,
        tableRenderer: TableRenderer,
        imageRenderer: ImageRenderer,
        emphasisRenderer: EmphasisRenderer,
        inlineCodeRenderer: InlineCodeRenderer,
        linkRenderer: LinkRenderer,
        strikethroughRenderer: StrikethroughRenderer
    ) {
        self.theme = theme
        self.context = context
        self.headingRenderer = headingRenderer
        self.paragraphRenderer = paragraphRenderer
        self.codeBlockRenderer = codeBlockRenderer
        self.blockquoteRenderer = blockquoteRenderer
        self.listRenderer = listRenderer
        self.horizontalRuleRenderer = horizontalRuleRenderer
        self.tableRenderer = tableRenderer
        self.imageRenderer = imageRenderer
        self.emphasisRenderer = emphasisRenderer
        self.inlineCodeRenderer = inlineCodeRenderer
        self.linkRenderer = linkRenderer
        self.strikethroughRenderer = strikethroughRenderer
    }

    /// Visits a document and renders all its children.
    mutating func visit(_ document: Document) {
        for child in document.children {
            visitBlock(child)
        }
    }

    // MARK: - Block Visitors

    private mutating func visitBlock(_ markup: Markup) {
        switch markup {
        case let heading as Heading:
            visitHeading(heading)
        case let paragraph as Paragraph:
            visitParagraph(paragraph)
        case let codeBlock as CodeBlock:
            visitCodeBlock(codeBlock)
        case let blockQuote as BlockQuote:
            visitBlockQuote(blockQuote)
        case let unorderedList as UnorderedList:
            visitUnorderedList(unorderedList)
        case let orderedList as OrderedList:
            visitOrderedList(orderedList)
        case let thematicBreak as ThematicBreak:
            visitThematicBreak(thematicBreak)
        case let table as Table:
            visitTable(table)
        case let htmlBlock as HTMLBlock:
            visitHTMLBlock(htmlBlock)
        default:
            break
        }
    }

    private mutating func visitHeading(_ heading: Heading) {
        // TODO: Support rich inline content in headings
        let text = collectInlineText(from: heading)
        let input = HeadingRenderer.Input(text: text, level: heading.level)
        result.append(headingRenderer.render(input, theme: theme, context: context))
    }

    private mutating func visitParagraph(_ paragraph: Paragraph) {
        let inlineContent = renderInlineChildren(of: paragraph)
        result.append(inlineContent)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing = theme.paragraphSpacing
        result.append(NSAttributedString(string: "\n", attributes: [.paragraphStyle: paragraphStyle]))
    }

    private mutating func visitCodeBlock(_ codeBlock: CodeBlock) {
        let input = CodeBlockRenderer.Input(code: codeBlock.code, language: codeBlock.language)
        result.append(codeBlockRenderer.render(input, theme: theme, context: context))
    }

    private mutating func visitBlockQuote(_ blockQuote: BlockQuote) {
        let content = NSMutableAttributedString()
        for child in blockQuote.children {
            if let paragraph = child as? Paragraph {
                let inlineContent = renderInlineChildren(of: paragraph)
                content.append(inlineContent)
            }
        }

        let nestedContext = context.nested()
        result.append(blockquoteRenderer.render(content, theme: theme, context: nestedContext))
    }

    private mutating func visitUnorderedList(_ list: UnorderedList) {
        var items: [MarkdownListItem] = []
        for listItem in list.listItems {
            items.append(buildListItem(listItem, isOrdered: false))
        }
        let input = ListRenderer.Input(items: items, isOrdered: false)
        result.append(listRenderer.render(input, theme: theme, context: context))
    }

    private mutating func visitOrderedList(_ list: OrderedList) {
        var items: [MarkdownListItem] = []
        for listItem in list.listItems {
            items.append(buildListItem(listItem, isOrdered: true))
        }
        let input = ListRenderer.Input(items: items, isOrdered: true)
        result.append(listRenderer.render(input, theme: theme, context: context))
    }

    private func buildListItem(_ listItem: ListItem, isOrdered: Bool) -> MarkdownListItem {
        let content = NSMutableAttributedString()
        var nestedItems: [MarkdownListItem]?
        var nestedOrdered = false

        for child in listItem.children {
            if let paragraph = child as? Paragraph {
                var tempWalker = self
                let inlineContent = tempWalker.renderInlineChildren(of: paragraph)
                content.append(inlineContent)
            } else if let nestedUnordered = child as? UnorderedList {
                var nested: [MarkdownListItem] = []
                for item in nestedUnordered.listItems {
                    nested.append(buildListItem(item, isOrdered: false))
                }
                nestedItems = nested
                nestedOrdered = false
            } else if let nestedOrderedList = child as? OrderedList {
                var nested: [MarkdownListItem] = []
                for item in nestedOrderedList.listItems {
                    nested.append(buildListItem(item, isOrdered: true))
                }
                nestedItems = nested
                nestedOrdered = true
            }
        }

        return MarkdownListItem(
            content: content,
            children: nestedItems,
            childrenOrdered: nestedOrdered
        )
    }

    private mutating func visitThematicBreak(_: ThematicBreak) {
        result.append(horizontalRuleRenderer.render((), theme: theme, context: context))
    }

    private mutating func visitTable(_ table: Table) {
        let headers: [NSAttributedString] = table.head.cells.map { cell in
            let content = NSMutableAttributedString()
            var tempWalker = self
            for child in cell.children {
                content.append(tempWalker.renderInlineMarkup(child))
            }
            return content
        }

        let rows: [[NSAttributedString]] = table.body.rows.map { row in
            row.cells.map { cell in
                let content = NSMutableAttributedString()
                var tempWalker = self
                for child in cell.children {
                    content.append(tempWalker.renderInlineMarkup(child))
                }
                return content
            }
        }

        let alignments: [TableRenderer.Alignment] = table.columnAlignments.map { alignment in
            switch alignment {
            case .center:
                return .center
            case .right:
                return .right
            case .left, nil:
                return .left
            }
        }

        let input = TableRenderer.Input(headers: headers, rows: rows, alignments: alignments)
        result.append(tableRenderer.render(input, theme: theme, context: context))
    }

    private mutating func visitHTMLBlock(_ htmlBlock: HTMLBlock) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: theme.bodyFont,
            .foregroundColor: theme.textColor
        ]
        result.append(NSAttributedString(string: htmlBlock.rawHTML + "\n", attributes: attributes))
    }

    // MARK: - Inline Rendering

    private mutating func renderInlineChildren(of container: some Markup) -> NSAttributedString {
        let content = NSMutableAttributedString()
        for child in container.children {
            content.append(renderInlineMarkup(child))
        }
        return content
    }

    private mutating func renderInlineMarkup(_ markup: Markup) -> NSAttributedString {
        if let result = renderTextFormatting(markup) {
            return result
        }
        return renderOtherInline(markup)
    }

    private mutating func renderTextFormatting(_ markup: Markup) -> NSAttributedString? {
        switch markup {
        case let text as Text:
            return renderText(text)
        case let emphasis as Emphasis:
            return renderEmphasis(emphasis)
        case let strong as Strong:
            return renderStrong(strong)
        case let strikethrough as Strikethrough:
            return renderStrikethrough(strikethrough)
        case let inlineCode as InlineCode:
            return renderInlineCode(inlineCode)
        default:
            return nil
        }
    }

    private mutating func renderOtherInline(_ markup: Markup) -> NSAttributedString {
        switch markup {
        case let link as Link:
            return renderLink(link)
        case let image as Image:
            return renderImage(image)
        case let softBreak as SoftBreak:
            return renderSoftBreak(softBreak)
        case let lineBreak as LineBreak:
            return renderLineBreak(lineBreak)
        case let inlineHTML as InlineHTML:
            return renderInlineHTML(inlineHTML)
        default:
            return NSAttributedString()
        }
    }

    private func renderText(_ text: Text) -> NSAttributedString {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: theme.bodyFont,
            .foregroundColor: theme.textColor
        ]
        return NSAttributedString(string: text.string, attributes: attributes)
    }

    private mutating func renderEmphasis(_ emphasis: Emphasis) -> NSAttributedString {
        var hasBoldItalic = false
        var innerContent = ""

        for child in emphasis.children {
            if let strong = child as? Strong {
                hasBoldItalic = true
                innerContent += collectInlineText(from: strong)
            } else if let text = child as? Text {
                innerContent += text.string
            } else {
                innerContent += collectInlineText(from: child)
            }
        }

        let style: EmphasisRenderer.Style = hasBoldItalic ? .boldItalic : .italic
        let input = EmphasisRenderer.Input(text: innerContent, style: style)
        return emphasisRenderer.render(input, theme: theme, context: context)
    }

    private mutating func renderStrong(_ strong: Strong) -> NSAttributedString {
        var hasBoldItalic = false
        var innerContent = ""

        for child in strong.children {
            if let emphasis = child as? Emphasis {
                hasBoldItalic = true
                innerContent += collectInlineText(from: emphasis)
            } else if let text = child as? Text {
                innerContent += text.string
            }
        }

        let style: EmphasisRenderer.Style = hasBoldItalic ? .boldItalic : .bold
        let input = EmphasisRenderer.Input(text: innerContent, style: style)
        return emphasisRenderer.render(input, theme: theme, context: context)
    }

    private func renderStrikethrough(_ strikethrough: Strikethrough) -> NSAttributedString {
        let content = collectInlineText(from: strikethrough)
        return strikethroughRenderer.render(content, theme: theme, context: context)
    }

    private func renderInlineCode(_ inlineCode: InlineCode) -> NSAttributedString {
        return inlineCodeRenderer.render(inlineCode.code, theme: theme, context: context)
    }

    private mutating func renderLink(_ link: Link) -> NSAttributedString {
        let text = collectInlineText(from: link)
        guard let url = link.destination.flatMap({ URL(string: $0) }) else {
            // Fallback to plain text if URL is invalid
            return renderText(Text(text))
        }
        let input = LinkRenderer.Input(text: text, url: url)
        return linkRenderer.render(input, theme: theme, context: context)
    }

    private func renderImage(_ image: Image) -> NSAttributedString {
        // Image sources need to be resolved externally before rendering
        let input = ImageRenderer.Input(image: nil, altText: image.plainText)
        return imageRenderer.render(input, theme: theme, context: context)
    }

    /// Soft breaks (single newline in source) become spaces in output per CommonMark spec.
    private func renderSoftBreak(_: SoftBreak) -> NSAttributedString {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: theme.bodyFont,
            .foregroundColor: theme.textColor
        ]
        return NSAttributedString(string: " ", attributes: attributes)
    }

    /// Hard breaks (two trailing spaces + newline) become actual line breaks.
    private func renderLineBreak(_: LineBreak) -> NSAttributedString {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: theme.bodyFont,
            .foregroundColor: theme.textColor
        ]
        return NSAttributedString(string: "\n", attributes: attributes)
    }

    private func renderInlineHTML(_ inlineHTML: InlineHTML) -> NSAttributedString {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: theme.bodyFont,
            .foregroundColor: theme.textColor
        ]
        return NSAttributedString(string: inlineHTML.rawHTML, attributes: attributes)
    }

    // MARK: - Helpers

    private func collectInlineText(from markup: some Markup) -> String {
        var text = ""
        for child in markup.children {
            if let textNode = child as? Text {
                text += textNode.string
            } else {
                text += collectInlineText(from: child)
            }
        }
        return text
    }
}
