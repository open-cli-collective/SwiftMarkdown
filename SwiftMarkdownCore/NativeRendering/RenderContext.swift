import Foundation

/// The type of block element currently being rendered.
public enum BlockType: Sendable, Equatable {
    case document
    case paragraph
    case heading(level: Int)
    case codeBlock
    case blockquote
    case orderedList
    case unorderedList
    case listItem
    case table
}

/// Context passed through the rendering process to track state.
///
/// This struct carries information about the current rendering position,
/// enabling proper indentation, list numbering, and nested styling.
///
/// ## Example
/// ```swift
/// var context = RenderContext()
/// context.nestingLevel = 1
/// context.listIndex = 3
/// ```
public struct RenderContext: Sendable {
    /// Current nesting level for indentation (0 = top level).
    public var nestingLevel: Int

    /// Current list item index (1-based) for ordered lists, nil for unordered.
    public var listIndex: Int?

    /// The type of the parent block element.
    public var parentBlockType: BlockType?

    /// Whether we're inside an inline context (e.g., inside a paragraph).
    public var isInlineContext: Bool

    /// Stack of parent block types for deeply nested structures.
    public var blockStack: [BlockType]

    /// Creates a new render context with default values.
    public init(
        nestingLevel: Int = 0,
        listIndex: Int? = nil,
        parentBlockType: BlockType? = nil,
        isInlineContext: Bool = false,
        blockStack: [BlockType] = []
    ) {
        self.nestingLevel = nestingLevel
        self.listIndex = listIndex
        self.parentBlockType = parentBlockType
        self.isInlineContext = isInlineContext
        self.blockStack = blockStack
    }

    /// Returns a new context with incremented nesting level.
    public func nested() -> RenderContext {
        var copy = self
        copy.nestingLevel += 1
        return copy
    }

    /// Returns a new context with the specified parent block type pushed.
    public func entering(_ blockType: BlockType) -> RenderContext {
        var copy = self
        copy.blockStack.append(blockType)
        copy.parentBlockType = blockType
        return copy
    }

    /// Returns a new context for rendering list items with the given index.
    public func withListIndex(_ index: Int) -> RenderContext {
        var copy = self
        copy.listIndex = index
        return copy
    }

    /// Returns a new context marked as inline.
    public func asInline() -> RenderContext {
        var copy = self
        copy.isInlineContext = true
        return copy
    }
}
