// Copyright © 2016 Brad Howes. All rights reserved.

import Foundation
import AVFoundation

public let phraseBeats = ScorePhrases.map { Int($0.duration * 4) }

public struct PerformerStats {
  let remainingBeats: Int
  let minPhrase: Int
  let maxPhrase: Int
  public var isDone: Bool { return remainingBeats == Int.max }
  
  public init() {
    self.init(remainingBeats: Int.max, minPhrase: Int.max, maxPhrase: Int.min)
  }
  
  public init(currentPhrase: Int) {
    self.init(remainingBeats: Int.max, minPhrase: currentPhrase, maxPhrase: currentPhrase)
  }
  
  public init(remainingBeats: Int, currentPhrase: Int) {
    self.init(remainingBeats: remainingBeats, minPhrase: currentPhrase, maxPhrase: currentPhrase)
  }
  
  public init(remainingBeats: Int, minPhrase: Int, maxPhrase: Int) {
    self.remainingBeats = remainingBeats
    self.minPhrase = minPhrase
    self.maxPhrase = maxPhrase
  }
  
  public func merge(other: PerformerStats) -> PerformerStats {
    PerformerStats(remainingBeats: min(remainingBeats, other.remainingBeats),
                   minPhrase: min(minPhrase, other.minPhrase),
                   maxPhrase: max(maxPhrase, other.maxPhrase))
  }
  
  public func merge(other: Performer) -> PerformerStats {
    PerformerStats(remainingBeats: min(remainingBeats, other.remainingBeats),
                   minPhrase: min(minPhrase, other.currentPhrase),
                   maxPhrase: max(maxPhrase, other.currentPhrase))
  }
}

public final class Performer {
  private let index: Int
  private let rando: Rando
  
  public private(set) var currentPhrase = 0
  public private(set) var remainingBeats: Int
  public private(set) var played: Int = 0
  public private(set) var desiredPlays: Int = 1
  public private(set) var playCounts: [Int] = []
  public private(set) var duration: MusicTimeStamp = 0.0
  
  public init(index: Int, rando: Rando) {
    self.index = index
    self.rando = rando
    self.remainingBeats = phraseBeats[0]
    self.playCounts.reserveCapacity(ScorePhrases.count)
  }
  
  public func tick(elapsed: Int, minPhrase: Int, maxPhrase: Int) -> PerformerStats {
    if currentPhrase == ScorePhrases.count {
      return PerformerStats(currentPhrase: currentPhrase)
    }
    
    remainingBeats -= elapsed
    if remainingBeats == 0 {
      played += 1
      let moveProb = currentPhrase == 0 ? 100 :
      max(maxPhrase - currentPhrase, 0) * 15 - max(currentPhrase - minPhrase, 0) * 15 +
      max(played - desiredPlays + 1, 0) * 100
      
      if rando.passes(threshold: moveProb) {
        playCounts.append(played)
        duration += MusicTimeStamp(played) * ScorePhrases[currentPhrase].duration
        currentPhrase += 1
        if currentPhrase == ScorePhrases.count {
          return PerformerStats(currentPhrase: currentPhrase)
        }
        
        played = 0
        desiredPlays = rando.phraseRepetitions(phraseIndex: currentPhrase)
      }
      
      remainingBeats = phraseBeats[currentPhrase]
    }
    
    return PerformerStats(remainingBeats: remainingBeats, currentPhrase: currentPhrase)
  }
  
  public func finish(goal: MusicTimeStamp) {
    precondition(playCounts.count == ScorePhrases.count)
    guard let lastPhrase = ScorePhrases.last else { return }
    while duration + lastPhrase.duration < goal {
      playCounts[ScorePhrases.count - 1] += 1
      duration += lastPhrase.duration
    }
  }
}

public protocol PerformanceGenerator {
  func generate() -> [Part]
}

public final class BasicPerformanceGenerator : PerformanceGenerator {
  var performers: [Performer]
  
