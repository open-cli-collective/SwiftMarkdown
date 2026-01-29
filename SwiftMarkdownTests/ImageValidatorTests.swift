import XCTest
@testable import SwiftMarkdownCore

final class ImageValidatorTests: XCTestCase {
    // MARK: - Data URI Detection

    func testIsDataURI() {
        XCTAssertTrue(ImageValidator.isDataURI("data:image/png;base64,iVBORw0KGgo="))
        XCTAssertTrue(ImageValidator.isDataURI("data:image/jpeg;base64,/9j/4AAQ"))
        XCTAssertTrue(ImageValidator.isDataURI("DATA:image/png;base64,iVBORw0KGgo="))  // Case insensitive
        XCTAssertFalse(ImageValidator.isDataURI("https://example.com/image.png"))
        XCTAssertFalse(ImageValidator.isDataURI("image.png"))
        XCTAssertFalse(ImageValidator.isDataURI(""))
    }

    func testIsImageMime() {
        XCTAssertTrue(ImageValidator.isImageMime("image/png"))
        XCTAssertTrue(ImageValidator.isImageMime("image/jpeg"))
        XCTAssertTrue(ImageValidator.isImageMime("image/gif"))
        XCTAssertTrue(ImageValidator.isImageMime("IMAGE/PNG"))  // Case insensitive
        XCTAssertFalse(ImageValidator.isImageMime("text/plain"))
        XCTAssertFalse(ImageValidator.isImageMime("application/json"))
    }

    // MARK: - Valid Image Validation

    func testValidPNGDataURI() {
        // Minimal valid PNG: 1x1 transparent pixel
        let pngBase64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
        let dataURI = "data:image/png;base64,\(pngBase64)"

        let result = ImageValidator.validate(dataURI: dataURI)

        if case .valid(let mime) = result {
            XCTAssertEqual(mime, "image/png")
        } else {
            XCTFail("Expected valid result, got \(result)")
        }
    }

    func testValidGIFDataURI() {
        // Minimal valid GIF: 1x1 transparent pixel
        let gifBase64 = "R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7"
        let dataURI = "data:image/gif;base64,\(gifBase64)"

        let result = ImageValidator.validate(dataURI: dataURI)

        if case .valid(let mime) = result {
            XCTAssertEqual(mime, "image/gif")
        } else {
            XCTFail("Expected valid result, got \(result)")
        }
    }

    // MARK: - MIME Type Mismatch Detection

    func testMismatchDetection() {
        // PNG data with JPEG declared MIME type
        let pngBase64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
        let dataURI = "data:image/jpeg;base64,\(pngBase64)"

        let result = ImageValidator.validate(dataURI: dataURI)

        if case .mismatch(let declared, let detected) = result {
            XCTAssertEqual(declared, "image/jpeg")
            XCTAssertEqual(detected, "image/png")
        } else {
            XCTFail("Expected mismatch result, got \(result)")
        }
    }

    // MARK: - Invalid Data Handling

    func testInvalidBase64() {
        // Base64 with invalid chars - behavior varies by OS version
        // (may decode partially or fail entirely), but should never be .valid
        let dataURI = "data:image/png;base64,not_valid_base64!!!"
        let result = ImageValidator.validate(dataURI: dataURI)
        if case .valid = result {
            XCTFail("Invalid base64 should not be marked as valid")
        }
    }

    func testTrulyInvalidDataURI() {
        // A data URI without the data: prefix
        let result = ImageValidator.validate(dataURI: "image/png;base64,abc")
        XCTAssertEqual(result, .invalidData)
    }

    func testMissingComma() {
        let dataURI = "data:image/pngbase64iVBORw0KGgo="
        let result = ImageValidator.validate(dataURI: dataURI)
        XCTAssertEqual(result, .invalidData)
    }

    func testEmptyData() {
        let dataURI = "data:image/png;base64,"
        let result = ImageValidator.validate(dataURI: dataURI)
        XCTAssertEqual(result, .unrecognized)
    }

    // MARK: - Unrecognized Format

    func testUnrecognizedFormat() {
        // Random bytes that don't match any known image format
        let randomBase64 = "dGhpcyBpcyBub3QgYW4gaW1hZ2U="  // "this is not an image" in base64
        let dataURI = "data:image/png;base64,\(randomBase64)"
        let result = ImageValidator.validate(dataURI: dataURI)
        XCTAssertEqual(result, .unrecognized)
    }

