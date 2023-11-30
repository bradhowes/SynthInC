struct PerformerStats {
  let remainingBeats: Int
  let minPhrase: Int
  let maxPhrase: Int

  var isDone: Bool { remainingBeats == Int.max }

  init() {
    self.init(remainingBeats: Int.max, minPhrase: Int.max, maxPhrase: Int.min)
  }

  init(currentPhrase: Int) {
    self.init(remainingBeats: Int.max, minPhrase: currentPhrase, maxPhrase: currentPhrase)
  }

  init(remainingBeats: Int, currentPhrase: Int) {
    self.init(remainingBeats: remainingBeats, minPhrase: currentPhrase, maxPhrase: currentPhrase)
  }

  init(remainingBeats: Int, minPhrase: Int, maxPhrase: Int) {
    self.remainingBeats = remainingBeats
    self.minPhrase = minPhrase
    self.maxPhrase = maxPhrase
  }

  func merge(other: PerformerStats) -> PerformerStats {
    PerformerStats(remainingBeats: min(remainingBeats, other.remainingBeats),
                   minPhrase: min(minPhrase, other.minPhrase),
                   maxPhrase: max(maxPhrase, other.maxPhrase))
  }
}