  public init(ensembleSize: Int, rando: Rando) {
    performers = (0..<ensembleSize).map { Performer(index: $0, rando: rando) }
  }
  
  public func generate() -> [Part] {
    var stats = performers.reduce(PerformerStats()) { $0.merge(other: $1) }
    while !stats.isDone {
      stats = performers.map({$0.tick(elapsed: stats.remainingBeats, minPhrase: stats.minPhrase, 
                                      maxPhrase: stats.maxPhrase)})
        .reduce(PerformerStats()) { $0.merge(other: $1) }
    }
    
    let goal = performers.compactMap({ $0.duration }).max() ?? 0.0
    performers.forEach { $0.finish(goal: goal) }
    
    return performers.map { $0.generatePart() }
  }
}

public class Part {
  public let index: Int
  public let playCounts: [Int]
  public let normalizedRunningDurations: [CGFloat]
  
  public init(index: Int, playCounts: [Int], duration: MusicTimeStamp) {
    self.index = index
    self.playCounts = playCounts
    let durations = zip(playCounts, ScorePhrases).map { MusicTimeStamp($0.0) * $0.1.duration }
    let elapsed = durations.reduce(into: Array<MusicTimeStamp>()) {
      $0.append(($0.last ?? ($0.reserveCapacity(playCounts.count), 0.0).1) + MusicTimeStamp($1))
    }
    normalizedRunningDurations = elapsed.map { CGFloat($0 / duration) }
  }
  
  public init?(data: Data) {
    guard let decoder = try? NSKeyedUnarchiver(forReadingFrom: data) else { return nil }
    self.index = decoder.decodeInteger(forKey: "index")
    guard let playCounts = decoder.decodeObject(forKey: "playCounts") as? [Int] else { return nil }
    guard 
      let normalizedRunningDurations = decoder.decodeObject(forKey: "normalizedRunningDurations") as? [CGFloat]
    else {
      return nil
    }
    self.playCounts = playCounts
    self.normalizedRunningDurations = normalizedRunningDurations
  }
  
  public func encodePerformance() -> Data {
    let encoder = NSKeyedArchiver(requiringSecureCoding: false)
    encoder.encode(index, forKey: "index")
    encoder.encode(playCounts, forKey: "playCounts")
    encoder.encode(normalizedRunningDurations, forKey: "normalizedRunningDurations")
    encoder.finishEncoding()
    return encoder.encodedData
  }
  
  public func timeline() -> String {
    "\(index):" + playCounts.enumerated().map({"\($0.0)" +
      String(repeating: "-", count: Int(((MusicTimeStamp($0.1) * ScorePhrases[$0.0].duration)).rounded(.up)))})
    .joined()
  }
}

extension Performer {
  func generatePart() -> Part {
    return Part(index: index, playCounts: playCounts, duration: duration)
  }
}

public class Performance {
  public let parts: [Part]

  public init(perfGen: PerformanceGenerator) {
    self.parts = perfGen.generate()
  }

  public init?(data: Data) {
    guard let decoder = try? NSKeyedUnarchiver(forReadingFrom: data) else { return nil }
    guard let configs = decoder.decodeObject(forKey: "parts") as? [Data] else { return nil }
    let parts = configs.compactMap{ Part(data: $0) }
    guard configs.count == parts.count else { return nil }
    self.parts = parts
  }

  public func encodePerformance() -> Data {
    let encoder = NSKeyedArchiver(requiringSecureCoding: false)
    encoder.encode(parts.map { $0.encodePerformance() }, forKey: "parts")
    encoder.finishEncoding()
    return encoder.encodedData
  }

  public func playCounts() -> String {
    parts.map {
      $0.playCounts.map {
        String($0)
      }.joined(separator: " ")
    }.joined(separator: "\n")
  }

  public func timelines() -> String {
    parts.map { 
      $0.timeline()
    }.joined(separator: "\n")
  }
}
