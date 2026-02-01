import AppKit

/// Renders markdown horizontal rules (---) to NSAttributedString with a visual line.
///
/// Uses an NSTextAttachment with a custom cell to draw the horizontal line.
/// The line is surrounded by newlines for visual separation.
///
/// ## Example
/// ```swift
/// let renderer = HorizontalRuleRenderer()
/// let result = renderer.render(
///     (),
///     theme: .default,
///     context: RenderContext()
/// )
/// ```
public struct HorizontalRuleRenderer: MarkdownElementRenderer {
    public typealias Input = Void

    public init() {}

    public func render(_ input: Void, theme: MarkdownTheme, context: RenderContext) -> NSAttributedString {
        let result = NSMutableAttributedString()

        // Add leading newline for spacing
        result.append(NSAttributedString(string: "\n"))

        // Create the horizontal rule attachment
        let attachment = NSTextAttachment()
        let cell = HorizontalRuleAttachmentCell(color: theme.textColor)
        attachment.attachmentCell = cell

        // Set bounds for the attachment (width will be overridden by text container)
        attachment.bounds = NSRect(x: 0, y: 0, width: 100, height: 16)

        // Create the attachment string
        let attachmentString = NSAttributedString(attachment: attachment)
        result.append(attachmentString)

        // Add trailing newline for spacing
        result.append(NSAttributedString(string: "\n"))

        return result
    }
}
