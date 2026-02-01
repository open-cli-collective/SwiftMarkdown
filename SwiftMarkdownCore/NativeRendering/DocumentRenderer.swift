import AppKit
import Markdown

/// Renders a complete markdown document to NSAttributedString.
///
/// This is the main entry point for native rendering. It traverses the swift-markdown
/// AST and dispatches to specialized element renderers for each node type.
///
/// ## Example
/// ```swift
/// let renderer = DocumentRenderer()
/// let document = Document(parsing: "# Hello\n\nWorld")
/// let result = renderer.render(document, theme: .default, context: RenderContext())
/// ```
public struct DocumentRenderer {
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

    /// Creates a document renderer with default element renderers.
    ///
    /// - Parameter syntaxHighlighter: Optional syntax highlighter for code blocks.
    public init(syntaxHighlighter: (any SyntaxHighlighter)? = nil) {
        self.headingRenderer = HeadingRenderer()
        self.paragraphRenderer = ParagraphRenderer()
        self.codeBlockRenderer = CodeBlockRenderer(highlighter: syntaxHighlighter)
        self.blockquoteRenderer = BlockquoteRenderer()
        self.listRenderer = ListRenderer()
        self.horizontalRuleRenderer = HorizontalRuleRenderer()
        self.tableRenderer = TableRenderer()
        self.imageRenderer = ImageRenderer()
        self.emphasisRenderer = EmphasisRenderer()
        self.inlineCodeRenderer = InlineCodeRenderer()
        self.linkRenderer = LinkRenderer()
        self.strikethroughRenderer = StrikethroughRenderer()
    }

    /// Renders a markdown document to an attributed string.
    ///
    /// - Parameters:
    ///   - document: The parsed markdown document.
    ///   - theme: The theme for styling.
    ///   - context: The rendering context.
    /// - Returns: The rendered attributed string.
    public func render(_ document: Document, theme: MarkdownTheme, context: RenderContext) -> NSAttributedString {
        var walker = AttributedStringWalker(
            theme: theme,
            context: context,
            headingRenderer: headingRenderer,
            paragraphRenderer: paragraphRenderer,
            codeBlockRenderer: codeBlockRenderer,
            blockquoteRenderer: blockquoteRenderer,
            listRenderer: listRenderer,
            horizontalRuleRenderer: horizontalRuleRenderer,
            tableRenderer: tableRenderer,
            imageRenderer: imageRenderer,
            emphasisRenderer: emphasisRenderer,
            inlineCodeRenderer: inlineCodeRenderer,
            linkRenderer: linkRenderer,
            strikethroughRenderer: strikethroughRenderer
        )

        walker.visit(document)

        return walker.result
    }
}
