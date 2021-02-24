// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WorkoutDecoders",
    platforms: [.iOS(.v11), .macOS(.v10_14), .watchOS(.v4)],
    products: [
        .library(
            name: "ZwoWorkoutDecoder",
            targets: ["ZwoWorkoutDecoder"]),
        .library(
            name: "FitWorkoutDecoder",
            targets: ["FitWorkoutDecoder"]),
        .library(
            name: "WorkoutDecoders",
            targets: ["WorkoutDecoders"])
    ],
    dependencies: [

        .package(
            name: "SwiftyXMLParser",
            url: "https://github.com/yahoojapan/SwiftyXMLParser", from: "5.3.0"),
        .package(
            name: "FitFileParser",
            url: "https://github.com/roznet/FitFileParser", from: "1.4.1")
    ],
    targets: [
        .target(
            name: "WorkoutDecoderBase",
            dependencies: []),
        .target(
            name: "ZwoWorkoutDecoder",
            dependencies: ["SwiftyXMLParser", "WorkoutDecoderBase"]),
        .target(
            name: "FitWorkoutDecoder",
            dependencies: ["FitFileParser", "WorkoutDecoderBase"]),
        .target(
            name: "WorkoutDecoders",
            dependencies: ["ZwoWorkoutDecoder", "FitWorkoutDecoder"]),
        .testTarget(
            name: "WorkoutDecodersTests",
            dependencies: ["WorkoutDecoders"],
            resources: [
                .copy("Resources")
            ]),
    ]
)
