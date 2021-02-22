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

final class WorkoutDecoder: WorkoutDecoding {

    private let userFtp: Int
    private lazy var fitDecoder: FitWorkoutDecoder = {
        FitWorkoutDecoder(userFtp: userFtp)
    }()
    private lazy var zwoDecoder: ZwoWorkoutDecoder = {
        ZwoWorkoutDecoder()
    }()

    init(userFtp: Int) {
        self.userFtp = userFtp
    }

    func decodeWorkout(from url: URL, data: Data) throws -> Workout {
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
