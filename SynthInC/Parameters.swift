// Copyright © 2016 Brad Howes. All rights reserved.

import Foundation
import SwiftyUserDefaults

// MARK: - Key definitions

extension DefaultsKeys {
  var randomSeed: DefaultsKey<Int> { .init("randomSeed", defaultValue: 123123) }
  var maxInstrumentCount: DefaultsKey<Int> { .init("maxInstrumentCount", defaultValue: 32) }
  var noteTimingSlop: DefaultsKey<Int> { .init("noteTimingSlop", defaultValue: 30) }
  var seqRepNorm: DefaultsKey<Double> { .init("seqRepNorm", defaultValue: 30.0) }
  var seqRepVar: DefaultsKey<Double> { .init("seqRepVar", defaultValue: 20.0) }
  var ensemble: DefaultsKey<Data?> { .init("ensemble", defaultValue: nil) }
  var performance: DefaultsKey<Data?> { .init("performance", defaultValue: nil) }
}

/**
 Collection of static attributes that obtain/update application parameter settings from/in NSUserDefaults
 */
struct Parameters {
  
  /// Seed value for random number generator
  static var randomSeed: Int {
    get { return Defaults[\.randomSeed] }
    set { Defaults[\.randomSeed] = newValue }
  }
  
  /// Maximum number of instruments that we can create
  static var maxInstrumentCount: Int {
    get { return Defaults[\.maxInstrumentCount] }
    set { Defaults[\.maxInstrumentCount] = newValue }
  }
  
  /// Variability in note ON accuracy
  static var noteTimingSlop: Int {
    get { return Defaults[\.noteTimingSlop] }
    set { Defaults[\.noteTimingSlop] = newValue }
  }
  
  /// A norm number of repetitions of an "In C" phrase. Expressed in beats.
  static var seqRepNorm: Double {
    get { return Defaults[\.seqRepNorm] }
    set { Defaults[\.seqRepNorm] = newValue }
  }
  
  /// The variation about the norm for repetitions of an "In C" phrase. Expressed in beats.
  static var seqRepVar: Double {
    get { return Defaults[\.seqRepVar] }
    set { Defaults[\.seqRepVar] = newValue }
  }
  
  /// The latest ensemble
  static var ensemble: Data? {
    get { return Defaults[\.ensemble] }
    set { Defaults[\.ensemble] = newValue }
  }
  
  /// The latest generated "In C" MIDI phrase sequences
  static var performance: Data? {
    get { return Defaults[\.performance] }
    set { Defaults[\.performance] = newValue }
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
  }
}
