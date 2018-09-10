// Recording.swift
// SynthInC
//
// Created by Brad Howes
// Copyright (c) 2016 Brad Howes. All rights reserved.

import Foundation
import AudioToolbox
import CoreAudio
import AVFoundation
import GameKit

extension Part {
    func createMusicTrack(_ musicSequence: MusicSequence, rando: Rando) -> (MusicTrack, MusicTimeStamp)? {
        var track: MusicTrack? = nil
        if IsAudioError("MusicSequenceNewTrack", MusicSequenceNewTrack(musicSequence, &track)) {
            return nil
        }

        let t = track!
        var clock = 120.scaled
        for (index, playCount) in playCounts.enumerated() {
            let phrase = ScorePhrases[index]
            for _ in 0..<playCount {
                clock = phrase.record(clock: clock) {
                    $1.addToTrack(t, clock: $0, slop: rando.noteOnSlop())
                }
            }
        }

        print("\(index) createMusicTrack - \(t) \(clock)")
        return (t, clock)
    }
}

extension Note {
    func addToTrack(_ track: MusicTrack, clock: MusicTimeStamp, slop: MusicTimeStamp = 0.0) -> Void {
        let beatWhen = getStartTime(clock: clock, slop: slop)
        if note != .re {
            var msg = MIDINoteMessage(channel: 0,
                                      note: UInt8(note.rawValue),
                                      velocity: isGraceNote ? 64 : 127,
                                      releaseVelocity: 0,
                                      duration: Float32(duration - slop))
            let status = MusicTrackNewMIDINoteEvent(track, beatWhen, &msg)
            if status != OSStatus(noErr) {
                print("*** failed creating note event: \(status)")
            }
        }
    }
}

public final class Recording {
    public let musicSequence: MusicSequence
    public let sequenceLength: MusicTimeStamp
    public let tracks: [MusicTrack]

    public init?(performance: Performance, rando: Rando) {
        var musicSequence: MusicSequence?
        guard !IsAudioError("NewMusicSequence", NewMusicSequence(&musicSequence)) else { return nil }

        self.musicSequence = musicSequence!
        let tracks = performance.parts.compactMap { $0.createMusicTrack(musicSequence!, rando: rando) }
        self.sequenceLength = tracks.max(by: { $0.1 < $1.1 })?.1 ?? MusicTimeStamp(0.0)
        self.tracks = tracks.map { $0.0 }

        print("sequenceLength: \(sequenceLength)")
    }

    public init?(data: Data) {
        let decoder = NSKeyedUnarchiver(forReadingWith: data)
        guard let sequenceData = decoder.decodeObject(forKey: "sequenceData") as? Data else {
            print("** invalid NSData for sequence data")
            return nil
        }

        var musicSequence: MusicSequence?
        if IsAudioError("NewMusicSequence", NewMusicSequence(&musicSequence)) { return nil }

        self.musicSequence = musicSequence!

        if IsAudioError("MusicSequenceFileLoadData",
                        MusicSequenceFileLoadData(musicSequence!, sequenceData as CFData, .anyType,
                                                  MusicSequenceLoadFlags())) {
            return nil
        }
        
        let trackCount = decoder.decodeInteger(forKey: "trackCount")
        self.tracks = (0..<trackCount).compactMap {
            var track: MusicTrack?
            if IsAudioError("MusicSequenceGetIndTrack", MusicSequenceGetIndTrack(musicSequence!, UInt32($0), &track)) {
                return nil
            }
            return track!
        }
        
        self.sequenceLength = decoder.decodeDouble(forKey: "sequenceLength")
    }
    
    deinit {
        DisposeMusicSequence(musicSequence)
    }

    public func activate(audioController: AudioController) -> Bool {
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
    public func saveMusicSequence() -> Data? {
        print("-- saving music sequence")
        let data = NSMutableData()
        let encoder = NSKeyedArchiver(forWritingWith: data)

        var cfData: Unmanaged<CFData>?
        if IsAudioError("MusicSequenceFileCreateData", MusicSequenceFileCreateData(musicSequence, .midiType, .eraseFile, 480, &cfData)) {
            return nil
        }

        let sequenceData: Data = cfData!.takeRetainedValue() as Data
        encoder.encode(sequenceData, forKey: "sequenceData")
        encoder.encode(tracks.count, forKey: "trackCount")
        encoder.encode(sequenceLength, forKey: "sequenceLength")

        encoder.finishEncoding()

        return data as Data
    }
}
