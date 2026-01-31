import XCTest
@testable import SwiftMarkdown

/// Tests for DropCapturingWebViewContainer to prevent regressions in drag-and-drop behavior.
///
/// History of this component (why these tests matter):
/// 1. Original: Invisible SwiftUI overlay captured drops but blocked ALL mouse events (no scroll/copy)
/// 2. Fix attempt: Remove overlay - broke drag-drop on subsequent files (WKWebView consumed events)
/// 3. Fix attempt: unregisterDraggedTypes() - ineffective (WebView's internal subviews handle drags)
/// 4. Current: DragInterceptorView with hitTest()->nil - works because:
///    - hitTest()->nil lets mouse events pass through to WebView
///    - Drag registration is SEPARATE from hit testing, so drops still work
///
/// These tests ensure future changes don't reintroduce either regression.
final class DropCapturingWebViewContainerTests: XCTestCase {
    // MARK: - Critical: hitTest must reach WebView, not the interceptor

    /// The DragInterceptorView returns nil from hitTest so mouse events pass through it.
    /// The container's hitTest should return the WebView (or its subviews), NOT the interceptor.
    /// This is critical - if the interceptor is returned, scrolling and text selection will break.
    func testHitTestReturnsWebViewNotInterceptor() {
        let container = DropCapturingWebViewContainer()
        container.frame = NSRect(x: 0, y: 0, width: 800, height: 600)
        container.layoutSubtreeIfNeeded()

        let hitView = container.hitTest(NSPoint(x: 400, y: 300))

        // Should return WebView or one of its subviews, NOT the drag interceptor
        // The interceptor returns nil from hitTest, so it's skipped
        XCTAssertNotNil(hitView)

        // Verify it's not the container itself (would mean subviews aren't set up)
        XCTAssertNotEqual(hitView, container)

        // The hit view should be the WebView or a descendant of it
        var currentView = hitView
        var isWebViewOrDescendant = false
        while let checkedView = currentView {
            if checkedView == container.webView {
                isWebViewOrDescendant = true
                break
            }
            currentView = checkedView.superview
        }
        XCTAssertTrue(isWebViewOrDescendant, "hitTest should return WebView or its descendant")
    }

    // MARK: - View Hierarchy

    func testContainerContainsWebView() {
        let container = DropCapturingWebViewContainer()

        XCTAssertNotNil(container.webView)
        XCTAssertTrue(container.subviews.contains(container.webView))
    }

    func testWebViewFillsContainer() {
        let container = DropCapturingWebViewContainer()
        container.frame = NSRect(x: 0, y: 0, width: 800, height: 600)
        container.layoutSubtreeIfNeeded()

        // WebView should fill the container
        XCTAssertEqual(container.webView.frame.width, container.frame.width)
        XCTAssertEqual(container.webView.frame.height, container.frame.height)
    }

    // MARK: - Drag Registration

    func testContainerHasDragInterceptorOnTop() {
        let container = DropCapturingWebViewContainer()

        // Should have exactly 2 subviews: WebView and drag interceptor
        XCTAssertEqual(container.subviews.count, 2)

        // WebView should be first (bottom), interceptor should be last (top)
        XCTAssertEqual(container.subviews.first, container.webView)
        XCTAssertNotEqual(container.subviews.last, container.webView)
    }

    // MARK: - Callback Wiring

    func testOnFileDropCallbackIsWired() {
        let container = DropCapturingWebViewContainer()
        var receivedURL: URL?

        container.onFileDrop = { url in
            receivedURL = url
        }

        // Verify callback is set (we can't easily simulate a real drop,
        // but we can verify the wiring is in place)
        XCTAssertNotNil(container.onFileDrop)

        // Simulate what would happen if a drop occurred
        let testURL = URL(fileURLWithPath: "/test/file.md")
        container.onFileDrop?(testURL)

        XCTAssertEqual(receivedURL, testURL)
    }

    func testOnFileDropDefaultsToNil() {
        let container = DropCapturingWebViewContainer()

        XCTAssertNil(container.onFileDrop)
    }
}
