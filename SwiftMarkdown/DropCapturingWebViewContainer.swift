import AppKit
import WebKit

// MARK: - Why This Architecture Exists
//
// WKWebView intercepts drag events at the AppKit level before SwiftUI's `.onDrop()` can receive them.
// We tried several approaches:
//
// 1. **SwiftUI overlay with onDrop** - Blocked ALL mouse events (no scroll, no text selection, no copy)
// 2. **Remove the overlay** - Drag-and-drop stopped working on subsequent files
// 3. **unregisterDraggedTypes() on WKWebView** - Didn't work because WebView's internal subviews
//    handle drags independently and WebKit may re-register types dynamically
//
// The solution: A transparent NSView overlay that:
// - Returns `nil` from `hitTest()` so all mouse events pass through to WebView
// - Is still registered for drag types (drag registration is SEPARATE from hit testing)
//
// This lets us intercept drops while preserving scroll, text selection, and copy functionality.
// See DropCapturingWebViewContainerTests for regression tests that guard this behavior.

/// An invisible overlay that intercepts drag-and-drop but passes all other events through.
///
/// **Critical**: `hitTest()` returns `nil` so mouse events pass through to the WebView below.
/// Drag-and-drop works because drag type registration is separate from hit testing.
private class DragInterceptorView: NSView {
    var onFileDrop: ((URL) -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.fileURL])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    // CRITICAL: Return nil so all mouse events (clicks, scrolls, drags for text selection)
    // pass through to the WebView below. Drag-and-drop still works because drag type
    // registration is handled separately from hit testing.
    // DO NOT return self or any view here - it will break scrolling and text selection.
    override func hitTest(_ point: NSPoint) -> NSView? {
        return nil
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return sender.draggingPasteboard.canReadObject(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) ? .copy : []
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return sender.draggingPasteboard.canReadObject(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) ? .copy : []
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let urls = sender.draggingPasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [URL],
              let url = urls.first else { return false }
        onFileDrop?(url)
        return true
    }
}

/// A container NSView that wraps WKWebView and handles drag-and-drop.
///
/// Uses an invisible overlay that intercepts drag events while passing all other
/// events (scroll, click, selection) through to the WebView.
class DropCapturingWebViewContainer: NSView {
    let webView: WKWebView
    private let dragInterceptor: DragInterceptorView

    var onFileDrop: ((URL) -> Void)? {
        get { dragInterceptor.onFileDrop }
        set { dragInterceptor.onFileDrop = newValue }
    }

    init() {
        webView = WKWebView()
        webView.setValue(false, forKey: "drawsBackground")
        dragInterceptor = DragInterceptorView()

        super.init(frame: .zero)

        // Add WebView first (bottom)
        addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false

        // Add drag interceptor on top
        addSubview(dragInterceptor)
        dragInterceptor.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor),

            dragInterceptor.topAnchor.constraint(equalTo: topAnchor),
            dragInterceptor.bottomAnchor.constraint(equalTo: bottomAnchor),
            dragInterceptor.leadingAnchor.constraint(equalTo: leadingAnchor),
            dragInterceptor.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
}