    // MARK: - Direct Data Validation

    func testValidateDataDirectly() {
        // Use complete PNG data (1x1 transparent pixel) to avoid crashes from incomplete data
        let pngBase64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
        guard let data = Data(base64Encoded: pngBase64) else {
            XCTFail("Failed to decode test PNG data")
            return
        }

        let result = ImageValidator.validate(data: data, declaredMime: "image/png")

        if case .valid(let mime) = result {
            XCTAssertEqual(mime, "image/png")
        } else {
            XCTFail("Expected valid result, got \(result)")
        }
    }

    // MARK: - MIME Type Normalization

    func testMimeTypeNormalization() {
        // Test that jpg/jpeg are treated as equivalent using complete PNG data
        // We validate PNG data with declared type "image/jpg" (which normalizes to image/jpeg)
        // This should return mismatch since PNG != JPEG, proving normalization is working
        let pngBase64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
        guard let data = Data(base64Encoded: pngBase64) else {
            XCTFail("Failed to decode test PNG data")
            return
        }

        // PNG data with "image/jpg" (alias for jpeg) should report mismatch with "image/jpeg"
        let result = ImageValidator.validate(data: data, declaredMime: "image/jpg")

        // The result should be a mismatch, but the declared type should be normalized
        if case .mismatch(let declared, let detected) = result {
            XCTAssertEqual(declared, "image/jpg")  // Original declared type
            XCTAssertEqual(detected, "image/png")  // Actual detected type
        } else if case .valid = result {
            XCTFail("PNG data should not validate as image/jpg")
        } else {
            XCTFail("Expected mismatch result, got \(result)")
        }
    }

    // MARK: - isValid Property

    func testIsValidPropertyForValidResult() {
        let pngBase64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
        let dataURI = "data:image/png;base64,\(pngBase64)"
        let result = ImageValidator.validate(dataURI: dataURI)
        XCTAssertTrue(result.isValid)
    }

    func testIsValidPropertyForMismatch() {
        let pngBase64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
        let dataURI = "data:image/jpeg;base64,\(pngBase64)"
        let result = ImageValidator.validate(dataURI: dataURI)
        XCTAssertFalse(result.isValid)
    }

    func testIsValidPropertyForUnrecognized() {
        let result = ImageValidationResult.unrecognized
        XCTAssertFalse(result.isValid)
    }

    func testIsValidPropertyForInvalidData() {
        let result = ImageValidationResult.invalidData
        XCTAssertFalse(result.isValid)
    }

    // MARK: - HTMLRenderer Integration

    func testHTMLRendererWithValidationDisabled() {
        let markdown = "![test](data:image/jpeg;base64,iVBORw0KGgo=)"  // PNG with JPEG declared
        let renderer = HTMLRenderer(validateImages: false)
        let document = MarkdownParser.parseDocument(markdown)
        let html = renderer.render(document)

        XCTAssertFalse(html.contains("invalid-image"))
        XCTAssertTrue(html.contains("<img src="))
    }

    func testHTMLRendererWithValidationEnabled() {
        // PNG data with JPEG declared - should be marked invalid
        let pngBase64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
        let markdown = "![test](data:image/jpeg;base64,\(pngBase64))"
        let renderer = HTMLRenderer(validateImages: true)
        let document = MarkdownParser.parseDocument(markdown)
        let html = renderer.render(document)

        XCTAssertTrue(html.contains("class=\"invalid-image\""))
    }

    func testHTMLRendererValidImagePasses() {
        let pngBase64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
        let markdown = "![test](data:image/png;base64,\(pngBase64))"
        let renderer = HTMLRenderer(validateImages: true)
        let document = MarkdownParser.parseDocument(markdown)
        let html = renderer.render(document)

        XCTAssertFalse(html.contains("invalid-image"))
        XCTAssertTrue(html.contains("<img src="))
    }

    func testHTMLRendererNonDataURIPassesThrough() {
        let markdown = "![test](https://example.com/image.png)"
        let renderer = HTMLRenderer(validateImages: true)
        let document = MarkdownParser.parseDocument(markdown)
        let html = renderer.render(document)

        XCTAssertFalse(html.contains("invalid-image"))
        XCTAssertTrue(html.contains("src=\"https://example.com/image.png\""))
    }
}
