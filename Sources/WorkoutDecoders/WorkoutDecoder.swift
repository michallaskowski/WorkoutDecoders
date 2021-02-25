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

public final class WorkoutDecoder {

    private let userFtp: Int
    private lazy var decoders: [WorkoutDecoding] = {
        [FitWorkoutDecoder(userFtp: userFtp), ZwoWorkoutDecoder()]
    }()

    public init(userFtp: Int) {
        self.userFtp = userFtp
    }

    public func register(decoders newDecoders: [WorkoutDecoding]) {
        decoders.append(contentsOf: newDecoders)
    }

    public func decodeWorkout(fileFormat: String, data: Data) throws -> Workout {
        guard let decoder = decoders.first(where: {
            $0.supportedFileFormats.contains(fileFormat)
        }) else {
            throw UnknownFileException()
        }
        return try decoder.decodeWorkout(data: data)
    }
}
