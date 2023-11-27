// Copyright © 2016 Brad Howes. All rights reserved.

import AVFoundation

/**
 A sequence of notes for a part of the "In C" score.
 */
public struct Phrase {

  /// The collection of notes in the phrase
  public let notes: [Note]
  /// The duration required to play all of the notes in the phrase
  public let duration: MusicTimeStamp

  /**
   Create a new Phrase using a sequence of Note objects.
   - parameter notes: one or or more Note objects that make up the phrase
   */
  public init(_ notes: Note...) {
    self.notes = notes
    self.duration = notes.filter{ $0.duration > 0 }.reduce(0.0) { $0 + $1.duration }
  }

  /**
   Hand the notes of a phrase to an optional recorder function.

   - Parameters:
   - clock: the current clock value
   - recorder: the optional function to pass in each note
   - Returns: the ending clock value
   */
  func record(clock: MusicTimeStamp, recorder: ((MusicTimeStamp, Note)->Void)? = nil) -> MusicTimeStamp {
    switch recorder {
    case let r?: return notes.reduce(clock) { r($0, $1); return $1.getEndTime(clock: $0) }
    case nil: return notes.reduce(clock) { $1.getEndTime(clock: $0) }
    }
  }
}

/// The set of 53 phrases in the "In C" score. The "0" phrase is a whole note rest so that we can
/// accommodate the grace note in the first phrase.
public let ScorePhrases: [Phrase] = [
  Phrase( // 0
    Note(.re,  Duration.whole)),
  Phrase( // 1
    Note(.C4,  Duration.eighth.grace),
    Note(.E4,  Duration.quarter),
    Note(.C4,  Duration.eighth.grace),
    Note(.E4,  Duration.quarter),
    Note(.C4,  Duration.eighth.grace),
    Note(.E4,  Duration.quarter)),
  Phrase( // 2
    Note(.C4,  Duration.eighth.grace),
    Note(.E4,  Duration.eighth),
    Note(.F4,  Duration.eighth),
    Note(.E4,  Duration.quarter)),
  Phrase( // 3
    Note(.re,  Duration.eighth),
    Note(.E4,  Duration.eighth),
    Note(.F4,  Duration.eighth),
    Note(.E4,  Duration.eighth)),
  Phrase( // 4
    Note(.re,  Duration.eighth),
    Note(.E4,  Duration.eighth),
    Note(.F4,  Duration.eighth),
    Note(.G4,  Duration.eighth)),
  Phrase( // 5
    Note(.E4,  Duration.eighth),
    Note(.F4,  Duration.eighth),
    Note(.G4,  Duration.eighth),
    Note(.re,  Duration.eighth)),
  Phrase( // 6
    Note(.C5,  Duration.whole + Duration.whole)),
  Phrase( // 7
    Note(.re,  Duration.quarter * 3 + Duration.eighth ),
    Note(.C4,  Duration.sixteenth),
    Note(.C4,  Duration.sixteenth),
    Note(.C4,  Duration.eighth),
    Note(.re,  Duration.quarter * 4 + Duration.eighth)),
  Phrase( // 8
    Note(.G4,  Duration.whole + Duration.half),
    Note(.F4,  Duration.whole + Duration.whole)),
  Phrase( // 9
    Note(.B4,  Duration.sixteenth),
    Note(.G4,  Duration.sixteenth),
    Note(.re,  Duration.quarter * 3 + Duration.eighth)),
  Phrase( // 10
    Note(.B4,  Duration.sixteenth),
    Note(.G4,  Duration.sixteenth)),
  Phrase( // 11
    Note(.F4,  Duration.sixteenth),
    Note(.G4,  Duration.sixteenth),
    Note(.B4,  Duration.sixteenth),
    Note(.G4,  Duration.sixteenth),
    Note(.B4,  Duration.sixteenth),
    Note(.G4,  Duration.sixteenth)),
  Phrase( // 12
    Note(.F4,  Duration.eighth),
    Note(.G4,  Duration.eighth),
    Note(.B4,  Duration.whole),
    Note(.C5,  Duration.quarter)),
  Phrase( // 13
    Note(.B4,  Duration.sixteenth),
    Note(.G4,  Duration.eighth.dotted),
    Note(.G4,  Duration.sixteenth),
    Note(.F4,  Duration.sixteenth),
    Note(.G4,  Duration.eighth),
    Note(.re,  Duration.eighth.dotted),
    Note(.G4,  Duration.sixteenth + Duration.half.dotted)),
  Phrase( // 14
    Note(.C5,  Duration.whole),
    Note(.B4,  Duration.whole),
    Note(.G4,  Duration.whole),
    Note(.F4s, Duration.whole)),
  Phrase( // 15
    Note(.G4,  Duration.sixteenth),
    Note(.re,  Duration.eighth.dotted + Duration.quarter * 3)),
  Phrase( // 16
    Note(.G4,  Duration.sixteenth),
    Note(.B4,  Duration.sixteenth),
    Note(.C5,  Duration.sixteenth),
    Note(.B4,  Duration.sixteenth)),
  Phrase( // 17
    Note(.B4,  Duration.sixteenth),
    Note(.C5,  Duration.sixteenth),
    Note(.B4,  Duration.sixteenth),
    Note(.C5,  Duration.sixteenth),
    Note(.B4,  Duration.sixteenth),
    Note(.re,  Duration.sixteenth)),
  Phrase( // 18
    Note(.E4,  Duration.sixteenth),
    Note(.F4s, Duration.sixteenth),
    Note(.E4,  Duration.sixteenth),
    Note(.F4s, Duration.sixteenth),
    Note(.E4,  Duration.eighth.dotted)),
  Phrase( // 19
    Note(.re,  Duration.quarter.dotted),
    Note(.G5,  Duration.eighth.dotted)),
  Phrase( // 20
    Note(.E4,  Duration.sixteenth),
    Note(.F4s, Duration.sixteenth),
    Note(.E4,  Duration.sixteenth),
    Note(.F4s, Duration.sixteenth),
    Note(.G3,  Duration.eighth.dotted),
    Note(.E4,  Duration.sixteenth),
    Note(.F4s, Duration.sixteenth),
    Note(.E4,  Duration.sixteenth),
    Note(.F4s, Duration.sixteenth),
    Note(.E4,  Duration.sixteenth)),
  Phrase( // 21
    Note(.F4s, Duration.half.dotted)),
  Phrase( // 22
    Note(.E4,  Duration.quarter.dotted),
    Note(.E4,  Duration.quarter.dotted),
    Note(.E4,  Duration.quarter.dotted),
    Note(.E4,  Duration.quarter.dotted),
    Note(.E4,  Duration.quarter.dotted),
    Note(.F4s, Duration.quarter.dotted),
    Note(.G4,  Duration.quarter.dotted),
    Note(.A4,  Duration.quarter.dotted),
    Note(.B4,  Duration.eighth)),
  Phrase( // 23
    Note(.E4,  Duration.eighth),
    Note(.F4s, Duration.quarter.dotted),
    Note(.F4s, Duration.quarter.dotted),
    Note(.F4s, Duration.quarter.dotted),
    Note(.F4s, Duration.quarter.dotted),
    Note(.F4s, Duration.quarter.dotted),
    Note(.G4,  Duration.quarter.dotted),
    Note(.A4,  Duration.quarter.dotted),
    Note(.B4,  Duration.quarter)),
  Phrase( // 24
    Note(.E4,  Duration.eighth),
    Note(.F4s, Duration.eighth),
    Note(.G4,  Duration.quarter.dotted),
    Note(.G4,  Duration.quarter.dotted),
    Note(.G4,  Duration.quarter.dotted),
    Note(.G4,  Duration.quarter.dotted),
    Note(.G4,  Duration.quarter.dotted),
    Note(.A4,  Duration.quarter.dotted),
    Note(.B4,  Duration.eighth)),
  Phrase( // 25
    Note(.E4,  Duration.eighth),
    Note(.F4s, Duration.eighth),
    Note(.G4,  Duration.eighth),
    Note(.A4,  Duration.quarter.dotted),
    Note(.A4,  Duration.quarter.dotted),
    Note(.A4,  Duration.quarter.dotted),
    Note(.A4,  Duration.quarter.dotted),
    Note(.A4,  Duration.quarter.dotted),
    Note(.B4,  Duration.quarter.dotted)),
  Phrase( // 26
    Note(.E4,  Duration.eighth),
    Note(.F4s, Duration.eighth),
    Note(.G4,  Duration.eighth),
    Note(.A4,  Duration.eighth),
    Note(.B4,  Duration.quarter.dotted),
    Note(.B4,  Duration.quarter.dotted),
    Note(.B4,  Duration.quarter.dotted),
    Note(.B4,  Duration.quarter.dotted),
    Note(.B4,  Duration.quarter.dotted)),
  Phrase( // 27
    Note(.E4,  Duration.sixteenth),
    Note(.F4s, Duration.sixteenth),
    Note(.E4,  Duration.sixteenth),
    Note(.F4s, Duration.sixteenth),
    Note(.G4,  Duration.eighth),
    Note(.E4,  Duration.sixteenth),
    Note(.G4,  Duration.sixteenth),
    Note(.F4,  Duration.sixteenth),
    Note(.E4,  Duration.sixteenth),
    Note(.F4,  Duration.sixteenth),
    Note(.E4,  Duration.sixteenth)),
  Phrase( // 28
    Note(.E4,  Duration.sixteenth),
    Note(.F4s, Duration.sixteenth),
    Note(.E4,  Duration.sixteenth),
    Note(.F4s, Duration.sixteenth),
    Note(.E4,  Duration.eighth.dotted),
    Note(.E4,  Duration.sixteenth)),
  Phrase( // 29
    Note(.E4,  Duration.half.dotted),
    Note(.G4,  Duration.half.dotted),
    Note(.C5,  Duration.half.dotted)),
  Phrase( // 30
    Note(.C5,  Duration.whole.dotted)),
  Phrase( // 31
    Note(.G4,  Duration.sixteenth),
    Note(.F4,  Duration.sixteenth),
    Note(.G4,  Duration.sixteenth),
    Note(.B4,  Duration.sixteenth),
    Note(.G4,  Duration.sixteenth),
    Note(.B4,  Duration.sixteenth)),
  Phrase( // 32
    Note(.F4,  Duration.sixteenth),
    Note(.G4,  Duration.sixteenth),
    Note(.F4,  Duration.sixteenth),
    Note(.G4,  Duration.sixteenth),
    Note(.B4,  Duration.sixteenth),
    Note(.F4,  Duration.sixteenth + Duration.half.dotted),
    Note(.G4,  Duration.quarter.dotted)),
  Phrase( // 33
    Note(.G4,  Duration.sixteenth),
    Note(.F4,  Duration.sixteenth),
    Note(.re,  Duration.eighth)),
  Phrase( // 34
    Note(.G4,  Duration.sixteenth),
    Note(.F4,  Duration.sixteenth)),
  Phrase( // 35
    Note(.F4,  Duration.sixteenth),
    Note(.G4,  Duration.sixteenth),
    Note(.B4,  Duration.sixteenth),
    Note(.G4,  Duration.sixteenth),
    Note(.B4,  Duration.sixteenth),
    Note(.G4,  Duration.sixteenth),
    Note(.B4,  Duration.sixteenth),
    Note(.G4,  Duration.sixteenth),
    Note(.B4,  Duration.sixteenth),
    Note(.G4,  Duration.sixteenth),
    Note(.re,  Duration.eighth + Duration.quarter * 3),
    Note(.A4s, Duration.quarter),
    Note(.G5,  Duration.half.dotted),
    Note(.A5,  Duration.eighth),
    Note(.G5,  Duration.quarter),
    Note(.B5,  Duration.eighth),
    Note(.A5,  Duration.quarter.dotted),
    Note(.G5,  Duration.eighth),
    Note(.E5,  Duration.half.dotted),
    Note(.G5,  Duration.eighth),
    Note(.F5s, Duration.eighth + Duration.half.dotted),
    Note(.re,  Duration.quarter * 2 + Duration.eighth),
    Note(.E5,  Duration.eighth + Duration.half),
    Note(.F5,  Duration.whole.dotted)),
  Phrase( // 36
    Note(.F4,  Duration.sixteenth),
    Note(.G4,  Duration.sixteenth),
    Note(.B4,  Duration.sixteenth),
    Note(.G4,  Duration.sixteenth),
    Note(.B4,  Duration.sixteenth),
    Note(.G4,  Duration.sixteenth)),
  Phrase( // 37
    Note(.F4,  Duration.sixteenth),
    Note(.G4,  Duration.sixteenth)),
  Phrase( // 38
    Note(.F4,  Duration.sixteenth),
    Note(.G4,  Duration.sixteenth),
    Note(.B4,  Duration.sixteenth)),
  Phrase( //39
    Note(.B4,  Duration.sixteenth),
    Note(.G4,  Duration.sixteenth),
    Note(.F4,  Duration.sixteenth),
    Note(.G4,  Duration.sixteenth),
    Note(.B4,  Duration.sixteenth),
    Note(.C5,  Duration.sixteenth)),
  Phrase( // 40
    Note(.B4,  Duration.sixteenth),
    Note(.F4,  Duration.sixteenth)),
  Phrase( // 41
    Note(.B4,  Duration.sixteenth),
    Note(.G4,  Duration.sixteenth)),
  Phrase( // 42
    Note(.C5,  Duration.whole),
    Note(.B4,  Duration.whole),
    Note(.A4,  Duration.whole),
    Note(.C5,  Duration.whole)),
  Phrase( // 43
    Note(.F5,  Duration.sixteenth),
    Note(.E5,  Duration.sixteenth),
    Note(.F5,  Duration.sixteenth),
    Note(.E5,  Duration.sixteenth),
    Note(.E5,  Duration.eighth),
    Note(.E5,  Duration.eighth),
    Note(.E5,  Duration.eighth),
    Note(.F5,  Duration.sixteenth),
    Note(.E5,  Duration.sixteenth)),
  Phrase( // 44
    Note(.F5,  Duration.eighth),
    Note(.E5,  Duration.eighth + Duration.eighth),
    Note(.E5,  Duration.eighth),
    Note(.C5,  Duration.quarter)),
  Phrase( // 45
    Note(.D5,  Duration.quarter),
    Note(.D5,  Duration.quarter),
    Note(.G4,  Duration.quarter)),
  Phrase( // 46
    Note(.G4,  Duration.sixteenth),
    Note(.D5,  Duration.sixteenth),
    Note(.E5,  Duration.sixteenth),
    Note(.D5,  Duration.sixteenth),
    Note(.re,  Duration.eighth),
    Note(.G4,  Duration.eighth),
    Note(.re,  Duration.eighth),
    Note(.G4,  Duration.eighth),
    Note(.re,  Duration.eighth),
    Note(.G4,  Duration.eighth),
    Note(.G4,  Duration.sixteenth),
    Note(.G4,  Duration.sixteenth),
    Note(.D5,  Duration.sixteenth),
    Note(.E5,  Duration.sixteenth),
    Note(.D5,  Duration.sixteenth)),
  Phrase( // 47
    Note(.D5,  Duration.sixteenth),
    Note(.E5,  Duration.sixteenth),
    Note(.D5,  Duration.sixteenth)),
  Phrase( // 48
    Note(.G4,  Duration.whole.dotted),
    Note(.G4,  Duration.whole),
    Note(.G4,  Duration.whole + Duration.quarter)),
  Phrase( // 49
    Note(.F4,  Duration.sixteenth),
    Note(.G4,  Duration.sixteenth),
    Note(.A4s, Duration.sixteenth),
    Note(.G4,  Duration.sixteenth),
    Note(.A4s, Duration.sixteenth),
    Note(.G4,  Duration.sixteenth)),
  Phrase( // 50
    Note(.F4,  Duration.sixteenth),
    Note(.G4,  Duration.sixteenth)),
  Phrase( // 51
    Note(.F4,  Duration.sixteenth),
    Note(.G4,  Duration.sixteenth),
    Note(.A4s, Duration.sixteenth)),
  Phrase( // 52
    Note(.G4,  Duration.sixteenth),
    Note(.A4s, Duration.sixteenth)),
  Phrase( // 53
    Note(.A4s, Duration.sixteenth),
    Note(.G4,  Duration.sixteenth))]

