import AppKit

/// Protocol for rendering markdown elements to NSAttributedString.
///
/// Each element type (heading, paragraph, code block, etc.) has its own
/// renderer conforming to this protocol. Renderers are composable and
/// receive theme and context to produce consistent output.
///
/// ## Example Implementation
/// ```swift
/// struct HeadingRenderer: MarkdownElementRenderer {
///     func render(text: String, level: Int, theme: MarkdownTheme, context: RenderContext) -> NSAttributedString {
///         let font = theme.headingFont(level: level)
///         return NSAttributedString(string: text + "\n", attributes: [.font: font])
///     }
/// }
/// ```
public protocol MarkdownElementRenderer {
    /// The input type for this renderer.
    associatedtype Input

    /// Renders the input to an attributed string.
    ///
    /// - Parameters:
    ///   - input: The element-specific input data.
    ///   - theme: The theme providing fonts, colors, and spacing.
    ///   - context: The rendering context with nesting and state information.
    /// - Returns: The rendered attributed string.
    func render(_ input: Input, theme: MarkdownTheme, context: RenderContext) -> NSAttributedString
}

/// A type-erased wrapper for any markdown element renderer.
///
/// Use this when you need to store renderers of different input types
/// in a collection or pass them around generically.
public struct AnyMarkdownRenderer<Input> {
    private let _render: (Input, MarkdownTheme, RenderContext) -> NSAttributedString

    public init<R: MarkdownElementRenderer>(_ renderer: R) where R.Input == Input {
        self._render = renderer.render
    }

    public func render(_ input: Input, theme: MarkdownTheme, context: RenderContext) -> NSAttributedString {
        _render(input, theme, context)
    }
}
