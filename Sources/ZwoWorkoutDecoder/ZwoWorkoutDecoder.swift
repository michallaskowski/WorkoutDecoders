//
//  WorkoutDecoder.swift
//  WatchTrainer WatchKit Extension
//
//  Created by Laskowski, Michal on 04/11/2020.
//

import Foundation
import WorkoutDecoderBase
import SwiftyXMLParser

public final class ZwoWorkoutDecoder: WorkoutDecoding {
    public init() {}

    public func decodeWorkout(from url: URL, data: Data) throws -> Workout {
        let xml = XML.parse(data)
        let workout = xml["workout_file"]
        let name: String = workout["name"].text ?? "no_name"
        let parts = try workout["workout"].element?.childElements.map { part -> WorkoutPart in
            let attributes = part.attributes
            switch part.name {
            case "SteadyState":
                return WorkoutPart.steady(duration: attributes.int("Duration"),
                                          power: Double(attributes["Power"]!)!)
            case "IntervalsT":
                return WorkoutPart.intervals(repeat: attributes.int("Repeat"),
                                             onDuration: attributes.int("OnDuration"),
                                             onPower: Double(attributes["OnPower"]!)!,
                                             offDuration: attributes.int("OffDuration"),
                                             offPower: Double(attributes["OffPower"]!)!)
            case "Warmup", "Cooldown", "Ramp":
                return WorkoutPart.ramp(duration: attributes.int("Duration"),
                                        powerLow: Double(attributes["PowerLow"]!)!,
                                        powerHigh: Double(attributes["PowerHigh"]!)!)
            case "FreeRide":
                return WorkoutPart.freeRide(duration: attributes.int("Duration"))
            default:
                throw WorkoutDecodeError.unknownElement(name: part.name)
            }
        } ?? []

        // each part duration and messages with time offset per WorkoutPart
        let messages = try workout["workout"].element?.childElements.map { part -> (Int, [WorkoutMessage]) in
            let attributes = part.attributes

            let duration: Int
            switch part.name {
            case "SteadyState", "Warmup", "Cooldown", "Ramp", "FreeRide":
                duration = attributes.int("Duration")
            case "IntervalsT":
                duration = (attributes.int("OnDuration") + attributes.int("OffDuration")) * attributes.int("Repeat")
            default:
                throw WorkoutDecodeError.unknownElement(name: part.name)
            }

            let messages = part.childElements.filter {
                $0.name == "textevent"
            }.map { message -> WorkoutMessage in
                let attributes = message.attributes
                return WorkoutMessage(timeOffset: attributes.int("timeoffset"), message: attributes["message"] ?? "")
            }

            return (duration, messages)
        } ?? []
        // normalize message offset, make offset from time 0
        let adjustedMessages = messages.reduce(into: (offset: 0, messages: [WorkoutMessage]())) { sum, messages in
            let adjustedMessages = messages.1.map {
                WorkoutMessage(timeOffset: sum.offset + $0.timeOffset, message: $0.message)
            }
            sum.messages.append(contentsOf: adjustedMessages)
            sum.offset += messages.0
        }

        return Workout(name: name, parts: parts, messages: adjustedMessages.messages)
    }
}

public enum WorkoutDecodeError: Error {
    case unknownElement(name: String?)
}

private extension Dictionary where Value == String {
    func int(_ key: Key, fallback: Int = 0) -> Int {
        return self[key].flatMap {
            Int($0)
        } ?? fallback
    }
}
