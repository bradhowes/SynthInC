import AVFoundation

/**
 The sequence of phrases that a given Instrument will perform.
 */
struct Part {
  /// The index of the Instrument in an Ensemble
  let index: Int
  /// The number of times each phrase will be played by this instrument
  let phraseRepetitions: [Int]
  /// The
  let normalizedRunningDurations: [CGFloat]

  init(index: Int, phraseRepetitions: [Int], duration: MusicTimeStamp) {
    self.index = index
    self.phraseRepetitions = phraseRepetitions
    let durations = zip(phraseRepetitions, Score.phrases).map { MusicTimeStamp($0.0) * $0.1.duration }
    let elapsed = durations.reduce(into: Array<MusicTimeStamp>()) {
      $0.append(($0.last ?? ($0.reserveCapacity(phraseRepetitions.count), 0.0).1) + MusicTimeStamp($1))
    }
    normalizedRunningDurations = elapsed.map { CGFloat($0 / duration) }
  }

  init?(data: Data) {
    guard let decoder = try? NSKeyedUnarchiver(forReadingFrom: data) else { return nil }
    self.index = decoder.decodeInteger(forKey: "index")
    guard let phraseRepetitions = decoder.decodeObject(forKey: "phraseRepetitions") as? [Int] else { return nil }
    guard
      let normalizedRunningDurations = decoder.decodeObject(forKey: "normalizedRunningDurations") as? [CGFloat]
    else {
      return nil
    }
    self.phraseRepetitions = phraseRepetitions
    self.normalizedRunningDurations = normalizedRunningDurations
  }

  func encodePerformance() -> Data {
    let encoder = NSKeyedArchiver(requiringSecureCoding: false)
    encoder.encode(index, forKey: "index")
    encoder.encode(phraseRepetitions, forKey: "phraseRepetitions")
    encoder.encode(normalizedRunningDurations, forKey: "normalizedRunningDurations")
    encoder.finishEncoding()
    return encoder.encodedData
  }

  func timeline() -> String {
    "\(index):" + phraseRepetitions.enumerated().map({"\($0.0)" +
      String(repeating: "-", count: Int(((MusicTimeStamp($0.1) * Score.phrases[$0.0].duration)).rounded(.up)))})
    .joined()
  }
}

extension Part {

  func createMusicTrack(_ musicSequence: MusicSequence, rando: Rando) -> (MusicTrack, MusicTimeStamp)? {
    guard let track = newMusicTrack(musicSequence: musicSequence) else {
      return nil
    }

    var clock = 120.scaled
    for (index, playCount) in phraseRepetitions.enumerated() {
      let phrase = Score.phrases[index]
      for _ in 0..<playCount {
        clock = phrase.advance(clock: clock) {
          $1.addToTrack(track, clock: $0, slop: rando.noteOnSlop())
        }
      }
    }

    print("\(index) createMusicTrack - \(track) \(clock)")
    return (track, clock)
  }
}

private func newMusicTrack(musicSequence: MusicSequence) -> MusicTrack? {
  var track: MusicTrack?
  return IsAudioError("MusicSequenceNewTrack",
                      MusicSequenceNewTrack(musicSequence, &track)) ? nil : track
}
