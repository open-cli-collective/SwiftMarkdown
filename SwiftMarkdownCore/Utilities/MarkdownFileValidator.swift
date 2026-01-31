import Foundation

/// Result of validating a file as markdown.
public enum MarkdownValidationResult: Equatable, Sendable {
    /// File appears to be valid markdown (text content with markdown extension).
    case valid
    /// File has a markdown extension but contains binary data.
    case binaryContent(detectedType: String?)
    /// File does not have a markdown extension.
    case invalidExtension
    /// File could not be read.
    case unreadable(error: String)

    /// Returns true if the validation result indicates a valid markdown file.
    public var isValid: Bool {
        if case .valid = self { return true }
        return false
    }

    /// Returns a user-friendly error message, or nil if valid.
    public var errorMessage: String? {
        switch self {
        case .valid:
            return nil
        case .binaryContent(let detectedType):
            if let type = detectedType {
                return "This appears to be a \(type) file, not markdown"
            }
            return "This file contains binary data, not text"
        case .invalidExtension:
            return "Not a markdown file"
        case .unreadable(let error):
            return "Could not read file: \(error)"
        }
    }
}

/// Utilities for validating markdown files.
public enum MarkdownFileValidator {
    /// Supported file extensions for markdown files.
    public static let supportedExtensions: Set<String> = ["md", "markdown", "mdown", "mkdn", "mkd"]

    /// Number of bytes to read for content validation.
    /// 8KB is enough to detect binary content and magic bytes.
    private static let sampleSize = 8192

    /// Magic byte signatures for common binary formats.
    private static let magicBytes: [(signature: [UInt8], name: String)] = [
        ([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A], "PNG image"),
        ([0xFF, 0xD8, 0xFF], "JPEG image"),
        ([0x47, 0x49, 0x46, 0x38], "GIF image"),
        ([0x25, 0x50, 0x44, 0x46], "PDF document"),
        ([0x50, 0x4B, 0x03, 0x04], "ZIP archive"),
        ([0xCF, 0xFA, 0xED, 0xFE], "Mach-O binary"),
        ([0xFE, 0xED, 0xFA, 0xCF], "Mach-O binary"),
        ([0xFE, 0xED, 0xFA, 0xCE], "Mach-O binary"),
        ([0xCE, 0xFA, 0xED, 0xFE], "Mach-O binary"),
        ([0x7F, 0x45, 0x4C, 0x46], "ELF binary"),
        ([0x52, 0x49, 0x46, 0x46], "RIFF container"),  // WebP, WAV, AVI
        ([0x00, 0x00, 0x00, 0x0C, 0x6A, 0x50], "JPEG 2000 image"),
        ([0x49, 0x44, 0x33], "MP3 audio"),  // ID3 tag
        ([0xFF, 0xFB], "MP3 audio"),
        ([0xFF, 0xFA], "MP3 audio"),
        ([0x4F, 0x67, 0x67, 0x53], "OGG container"),
        ([0x66, 0x4C, 0x61, 0x43], "FLAC audio"),
        ([0x1A, 0x45, 0xDF, 0xA3], "WebM/MKV video"),
        ([0x00, 0x00, 0x00], "possibly MP4/MOV")  // Needs more context but catches most
    ]

    /// Check if a URL points to a valid markdown file based on extension only.
    /// For content-aware validation, use `validate(_:)` instead.
    public static func isMarkdownFile(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return supportedExtensions.contains(ext)
    }

    /// Validates a file as markdown by checking both extension and content.
    ///
    /// This method:
    /// 1. Checks the file extension is a valid markdown extension
    /// 2. Reads the first 8KB of the file
    /// 3. Checks for binary content (null bytes, invalid UTF-8, or known binary magic bytes)
    ///
    /// - Parameter url: The file URL to validate.
    /// - Returns: A validation result indicating whether the file is valid markdown.
    public static func validate(_ url: URL) -> MarkdownValidationResult {
        // First check extension
        guard isMarkdownFile(url) else {
            return .invalidExtension
        }

        // Read sample of file content
        let data: Data
        do {
            let handle = try FileHandle(forReadingFrom: url)
            defer { try? handle.close() }
            data = handle.readData(ofLength: sampleSize)
        } catch {
            return .unreadable(error: error.localizedDescription)
        }

        // Empty files are valid (edge case but allowed)
        if data.isEmpty {
            return .valid
        }

        // Check for known binary formats by magic bytes
        if let binaryType = detectBinaryType(data) {
            return .binaryContent(detectedType: binaryType)
        }

        // Check if content is valid UTF-8 text
        if !isTextContent(data) {
            return .binaryContent(detectedType: nil)
        }

        return .valid
    }

    /// Checks if data appears to be valid UTF-8 text content.
    ///
    /// Detects binary content by:
    /// - Checking for null bytes (common in binary formats)
    /// - Verifying the data can be decoded as valid UTF-8
    ///
    /// - Parameter data: The data to check.
    /// - Returns: `true` if the data appears to be text, `false` if binary.
    public static func isTextContent(_ data: Data) -> Bool {
        // Check for null bytes (strong indicator of binary)
        if data.contains(0x00) {
            return false
        }

        // Try to decode as UTF-8
        return String(data: data, encoding: .utf8) != nil
    }

    /// Attempts to identify a binary file type from its magic bytes.
    ///
    /// - Parameter data: The file data to check.
    /// - Returns: The detected file type name, or `nil` if no known type matched.
    public static func detectBinaryType(_ data: Data) -> String? {
        let bytes = [UInt8](data)

        for (signature, name) in magicBytes where bytes.count >= signature.count {
            let prefix = Array(bytes.prefix(signature.count))
            if prefix == signature {
                return name
            }
        }

        return nil
    }
}
