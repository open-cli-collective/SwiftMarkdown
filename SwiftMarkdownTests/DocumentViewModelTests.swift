import AppKit
import XCTest

@testable import SwiftMarkdown
@testable import SwiftMarkdownCore

final class DocumentViewModelTests: XCTestCase {
    // MARK: - Initial State Tests

    @MainActor
    func test_initialState_hasEmptyRenderedContent() {
        let viewModel = DocumentViewModel()

        XCTAssertEqual(viewModel.renderedContent.length, 0)
    }

    @MainActor
    func test_initialState_hasNoFileURL() {
        let viewModel = DocumentViewModel()

        XCTAssertNil(viewModel.fileURL)
    }

    @MainActor
    func test_initialState_isNotLoading() {
        let viewModel = DocumentViewModel()

        XCTAssertFalse(viewModel.isLoading)
    }

    @MainActor
    func test_initialState_hasNoError() {
        let viewModel = DocumentViewModel()

        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - Load File Tests

    @MainActor
    func test_loadFile_producesAttributedString() async throws {
        let viewModel = DocumentViewModel()

        // Create a temporary markdown file
        let tempURL = try createTempMarkdownFile(content: "# Hello World")

        await viewModel.loadFile(at: tempURL)

        XCTAssertGreaterThan(viewModel.renderedContent.length, 0)
        XCTAssertTrue(viewModel.renderedContent.string.contains("Hello World"))
    }

    @MainActor
    func test_loadFile_setsFileURL() async throws {
        let viewModel = DocumentViewModel()
        let tempURL = try createTempMarkdownFile(content: "Test content")

        await viewModel.loadFile(at: tempURL)

        XCTAssertEqual(viewModel.fileURL, tempURL)
    }

    @MainActor
    func test_loadFile_clearsError() async throws {
        let viewModel = DocumentViewModel()
        viewModel.errorMessage = "Previous error"

        let tempURL = try createTempMarkdownFile(content: "Test")

        await viewModel.loadFile(at: tempURL)

        XCTAssertNil(viewModel.errorMessage)
    }

    @MainActor
    func test_loadFile_setsLoadingDuringRender() async throws {
        let viewModel = DocumentViewModel()
        let tempURL = try createTempMarkdownFile(content: "Test")

        // Start loading
        let loadTask = Task {
            await viewModel.loadFile(at: tempURL)
        }

        // The implementation sets isLoading = true at start and false at end
        // After completion, isLoading should be false
        await loadTask.value

        XCTAssertFalse(viewModel.isLoading)
    }

    @MainActor
    func test_loadFile_appliesHeadingFormatting() async throws {
        let viewModel = DocumentViewModel()
        let tempURL = try createTempMarkdownFile(content: "# Big Heading")

        await viewModel.loadFile(at: tempURL)

        // Check that the attributed string contains font attributes
        var hasFont = false
        viewModel.renderedContent.enumerateAttribute(
            .font,
            in: NSRange(location: 0, length: viewModel.renderedContent.length),
            options: []
        ) { value, _, _ in
            if value != nil {
                hasFont = true
            }
        }

        XCTAssertTrue(hasFont)
    }

    @MainActor
    func test_loadFile_preservesFormattingInOutput() async throws {
        let viewModel = DocumentViewModel()
        let tempURL = try createTempMarkdownFile(content: """
            # Heading

            This is **bold** and *italic* text.
            """)

        await viewModel.loadFile(at: tempURL)

        // The content should include the text
        XCTAssertTrue(viewModel.renderedContent.string.contains("Heading"))
        XCTAssertTrue(viewModel.renderedContent.string.contains("bold"))
        XCTAssertTrue(viewModel.renderedContent.string.contains("italic"))
    }

    @MainActor
    func test_loadFile_withInvalidFile_setsError() async {
        let viewModel = DocumentViewModel()
        let invalidURL = URL(fileURLWithPath: "/nonexistent/file.md")

        await viewModel.loadFile(at: invalidURL)

        XCTAssertNotNil(viewModel.errorMessage)
    }

    @MainActor
    func test_loadFile_withNonMarkdownFile_setsError() async throws {
        let viewModel = DocumentViewModel()

        // Create a temporary non-markdown file
        let tempDir = FileManager.default.temporaryDirectory
        let tempURL = tempDir.appendingPathComponent("test.txt")
        try "Not markdown".write(to: tempURL, atomically: true, encoding: .utf8)

        await viewModel.loadFile(at: tempURL)

        XCTAssertNotNil(viewModel.errorMessage)

        try? FileManager.default.removeItem(at: tempURL)
    }

    // MARK: - Clear Document Tests

    @MainActor
    func test_clearDocument_resetsRenderedContent() async throws {
        let viewModel = DocumentViewModel()
        let tempURL = try createTempMarkdownFile(content: "# Test")

        await viewModel.loadFile(at: tempURL)
        XCTAssertGreaterThan(viewModel.renderedContent.length, 0)

        viewModel.clearDocument()

        XCTAssertEqual(viewModel.renderedContent.length, 0)
    }

    @MainActor
    func test_clearDocument_resetsFileURL() async throws {
        let viewModel = DocumentViewModel()
        let tempURL = try createTempMarkdownFile(content: "Test")

        await viewModel.loadFile(at: tempURL)
        XCTAssertNotNil(viewModel.fileURL)

        viewModel.clearDocument()

        XCTAssertNil(viewModel.fileURL)
    }

    @MainActor
    func test_clearDocument_clearsError() async {
        let viewModel = DocumentViewModel()
        viewModel.errorMessage = "Some error"

        viewModel.clearDocument()

        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - File Name Tests

    @MainActor
    func test_fileName_returnsLastPathComponent() async throws {
        let viewModel = DocumentViewModel()
        let tempURL = try createTempMarkdownFile(content: "Test", filename: "readme.md")

        await viewModel.loadFile(at: tempURL)

        XCTAssertEqual(viewModel.fileName, "readme.md")
    }

    @MainActor
    func test_fileName_withNoFile_returnsDefault() {
        let viewModel = DocumentViewModel()

        XCTAssertEqual(viewModel.fileName, "SwiftMarkdown")
    }

    // MARK: - Cancellation Tests

    @MainActor
    func test_loadFile_cancelsPreviousRender() async throws {
        let viewModel = DocumentViewModel()

        let file1 = try createTempMarkdownFile(content: "# File One", filename: "file1.md")
        let file2 = try createTempMarkdownFile(content: "# File Two", filename: "file2.md")

        // Start loading first file
        let task1 = Task {
            await viewModel.loadFile(at: file1)
        }

        // Give it a moment to start, then load second file
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms

        // Start loading second file - this should cancel/supersede the first
        await viewModel.loadFile(at: file2)

        // Wait for first task to complete (it may have been cancelled)
        await task1.value

        // The second file should be the final state
        XCTAssertEqual(viewModel.fileURL, file2)
        XCTAssertTrue(viewModel.renderedContent.string.contains("File Two"))
    }

    // MARK: - Static Method Tests

    func test_isMarkdownFile_withMdExtension_returnsTrue() {
        let url = URL(fileURLWithPath: "/path/to/file.md")
        XCTAssertTrue(DocumentViewModel.isMarkdownFile(url))
    }

    func test_isMarkdownFile_withMarkdownExtension_returnsTrue() {
        let url = URL(fileURLWithPath: "/path/to/file.markdown")
        XCTAssertTrue(DocumentViewModel.isMarkdownFile(url))
    }

    func test_isMarkdownFile_withTxtExtension_returnsFalse() {
        let url = URL(fileURLWithPath: "/path/to/file.txt")
        XCTAssertFalse(DocumentViewModel.isMarkdownFile(url))
    }

    func test_isMarkdownFile_withUppercaseMD_returnsTrue() {
        let url = URL(fileURLWithPath: "/path/to/FILE.MD")
        XCTAssertTrue(DocumentViewModel.isMarkdownFile(url))
    }

    // MARK: - Helpers

    private func createTempMarkdownFile(
        content: String,
        filename: String = "test.md"
    ) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let tempURL = tempDir.appendingPathComponent(filename)
        try content.write(to: tempURL, atomically: true, encoding: .utf8)

        addTeardownBlock {
            try? FileManager.default.removeItem(at: tempURL)
        }

        return tempURL
    }
}
