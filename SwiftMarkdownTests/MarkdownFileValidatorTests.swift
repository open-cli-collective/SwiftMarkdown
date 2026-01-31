import XCTest
@testable import SwiftMarkdownCore

final class MarkdownFileValidatorTests: XCTestCase {
    // MARK: - Test File Setup

    // swiftlint:disable:next implicitly_unwrapped_optional
    private var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    private func createTempFile(name: String, contents: Data) -> URL {
        let url = tempDirectory.appendingPathComponent(name)
        try? contents.write(to: url)
        return url
    }

    // MARK: - isMarkdownFile Tests (Extension-Only)

    func testIsMarkdownFileWithMdExtension() {
        let url = URL(fileURLWithPath: "/path/to/file.md")
        XCTAssertTrue(MarkdownFileValidator.isMarkdownFile(url))
    }

    func testIsMarkdownFileWithMarkdownExtension() {
        let url = URL(fileURLWithPath: "/path/to/file.markdown")
        XCTAssertTrue(MarkdownFileValidator.isMarkdownFile(url))
    }

    func testIsMarkdownFileWithMdownExtension() {
        let url = URL(fileURLWithPath: "/path/to/file.mdown")
        XCTAssertTrue(MarkdownFileValidator.isMarkdownFile(url))
    }

    func testIsMarkdownFileWithMkdnExtension() {
        let url = URL(fileURLWithPath: "/path/to/file.mkdn")
        XCTAssertTrue(MarkdownFileValidator.isMarkdownFile(url))
    }

    func testIsMarkdownFileWithMkdExtension() {
        let url = URL(fileURLWithPath: "/path/to/file.mkd")
        XCTAssertTrue(MarkdownFileValidator.isMarkdownFile(url))
    }

    func testIsMarkdownFileIsCaseInsensitive() {
        XCTAssertTrue(MarkdownFileValidator.isMarkdownFile(URL(fileURLWithPath: "/path/to/FILE.MD")))
        XCTAssertTrue(MarkdownFileValidator.isMarkdownFile(URL(fileURLWithPath: "/path/to/File.Markdown")))
        XCTAssertTrue(MarkdownFileValidator.isMarkdownFile(URL(fileURLWithPath: "/path/to/README.MDOWN")))
    }

    func testIsMarkdownFileReturnsFalseForTextFile() {
        let url = URL(fileURLWithPath: "/path/to/file.txt")
        XCTAssertFalse(MarkdownFileValidator.isMarkdownFile(url))
    }

    func testIsMarkdownFileReturnsFalseForHtmlFile() {
        let url = URL(fileURLWithPath: "/path/to/file.html")
        XCTAssertFalse(MarkdownFileValidator.isMarkdownFile(url))
    }

    func testIsMarkdownFileReturnsFalseForPdfFile() {
        let url = URL(fileURLWithPath: "/path/to/document.pdf")
        XCTAssertFalse(MarkdownFileValidator.isMarkdownFile(url))
    }

    func testIsMarkdownFileReturnsFalseForNoExtension() {
        let url = URL(fileURLWithPath: "/path/to/README")
        XCTAssertFalse(MarkdownFileValidator.isMarkdownFile(url))
    }

    func testIsMarkdownFileReturnsFalseForSimilarExtension() {
        // .mdx is not in the supported list
        let url = URL(fileURLWithPath: "/path/to/file.mdx")
        XCTAssertFalse(MarkdownFileValidator.isMarkdownFile(url))
    }

    // MARK: - supportedExtensions Tests

    func testSupportedExtensionsContainsExpectedValues() {
        let expected: Set<String> = ["md", "markdown", "mdown", "mkdn", "mkd"]
        XCTAssertEqual(MarkdownFileValidator.supportedExtensions, expected)
    }

    // MARK: - validate Tests (Content-Aware)

    func testValidateReturnsValidForTextMarkdown() {
        let content = "# Hello World\n\nThis is **markdown**."
        let url = createTempFile(name: "test.md", contents: Data(content.utf8))

        let result = MarkdownFileValidator.validate(url)
        XCTAssertEqual(result, .valid)
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }

    func testValidateReturnsValidForEmptyFile() {
        let url = createTempFile(name: "empty.md", contents: Data())

        let result = MarkdownFileValidator.validate(url)
        XCTAssertEqual(result, .valid)
    }

    func testValidateReturnsInvalidExtensionForWrongExtension() {
        let content = "# Hello World"
        let url = createTempFile(name: "test.txt", contents: Data(content.utf8))

        let result = MarkdownFileValidator.validate(url)
        XCTAssertEqual(result, .invalidExtension)
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Not a markdown file")
    }

