import XCTest

@testable import WorkoutDecoderBase
import WorkoutDecoders

final class WorkoutDecodersTests: XCTestCase {

    private func decodedWorkout(from filename: String = "workout1") -> Workout {
        let decoder = WorkoutDecoder(userFtp: 200)
        let file = Bundle.module.url(forResource: filename, withExtension: "zwo",
                                        subdirectory: "Resources")!
        let data = try! Data(contentsOf: file)
        return try! decoder.decodeWorkout(fileFormat: "zwo", data: data)
    }

    func testDecodesSegments() {
        let workout = decodedWorkout()

        XCTAssertEqual(workout.segments, [
            WorkoutSegment(duration: 10, index: 0, intervalIndex: nil, powerStart: 0.5, powerEnd: 0.55),
            WorkoutSegment(duration: 5, index: 1, intervalIndex: nil, powerStart: 0.4, powerEnd: nil),
            WorkoutSegment(duration: 100, index: 2, intervalIndex: nil, powerStart: -1, powerEnd: nil), // free ride
            WorkoutSegment(duration: 10, index: 3, intervalIndex: nil, powerStart: 0.5, powerEnd: nil),
            // interval start, repeat 3
            WorkoutSegment(duration: 15, index: 4, intervalIndex: 0, powerStart: 1.2, powerEnd: nil),
            WorkoutSegment(duration: 5, index: 5, intervalIndex: 0, powerStart: 0.4, powerEnd: nil),
            WorkoutSegment(duration: 15, index: 6, intervalIndex: 1, powerStart: 1.2, powerEnd: nil),
            WorkoutSegment(duration: 5, index: 7, intervalIndex: 1, powerStart: 0.4, powerEnd: nil),
            WorkoutSegment(duration: 15, index: 8, intervalIndex: 2, powerStart: 1.2, powerEnd: nil),
            WorkoutSegment(duration: 5, index: 9, intervalIndex: 2, powerStart: 0.4, powerEnd: nil),
            // interval end
            WorkoutSegment(duration: 5, index: 10, intervalIndex: nil, powerStart: 0.6, powerEnd: nil)
        ])
    }

    func testDecodesMessages() {
        let workout = decodedWorkout()

        XCTAssertEqual(workout.messages, [
            WorkoutMessage(timeOffset: 0, message: "Starting message"),
            WorkoutMessage(timeOffset: 120, message: "Should be at offset 120"),
            WorkoutMessage(timeOffset: 125, message: "Start interval message"),
            WorkoutMessage(timeOffset: 175, message: "Near end interval message"),
            WorkoutMessage(timeOffset: 187, message: "Last segment message")
        ])
    }

    static var allTests = [
        ("testDecodesSegments", testDecodesSegments),
        ("testDecodesMessages", testDecodesMessages)
    ]
}
