// Phrases.swift
// SynthInC
//
// Created by Brad Howes
// Copyright (c) 2016 Brad Howes. All rights reserved.

import AVFoundation

/**
 Generate a textual representation of a MIDI note. For instance, MIDI note 60 is "C4" and 73 is "C#5"
 
 - parameter note: the MIDI note to convert
 
 - returns: the note textual representation
 */
private func noteText(_ note: Int) -> String {
    let notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    let octave = (note / 12) - 1
    let index = note % 12
    return "\(notes[index])\(octave)"
}

/// Generator of random note ON slop values.
private let slopGen = RandomGaussian(lowestValue: -Parameters.noteTimingSlop, highestValue: Parameters.noteTimingSlop)

/**
 A note has a time when it begins, a duration (sustain), and a pitch. Notes make up a `Phrase`.
 */
struct Note {
    var when: Int
    var duration: Int
    var note: Int

    /**
     Initialize new Note instance

     - parameter when: when the note beings
     - parameter duration: how long the note plays
     - parameter note: the pitch of the note (a value of zero (0) indicates a rest)
     */
    init(when: Int, duration: Int, note: Int) {
        self.when = when
        self.duration = duration
        self.note = note
    }

    /**
     Create MIDINoteMessage using note data and add it to to a MusicTrack instance.
     
     - parameter track: the MusicTrack instance to add to
     - parameter clock: the current clock value
     - parameter octaveShift: the instrument's octave setting (**not used**)
     
     - returns: the clock value at the end of the note duration
     */
    func addToTrack(_ track: MusicTrack, clock: MusicTimeStamp, octaveShift: Int = 0) -> MusicTimeStamp {
        let slop = slopGen.value
        
        // Calculate the note duration in beats
        //
        let beatDuration = Float32(duration) / Float32(480.0)
        if note != 0 {

            // Calculate when to fire this note (also in beats)
            //
            let beatWhen = clock + Float64(when + slop) / Float64(480.0)

            // Generate a MIDI note ON message and add to the MIDI track
            //
            var msg = MIDINoteMessage(channel: 0, note: UInt8(note + octaveShift * 12), velocity: 64,
                                      releaseVelocity: 0, duration: beatDuration)
            let status = MusicTrackNewMIDINoteEvent(track, beatWhen, &msg)
            if status != OSStatus(noErr) {
                print("*** failed creating note event: \(status)")
            }
        }
        
        // Clock is now the current clock plus the duration of the new note - in beats. We recalculate since we do not
        // want any slop value to affect the overall rhythm.
        return clock + Float64(when) / Float64(480.0) + Float64(beatDuration)
    }
}

/**
 A sequence of notes for a part of the "In C" score.
 */
struct Phrase {
    var duration: Int
    var beats: Double
    var notes: [Note] = []
    init(duration: Int, beats: Double, notes: [Note]) {
        self.duration = duration
        self.beats = beats
        self.notes = notes
    }

    /**
     Add the notes of the phrase to a MusicTrack instance.
     
     - parameter track: the MusicTrack instance to add to
     - parameter clock: the current clock value
     - parameter octaveShift: the instrument's octave setting

     - returns: the clock value at the end of the phrase
     */
    func addToTrack(_ track: MusicTrack, clock: MusicTimeStamp, octaveShift: Int = 0) -> MusicTimeStamp {
        var nextClock = clock
        for note in notes {
            nextClock = note.addToTrack(track, clock: clock, octaveShift: octaveShift)
        }
        return nextClock
    }
}

