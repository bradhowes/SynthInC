// Copyright © 2016 Brad Howes. All rights reserved.

import AVFoundation

/**
 A sequence of notes for a part of the "In C" score. There are 53 phrases in the "In C" score. Phrases do not all have
 the same duration in beats, which can lead to interesting polyrythmic interplay when they are combined.
 */
struct Phrase {

  /// The collection of notes in the phrase
  let notes: [Note]
  /// The duration required to play all of the notes in the phrase
  let duration: MusicTimeStamp

  /**
   Create a new Phrase using a sequence of Note objects.
   
   - parameter notes: one or or more Note objects that make up the phrase
   */
  init(_ notes: Note...) {
    self.notes = notes
    self.duration = notes.filter{ $0.duration > 0 }.reduce(0.0) { $0 + $1.duration }
  }

  /**
   Obtain the clock time at the end of the phrase.

   - parameter clock: the current clock value
   - parameter recorder: the optional function to pass in each note
   - returns: the ending clock value
   */
  func advance(clock: MusicTimeStamp, recorder: ((MusicTimeStamp, Note)->Void)? = nil) -> MusicTimeStamp {
    switch recorder {
    case let r?: return notes.reduce(clock) { r($0, $1); return $1.getEndTime(clock: $0) }
    case nil: return notes.reduce(clock) { $1.getEndTime(clock: $0) }
    }
  }
}
