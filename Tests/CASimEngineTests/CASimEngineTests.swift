import CASimEngine
import XCTest // import Testing for 6.0...

final class grokTests: XCTestCase {
    func testTupleSort() throws {
        // when comparing tuples, the first element is compared across, and if that's equal then the second element is compared.
        XCTAssertFalse((1, 5) < (0, 6))
        XCTAssertTrue((1, 5) < (1, 6))
        XCTAssertTrue((1, 5) < (2, 6))
        XCTAssertFalse((2, 5) < (1, 6))

        // when comparing for equality, all elements must be equal
        XCTAssertTrue((1, 5) != (1, 6))
        XCTAssertTrue((1, 5) == (1, 5))
    }
}
