import Foundation
import Markdown

/// Shared HTML rendering utilities for inline and simple block elements.
///
/// Used by both `HTMLWalker` (synchronous) and `AsyncHTMLWalker` (async)
/// to avoid code duplication.
enum HTMLElementRenderer {
    // MARK: - Inline Elements

    static func renderText(_ text: Text) -> String {
        text.string.htmlEscaped
    }

    static func renderInlineCode(_ inlineCode: InlineCode) -> String {
        "<code>\(inlineCode.code.htmlEscaped)</code>"
    }

    static func renderLineBreak() -> String {
        "<br>\n"
    }

    static func renderSoftBreak() -> String {
        "\n"
    }

    static func renderHTMLBlock(_ html: HTMLBlock) -> String {
        html.rawHTML
    }

    static func renderInlineHTML(_ html: InlineHTML) -> String {
        html.rawHTML
    }

    static func renderThematicBreak() -> String {
        "<hr>\n"
    }

    // MARK: - Element Wrappers

    static func openTag(_ tag: String) -> String {
        "<\(tag)>"
    }

    static func closeTag(_ tag: String) -> String {
        "</\(tag)>"
    }

    static func openTagWithNewline(_ tag: String) -> String {
        "<\(tag)>\n"
    }

    static func closeTagWithNewline(_ tag: String) -> String {
        "</\(tag)>\n"
    }

    // MARK: - Links

    static func openLink(_ link: Link) -> String {
        let href = link.destination ?? ""
        return "<a href=\"\(href.htmlEscaped)\">"
    }

    static func closeLink() -> String {
        "</a>"
    }

    // MARK: - Images

    static func renderImage(_ image: Image, validateImages: Bool) -> String {
        let src = image.source ?? ""
        let alt = image.plainText
        let escapedSrc = src.htmlEscaped
        let escapedAlt = alt.htmlEscaped

        let isInvalid = validateImages
            && ImageValidator.isDataURI(src)
            && !ImageValidator.validate(dataURI: src).isValid

        if isInvalid {
            return "<img class=\"invalid-image\" src=\"\(escapedSrc)\" alt=\"\(escapedAlt)\">"
        }
        return "<img src=\"\(escapedSrc)\" alt=\"\(escapedAlt)\">"
    }

    // MARK: - Headings

    static func openHeading(level: Int) -> String {
        "<h\(level)>"
    }

    static func closeHeading(level: Int) -> String {
        "</h\(level)>\n"
    }

    // MARK: - Code Blocks

    static func openCodeBlock(language: String) -> String {
        language.isEmpty
            ? "<pre><code>"
            : "<pre><code class=\"language-\(language.htmlEscaped)\">"
    }

    static func closeCodeBlock() -> String {
        "</code></pre>\n"
    }

    // MARK: - List Items

    static func openListItem(_ listItem: ListItem) -> String {
        guard let checkbox = listItem.checkbox else {
            return "<li>"
        }
        let checked = checkbox == .checked ? " checked" : ""
        return "<li><input type=\"checkbox\" disabled\(checked)> "
    }

    static func closeListItem() -> String {
        "</li>\n"
    }

    // MARK: - Tables

    static func openTable() -> String {
        "<table>\n"
    }

    static func closeTable() -> String {
        "</tbody>\n</table>\n"
    }

    static func openTableHead() -> String {
        "<thead>\n<tr>\n"
    }

    static func closeTableHead() -> String {
        "</tr>\n</thead>\n<tbody>\n"
    }

    static func openTableRow() -> String {
        "<tr>\n"
    }

    static func closeTableRow() -> String {
        "</tr>\n"
    }

    static func openTableHeader() -> String {
        "<th>"
    }

    static func closeTableHeader() -> String {
        "</th>\n"
    }

    static func openTableCell() -> String {
        "<td>"
    }

    static func closeTableCell() -> String {
        "</td>\n"
    }
}
