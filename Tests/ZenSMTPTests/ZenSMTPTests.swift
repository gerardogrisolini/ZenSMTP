import XCTest
@testable import ZenSMTP

final class ZenSMTPTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(ZenSMTP().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
