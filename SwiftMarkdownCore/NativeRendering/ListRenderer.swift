import AppKit

/// Renders markdown lists (ordered and unordered) to NSAttributedString.
///
/// Supports nested lists with proper indentation and different bullet styles
/// for each nesting level. Uses hanging indents so wrapped text aligns with
/// the first line content.
///
/// ## Bullet Styles by Level
/// - Level 0: • (bullet)
/// - Level 1: ◦ (white bullet)
/// - Level 2+: ▪ (small square)
///
/// ## Example
/// ```swift
/// let renderer = ListRenderer()
/// let items = [
///     MarkdownListItem(content: NSAttributedString(string: "First")),
///     MarkdownListItem(content: NSAttributedString(string: "Second"))
/// ]
/// let result = renderer.render(
///     ListRenderer.Input(items: items, isOrdered: false),
///     theme: .default,
///     context: RenderContext()
/// )
/// ```
public struct ListRenderer: MarkdownElementRenderer {
    /// Input for list rendering.
    public struct Input {
        /// The list items to render.
        public let items: [MarkdownListItem]
        /// Whether this is an ordered (numbered) list.
        public let isOrdered: Bool

        public init(items: [MarkdownListItem], isOrdered: Bool) {
            self.items = items
            self.isOrdered = isOrdered
        }
    }

    /// Bullet characters for different nesting levels.
    private static let bullets: [Character] = ["•", "◦", "▪"]

    public init() {}

    public func render(_ input: Input, theme: MarkdownTheme, context: RenderContext) -> NSAttributedString {
        guard !input.items.isEmpty else {
            return NSAttributedString(string: "\n")
        }

        let result = NSMutableAttributedString()

        for (index, item) in input.items.enumerated() {
            let itemResult = renderItem(
                item,
                index: index,
                isOrdered: input.isOrdered,
                theme: theme,
                nestingLevel: context.nestingLevel
            )
            result.append(itemResult)
        }

        return result
    }

    private func renderItem(
        _ item: MarkdownListItem,
        index: Int,
        isOrdered: Bool,
        theme: MarkdownTheme,
        nestingLevel: Int
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()

        // Calculate indentation
        let baseIndent = theme.listIndent * CGFloat(nestingLevel)
        let bulletWidth: CGFloat = 20 // Space for bullet/number + padding

        // Create paragraph style with hanging indent
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.firstLineHeadIndent = baseIndent
        paragraphStyle.headIndent = baseIndent + bulletWidth
        paragraphStyle.paragraphSpacing = theme.paragraphSpacing * 0.5

        // Add tab stop for bullet-to-text alignment
        paragraphStyle.tabStops = [NSTextTab(type: .leftTabStopType, location: baseIndent + bulletWidth)]

        // Create the marker (bullet or number)
        let marker: String
        if isOrdered {
            marker = "\(index + 1).\t"
        } else {
            let bulletIndex = min(nestingLevel, Self.bullets.count - 1)
            marker = "\(Self.bullets[bulletIndex])\t"
        }

        let attributes: [NSAttributedString.Key: Any] = [
            .font: theme.bodyFont,
            .foregroundColor: theme.textColor,
            .paragraphStyle: paragraphStyle
        ]

        // Add marker
        result.append(NSAttributedString(string: marker, attributes: attributes))

        // Add content (preserving its attributes but applying paragraph style)
        let content = NSMutableAttributedString(attributedString: item.content)
        content.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: content.length))
        result.append(content)

        // Add newline
        result.append(NSAttributedString(string: "\n", attributes: attributes))

        // Render children if present
        if let children = item.children, !children.isEmpty {
            let childContext = RenderContext(nestingLevel: nestingLevel + 1)
            let childInput = Input(items: children, isOrdered: item.childrenOrdered)
            let childResult = render(childInput, theme: theme, context: childContext)
            result.append(childResult)
        }

        return result
    }
}
