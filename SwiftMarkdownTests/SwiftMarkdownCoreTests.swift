import XCTest
@testable import SwiftMarkdownCore

final class SwiftMarkdownCoreTests: XCTestCase {
    func testVersionIsNotEmpty() {
        XCTAssertFalse(SwiftMarkdownCore.version.isEmpty)
    }

    func testVersionFormat() {
        // Version should be in semver format (e.g., "0.1.0")
        let components = SwiftMarkdownCore.version.split(separator: ".")
        XCTAssertEqual(components.count, 3)
    }
}
