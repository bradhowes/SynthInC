// Copyright © 2018 Brad Howes. All rights reserved.

import AVFoundation
import Foundation
import GameKit

protocol Rando {
  func passes(threshold: Int) -> Bool
  func phraseRepetitions(phraseIndex: Int) -> Int
  func noteOnSlop() -> MusicTimeStamp
  func uniform() -> Double
  func pick(from range: ClosedRange<Int>) -> Int
  func pick(from range: Range<Int>) -> Int
}

struct RandomSources : Rando {
  private let config: Config
  private let randomSource: GKARC4RandomSource
  private let d100: GKRandomDistribution
  private let phraseDurationGen: GKRandomDistribution

  struct Config {
    let seed: Int
    let minPhraseDurationSeconds: Double
    let maxPhraseDurationSeconds: Double
    let minSlopRange: Double
    let maxSlopRange: Double

    init(seed: Int = 0,
         minPhraseDurationSeconds: Double = 25.0,
         maxPhraseDurationSeconds: Double = 100.0,
         minSlopRange: Int = 0,
         maxSlopRange: Int = 0) {
      self.seed = seed
      self.minPhraseDurationSeconds = minPhraseDurationSeconds
      self.maxPhraseDurationSeconds = maxPhraseDurationSeconds
      self.minSlopRange = minSlopRange.scaled
      self.maxSlopRange = maxSlopRange.scaled
    }
  }

  init(config: Config = Config()) {
    self.config = config
    if config.seed > 0 {
      var randomSeed = config.seed
      let seedData = NSMutableData(bytes:&randomSeed, length: MemoryLayout.size(ofValue: randomSeed)) as Data
      self.randomSource = GKARC4RandomSource(seed: seedData)
    }
    else {
      self.randomSource = GKARC4RandomSource()
    }

    self.randomSource.dropValues(800)
    self.d100 = GKRandomDistribution(lowestValue: 0, highestValue: 100)

    let rate = 120.0 // beats per minute
    let lowRepCount = Int(rate * config.minPhraseDurationSeconds / 60.0)
    let highRepCount = Int(rate * config.maxPhraseDurationSeconds / 60.0)
    self.phraseDurationGen = GKGaussianDistribution(lowestValue: lowRepCount, highestValue: highRepCount)
  }

  func passes(threshold: Int) -> Bool {
    d100.nextInt() < threshold
  }

  func phraseRepetitions(phraseIndex: Int) -> Int {
    Int((MusicTimeStamp(phraseDurationGen.nextInt()) / Score.phrases[phraseIndex].duration).rounded(.up))
  }

  func noteOnSlop() -> MusicTimeStamp {
    return uniform() * (config.maxSlopRange - config.minSlopRange) + config.minSlopRange
  }

  func uniform() -> Double {
    Double(randomSource.nextUniform())
  }

  func pick(from range: ClosedRange<Int>) -> Int {
    Int(uniform() * Double(range.upperBound - range.lowerBound)) + range.lowerBound
  }

  func pick(from range: Range<Int>) -> Int {
    Int(uniform() * Double(range.upperBound + 1 - range.lowerBound)) + range.lowerBound
  }
}