/// The set of 53 phrases in the "In C" score
let phrases = [
    Phrase(duration: 1440, beats: 3.0, notes: [
        Note(when: 0    , duration: 60  , note: 60),
        Note(when: 60   , duration: 420 , note: 64),
        Note(when: 480  , duration: 60  , note: 60),
        Note(when: 540  , duration: 420 , note: 64),
        Note(when: 960  , duration: 60  , note: 60),
        Note(when: 1020 , duration: 420 , note: 64) ]),
    Phrase(duration: 960, beats: 2.0, notes: [
        Note(when: 0    , duration: 60  , note: 60),
        Note(when: 60   , duration: 180 , note: 64),
        Note(when: 240  , duration: 240 , note: 65),
        Note(when: 480  , duration: 480 , note: 64) ]),
    Phrase(duration: 960, beats: 2.0, notes: [
        Note(when: 240  , duration: 240 , note: 64),
        Note(when: 480  , duration: 240 , note: 65),
        Note(when: 720  , duration: 240 , note: 64) ]),
    Phrase(duration: 960, beats: 2.0, notes: [
        Note(when: 240  , duration: 240 , note: 64),
        Note(when: 480  , duration: 240 , note: 65),
        Note(when: 720  , duration: 240 , note: 67) ]),
    Phrase(duration: 960, beats: 2.0, notes: [
        Note(when: 0    , duration: 240 , note: 64),
        Note(when: 240  , duration: 240 , note: 65),
        Note(when: 480  , duration: 240 , note: 67),
        Note(when: 720  , duration: 240 , note: 0 ) ]),
    Phrase(duration: 3840, beats: 8.0, notes: [
        Note(when: 0    , duration: 3840, note: 72) ]),
    Phrase(duration: 4320, beats: 9.0, notes: [
        Note(when: 1680 , duration: 120 , note: 60),
        Note(when: 1800 , duration: 120 , note: 60),
        Note(when: 1920 , duration: 240 , note: 60),
        Note(when: 2160 , duration: 2160, note: 0 ) ]),
    Phrase(duration: 6720, beats: 14.0, notes: [
        Note(when: 0    , duration: 2880, note: 67),
        Note(when: 2880 , duration: 3840, note: 65) ]),
    Phrase(duration: 1920, beats: 4.0, notes: [
        Note(when: 0    , duration: 120 , note: 71),
        Note(when: 120  , duration: 120 , note: 67),
        Note(when: 240  , duration: 1680, note: 0 ) ]),
    Phrase(duration: 240, beats: 0.5, notes: [
        Note(when: 0    , duration: 120 , note: 71),
        Note(when: 120  , duration: 120 , note: 67) ]),
    Phrase(duration: 720, beats: 1.5, notes: [
        Note(when: 0    , duration: 120 , note: 65),
        Note(when: 120  , duration: 120 , note: 67),
        Note(when: 240  , duration: 120 , note: 71),
        Note(when: 360  , duration: 120 , note: 67),
        Note(when: 480  , duration: 120 , note: 71),
        Note(when: 600  , duration: 120 , note: 67) ]),
    Phrase(duration: 2880, beats: 6.0, notes: [ // 12
        Note(when: 0    , duration: 240 , note: 65),
        Note(when: 240  , duration: 240 , note: 67),
        Note(when: 480  , duration: 1920, note: 71),
        Note(when: 2400 , duration: 480 , note: 72)]),
    Phrase(duration: 2400, beats: 5.0, notes: [ // 13
        Note(when: 0    , duration: 120 , note: 71),
        Note(when: 120  , duration: 360 , note: 67),
        Note(when: 480  , duration: 120 , note: 67),
        Note(when: 600  , duration: 120 , note: 65),
        Note(when: 720  , duration: 240 , note: 67),
        Note(when: 1320 , duration: 1080, note: 67) ]),
    Phrase(duration: 7680, beats: 16.0, notes: [ // 14
        Note(when: 0    , duration: 1920, note: 72),
        Note(when: 1920 , duration: 1920, note: 71),
        Note(when: 3840 , duration: 1920, note: 67),
        Note(when: 5760 , duration: 1920, note: 66) ]),
    Phrase(duration: 2280, beats: 4.75, notes: [ // 15
        Note(when: 0    , duration: 120 , note: 67),
        Note(when: 120 , duration: 2160, note: 0 ) ]),
    Phrase(duration: 480, beats: 1.0, notes: [ // 16
        Note(when: 0    , duration: 120 , note: 67),
        Note(when: 120  , duration: 120 , note: 71),
        Note(when: 240  , duration: 120 , note: 72),
        Note(when: 360  , duration: 120 , note: 71) ]),
    Phrase(duration: 720, beats: 1.5, notes: [ // 17
        Note(when: 0    , duration: 120 , note: 71),
        Note(when: 120  , duration: 120 , note: 72),
        Note(when: 240  , duration: 120 , note: 71),
        Note(when: 360  , duration: 120 , note: 72),
        Note(when: 480  , duration: 120 , note: 71),
        Note(when: 600  , duration: 120 , note: 0) ]),
    Phrase(duration: 960, beats: 2.0, notes: [ // 18
        Note(when: 0    , duration: 120 , note: 64),
        Note(when: 120  , duration: 120 , note: 66),
        Note(when: 240  , duration: 120 , note: 64),
        Note(when: 360  , duration: 120 , note: 66),
        Note(when: 480  , duration: 320 , note: 64),
        Note(when: 800  , duration: 160 , note: 64) ]),
    Phrase(duration: 1440, beats: 3.0, notes: [ // 19
        Note(when: 720  , duration: 720 , note: 79) ]),
    Phrase(duration: 1440, beats: 3.0, notes: [ // 20
        Note(when: 0    , duration: 120 , note: 64),
        Note(when: 120  , duration: 120 , note: 66),
        Note(when: 240  , duration: 120 , note: 64),
        Note(when: 360  , duration: 120 , note: 66),
        Note(when: 480  , duration: 320 , note: 55),
        Note(when: 800  , duration: 160 , note: 64),
        Note(when: 960  , duration: 120 , note: 66),
        Note(when: 1080 , duration: 120 , note: 64),
        Note(when: 1200 , duration: 120 , note: 66),
        Note(when: 1320 , duration: 120 , note: 64) ]),
    Phrase(duration: 1440, beats: 3.0, notes: [ // 21
        Note(when: 0    , duration: 1440, note: 66) ]),
    Phrase(duration: 6000, beats: 12.5, notes: [ // 22
        Note(when: 0    , duration: 720 , note: 64),
        Note(when: 720  , duration: 720 , note: 64),
        Note(when: 1440 , duration: 720 , note: 64),
        Note(when: 2160 , duration: 720 , note: 64),
        Note(when: 2880 , duration: 720 , note: 64),
        Note(when: 3600 , duration: 720 , note: 66),
        Note(when: 4320 , duration: 720 , note: 67),
        Note(when: 5040 , duration: 720 , note: 69),
        Note(when: 5760 , duration: 240 , note: 71) ]),
    Phrase(duration: 5760, beats: 12.0, notes: [ // 23
        Note(when: 0    , duration: 240 , note: 64),
        Note(when: 240  , duration: 720 , note: 66),
        Note(when: 960  , duration: 720 , note: 66),
        Note(when: 1680 , duration: 720 , note: 66),
        Note(when: 2400 , duration: 720 , note: 66),
        Note(when: 3120 , duration: 720 , note: 66),
        Note(when: 3840 , duration: 720 , note: 67),
        Note(when: 4560 , duration: 720 , note: 69),
        Note(when: 5280 , duration: 480 , note: 71) ]),
    Phrase(duration: 5040, beats: 10.5, notes: [ // 24
        Note(when: 0    , duration: 240 , note: 64),
        Note(when: 240  , duration: 240 , note: 66),
        Note(when: 480  , duration: 720 , note: 67),
        Note(when: 1200 , duration: 720 , note: 67),
        Note(when: 1920 , duration: 720 , note: 67),
        Note(when: 2640 , duration: 720 , note: 67),
        Note(when: 3360 , duration: 720 , note: 67),
        Note(when: 4080 , duration: 720 , note: 69),
        Note(when: 4800 , duration: 240 , note: 71) ]),
    Phrase(duration: 5040, beats: 10.5, notes: [ // 25
        Note(when: 0    , duration: 240 , note: 64),
        Note(when: 240  , duration: 240 , note: 66),
        Note(when: 480  , duration: 240 , note: 67),
        Note(when: 720  , duration: 720 , note: 69),
        Note(when: 1440 , duration: 720 , note: 69),
        Note(when: 2160 , duration: 720 , note: 69),
        Note(when: 2880 , duration: 720 , note: 69),
        Note(when: 3600 , duration: 720 , note: 69),
        Note(when: 4320 , duration: 720 , note: 71) ]),
    Phrase(duration: 4560, beats: 9.5, notes: [ // 26
        Note(when: 0    , duration: 240 , note: 64),
        Note(when: 240  , duration: 240 , note: 66),
        Note(when: 480  , duration: 240 , note: 67),
        Note(when: 720  , duration: 240 , note: 69),
        Note(when: 960  , duration: 720 , note: 71),
        Note(when: 1680 , duration: 720 , note: 71),
        Note(when: 2400 , duration: 720 , note: 71),
        Note(when: 3120 , duration: 720 , note: 71),
        Note(when: 3840 , duration: 720 , note: 71) ]),
    Phrase(duration: 1440, beats: 3.0, notes: [ // 27
        Note(when: 0    , duration: 120 , note: 64),
        Note(when: 120  , duration: 120 , note: 66),
        Note(when: 240  , duration: 120 , note: 64),
        Note(when: 360  , duration: 120 , note: 66),
        Note(when: 480  , duration: 240 , note: 67),
        Note(when: 720  , duration: 120 , note: 64),
        Note(when: 840  , duration: 120 , note: 67),
        Note(when: 960  , duration: 120 , note: 66),
        Note(when: 1080 , duration: 120 , note: 64),
        Note(when: 1200 , duration: 120 , note: 66),
        Note(when: 1320 , duration: 120 , note: 64) ]),
    Phrase(duration: 960, beats: 2.0, notes: [ // 28
        Note(when: 0    , duration: 120 , note: 64),
        Note(when: 120  , duration: 120 , note: 66),
        Note(when: 240  , duration: 120 , note: 64),
        Note(when: 360  , duration: 120 , note: 66),
        Note(when: 480  , duration: 360 , note: 64),
        Note(when: 840  , duration: 120 , note: 64) ]),
    Phrase(duration: 4320, beats: 9.0, notes: [ // 29
        Note(when: 0    , duration: 1440, note: 64),
        Note(when: 1440 , duration: 1440, note: 67),
        Note(when: 2880 , duration: 1440, note: 72) ]),
    Phrase(duration: 2880, beats: 6.0, notes: [ // 30
        Note(when: 0    , duration: 2880, note: 72) ]),
    Phrase(duration: 720, beats: 1.5, notes: [ // 31
        Note(when: 0    , duration: 120 , note: 67),
        Note(when: 120  , duration: 120 , note: 65),
        Note(when: 240  , duration: 120 , note: 67),
        Note(when: 360  , duration: 120 , note: 71),
        Note(when: 480  , duration: 120 , note: 67),
        Note(when: 600  , duration: 120 , note: 71) ]),
    Phrase(duration: 2640, beats: 5.5, notes: [ // 32
        Note(when: 0    , duration: 120 , note: 65),
        Note(when: 120  , duration: 120 , note: 67),
        Note(when: 240  , duration: 120 , note: 65),
        Note(when: 360  , duration: 120 , note: 67),
        Note(when: 480  , duration: 120 , note: 71),
        Note(when: 600  , duration: 1400, note: 65),
        Note(when: 2000 , duration: 640 , note: 67) ]),
    Phrase(duration: 480, beats: 1.0, notes: [ // 33
        Note(when: 0    , duration: 120 , note: 67),
        Note(when: 120  , duration: 120 , note: 65),
        Note(when: 240  , duration: 240 , note: 0) ]),
    Phrase(duration: 240, beats: 0.5, notes: [ // 34
        Note(when: 0    , duration: 120 , note: 67),
        Note(when: 120  , duration: 120 , note: 65) ]),
    Phrase(duration: 15360, beats: 32.0, notes: [ // 35
        Note(when: 0    , duration: 120 , note: 65),
        Note(when: 120  , duration: 120 , note: 67),
        Note(when: 240  , duration: 120 , note: 71),
        Note(when: 360  , duration: 120 , note: 67),
        Note(when: 480  , duration: 120 , note: 71),
        Note(when: 600  , duration: 120 , note: 67),
        Note(when: 720  , duration: 120 , note: 71),
        Note(when: 840  , duration: 120 , note: 67),
        Note(when: 960  , duration: 120 , note: 71),
        Note(when: 1080 , duration: 120 , note: 67),
        Note(when: 2880 , duration: 480 , note: 70),
        Note(when: 3360 , duration: 1440, note: 79),
        Note(when: 4800 , duration: 240 , note: 81),
        Note(when: 5040 , duration: 480 , note: 79),
        Note(when: 5520 , duration: 240 , note: 83),
        Note(when: 5760 , duration: 720 , note: 81),
        Note(when: 6480 , duration: 240 , note: 79),
        Note(when: 6720 , duration: 1440, note: 76),
        Note(when: 8160 , duration: 240 , note: 79),
        Note(when: 8400 , duration: 1680, note: 78),
        Note(when: 11280, duration: 1200, note: 76),
        Note(when: 12480, duration: 2880, note: 77) ]),
    Phrase(duration: 720, beats: 1.5, notes: [ // 36
        Note(when: 0    , duration: 120 , note: 65),
        Note(when: 120  , duration: 120 , note: 67),
        Note(when: 240  , duration: 120 , note: 71),
        Note(when: 360  , duration: 120 , note: 67),
        Note(when: 480  , duration: 120 , note: 71),
        Note(when: 600  , duration: 120 , note: 67) ]),
    Phrase(duration: 240, beats: 0.5, notes: [ // 37
        Note(when: 0    , duration: 120 , note: 65),
        Note(when: 120  , duration: 120 , note: 67) ]),
    Phrase(duration: 360, beats: 0.75, notes: [ // 38
        Note(when: 0    , duration: 120 , note: 65),
        Note(when: 120  , duration: 120 , note: 67),
        Note(when: 240  , duration: 120 , note: 71) ]),
    Phrase(duration: 720, beats: 1.5, notes: [ // 39
        Note(when: 0    , duration: 120 , note: 71),
        Note(when: 120  , duration: 120 , note: 67),
        Note(when: 240  , duration: 120 , note: 65),
        Note(when: 360  , duration: 120 , note: 67),
        Note(when: 480  , duration: 120 , note: 71),
        Note(when: 600  , duration: 120 , note: 72) ]),
    Phrase(duration: 240, beats: 0.5, notes: [ // 40
        Note(when: 0    , duration: 120 , note: 71),
        Note(when: 120  , duration: 120 , note: 65) ]),
    Phrase(duration: 240, beats: 0.5, notes: [ // 41
        Note(when: 0    , duration: 120 , note: 71),
        Note(when: 120  , duration: 120 , note: 67) ]),
    Phrase(duration: 7680, beats: 16.0, notes: [ // 42
        Note(when: 0    , duration: 1920, note: 72),
        Note(when: 1920 , duration: 1920, note: 71),
        Note(when: 3840 , duration: 1920, note: 69),
        Note(when: 5760 , duration: 1920, note: 72) ]),
    Phrase(duration: 1440, beats: 3.0, notes: [ // 43
        Note(when: 0    , duration: 120 , note: 77),
        Note(when: 120  , duration: 120 , note: 76),
        Note(when: 240  , duration: 120 , note: 77),
        Note(when: 360  , duration: 120 , note: 76),
        Note(when: 480  , duration: 240 , note: 76),
        Note(when: 720  , duration: 240 , note: 76),
        Note(when: 960  , duration: 240 , note: 76),
        Note(when: 1200 , duration: 120 , note: 77),
        Note(when: 1320 , duration: 120 , note: 76) ]),
    Phrase(duration: 1440, beats: 3.0, notes: [ // 44
        Note(when: 0    , duration: 240 , note: 77),
        Note(when: 240  , duration: 480 , note: 76),
        Note(when: 720  , duration: 240 , note: 76),
        Note(when: 960  , duration: 480 , note: 72) ]),
    Phrase(duration: 1440, beats: 3.0, notes: [ // 45
        Note(when: 0    , duration: 480 , note: 74),
        Note(when: 480  , duration: 480 , note: 74),
        Note(when: 960  , duration: 480 , note: 67) ]),
    Phrase(duration: 2400, beats: 5.0, notes: [ // 46
        Note(when: 0    , duration: 120 , note: 67),
        Note(when: 120  , duration: 120 , note: 74),
        Note(when: 240  , duration: 120 , note: 76),
        Note(when: 360  , duration: 120 , note: 74),
        Note(when: 720  , duration: 240 , note: 67),
        Note(when: 1200 , duration: 240 , note: 67),
        Note(when: 1680 , duration: 240 , note: 67),
        Note(when: 1920 , duration: 120 , note: 67),
        Note(when: 2040 , duration: 120 , note: 74),
        Note(when: 2160 , duration: 120 , note: 76),
        Note(when: 2280 , duration: 120 , note: 74) ]),
    Phrase(duration: 960, beats: 2.0, notes: [ // 47
        Note(when: 0    , duration: 120 , note: 74),
        Note(when: 120  , duration: 120 , note: 76),
        Note(when: 240  , duration: 240 , note: 74),
        Note(when: 480  , duration: 120 , note: 74),
        Note(when: 600  , duration: 120 , note: 76),
        Note(when: 720  , duration: 240 , note: 74) ]),
    Phrase(duration: 7200, beats: 15.0, notes: [ // 48
        Note(when: 0    , duration: 2880, note: 67),
        Note(when: 2880 , duration: 1920, note: 67),
        Note(when: 4800 , duration: 2400, note: 65) ]),
    Phrase(duration: 720, beats: 1.5, notes: [ // 49
        Note(when: 0    , duration: 120 , note: 65),
        Note(when: 120  , duration: 120 , note: 67),
        Note(when: 240  , duration: 120 , note: 70),
        Note(when: 360  , duration: 120 , note: 67),
        Note(when: 480  , duration: 120 , note: 70),
        Note(when: 600  , duration: 120 , note: 67) ]),
    Phrase(duration: 240, beats: 0.5, notes: [ // 50
        Note(when: 0    , duration: 120 , note: 65),
        Note(when: 120  , duration: 120 , note: 67) ]),
    Phrase(duration: 360, beats: 0.75, notes: [ // 51
        Note(when: 0    , duration: 120 , note: 65),
        Note(when: 120  , duration: 120 , note: 67),
        Note(when: 240  , duration: 120 , note: 70) ]),
    Phrase(duration: 240, beats: 0.5, notes: [ // 52
        Note(when: 0    , duration: 120 , note: 67),
        Note(when: 120  , duration: 120 , note: 70) ]),
    Phrase(duration: 240, beats: 0.5, notes: [ // 53
        Note(when: 0    , duration: 120 , note: 70),
        Note(when: 120  , duration: 120 , note: 67) ])]
