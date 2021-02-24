//
//  WorkoutDecoder.swift
//  WatchTrainer
//
//  Created by Laskowski, Michal on 14/12/2020.
//

import Foundation
import WorkoutDecoderBase
import FitWorkoutDecoder
import ZwoWorkoutDecoder

public struct UnknownFileException: Error {}

public final class WorkoutDecoder: WorkoutDecoding {

    private let userFtp: Int
    private lazy var fitDecoder: FitWorkoutDecoder = {
        FitWorkoutDecoder(userFtp: userFtp)
    }()
    private lazy var zwoDecoder: ZwoWorkoutDecoder = {
        ZwoWorkoutDecoder()
    }()

    public init(userFtp: Int) {
        self.userFtp = userFtp
    }

    public func decodeWorkout(from url: URL, data: Data) throws -> Workout {
        switch url.pathExtension {
        case "zwo":
            return try zwoDecoder.decodeWorkout(from: url, data: data)
        case "fit":
            return try fitDecoder.decodeWorkout(from: url, data: data)
        default:
            throw UnknownFileException()
        }
    }
}
