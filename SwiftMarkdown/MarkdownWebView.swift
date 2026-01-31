import SwiftUI
import WebKit

/// A SwiftUI wrapper around WKWebView for displaying rendered HTML.
///
/// Uses `DropCapturingWebViewContainer` to handle drag-and-drop at the AppKit level,
/// allowing drops to work while preserving scrolling, text selection, and copy functionality.
struct MarkdownWebView: NSViewRepresentable {
    let html: String
    var onFileDrop: ((URL) -> Void)?

    func makeNSView(context: Context) -> DropCapturingWebViewContainer {
        let container = DropCapturingWebViewContainer()
        container.onFileDrop = onFileDrop
        return container
    }

    func updateNSView(_ container: DropCapturingWebViewContainer, context: Context) {
        container.webView.loadHTMLString(html, baseURL: nil)
        container.onFileDrop = onFileDrop
    }
}
