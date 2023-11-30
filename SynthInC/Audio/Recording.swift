// Copyright © 2016 Brad Howes. All rights reserved.

import Foundation
import AudioToolbox
import CoreAudio
import AVFoundation

struct Recording {
  let musicSequence: MusicSequence
  let sequenceLength: MusicTimeStamp
  let tracks: [MusicTrack]
  private let finalizer: Finalizer

  init?(performance: Performance, rando: Rando) {
    guard let musicSequence = newMusicSequence() else { return nil }
    self.musicSequence = musicSequence
    let tracks = performance.parts.compactMap { $0.createMusicTrack(musicSequence, rando: rando) }
    self.sequenceLength = tracks.max(by: { $0.1 < $1.1 } )?.1 ?? MusicTimeStamp(0.0)
    self.tracks = tracks.map { $0.0 }
    self.finalizer = Finalizer { DisposeMusicSequence(musicSequence) }
    print("sequenceLength: \(sequenceLength)")
  }

  init?(data: Data) {
    guard let decoder = try? NSKeyedUnarchiver(forReadingFrom: data) else { return nil }
    decoder.requiresSecureCoding = false
    guard let sequenceData = decoder.decodeObject(forKey: "sequenceData") as? Data else {
      print("** invalid NSData for sequence data")
      return nil
    }

    guard let musicSequence = newMusicSequence() else { return nil }
    self.musicSequence = musicSequence

    if IsAudioError("MusicSequenceFileLoadData",
                    MusicSequenceFileLoadData(musicSequence, sequenceData as CFData, .anyType,
                                              MusicSequenceLoadFlags())) {
      return nil
    }

    let trackCount = decoder.decodeInteger(forKey: "trackCount")
    self.tracks = (0..<trackCount).compactMap { getMusicTrack(from: musicSequence, at: $0) }
    self.sequenceLength = decoder.decodeDouble(forKey: "sequenceLength")
    self.finalizer = Finalizer { DisposeMusicSequence(musicSequence) }
  }

  func activate(audioController: AudioController) -> Bool {
    guard let graph = audioController.graph else { return false }
    guard audioController.ensemble.count == tracks.count else { return false }

    if IsAudioError("MusicSequenceSetAUGraph", MusicSequenceSetAUGraph(musicSequence, graph)) {
      return false
    }

    for (track, instrument) in zip(tracks, audioController.ensemble) {
      if IsAudioError("MusicTrackSetDestNode", MusicTrackSetDestNode(track, instrument.samplerNode)) {
        return false
      }
    }

    return true
  }

  /**
   Save the current MusicSequence instance.

   - returns: true if successful
   */
  func saveMusicSequence() -> Data? {
    print("-- saving music sequence")
    let encoder = NSKeyedArchiver(requiringSecureCoding: false)
    var cfData: Unmanaged<CFData>?
    if IsAudioError("MusicSequenceFileCreateData",
                    MusicSequenceFileCreateData(musicSequence, .midiType, .eraseFile, 480, &cfData)) {
      return nil
    }

    let sequenceData: Data = cfData!.takeRetainedValue() as Data
    encoder.encode(sequenceData, forKey: "sequenceData")
    encoder.encode(tracks.count, forKey: "trackCount")
    encoder.encode(sequenceLength, forKey: "sequenceLength")
    encoder.finishEncoding()
    return encoder.encodedData
  }
}

private func newMusicSequence() -> MusicSequence? {
  var sequence: MusicSequence?
  return IsAudioError("NewMusicSequence",
                      NewMusicSequence(&sequence)) ? nil : sequence
}

private func getMusicTrack(from musicSequence: MusicSequence, at index: Int) -> MusicTrack? {
  var track: MusicTrack?
  return IsAudioError("MusicSequenceGetIndTrack",
                      MusicSequenceGetIndTrack(musicSequence, UInt32(index), &track)) ? nil : track
}

private class Finalizer {
  let onDeinit: () -> Void

  init(onDeinit: @escaping () -> Void) {
    self.onDeinit = onDeinit
  }

  deinit { onDeinit() }
}

