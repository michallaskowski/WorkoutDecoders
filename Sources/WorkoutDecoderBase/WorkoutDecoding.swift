//
//  WorkoutDecoding.swift
//  WatchTrainer
//
//  Created by Laskowski, Michal on 14/12/2020.
//

import Foundation

public protocol WorkoutDecoding {
    func decodeWorkout(from url: URL, data: Data) throws -> Workout
}

public enum WorkoutPart {
    case steady(duration: Int, power: Double)
    case intervals(repeat: Int, onDuration: Int, onPower: Double, offDuration: Int, offPower: Double)
    case ramp(duration: Int, powerLow: Double, powerHigh: Double)
    case freeRide(duration: Int)

    public func toSegments(startIndex: Int) -> [WorkoutSegment] {
        switch self {
        case .steady(let duration, let power):
            return [WorkoutSegment(duration: duration, index: startIndex, intervalIndex: nil, powerStart: power, powerEnd: nil)]
        case .intervals(let repeats, let onDuration, let onPower, let offDuration, let offPower):
            return (0...repeats).map { index -> [WorkoutSegment] in
                [
                    WorkoutSegment(duration: onDuration, index: startIndex + index * 2,
                                   intervalIndex: index, powerStart: onPower, powerEnd: nil),
                    WorkoutSegment(duration: offDuration, index: startIndex + index * 2 + 1,
                                   intervalIndex: index, powerStart: offPower, powerEnd: nil),
                ]
            }.flatMap { $0 }

        case .ramp(let duration, let powerLow, let powerHigh):
            return [WorkoutSegment(duration: duration, index: startIndex,
                                   intervalIndex: nil, powerStart: powerLow, powerEnd: powerHigh)]
        case .freeRide(let duration):
            return [WorkoutSegment(duration: duration, index: startIndex, intervalIndex: nil, powerStart: -1.0, powerEnd: nil)]
        }
    }
}

public struct WorkoutSegment: Codable {
    public let duration: Int
    public let index: Int
    public let intervalIndex: Int?
    public let powerStart: Double // negative power means free ride
    public let powerEnd: Double?

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

public struct WorkoutMessage: Codable {
    public let timeOffset: Int
    public let message: String

    public init(timeOffset: Int, message: String) {
        self.timeOffset = timeOffset
        self.message = message
    }
}

public struct Workout: Codable {
    public let name: String
    public let segments: [WorkoutSegment]
    public let duration: Int
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