    func testValidateDetectsPNG() {
        // PNG magic bytes: 89 50 4E 47 0D 0A 1A 0A
        let pngData = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00])
        let url = createTempFile(name: "fake.md", contents: pngData)

        let result = MarkdownFileValidator.validate(url)
        XCTAssertEqual(result, .binaryContent(detectedType: "PNG image"))
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "This appears to be a PNG image file, not markdown")
    }

    func testValidateDetectsJPEG() {
        // JPEG magic bytes: FF D8 FF
        let jpegData = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10])
        let url = createTempFile(name: "fake.md", contents: jpegData)

        let result = MarkdownFileValidator.validate(url)
        XCTAssertEqual(result, .binaryContent(detectedType: "JPEG image"))
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "This appears to be a JPEG image file, not markdown")
    }

    func testValidateDetectsGIF() {
        // GIF magic bytes: 47 49 46 38 (GIF8)
        let gifData = Data([0x47, 0x49, 0x46, 0x38, 0x39, 0x61])
        let url = createTempFile(name: "fake.md", contents: gifData)

        let result = MarkdownFileValidator.validate(url)
        XCTAssertEqual(result, .binaryContent(detectedType: "GIF image"))
        XCTAssertFalse(result.isValid)
    }

    func testValidateDetectsPDF() {
        // PDF magic bytes: 25 50 44 46 (%PDF)
        let pdfData = Data([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E])
        let url = createTempFile(name: "fake.md", contents: pdfData)

        let result = MarkdownFileValidator.validate(url)
        XCTAssertEqual(result, .binaryContent(detectedType: "PDF document"))
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "This appears to be a PDF document file, not markdown")
    }

    func testValidateDetectsZIP() {
        // ZIP magic bytes: 50 4B 03 04
        let zipData = Data([0x50, 0x4B, 0x03, 0x04, 0x14, 0x00])
        let url = createTempFile(name: "fake.md", contents: zipData)

        let result = MarkdownFileValidator.validate(url)
        XCTAssertEqual(result, .binaryContent(detectedType: "ZIP archive"))
        XCTAssertFalse(result.isValid)
    }

    func testValidateDetectsMachO() {
        // Mach-O magic bytes: CF FA ED FE (64-bit little-endian)
        let machoData = Data([0xCF, 0xFA, 0xED, 0xFE, 0x07, 0x00])
        let url = createTempFile(name: "fake.md", contents: machoData)

        let result = MarkdownFileValidator.validate(url)
        XCTAssertEqual(result, .binaryContent(detectedType: "Mach-O binary"))
        XCTAssertFalse(result.isValid)
    }

    func testValidateDetectsELF() {
        // ELF magic bytes: 7F 45 4C 46
        let elfData = Data([0x7F, 0x45, 0x4C, 0x46, 0x02, 0x01])
        let url = createTempFile(name: "fake.md", contents: elfData)

        let result = MarkdownFileValidator.validate(url)
        XCTAssertEqual(result, .binaryContent(detectedType: "ELF binary"))
        XCTAssertFalse(result.isValid)
    }

    func testValidateDetectsBinaryWithNullBytes() {
        // Generic binary data with null bytes (not matching any magic bytes)
        let binaryData = Data([0x01, 0x02, 0x00, 0x03, 0x04, 0x00])
        let url = createTempFile(name: "fake.md", contents: binaryData)

        let result = MarkdownFileValidator.validate(url)
        XCTAssertEqual(result, .binaryContent(detectedType: nil))
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "This file contains binary data, not text")
    }

    func testValidateReturnsUnreadableForNonexistentFile() {
        let url = tempDirectory.appendingPathComponent("nonexistent.md")

        let result = MarkdownFileValidator.validate(url)
        if case .unreadable(let error) = result {
            XCTAssertFalse(error.isEmpty)
        } else {
            XCTFail("Expected unreadable result")
        }
        XCTAssertFalse(result.isValid)
    }

    func testValidateHandlesUTF8WithSpecialCharacters() {
        let content = "# Hello 世界\n\n日本語テキスト with emoji 🎉"
        let url = createTempFile(name: "unicode.md", contents: Data(content.utf8))

        let result = MarkdownFileValidator.validate(url)
        XCTAssertEqual(result, .valid)
    }

    func testValidateHandlesUTF8BOM() {
        // UTF-8 BOM: EF BB BF followed by text
        var data = Data([0xEF, 0xBB, 0xBF])
        data.append(Data("# Hello World".utf8))
        let url = createTempFile(name: "bom.md", contents: data)

        let result = MarkdownFileValidator.validate(url)
        XCTAssertEqual(result, .valid)
    }

    // MARK: - isTextContent Tests

    func testIsTextContentReturnsTrueForPlainText() {
        let data = Data("Hello, World!".utf8)
        XCTAssertTrue(MarkdownFileValidator.isTextContent(data))
    }

    func testIsTextContentReturnsTrueForUTF8() {
        let data = Data("日本語".utf8)
        XCTAssertTrue(MarkdownFileValidator.isTextContent(data))
    }

    func testIsTextContentReturnsFalseForNullBytes() {
        let data = Data([0x48, 0x65, 0x6C, 0x6C, 0x6F, 0x00, 0x57])
        XCTAssertFalse(MarkdownFileValidator.isTextContent(data))
    }

    func testIsTextContentReturnsFalseForInvalidUTF8() {
        // Invalid UTF-8 sequence
        let data = Data([0xFF, 0xFE, 0x00, 0x01])
        XCTAssertFalse(MarkdownFileValidator.isTextContent(data))
    }

    func testIsTextContentReturnsTrueForEmptyData() {
        // Empty data is valid UTF-8
        let data = Data()
        XCTAssertTrue(MarkdownFileValidator.isTextContent(data))
    }

    // MARK: - detectBinaryType Tests

    func testDetectBinaryTypeReturnsPNGForPNGData() {
        let data = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
        XCTAssertEqual(MarkdownFileValidator.detectBinaryType(data), "PNG image")
    }

    func testDetectBinaryTypeReturnsJPEGForJPEGData() {
        let data = Data([0xFF, 0xD8, 0xFF, 0xE0])
        XCTAssertEqual(MarkdownFileValidator.detectBinaryType(data), "JPEG image")
    }

    func testDetectBinaryTypeReturnsNilForTextData() {
        let data = Data("# Hello World".utf8)
        XCTAssertNil(MarkdownFileValidator.detectBinaryType(data))
    }

    func testDetectBinaryTypeReturnsNilForEmptyData() {
        let data = Data()
        XCTAssertNil(MarkdownFileValidator.detectBinaryType(data))
    }

    func testDetectBinaryTypeReturnsNilForPartialSignature() {
        // Only first 2 bytes of PNG signature
        let data = Data([0x89, 0x50])
        XCTAssertNil(MarkdownFileValidator.detectBinaryType(data))
    }

    // MARK: - MarkdownValidationResult Tests

    func testValidationResultIsValidReturnsCorrectValues() {
        XCTAssertTrue(MarkdownValidationResult.valid.isValid)
        XCTAssertFalse(MarkdownValidationResult.invalidExtension.isValid)
        XCTAssertFalse(MarkdownValidationResult.binaryContent(detectedType: "PNG").isValid)
        XCTAssertFalse(MarkdownValidationResult.binaryContent(detectedType: nil).isValid)
        XCTAssertFalse(MarkdownValidationResult.unreadable(error: "test").isValid)
    }

    func testValidationResultErrorMessageReturnsCorrectValues() {
        XCTAssertNil(MarkdownValidationResult.valid.errorMessage)
        XCTAssertEqual(MarkdownValidationResult.invalidExtension.errorMessage, "Not a markdown file")
        XCTAssertEqual(
            MarkdownValidationResult.binaryContent(detectedType: "PNG image").errorMessage,
            "This appears to be a PNG image file, not markdown"
        )
        XCTAssertEqual(
            MarkdownValidationResult.binaryContent(detectedType: nil).errorMessage,
            "This file contains binary data, not text"
        )
        XCTAssertEqual(
            MarkdownValidationResult.unreadable(error: "test error").errorMessage,
            "Could not read file: test error"
        )
    }

    func testValidationResultEquality() {
        XCTAssertEqual(MarkdownValidationResult.valid, MarkdownValidationResult.valid)
        XCTAssertEqual(MarkdownValidationResult.invalidExtension, MarkdownValidationResult.invalidExtension)
        XCTAssertEqual(
            MarkdownValidationResult.binaryContent(detectedType: "PNG"),
            MarkdownValidationResult.binaryContent(detectedType: "PNG")
        )
        XCTAssertNotEqual(
            MarkdownValidationResult.binaryContent(detectedType: "PNG"),
            MarkdownValidationResult.binaryContent(detectedType: "JPEG")
        )
        XCTAssertNotEqual(
            MarkdownValidationResult.valid,
            MarkdownValidationResult.invalidExtension
        )
    }
}
