
struct BasicPerformanceGenerator : PerformanceGenerator {
  let ensembleSize: Int
  let rando: Rando

  init(ensembleSize: Int, rando: Rando) {
    self.ensembleSize = ensembleSize
    self.rando = rando
  }

  func generate() -> [Part] {
    let performers = (0..<ensembleSize).map { Performer(index: $0, rando: rando) }
    var stats: PerformerStats = performers.reduce(.init()) {
      $0.merge(other: $1.stats)
    }

    while !stats.isDone {
      stats = performers.map {
        $0.tick(elapsed: stats.remainingBeats, minPhrase: stats.minPhrase, maxPhrase: stats.maxPhrase)
      }.reduce(.init()) {
        $0.merge(other: $1)
      }
    }

    let goal = performers.compactMap({ $0.duration }).max() ?? 0.0
    performers.forEach { $0.finish(goal: goal) }

    return performers.map { $0.generatePart() }
  }
}
