// Parameters.swift
// SynthInC
//
// Created by Brad Howes
// Copyright (c) 2016 Brad Howes. All rights reserved.

import Foundation
import SwiftyUserDefaults

// MARK: - Key definitions
extension DefaultsKeys {
    static let randomSeed = DefaultsKey<Int?>("randomSeed")
    static let maxInstrumentCount = DefaultsKey<Int?>("maxInstrumentCount")
    static let noteTimingSlop = DefaultsKey<Int?>("noteTimingSlop")
    static let seqRepNorm = DefaultsKey<Double?>("seqRepNorm")
    static let seqRepVar = DefaultsKey<Double?>("seqRepVar")
    static let soundFont = DefaultsKey<String?>("soundFont")
    static let setup = DefaultsKey<Data?>("setup")
    static let sequence = DefaultsKey<Data?>("sequence")
}

/**
 Collection of static attributes that obtain/update application parameter settings from/in NSUserDefaults
 */
struct Parameters {

    /// Seed value for random number generator
    static var randomSeed: Int {
        get { return Defaults[.randomSeed] ?? 123123 }
        set { Defaults[.randomSeed] = newValue }
    }

    /// Maximum number of instruments that we can create
    static var maxInstrumentCount: Int {
        get { return Defaults[.maxInstrumentCount] ?? 32 }
        set { Defaults[.maxInstrumentCount] = newValue }
    }

    /// Variability in note ON accuracy
    static var noteTimingSlop: Int {
        get { return Defaults[.noteTimingSlop] ?? 30 }
        set { Defaults[.noteTimingSlop] = newValue }
    }

    /// A norm number of repetitions of an "In C" phrase. Expressed in beats.
    static var seqRepNorm: Double {
        get { return Defaults[.seqRepNorm] ?? 30 }
        set { Defaults[.seqRepNorm] = newValue }
    }
    
    /// The variation about the norm for repetitions of an "In C" phrase. Expressed in beats.
    static var seqRepVar: Double {
        get { return Defaults[.seqRepVar] ?? 20 }
        set { Defaults[.seqRepVar] = newValue }
    }

    /// The default sound font to use if one is not found
    static var soundFont: String {
        get { return Defaults[.soundFont] ?? "FreeFont" }
        set { Defaults[.soundFont] = newValue }
    }

    /// The latest instruments setup data
    static var setup: Data? {
        get { return Defaults[.setup] }
        set { Defaults[.setup] = newValue }
    }

    /// The latest generated "In C" MIDI phrase sequences
    static var sequence: Data? {
        get { return Defaults[.sequence] }
        set { Defaults[.sequence] = newValue }
    }

    /**
     Print out the current application settings.
     */
    static func dump() {
        print("randomSeed: \(randomSeed)")
        print("maxInstrumentCount: \(maxInstrumentCount)")
        print("noteTimingSlop: \(noteTimingSlop)")
        print("seqRepNorm: \(seqRepNorm)")
        print("seqRepVar: \(seqRepVar)")
        print("soundFont: \(soundFont)")
    }
}
