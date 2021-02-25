# WorkoutDecoders

## About the project

A common interface for (currently) two decoders:
* zwo files (xml format)
* fit files (binary format)

that allow to create a common model of a workout. See `Sources/WorkoutDecoderBase/WorkoutDecoding.swift` for model definitions.

### Built with

* [FitFileParser](https://github.com/roznet/FitFileParser)
* [SwiftyXMLParser](https://github.com/yahoojapan/SwiftyXMLParser)

## Getting started

To use the decoders in your project, add this Swift Package in your project. You can choose individual decoders, or a common facade `WorkoutDecoders`.

## Usage

See tests for example of decoding workouts. 
Workout definitions may be using both absolute and FTP relative values, but for simplicity workouts are decoded to contain only FTP relative values. That's why FTP is needed for FIT file decoding.

```
let decoder = WorkoutDecoder(userFtp: 200)
let file = Bundle.module.url(forResource: "workout", withExtension: "fit")!
do {
  let data = try Data(contentsOf: file)
  let workout = try decoder.decodeWorkout(from: file, data: data)
  // use workout
} catch {
  // handle decoding errors
}
```

## Roadmap

For an app I am developing, ZWO and FIT file support is enough. MRC, ERG or other file support could be added if needed, but preferably by providing a PR :)  
Workout model could be extended if there is also a need for that.

## Contributing

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request


## License

Distributed under the MIT License. See `LICENSE` for more information.
