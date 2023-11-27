// Copyright © 2016 Brad Howes. All rights reserved.

import AVFoundation
import Foundation

/**
 Generate a textual representation of a MIDI note. For instance, MIDI note 60 is "C4" and 73 is "C#5"

 - parameter note: the MIDI note to convert

 - returns: the note textual representation
 */
public func noteText(_ note: Int) -> String {
  let notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
  let octave = (note / 12) - 1
  let index = note % 12
  return "\(notes[index])\(octave)"
}

// Define some common durations. For reasons lost to me, a quarter note is defined as 480, so a 32nd note would be 60.
// Once we move to the AVFoundation level though, we deal with MusicTimeStamp values which are just Doubles.
// Duration.quarter == 480
// Duration.quarter == MusicTimeStamp(1.0)

public typealias Duration = Int


/// Additional functions for Duration values.
public extension Duration {

  /// Calculate a dotted note duration
  var dotted: Duration { return self + self / 2 }
  /// Obtain a scaled note duration, where 1.0 is a 1/4 note (why?)
  var scaled: MusicTimeStamp { return MusicTimeStamp(self) / MusicTimeStamp(480.0) }
  /// Obtain a grace note duration
  var grace: Duration { return -abs(self / 2) }

  static let thirtysecond = 60
  static let sixteenth = thirtysecond * 2 //  120
  static let eighth = sixteenth * 2       //  240
  static let quarter = eighth * 2         //  480
  static let half = quarter * 2           //  960
  static let whole = half * 2             // 1920
}

/// Enumeration of all of the notes in the "In C" score. The assigned integers are the MIDI note values.
public enum NoteValue : Int {
  case re = 0
  case G3 = 55
  case C4 = 60
  case C4s = 61
  case D4 = 62
  case D4s = 63
  case E4 = 64
  case F4 = 65
  case F4s = 66
  case G4 = 67
  case G4s = 68
  case A4 = 69
  case A4s = 70
  case B4 = 71
  case C5 = 72
  case C5s = 73
  case D5 = 74
  case D5s = 75
  case E5 = 76
  case F5 = 77
  case F5s = 78
  case G5 = 79
  case G5s = 80
  case A5 = 81
  case A5s = 82
  case B5 = 83
  case C6 = 84
}

/**
 A note has a pitch and a duration (sustain). Notes make up a `Phrase`.
 */
public struct Note {
  let note: NoteValue
  let isGraceNote: Bool
  let duration: MusicTimeStamp

  /**
   Initialize new Note instance

   - parameter note: the pitch of the note (a value of zero (0) indicates a rest)
   - parameter duration: how long the note plays (120 is a sixteenth note)
   */
  public init(_ note: NoteValue, _ duration: Duration) {
    self.note = note
    self.isGraceNote = duration < 0
    self.duration = abs(duration.scaled)
  }

  /**
   Obtain the time when this note starts playing

   - parameter clock: the current clock time
   - parameter slop: random variation to apply to the time
   - returns: start time
   */
  public func getStartTime(clock: MusicTimeStamp, slop: MusicTimeStamp) -> MusicTimeStamp {
    return clock + (isGraceNote ? -duration : slop)
  }

  /**
   Obtain the time when this note stops playing

   - parameter clock: the current clock time
   - returns: end time
   */
  public func getEndTime(clock: MusicTimeStamp) -> MusicTimeStamp {
    return isGraceNote ? clock : clock + duration
  }
}
