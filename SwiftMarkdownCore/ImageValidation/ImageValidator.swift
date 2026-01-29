import Foundation
import FileType

/// Result of validating an image's MIME type against its actual content.
public enum ImageValidationResult: Equatable {
    /// The image data matches the declared MIME type.
    case valid(detectedMime: String)
    /// The declared MIME type doesn't match the actual content.
    case mismatch(declared: String, detected: String)
    /// The image format could not be recognized from the data.
    case unrecognized
    /// The data could not be decoded (e.g., invalid base64).
    case invalidData
}

/// Validates embedded images in data URIs by checking magic bytes.
///
/// Uses the FileType library to detect actual image format from binary data
/// and compares against the declared MIME type in data URIs.
///
/// ## Example
/// ```swift
/// let dataURI = "data:image/png;base64,iVBORw0KGgo..."
/// let result = ImageValidator.validate(dataURI: dataURI)
/// switch result {
/// case .valid(let mime):
///     print("Valid \(mime) image")
/// case .mismatch(let declared, let detected):
///     print("Declared \(declared) but actually \(detected)")
/// case .unrecognized:
///     print("Unknown image format")
/// case .invalidData:
///     print("Could not decode data")
/// }
/// ```
public struct ImageValidator {
    /// MIME types that represent images we can validate.
    public static let supportedImageMimes: Set<String> = [
        "image/jpeg",
        "image/png",
        "image/gif",
        "image/webp",
        "image/bmp",
        "image/tiff",
        "image/avif",
        "image/heic",
        "image/x-icon",
        "image/vnd.microsoft.icon",
        "image/apng"
    ]

    /// Parses a data URI and validates that the declared MIME type matches the actual content.
    ///
    /// - Parameter dataURI: A data URI string (e.g., `data:image/png;base64,iVBORw0...`)
    /// - Returns: The validation result indicating whether the image is valid, mismatched, etc.
    public static func validate(dataURI: String) -> ImageValidationResult {
        guard let parsed = parseDataURI(dataURI) else {
            return .invalidData
        }

        return validate(data: parsed.data, declaredMime: parsed.mimeType)
    }

    /// Validates that image data matches a declared MIME type.
    ///
    /// - Parameters:
    ///   - data: The raw image data bytes.
    ///   - declaredMime: The MIME type that was declared (e.g., in a data URI).
    /// - Returns: The validation result.
    public static func validate(data: Data, declaredMime: String) -> ImageValidationResult {
        guard let fileType = FileType.getFor(data: data) else {
            return .unrecognized
        }

        let detectedMime = fileType.mime
        let normalizedDeclared = normalizeMime(declaredMime)
        let normalizedDetected = normalizeMime(detectedMime)

        if normalizedDeclared == normalizedDetected {
            return .valid(detectedMime: detectedMime)
        } else {
            return .mismatch(declared: declaredMime, detected: detectedMime)
        }
    }

    /// Checks if a string appears to be a data URI.
    ///
    /// - Parameter string: The string to check.
    /// - Returns: `true` if the string starts with `data:`.
    public static func isDataURI(_ string: String) -> Bool {
        string.lowercased().hasPrefix("data:")
    }

    /// Checks if a MIME type represents an image we can validate.
    ///
    /// - Parameter mime: The MIME type to check.
    /// - Returns: `true` if this is a supported image MIME type.
    public static func isImageMime(_ mime: String) -> Bool {
        let normalized = normalizeMime(mime)
        return supportedImageMimes.contains(normalized) || normalized.hasPrefix("image/")
    }

    // MARK: - Private

    private struct ParsedDataURI {
        let mimeType: String
        let data: Data
    }

    /// Parses a data URI into its components.
    ///
    /// Supports format: `data:[<mediatype>][;base64],<data>`
    private static func parseDataURI(_ uri: String) -> ParsedDataURI? {
        // Must start with "data:"
        guard uri.lowercased().hasPrefix("data:") else {
            return nil
        }

        // Find the comma that separates metadata from data
        guard let commaIndex = uri.firstIndex(of: ",") else {
            return nil
        }

        let metadataStart = uri.index(uri.startIndex, offsetBy: 5) // Skip "data:"
        let metadata = String(uri[metadataStart..<commaIndex])
        let dataStart = uri.index(after: commaIndex)
        let encodedData = String(uri[dataStart...])

        // Parse metadata: [<mediatype>][;base64]
        let parts = metadata.split(separator: ";", omittingEmptySubsequences: false)
        let mimeType = parts.isEmpty || parts[0].isEmpty ? "text/plain" : String(parts[0])
        let isBase64 = parts.contains { $0.lowercased() == "base64" }

        // Decode the data
        let data: Data?
        if isBase64 {
            // Handle URL-safe base64 and padding
            var base64String = encodedData
                .replacingOccurrences(of: "-", with: "+")
                .replacingOccurrences(of: "_", with: "/")

            // Add padding if needed
            let remainder = base64String.count % 4
            if remainder > 0 {
                base64String += String(repeating: "=", count: 4 - remainder)
            }

            data = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters)
        } else {
            // URL-encoded data
            data = encodedData.removingPercentEncoding?.data(using: .utf8)
        }

        guard let decodedData = data else {
            return nil
        }

        return ParsedDataURI(mimeType: mimeType, data: decodedData)
    }

    /// Normalizes a MIME type for comparison.
    ///
    /// Handles common variations like `image/jpg` vs `image/jpeg`.
    private static func normalizeMime(_ mime: String) -> String {
        var normalized = mime.lowercased().trimmingCharacters(in: .whitespaces)

        // Common MIME type aliases
        let aliases: [String: String] = [
            "image/jpg": "image/jpeg",
            "image/tif": "image/tiff",
            "image/ico": "image/x-icon",
            "image/vnd.microsoft.icon": "image/x-icon"
        ]

        if let canonical = aliases[normalized] {
            normalized = canonical
        }

        return normalized
    }
}
