import XCTest
@testable import SwiftMarkdownCore

final class GrammarManifestTests: XCTestCase {
    // MARK: - Parsing Tests

    func testParseValidManifest() throws {
        let json = """
        {
            "version": "1.0.0",
            "generatedAt": "2026-01-29T12:00:00Z",
            "grammars": {
                "javascript": {
                    "displayName": "JavaScript",
                    "version": "v0.23.1",
                    "license": "MIT",
                    "aliases": ["js", "jsx"],
                    "checksum": "abc123",
                    "size": 791664
                }
            }
        }
        """

        let manifest = try GrammarManifest.parse(from: json)

        XCTAssertEqual(manifest.version, "1.0.0")
        XCTAssertEqual(manifest.generatedAt, "2026-01-29T12:00:00Z")
        XCTAssertEqual(manifest.grammars.count, 1)

        let jsInfo = manifest.grammars["javascript"]
        XCTAssertNotNil(jsInfo)
        XCTAssertEqual(jsInfo?.displayName, "JavaScript")
        XCTAssertEqual(jsInfo?.version, "v0.23.1")
        XCTAssertEqual(jsInfo?.license, "MIT")
        XCTAssertEqual(jsInfo?.aliases, ["js", "jsx"])
        XCTAssertEqual(jsInfo?.checksum, "abc123")
        XCTAssertEqual(jsInfo?.size, 791664)
    }

    func testParseMultipleGrammars() throws {
        let json = """
        {
            "version": "1.0.0",
            "generatedAt": "2026-01-29T12:00:00Z",
            "grammars": {
                "javascript": {
                    "displayName": "JavaScript",
                    "version": "v0.23.1",
                    "license": "MIT",
                    "aliases": ["js"],
                    "checksum": "abc",
                    "size": 100
                },
                "python": {
                    "displayName": "Python",
                    "version": "v0.23.6",
                    "license": "MIT",
                    "aliases": ["py"],
                    "checksum": "def",
                    "size": 200
                }
            }
        }
        """

        let manifest = try GrammarManifest.parse(from: json)

        XCTAssertEqual(manifest.grammars.count, 2)
        XCTAssertNotNil(manifest.grammars["javascript"])
        XCTAssertNotNil(manifest.grammars["python"])
    }

    func testParseEmptyGrammars() throws {
        let json = """
        {
            "version": "1.0.0",
            "generatedAt": "2026-01-29T12:00:00Z",
            "grammars": {}
        }
        """

        let manifest = try GrammarManifest.parse(from: json)

        XCTAssertEqual(manifest.grammars.count, 0)
    }

    func testParseInvalidJSON() {
        let invalidJSON = "not valid json"

        XCTAssertThrowsError(try GrammarManifest.parse(from: invalidJSON)) { error in
            if case GrammarError.manifestParseError = error {
                // Expected error
            } else {
                XCTFail("Expected manifestParseError, got \(error)")
            }
        }
    }

    func testParseMissingRequiredField() {
        let json = """
        {
            "version": "1.0.0"
        }
        """

        XCTAssertThrowsError(try GrammarManifest.parse(from: json))
    }

    // MARK: - Canonical Name Tests

    func testCanonicalNameDirectMatch() throws {
        let manifest = try makeManifest(grammars: [
            "javascript": GrammarInfo(
                displayName: "JavaScript",
                version: "v1.0.0",
                license: "MIT",
                aliases: ["js"],
                checksum: "abc",
                size: 100
            )
        ])

        XCTAssertEqual(manifest.canonicalName(for: "javascript"), "javascript")
    }

    func testCanonicalNameAlias() throws {
        let manifest = try makeManifest(grammars: [
            "javascript": GrammarInfo(
                displayName: "JavaScript",
                version: "v1.0.0",
                license: "MIT",
                aliases: ["js", "jsx"],
                checksum: "abc",
                size: 100
            )
        ])

        XCTAssertEqual(manifest.canonicalName(for: "js"), "javascript")
        XCTAssertEqual(manifest.canonicalName(for: "jsx"), "javascript")
    }

    func testCanonicalNameCaseInsensitive() throws {
        let manifest = try makeManifest(grammars: [
            "javascript": GrammarInfo(
                displayName: "JavaScript",
                version: "v1.0.0",
                license: "MIT",
                aliases: ["js"],
                checksum: "abc",
                size: 100
            )
        ])

        XCTAssertEqual(manifest.canonicalName(for: "JavaScript"), "javascript")
        XCTAssertEqual(manifest.canonicalName(for: "JAVASCRIPT"), "javascript")
        XCTAssertEqual(manifest.canonicalName(for: "JS"), "javascript")
    }

    func testCanonicalNameNotFound() throws {
        let manifest = try makeManifest(grammars: [:])

        XCTAssertNil(manifest.canonicalName(for: "unknown"))
    }

    // MARK: - Grammar Info Tests

    func testGrammarInfoDirectMatch() throws {
        let jsInfo = GrammarInfo(
            displayName: "JavaScript",
            version: "v1.0.0",
            license: "MIT",
            aliases: ["js"],
            checksum: "abc",
            size: 100
        )
        let manifest = try makeManifest(grammars: ["javascript": jsInfo])

        XCTAssertEqual(manifest.grammarInfo(for: "javascript"), jsInfo)
    }

    func testGrammarInfoViaAlias() throws {
        let jsInfo = GrammarInfo(
            displayName: "JavaScript",
            version: "v1.0.0",
            license: "MIT",
            aliases: ["js"],
            checksum: "abc",
            size: 100
        )
        let manifest = try makeManifest(grammars: ["javascript": jsInfo])

        XCTAssertEqual(manifest.grammarInfo(for: "js"), jsInfo)
    }

    func testGrammarInfoNotFound() throws {
        let manifest = try makeManifest(grammars: [:])

        XCTAssertNil(manifest.grammarInfo(for: "unknown"))
    }

    // MARK: - Supported Languages Tests

    func testSupportedLanguages() throws {
        let manifest = try makeManifest(grammars: [
            "javascript": GrammarInfo(
                displayName: "JavaScript",
                version: "v1.0.0",
                license: "MIT",
                aliases: ["js", "jsx"],
                checksum: "abc",
                size: 100
            ),
            "python": GrammarInfo(
                displayName: "Python",
                version: "v1.0.0",
                license: "MIT",
                aliases: ["py"],
                checksum: "def",
                size: 200
            )
        ])

        let supported = manifest.supportedLanguages

        XCTAssertTrue(supported.contains("javascript"))
        XCTAssertTrue(supported.contains("js"))
        XCTAssertTrue(supported.contains("jsx"))
        XCTAssertTrue(supported.contains("python"))
        XCTAssertTrue(supported.contains("py"))
    }

    func testSupportedLanguagesEmpty() throws {
        let manifest = try makeManifest(grammars: [:])

        XCTAssertTrue(manifest.supportedLanguages.isEmpty)
    }

    // MARK: - Helpers

    private func makeManifest(grammars: [String: GrammarInfo]) throws -> GrammarManifest {
        GrammarManifest(
            version: "1.0.0",
            generatedAt: "2026-01-29T12:00:00Z",
            grammars: grammars
        )
    }
}
