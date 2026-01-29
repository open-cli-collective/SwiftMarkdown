import Foundation
import Markdown

/// A protocol for types that can render parsed Markdown documents into various output formats.
///
/// Conforming types implement the `render(_:)` method to convert a `Document` AST
/// into their specific output type. This enables swappable rendering backends
/// while keeping the parsing layer independent.
///
/// ## Example
/// ```swift
/// let renderer = HTMLRenderer()
/// let document = MarkdownParser.parseDocument("# Hello **World**")
/// let html = renderer.render(document)
/// ```
public protocol MarkdownRenderer {
    /// The output type produced by this renderer.
    associatedtype Output

    /// Renders a parsed Markdown document into the output format.
    /// - Parameter document: The parsed Markdown document AST.
    /// - Returns: The rendered output.
    func render(_ document: Document) -> Output
}

/// A specialized renderer protocol for HTML output.
///
/// Conforming types produce HTML strings and may provide CSS styles
/// for complete document rendering.
public protocol HTMLMarkdownRenderer: MarkdownRenderer where Output == String {
    /// CSS styles to be included with the rendered HTML.
    var cssStyles: String { get }

    /// Whether to wrap the rendered content in a complete HTML document.
    var wrapInDocument: Bool { get set }
}
