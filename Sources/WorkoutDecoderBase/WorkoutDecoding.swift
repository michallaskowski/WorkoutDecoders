//
//  WorkoutDecoding.swift
//  WatchTrainer
//
//  Created by Laskowski, Michal on 14/12/2020.
//

import Foundation

public protocol WorkoutDecoding {
    var supportedFileFormats: [String] { get }
    func decodeWorkout(data: Data) throws -> Workout
}

public enum WorkoutPart {
    case steady(duration: TimeInterval, power: Double, cadence: String?)
    case intervals(repeat: Int, onDuration: TimeInterval, onPower: Double, offDuration: TimeInterval, offPower: Double, cadence: String?)
    case ramp(duration: TimeInterval, powerLow: Double, powerHigh: Double, cadence: String?)
    case freeRide(duration: TimeInterval, cadence: String?)

    public func toSegments(startIndex: Int) -> [WorkoutSegment] {
        switch self {
        case .steady(let duration, let power, let cadence):
            return [WorkoutSegment(duration: duration, index: startIndex, intervalIndex: nil,
                                   powerStart: power, powerEnd: nil, cadence: cadence)]
        case .intervals(let repeats, let onDuration, let onPower, let offDuration, let offPower, let cadence):
            return (0..<repeats).map { index -> [WorkoutSegment] in
                [
                    WorkoutSegment(duration: onDuration, index: startIndex + index * 2,
                                   intervalIndex: index, powerStart: onPower, powerEnd: nil, cadence: cadence),
                    WorkoutSegment(duration: offDuration, index: startIndex + index * 2 + 1,
                                   intervalIndex: index, powerStart: offPower, powerEnd: nil, cadence: cadence)
                ]
            }.flatMap { $0 }

        case .ramp(let duration, let powerLow, let powerHigh, let cadence):
            return [WorkoutSegment(duration: duration, index: startIndex,
                                   intervalIndex: nil, powerStart: powerLow, powerEnd: powerHigh, cadence: cadence)]
        case .freeRide(let duration, let cadence):
            return [WorkoutSegment(duration: duration, index: startIndex, intervalIndex: nil,
                                   powerStart: -1.0, powerEnd: nil, cadence: cadence)]
        }
    }
}

public struct WorkoutSegment: Codable, Equatable {
    public let duration: TimeInterval
    public let index: Int
    public let intervalIndex: Int?
    public let powerStart: Double // negative power means free ride
    public let powerEnd: Double?
    public let cadence: String?

    public func powerAt(second: Int, for ftp: Double) -> Int {
        let power: Double
        if let powerOff = powerEnd {
            power = Double(second) / Double(duration) * (powerOff - powerStart) + powerStart
        } else {
            power = powerStart
        }
        return Int(power * ftp)
    }
}

public struct WorkoutMessage: Codable, Equatable {
    public let timeOffset: TimeInterval
    public let message: String

    public init(timeOffset: TimeInterval, message: String) {
        self.timeOffset = timeOffset
        self.message = message
    }
}

public struct Workout: Codable {
    public let name: String
    public let segments: [WorkoutSegment]
    public let duration: TimeInterval
    public let messages: [WorkoutMessage]

    public init(name: String, parts: [WorkoutPart], messages: [WorkoutMessage]) {
        self.name = name
        self.messages = messages
        segments = parts.reduce([WorkoutSegment](), { (accumulator, part) -> [WorkoutSegment] in
            let index = (accumulator.last?.index ?? -1) + 1
            return accumulator + part.toSegments(startIndex: index)
        })
        duration = segments.reduce(0, { $0 + $1.duration })
    }
}
