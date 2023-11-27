// Copyright © 2016 Brad Howes. All rights reserved.

import Foundation
import Foil

/**
 Collection of static attributes that obtain/update application parameter settings from/in NSUserDefaults.
 */
final class Parameters {
  static let shared = Parameters()

  /// Seed value for random number generator
  @WrappedDefaultOptional(key: .randomSeed)
  var randomSeed: Int?

  /// Maximum number of instruments that we can create
  @WrappedDefaultOptional(key: .maxInstrumentCount)
  var maxInstrumentCount: Int?

  /// Variability in note ON accuracy
  @WrappedDefaultOptional(key: .noteTimingSlop)
  var noteTimingSlop: Double?

  /// A norm number of repetitions of an "In C" phrase. Expressed in beats, where 480 is a quarter note
  @WrappedDefaultOptional(key: .sequenceRepeatingNorm)
  var sequenceRepeatingNorm: Double?

  /// The variation about the norm for repetitions of an "In C" phrase. Expressed in beats.
  @WrappedDefaultOptional(key: .sequenceReatingVariance)
  var sequenceRepeatVariance: Double?

  /// The latest ensemble
  @WrappedDefaultOptional(key: .ensemble)
  var ensemble: Data?

  /// The latest generated "In C" MIDI phrase sequences
  @WrappedDefaultOptional(key: .performance)
  var performance: Data?
}

enum ParametersKey: String, CaseIterable {
  case randomSeed
  case maxInstrumentCount
  case noteTimingSlop
  case sequenceRepeatingNorm
  case sequenceReatingVariance
  case ensemble
  case performance
}

extension WrappedDefault {
  init(wrappedValue: T, key: ParametersKey) {
    self.init(wrappedValue: wrappedValue, key: key.rawValue)
  }
}

extension WrappedDefaultOptional {
  init(key: ParametersKey) {
    self.init(key: key.rawValue)
  }
}

extension Parameters {

  static var randomSeed: Int {
    get { shared.randomSeed ?? 0 }
    set { shared.randomSeed = newValue }
  }

  static var maxInstrumentCount: Int {
    get { shared.maxInstrumentCount ?? 32 }
    set { shared.maxInstrumentCount = newValue }
  }

  static var noteTimingSlop: Double {
    get { shared.noteTimingSlop ?? 0.0 }
    set { shared.noteTimingSlop = newValue }
  }

  static var sequenceRepeatingNorm: Double {
    get { shared.sequenceRepeatingNorm ?? 0.0 }
    set { shared.sequenceRepeatingNorm = newValue }
  }

  static var sequenceRepeatingVariance: Double {
    get { shared.sequenceRepeatVariance ?? 0.0 }
    set { shared.sequenceRepeatVariance = newValue }
  }

  static var ensemble: Data? {
    get { shared.ensemble }
    set { shared.ensemble = newValue }
  }

  static var performance: Data? {
    get { shared.performance }
    set { shared.performance = newValue }
  }

  /**
   Print out the current application settings.
   */
  static func dump() {
    print("randomSeed: \(randomSeed)")
    print("maxInstrumentCount: \(maxInstrumentCount)")
    print("noteTimingSlop: \(noteTimingSlop)")
    print("sequenceRepeatingNorm: \(sequenceRepeatingNorm)")
    print("sequenceRepeatingVariance: \(sequenceRepeatingVariance)")
  }
}
