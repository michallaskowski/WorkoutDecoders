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
    public let supportedFileFormats: [String] = ["zwo"]

    public init() {}

    public func decodeWorkout(data: Data) throws -> Workout {
        let xml = XML.parse(data)
        let workout = xml["workout_file"]
        let name: String = workout["name"].text ?? "no_name"
        let parts = try workout["workout"].element?.childElements.map { part -> WorkoutPart in
            let attributes = part.attributes
            let cadence = attributes["Cadence"]
            switch part.name {
            case "SteadyState":
                return WorkoutPart.steady(duration: attributes.double("Duration"),
                                          power: attributes.double("Power"),
                                          cadence: cadence)
            case "IntervalsT":
                return WorkoutPart.intervals(repeat: attributes.int("Repeat"),
                                             onDuration: attributes.double("OnDuration"),
                                             onPower: attributes.double("OnPower"),
                                             offDuration: attributes.double("OffDuration"),
                                             offPower: attributes.double("OffPower"),
                                             cadence: cadence)
            case "Warmup", "Cooldown", "Ramp":
                return WorkoutPart.ramp(duration: attributes.double("Duration"),
                                        powerLow: attributes.double("PowerLow"),
                                        powerHigh: attributes.double("PowerHigh"),
                                        cadence: cadence)
            case "FreeRide":
                return WorkoutPart.freeRide(duration: attributes.double("Duration"),
                                            cadence: cadence)
            default:
                throw WorkoutDecodeError.unknownElement(name: part.name)
            }
        } ?? []

        // each part duration and messages with time offset per WorkoutPart
        let messages = try workout["workout"].element?.childElements.map { part -> (TimeInterval, [WorkoutMessage]) in
            let attributes = part.attributes

            let duration: TimeInterval
            switch part.name {
            case "SteadyState", "Warmup", "Cooldown", "Ramp", "FreeRide":
                duration = attributes.double("Duration")
            case "IntervalsT":
                duration = (attributes.double("OnDuration") + attributes.double("OffDuration")) * Double(attributes.int("Repeat"))
            default:
                throw WorkoutDecodeError.unknownElement(name: part.name)
            }

            let messages = part.childElements.filter {
                $0.name == "textevent"
            }.map { message -> WorkoutMessage in
                let attributes = message.attributes
                return WorkoutMessage(timeOffset: attributes.double("timeoffset"), message: attributes["message"] ?? "")
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

    func double(_ key: Key, fallback: Double = 0.0) -> Double {
        return self[key].flatMap {
            Double($0)
        } ?? fallback
    }
}
