import XCTest
@testable import WorkoutDecoders

final class WorkoutDecodersTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(WorkoutDecoders().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
