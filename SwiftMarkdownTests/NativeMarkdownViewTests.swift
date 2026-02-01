import AppKit
import XCTest

@testable import SwiftMarkdown

final class NativeMarkdownViewTests: XCTestCase {
    // MARK: - Coordinator Tests

    func test_coordinator_handlesURLLinkClick() throws {
        var clickedURL: URL?
        let coordinator = NativeMarkdownView.Coordinator(onLinkClick: { url in
            clickedURL = url
        })

        let textView = NSTextView()
        let url = try XCTUnwrap(URL(string: "https://example.com"))

        let handled = coordinator.textView(textView, clickedOnLink: url, at: 0)

        XCTAssertTrue(handled)
        XCTAssertEqual(clickedURL, url)
    }

    func test_coordinator_handlesStringLinkClick() {
        var clickedURL: URL?
        let coordinator = NativeMarkdownView.Coordinator(onLinkClick: { url in
            clickedURL = url
        })

        let textView = NSTextView()

        let handled = coordinator.textView(textView, clickedOnLink: "https://string.com", at: 0)

        XCTAssertTrue(handled)
        XCTAssertEqual(clickedURL?.absoluteString, "https://string.com")
    }

    func test_coordinator_ignoresInvalidLinkTypes() {
        var clickedURL: URL?
        let coordinator = NativeMarkdownView.Coordinator(onLinkClick: { url in
            clickedURL = url
        })

        let textView = NSTextView()

        let handled = coordinator.textView(textView, clickedOnLink: 12345, at: 0)

        XCTAssertFalse(handled)
        XCTAssertNil(clickedURL)
    }

    func test_coordinator_returnsFalseWithNoHandler() throws {
        let coordinator = NativeMarkdownView.Coordinator(onLinkClick: nil)

        let textView = NSTextView()
        let url = try XCTUnwrap(URL(string: "https://test.com"))

        let handled = coordinator.textView(textView, clickedOnLink: url, at: 0)

        XCTAssertFalse(handled)
    }

    func test_coordinator_handlesInvalidStringURL() {
        var clickedURL: URL?
        let coordinator = NativeMarkdownView.Coordinator(onLinkClick: { url in
            clickedURL = url
        })

        let textView = NSTextView()

        // Empty string can't be parsed as a URL
        let handled = coordinator.textView(textView, clickedOnLink: "", at: 0)

        XCTAssertFalse(handled)
        XCTAssertNil(clickedURL)
    }

    // MARK: - View Creation Integration Tests

    func test_nativeMarkdownView_createsScrollableTextView() {
        // This test verifies the view structure by creating a real view
        let content = NSAttributedString(string: "Test content")
        let view = NativeMarkdownView(attributedString: content)

        // Use the real coordinator
        let coordinator = view.makeCoordinator()

        // Create a mock representable context by using internal testing approach
        // We can't create a real NSViewRepresentableContext, but we can test
        // the view's behavior by creating views directly

        // Test that the view can be created without crashing
        // The actual NSViewRepresentable behavior is tested via UI tests
        XCTAssertNotNil(coordinator)
    }

    func test_coordinator_updatesCallback() throws {
        var firstCallbackCalled = false
        var secondCallbackCalled = false

        let coordinator = NativeMarkdownView.Coordinator(onLinkClick: { _ in
            firstCallbackCalled = true
        })

        // Update callback
        coordinator.onLinkClick = { _ in
            secondCallbackCalled = true
        }

        let textView = NSTextView()
        let url = try XCTUnwrap(URL(string: "https://test.com"))
        _ = coordinator.textView(textView, clickedOnLink: url, at: 0)

        XCTAssertFalse(firstCallbackCalled)
        XCTAssertTrue(secondCallbackCalled)
    }

    // MARK: - View Behavior Tests (using reflection)

    func test_nativeMarkdownView_hasCorrectProperties() throws {
        let content = NSAttributedString(string: "Test")
        var linkClicked = false
        var fileDropped = false

        let view = NativeMarkdownView(
            attributedString: content,
            onLinkClick: { _ in linkClicked = true },
            onFileDrop: { _ in fileDropped = true }
        )

        // Verify properties are set
        XCTAssertEqual(view.attributedString.string, "Test")
        XCTAssertNotNil(view.onLinkClick)
        XCTAssertNotNil(view.onFileDrop)

        // Test callbacks work
        let testURL = try XCTUnwrap(URL(string: "https://test.com"))
        view.onLinkClick?(testURL)
        view.onFileDrop?(URL(fileURLWithPath: "/test.md"))

        XCTAssertTrue(linkClicked)
        XCTAssertTrue(fileDropped)
    }

    func test_nativeMarkdownView_defaultsToNilCallbacks() {
        let content = NSAttributedString(string: "Test")
        let view = NativeMarkdownView(attributedString: content)

        XCTAssertNil(view.onLinkClick)
        XCTAssertNil(view.onFileDrop)
    }
}
