import AppKit
import SwiftUI

/// A SwiftUI wrapper around NSTextView for displaying rendered markdown.
///
/// Uses native text rendering for fast display, text selection, and copy support.
/// Handles link clicks via `NSTextViewDelegate` and file drops via an overlay.
struct NativeMarkdownView: NSViewRepresentable {
    let attributedString: NSAttributedString
    var onLinkClick: ((URL) -> Void)?
    var onFileDrop: ((URL) -> Void)?

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()

        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }

        // Configure text view
        textView.isEditable = false
        textView.isSelectable = true
        textView.delegate = context.coordinator
        textView.textContainerInset = NSSize(width: 16, height: 16)
        textView.backgroundColor = .textBackgroundColor
        textView.isAutomaticLinkDetectionEnabled = false

        // Set up text container for proper wrapping
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )

        // Add drop interceptor if we have a drop handler
        if onFileDrop != nil {
            let dropInterceptor = DropInterceptorView()
            dropInterceptor.onFileDrop = onFileDrop
            dropInterceptor.translatesAutoresizingMaskIntoConstraints = false
            scrollView.addSubview(dropInterceptor)

            NSLayoutConstraint.activate([
                dropInterceptor.topAnchor.constraint(equalTo: scrollView.topAnchor),
                dropInterceptor.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
                dropInterceptor.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
                dropInterceptor.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor)
            ])
        }

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        // Update content
        textView.textStorage?.setAttributedString(attributedString)

        // Update coordinator's callback
        context.coordinator.onLinkClick = onLinkClick

        // Update drop handler
        for subview in scrollView.subviews {
            if let dropInterceptor = subview as? DropInterceptorView {
                dropInterceptor.onFileDrop = onFileDrop
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onLinkClick: onLinkClick)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, NSTextViewDelegate {
        var onLinkClick: ((URL) -> Void)?

        init(onLinkClick: ((URL) -> Void)?) {
            self.onLinkClick = onLinkClick
        }

        func textView(
            _ textView: NSTextView,
            clickedOnLink link: Any,
            at charIndex: Int
        ) -> Bool {
            guard let onLinkClick = onLinkClick else {
                return false
            }

            if let url = link as? URL {
                onLinkClick(url)
                return true
            } else if let string = link as? String, let url = URL(string: string) {
                onLinkClick(url)
                return true
            }

            return false
        }
    }
}

// MARK: - Drop Interceptor

/// An invisible overlay that intercepts drag-and-drop but passes all other events through.
///
/// **Critical**: `hitTest()` returns `nil` so mouse events pass through to the view below.
/// Drag-and-drop works because drag type registration is separate from hit testing.
private class DropInterceptorView: NSView {
    var onFileDrop: ((URL) -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.fileURL])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    // Return nil so all mouse events pass through to the text view below
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
