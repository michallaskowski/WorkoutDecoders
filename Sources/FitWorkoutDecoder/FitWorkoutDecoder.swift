//
//  FitWorkoutDecoder.swift
//  WatchTrainer
//
//  Created by Laskowski, Michal on 14/12/2020.
//

import Foundation
import WorkoutDecoderBase
import FitFileParser

public enum FitDecodeError: Error {
    case notOneWorkoutMessage
    case notSupportedRange
}

private struct RepeatSteps {
    let range: Range<Int>
    let repeatCount: Int
}

public final class FitWorkoutDecoder: WorkoutDecoding {
    public let supportedFileFormats: [String] = ["fit"]

    private let userFtp: Int
    public init(userFtp: Int) {
        self.userFtp = userFtp
    }

    public func decodeWorkout(data: Data) throws -> Workout {
        let file = FitFile(data: data)

        let workoutMessages = file.messages(forMessageType: .workout)
        guard workoutMessages.count == 1 else {
            throw FitDecodeError.notOneWorkoutMessage
        }
        let workoutName = workoutMessages[0].interpretedField(key: "wkt_name")?.name ?? ""
        assert(!workoutName.isEmpty)

        let workoutSteps = file.messages(forMessageType: .workout_step)
        let repeatSteps = workoutSteps.enumerated()
            .filter { step in
                step.element.interpretedField(key: "duration_type")?.name == "repeat_until_steps_cmplt"
            }
            .map { repeatStep -> RepeatSteps in
                let startIndex = repeatStep.element.interpretedField(key: "duration_value")?.value.map {
                    Int($0)
                } ?? -1
                assert(startIndex >= 0)
                let repeatRange = Range<Int>(uncheckedBounds: (lower: startIndex, upper: repeatStep.offset - 1))
                let repeatCount = repeatStep.element.interpretedField(key: "target_value")?.value.map {
                    Int($0)
                } ?? -1
                assert(repeatCount >= 0)

                return RepeatSteps(range: repeatRange, repeatCount: repeatCount)
            }

        let parts = try repeatSteps.map { repeatStep -> WorkoutPart in
            let stepsDistance = repeatStep.range.upperBound - repeatStep.range.lowerBound
            switch stepsDistance {
            case 0:
                let workoutStep = workoutSteps[repeatStep.range.lowerBound]
                return WorkoutPart.steady(duration: TimeInterval(workoutStep.duration), power: workoutStep.power(for: userFtp),
                                          cadence: nil)
            case 1:
                let firstWorkoutStep = workoutSteps[repeatStep.range.lowerBound]
                let secondWorkoutStep = workoutSteps[repeatStep.range.upperBound]
                return WorkoutPart.intervals(repeat: repeatStep.repeatCount,
                                             onDuration: TimeInterval(firstWorkoutStep.duration), onPower: firstWorkoutStep.power(for: userFtp),
                                             offDuration: TimeInterval(secondWorkoutStep.duration), offPower: secondWorkoutStep.power(for: userFtp),
                                             cadence: nil)
            default:
                throw FitDecodeError.notSupportedRange
            }
        }

        return Workout(name: workoutName,
                       parts: parts,
                       messages: [])
    }
}

private extension FitFileParser.FitMessage {
    var duration: Int {
        let duration = interpretedField(key: "duration_value")?.value.map {
            Int($0 / 1000.0)
        } ?? -1
        assert(duration > 0)
        return duration
    }

    func power(for ftp: Int) -> Double {
        let power = interpretedField(key: "custom_target_value_high")?.value.map {
            $0.fitPowerValueToRelativeFtp(for: ftp)
        } ?? -1
        assert(power > 0)
        return power
    }
}

// based on https://developer.garmin.com/fit/cookbook/encoding-workout-files/
// Relative values are provided as an integer value ranging 0 – 1000% functional threshold power (FTP)
// the ranges 0 to 1000 (power) are reserved for relative values
// power values must be offset 1000 watts.
extension Double {
    func fitPowerValueToRelativeFtp(for ftp: Int) -> Double {
        if self < 1000 {
            return self / 100.0
        } else {
            return (self - 1000.0) / Double(ftp)
        }
    }
}
