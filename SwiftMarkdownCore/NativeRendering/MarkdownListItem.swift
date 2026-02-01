import AppKit

/// A model representing a list item for native NSAttributedString rendering.
///
/// List items contain content (already rendered with inline styles) and
/// optionally nested child items forming sublists.
///
/// Note: Named `MarkdownListItem` to avoid conflict with swift-markdown's `ListItem`.
public struct MarkdownListItem {
    /// The content of the list item as an attributed string.
    public let content: NSAttributedString

    /// Nested list items, if any.
    public let children: [MarkdownListItem]?

    /// Whether the nested children form an ordered list.
    public let childrenOrdered: Bool

    /// Creates a list item.
    ///
    /// - Parameters:
    ///   - content: The item's content as an attributed string.
    ///   - children: Optional nested list items.
    ///   - childrenOrdered: Whether nested children are an ordered list.
    public init(content: NSAttributedString, children: [MarkdownListItem]? = nil, childrenOrdered: Bool = false) {
        self.content = content
        self.children = children
        self.childrenOrdered = childrenOrdered
    }
}
