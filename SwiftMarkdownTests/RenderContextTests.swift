import XCTest
@testable import SwiftMarkdownCore

final class RenderContextTests: XCTestCase {
    // MARK: - Default Values

    func test_init_defaultValues() {
        let context = RenderContext()
        XCTAssertEqual(context.nestingLevel, 0)
        XCTAssertNil(context.listIndex)
        XCTAssertNil(context.parentBlockType)
        XCTAssertFalse(context.isInlineContext)
        XCTAssertTrue(context.blockStack.isEmpty)
    }

    // MARK: - nested()

    func test_nested_incrementsNestingLevel() {
        let context = RenderContext()
        let nested = context.nested()
        XCTAssertEqual(nested.nestingLevel, 1)
    }

    func test_nested_preservesOtherProperties() {
        var context = RenderContext()
        context.listIndex = 5
        context.isInlineContext = true
        let nested = context.nested()
        XCTAssertEqual(nested.listIndex, 5)
        XCTAssertTrue(nested.isInlineContext)
    }

    func test_nested_doesNotMutateOriginal() {
        let context = RenderContext()
        _ = context.nested()
        XCTAssertEqual(context.nestingLevel, 0)
    }

    // MARK: - entering(_:)

    func test_entering_setsParentBlockType() {
        let context = RenderContext()
        let entered = context.entering(.blockquote)
        XCTAssertEqual(entered.parentBlockType, .blockquote)
    }

    func test_entering_pushesToBlockStack() {
        let context = RenderContext()
        let entered = context.entering(.orderedList)
        XCTAssertEqual(entered.blockStack.count, 1)
        XCTAssertEqual(entered.blockStack.last, .orderedList)
    }

    func test_entering_chainedCalls_buildStack() {
        let context = RenderContext()
            .entering(.document)
            .entering(.orderedList)
            .entering(.listItem)
        XCTAssertEqual(context.blockStack.count, 3)
        XCTAssertEqual(context.parentBlockType, .listItem)
    }

    // MARK: - withListIndex(_:)

    func test_withListIndex_setsIndex() {
        let context = RenderContext()
        let indexed = context.withListIndex(3)
        XCTAssertEqual(indexed.listIndex, 3)
    }

    func test_withListIndex_preservesNestingLevel() {
        var context = RenderContext()
        context.nestingLevel = 2
        let indexed = context.withListIndex(1)
        XCTAssertEqual(indexed.nestingLevel, 2)
    }

    // MARK: - asInline()

    func test_asInline_setsInlineContext() {
        let context = RenderContext()
        let inline = context.asInline()
        XCTAssertTrue(inline.isInlineContext)
    }

    func test_asInline_preservesOtherProperties() {
        var context = RenderContext()
        context.nestingLevel = 3
        context.listIndex = 2
        let inline = context.asInline()
        XCTAssertEqual(inline.nestingLevel, 3)
        XCTAssertEqual(inline.listIndex, 2)
    }

    // MARK: - BlockType Equality

    func test_blockType_headingLevel_equality() {
        let h1 = BlockType.heading(level: 1)
        let h1Copy = BlockType.heading(level: 1)
        let h2 = BlockType.heading(level: 2)

        XCTAssertEqual(h1, h1Copy)
        XCTAssertNotEqual(h1, h2)
    }
}
